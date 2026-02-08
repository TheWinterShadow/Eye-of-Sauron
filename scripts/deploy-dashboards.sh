#!/bin/bash
set -euo pipefail

echo "Deploying dashboards to Grafana Cloud..."

: "${GRAFANA_CLOUD_URL:?Environment variable GRAFANA_CLOUD_URL is required}"
: "${GRAFANA_CLOUD_API_KEY:?Environment variable GRAFANA_CLOUD_API_KEY is required}"

DASHBOARDS_DIR="grafana-cloud/dashboards"
FOLDER_UID="cicd-monitoring"

# Create folder if it doesn't exist
echo "Checking/creating folder: $FOLDER_UID"
FOLDER_RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
  "${GRAFANA_CLOUD_URL}/api/folders/$FOLDER_UID")

if echo "$FOLDER_RESPONSE" | jq -e '.uid' > /dev/null 2>&1; then
  echo "  ✓ Folder already exists"
else
  echo "  Creating folder..."
  CREATE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"uid\":\"$FOLDER_UID\",\"title\":\"CI/CD Monitoring\"}" \
    "${GRAFANA_CLOUD_URL}/api/folders")
  
  if echo "$CREATE_RESPONSE" | jq -e '.uid' > /dev/null 2>&1; then
    echo "  ✓ Folder created successfully"
  else
    echo "  ⚠ Could not create folder, will deploy to General folder"
    FOLDER_UID=""
  fi
fi
echo ""

if [ ! -d "$DASHBOARDS_DIR" ]; then
  echo "ERROR: Dashboards directory not found: $DASHBOARDS_DIR"
  exit 1
fi

for dashboard_file in "$DASHBOARDS_DIR"/*.json; do
  if [ ! -f "$dashboard_file" ]; then
    echo "No dashboard files found in $DASHBOARDS_DIR"
    continue
  fi

  echo "Processing: $dashboard_file"
  
  # Extract dashboard UID and title
  DASHBOARD_UID=$(jq -r '.uid' "$dashboard_file")
  DASHBOARD_TITLE=$(jq -r '.title' "$dashboard_file")
  
  echo "  Title: $DASHBOARD_TITLE"
  echo "  UID: $DASHBOARD_UID"
  
  # Wrap dashboard in the required API format
  if [ -n "$FOLDER_UID" ]; then
    PAYLOAD=$(jq -n \
      --arg folderUid "$FOLDER_UID" \
      --argjson dashboard "$(cat "$dashboard_file")" \
      '{dashboard: $dashboard, folderUid: $folderUid, overwrite: true}')
  else
    PAYLOAD=$(jq -n \
      --argjson dashboard "$(cat "$dashboard_file")" \
      '{dashboard: $dashboard, overwrite: true}')
  fi
  
  # Deploy dashboard
  RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "${GRAFANA_CLOUD_URL}/api/dashboards/db")
  
  # Check if successful
  if echo "$RESPONSE" | jq -e '.status == "success"' > /dev/null; then
    echo "  ✓ Dashboard deployed successfully"
    DASHBOARD_URL=$(echo "$RESPONSE" | jq -r '.url')
    echo "  URL: ${GRAFANA_CLOUD_URL}${DASHBOARD_URL}"
  else
    echo "  ✗ Failed to deploy dashboard"
    echo "  Response: $RESPONSE"
    exit 1
  fi
  
  echo ""
done

echo "All dashboards deployed successfully!"
