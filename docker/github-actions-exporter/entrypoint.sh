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

if [ -z "$GITHUB_ORGAS" ]; then
  echo "ERROR: GITHUB_ORGAS environment variable is required"
  exit 1
fi

echo "Starting GitHub Actions Exporter..."
echo "Organizations: $GITHUB_ORGAS"
echo "Refresh interval: ${GITHUB_REFRESH}s"

# Execute the original entrypoint
exec /app/github-actions-exporter
