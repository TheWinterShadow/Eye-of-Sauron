"""GitHub Actions Historical Run Collector.

Polls the GitHub Actions API for completed workflow runs and pushes
structured JSON log entries to Grafana Cloud Loki for historical dashboards.
"""

import base64
import json
import logging
import os
import signal
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
class Config:
    def __init__(self):
        self.github_token = os.environ["GITHUB_TOKEN"]
        self.loki_url = os.environ["LOKI_URL"]
        self.loki_user = os.environ["LOKI_USER"]
        self.loki_api_key = os.environ["LOKI_API_KEY"]
        self.poll_interval = int(os.getenv("POLL_INTERVAL", "300"))
        self.backfill_days = int(os.getenv("BACKFILL_DAYS", "7"))
        self.state_file = Path(os.getenv("STATE_FILE", "/data/collector_state.json"))
        self.log_level = os.getenv("LOG_LEVEL", "INFO")

        repos_str = os.getenv("RESOLVED_REPOS", "")
        self.repos = [r.strip() for r in repos_str.split(",") if r.strip()]
        if not self.repos:
            raise ValueError(
                "No repositories resolved. "
                "Set GITHUB_ORGAS, GITHUB_USERS, or GITHUB_REPOS."
            )


# ---------------------------------------------------------------------------
# GitHub API Client
# ---------------------------------------------------------------------------
class GitHubClient:
    BASE_URL = "https://api.github.com"

    def __init__(self, token: str):
        self.token = token
        self.rate_remaining = 5000
        self.rate_reset = 0

    def _request(self, url: str):
        req = urllib.request.Request(url)
        req.add_header("Authorization", f"token {self.token}")
        req.add_header("Accept", "application/vnd.github.v3+json")
        req.add_header("User-Agent", "eye-of-sauron-collector")

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                self.rate_remaining = int(
                    resp.headers.get("X-RateLimit-Remaining", 5000)
                )
                self.rate_reset = int(resp.headers.get("X-RateLimit-Reset", 0))
                link_header = resp.headers.get("Link", "")
                data = json.loads(resp.read().decode())
                return data, link_header
        except urllib.error.HTTPError as e:
            if e.code == 403 and self.rate_remaining == 0:
                wait = max(self.rate_reset - int(time.time()), 1)
                log.warning("Rate limited. Sleeping %ds until reset.", wait)
                time.sleep(wait)
                return self._request(url)
            raise

    @staticmethod
    def _parse_next_url(link_header: str):
        if not link_header:
            return None
        for part in link_header.split(","):
            if 'rel="next"' in part:
                return part.split(";")[0].strip().strip("<>")
        return None

    def get_workflow_runs(self, repo: str, since: str = None):
        url = f"{self.BASE_URL}/repos/{repo}/actions/runs?status=completed&per_page=100"
        if since:
            url += f"&created=>={since}"

        all_runs = []
        while url:
            data, link_header = self._request(url)
            runs = data.get("workflow_runs", [])
            if not runs:
                break
            all_runs.extend(runs)
            url = self._parse_next_url(link_header)
            if len(all_runs) > 5000:
                log.warning("Stopping pagination at 5000 runs for %s", repo)
                break

        return all_runs


# ---------------------------------------------------------------------------
# Loki Push Client
# ---------------------------------------------------------------------------
class LokiClient:
    def __init__(self, url: str, user: str, api_key: str):
        self.url = url
        self.credentials = base64.b64encode(
            f"{user}:{api_key}".encode()
        ).decode()

    def push(self, entries: list):
        if not entries:
            return

        streams = {}
        for entry in entries:
            key = json.dumps(entry["labels"], sort_keys=True)
            if key not in streams:
                streams[key] = {"stream": entry["labels"], "values": []}
            streams[key]["values"].append(
                [entry["timestamp_ns"], entry["line"]]
            )

        payload = json.dumps({"streams": list(streams.values())}).encode()

        req = urllib.request.Request(self.url, data=payload, method="POST")
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", f"Basic {self.credentials}")

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                if resp.status == 204:
                    log.info("Pushed %d entries to Loki", len(entries))
                else:
                    log.warning("Loki returned status %d", resp.status)
        except urllib.error.HTTPError as e:
            body = e.read().decode() if e.fp else ""
            log.error("Loki push failed: %d %s", e.code, body)
            raise


# ---------------------------------------------------------------------------
# State Management (dedup)
# ---------------------------------------------------------------------------
class StateManager:
    def __init__(self, state_file: Path):
        self.state_file = state_file
        self.state = self._load()

    def _load(self) -> dict:
        if self.state_file.exists():
            try:
                with open(self.state_file) as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                log.warning("Corrupt state file, starting fresh")
        return {}

    def save(self):
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.state_file.with_suffix(".tmp")
        with open(tmp, "w") as f:
            json.dump(self.state, f, indent=2)
        tmp.rename(self.state_file)

    def get_last_updated(self, repo: str):
        return self.state.get(repo, {}).get("last_updated_at")

    def set_last_updated(self, repo: str, updated_at: str):
        if repo not in self.state:
            self.state[repo] = {}
        self.state[repo]["last_updated_at"] = updated_at


