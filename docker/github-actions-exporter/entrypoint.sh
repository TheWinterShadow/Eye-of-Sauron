#!/bin/sh
set -e

# Set defaults if not provided
export PORT="${PORT:-9999}"
export GITHUB_REFRESH="${GITHUB_REFRESH:-30}"
export EXPORT_FIELDS="${EXPORT_FIELDS:-repo,id,node_id,head_branch,head_sha,run_number,workflow_id,workflow,event,status}"

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GITHUB_TOKEN environment variable is required"
  exit 1
fi

if [ -z "$GITHUB_ORGAS" ] && [ -z "$GITHUB_USERS" ]; then
  echo "ERROR: GITHUB_ORGAS or GITHUB_USERS environment variable is required"
  exit 1
fi

# Fetch all repos for a GitHub user (handles pagination)
fetch_user_repos() {
  user="$1"
  page=1
  while true; do
    response=$(wget -qO- --header="Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/users/$user/repos?per_page=100&page=$page&type=owner" 2>/dev/null) || break
    repos=$(echo "$response" | jq -r '.[].full_name // empty')
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
    repos=$(echo "$response" | jq -r '.[].full_name // empty')
    [ -z "$repos" ] && break
    echo "$repos"
    page=$((page + 1))
  done
}

# If GITHUB_USERS is set, resolve all repos dynamically at startup.
# The upstream exporter ignores GITHUB_ORGAS when GITHUB_REPOS is set,
# so we also resolve org repos here and combine everything into GITHUB_REPOS.
if [ -n "$GITHUB_USERS" ]; then
  RESOLVED_REPOS=""

  # Fetch repos for each user
  for user in $(echo "$GITHUB_USERS" | tr ',' ' '); do
    echo "Fetching repositories for user: $user"
    user_repos=$(fetch_user_repos "$user")
    for repo in $user_repos; do
      RESOLVED_REPOS="${RESOLVED_REPOS:+$RESOLVED_REPOS,}$repo"
    done
  done

  # Also fetch org repos since setting GITHUB_REPOS causes the exporter to skip GITHUB_ORGAS
  if [ -n "$GITHUB_ORGAS" ]; then
    for org in $(echo "$GITHUB_ORGAS" | tr ',' ' '); do
      echo "Fetching repositories for org: $org"
      org_repos=$(fetch_org_repos "$org")
      for repo in $org_repos; do
        RESOLVED_REPOS="${RESOLVED_REPOS:+$RESOLVED_REPOS,}$repo"
      done
    done
    unset GITHUB_ORGAS
  fi

  # Append any manually specified repos
  if [ -n "$GITHUB_REPOS" ]; then
    RESOLVED_REPOS="${RESOLVED_REPOS:+$RESOLVED_REPOS,}$GITHUB_REPOS"
  fi

  export GITHUB_REPOS="$RESOLVED_REPOS"
  echo "Resolved $(echo "$GITHUB_REPOS" | tr ',' '\n' | wc -l | tr -d ' ') repositories"
fi

# Unset GITHUB_REPOS if empty to prevent upstream panic
# (urfave/cli treats empty string as a single-element slice [""])
if [ -z "$GITHUB_REPOS" ]; then
  unset GITHUB_REPOS
fi

echo "Starting GitHub Actions Exporter..."
[ -n "$GITHUB_ORGAS" ] && echo "Organizations: $GITHUB_ORGAS"
[ -n "$GITHUB_USERS" ] && echo "Users: $GITHUB_USERS"
echo "Refresh interval: ${GITHUB_REFRESH}s"

# Execute the original entrypoint
exec /app/github-actions-exporter
