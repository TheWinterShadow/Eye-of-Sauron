#!/bin/sh
set -e

# Set defaults
export POLL_INTERVAL="${POLL_INTERVAL:-300}"
export BACKFILL_DAYS="${BACKFILL_DAYS:-7}"
export STATE_FILE="${STATE_FILE:-/data/collector_state.json}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GITHUB_TOKEN environment variable is required"
  exit 1
fi

if [ -z "$LOKI_URL" ]; then
  echo "ERROR: LOKI_URL environment variable is required"
  exit 1
fi

if [ -z "$LOKI_USER" ]; then
  echo "ERROR: LOKI_USER environment variable is required"
  exit 1
fi

if [ -z "$LOKI_API_KEY" ]; then
  echo "ERROR: LOKI_API_KEY environment variable is required"
  exit 1
fi

if [ -z "$GITHUB_ORGAS" ] && [ -z "$GITHUB_USERS" ] && [ -z "$GITHUB_REPOS" ]; then
  echo "ERROR: GITHUB_ORGAS, GITHUB_USERS, or GITHUB_REPOS is required"
  exit 1
fi

# Fetch all repos for a GitHub user (handles pagination)
fetch_user_repos() {
  user="$1"
  page=1
  while true; do
    response=$(wget -qO- --header="Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/users/$user/repos?per_page=100&page=$page&type=owner" 2>/dev/null) || break
    repos=$(echo "$response" | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    if r.get('full_name'):
        print(r['full_name'])
" 2>/dev/null)
    [ -z "$repos" ] && break
    echo "$repos"
    page=$((page + 1))
  done
}

# Fetch all repos for a GitHub org (handles pagination)
fetch_org_repos() {
  org="$1"
  page=1
  while true; do
    response=$(wget -qO- --header="Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/orgs/$org/repos?per_page=100&page=$page" 2>/dev/null) || break
    repos=$(echo "$response" | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    if r.get('full_name'):
        print(r['full_name'])
" 2>/dev/null)
    [ -z "$repos" ] && break
    echo "$repos"
    page=$((page + 1))
  done
}

RESOLVED_REPOS=""

# Resolve org repos
if [ -n "$GITHUB_ORGAS" ]; then
  for org in $(echo "$GITHUB_ORGAS" | tr ',' ' '); do
    echo "Fetching repositories for org: $org"
    org_repos=$(fetch_org_repos "$org")
    for repo in $org_repos; do
      RESOLVED_REPOS="${RESOLVED_REPOS:+$RESOLVED_REPOS,}$repo"
    done
  done
fi

# Resolve user repos
if [ -n "$GITHUB_USERS" ]; then
  for user in $(echo "$GITHUB_USERS" | tr ',' ' '); do
    echo "Fetching repositories for user: $user"
    user_repos=$(fetch_user_repos "$user")
    for repo in $user_repos; do
      RESOLVED_REPOS="${RESOLVED_REPOS:+$RESOLVED_REPOS,}$repo"
    done
  done
fi

# Append explicit repos
if [ -n "$GITHUB_REPOS" ]; then
  RESOLVED_REPOS="${RESOLVED_REPOS:+$RESOLVED_REPOS,}$GITHUB_REPOS"
fi

if [ -z "$RESOLVED_REPOS" ]; then
  echo "ERROR: No repositories resolved"
  exit 1
fi

export RESOLVED_REPOS
repo_count=$(echo "$RESOLVED_REPOS" | tr ',' '\n' | wc -l | tr -d ' ')
echo "Resolved $repo_count repositories"
echo "Poll interval: ${POLL_INTERVAL}s"
echo "First run: fetches latest run per workflow (no date limit)"
echo "Starting GitHub Actions Collector..."

exec python3 /app/collector.py