# ---------------------------------------------------------------------------
# Run Processing
# ---------------------------------------------------------------------------
def process_run(run: dict) -> dict:
    repo_full = run["repository"]["full_name"]
    org = repo_full.split("/")[0]

    run_started = run.get("run_started_at")
    updated = run.get("updated_at")
    duration_seconds = None
    if run_started and updated:
        try:
            start_dt = datetime.fromisoformat(run_started.replace("Z", "+00:00"))
            end_dt = datetime.fromisoformat(updated.replace("Z", "+00:00"))
            duration_seconds = max(0, int((end_dt - start_dt).total_seconds()))
        except (ValueError, TypeError):
            pass

    updated_dt = datetime.fromisoformat(updated.replace("Z", "+00:00"))
    timestamp_ns = str(int(updated_dt.timestamp() * 1_000_000_000))

    line = json.dumps(
        {
            "repo": repo_full,
            "workflow": run.get("name", ""),
            "branch": run.get("head_branch", ""),
            "sha": (run.get("head_sha") or "")[:8],
            "sha_full": run.get("head_sha", ""),
            "conclusion": run.get("conclusion", ""),
            "status": run.get("status", ""),
            "event": run.get("event", ""),
            "actor": run.get("actor", {}).get("login", ""),
            "run_number": run.get("run_number", 0),
            "run_id": run.get("id", 0),
            "html_url": run.get("html_url", ""),
            "created_at": run.get("created_at", ""),
            "updated_at": updated,
            "run_started_at": run_started or "",
            "duration_seconds": duration_seconds,
        },
        separators=(",", ":"),
    )

    return {
        "labels": {"job": "github-actions-collector", "org": org},
        "timestamp_ns": timestamp_ns,
        "line": line,
    }


# ---------------------------------------------------------------------------
# Collector
# ---------------------------------------------------------------------------
class Collector:
    BATCH_SIZE = 500

    def __init__(self, config: Config):
        self.config = config
        self.github = GitHubClient(config.github_token)
        self.loki = LokiClient(config.loki_url, config.loki_user, config.loki_api_key)
        self.state = StateManager(config.state_file)
        self.running = True
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

    def _handle_signal(self, signum, _frame):
        log.info("Received signal %d, shutting down", signum)
        self.running = False

    def poll_once(self):
        total_new = 0
        all_entries = []
        # Track max_updated per repo; only commit to state after push succeeds
        repo_updates = {}

        # Loki rejects entries older than ~7 days on the free tier.
        # Use a 6-day cutoff to provide a safety margin.
        min_timestamp_ns = str(
            int(
                (datetime.now(timezone.utc) - timedelta(days=6)).timestamp()
                * 1_000_000_000
            )
        )

        for repo in self.config.repos:
            try:
                last_updated = self.state.get_last_updated(repo)

                if last_updated is None:
                    since = (
                        datetime.now(timezone.utc)
                        - timedelta(days=self.config.backfill_days)
                    ).strftime("%Y-%m-%dT%H:%M:%SZ")
                    log.info("First run for %s, backfilling from %s", repo, since)
                else:
                    since = last_updated

                runs = self.github.get_workflow_runs(repo, since=since)
                if not runs:
                    continue

                new_runs = [
                    r
                    for r in runs
                    if not last_updated or r["updated_at"] > last_updated
                ]
                if not new_runs:
                    continue

                entries = [process_run(r) for r in new_runs]

                # Filter out entries too old for Loki ingestion
                before_filter = len(entries)
                entries = [e for e in entries if e["timestamp_ns"] >= min_timestamp_ns]
                if before_filter != len(entries):
                    log.info(
                        "%s: filtered %d/%d entries (too old for Loki)",
                        repo,
                        before_filter - len(entries),
                        before_filter,
                    )

                all_entries.extend(entries)

                max_updated = max(r["updated_at"] for r in new_runs)
                repo_updates[repo] = max_updated
                total_new += len(new_runs)
                log.info("%s: %d new runs (%d within Loki window)", repo, len(new_runs), len(entries))

            except Exception:
                log.exception("Error polling %s", repo)

        if all_entries:
            all_entries.sort(key=lambda e: e["timestamp_ns"])
            for i in range(0, len(all_entries), self.BATCH_SIZE):
                self.loki.push(all_entries[i : i + self.BATCH_SIZE])

        # Only update state after successful push
        for repo, max_updated in repo_updates.items():
            self.state.set_last_updated(repo, max_updated)
        self.state.save()

        log.info(
            "Poll complete: %d new runs across %d repos (rate remaining: %d)",
            total_new,
            len(self.config.repos),
            self.github.rate_remaining,
        )

    def run(self):
        log.info(
            "Starting collector: %d repos, polling every %ds",
            len(self.config.repos),
            self.config.poll_interval,
        )
        while self.running:
            try:
                self.poll_once()
            except Exception:
                log.exception("Poll cycle failed")

            for _ in range(self.config.poll_interval):
                if not self.running:
                    break
                time.sleep(1)

        log.info("Collector stopped")


def main():
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
        stream=sys.stdout,
    )
    try:
        config = Config()
    except (KeyError, ValueError) as e:
        log.error("Configuration error: %s", e)
        sys.exit(1)

    Collector(config).run()


if __name__ == "__main__":
    main()
