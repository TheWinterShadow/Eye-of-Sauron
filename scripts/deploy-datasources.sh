#!/bin/bash
set -euo pipefail

echo "Deploying datasources to Grafana Cloud..."

# Validate required environment variables
: "${GRAFANA_CLOUD_URL:?Environment variable GRAFANA_CLOUD_URL is required}"
: "${GRAFANA_CLOUD_API_KEY:?Environment variable GRAFANA_CLOUD_API_KEY is required}"

DATASOURCES_DIR="grafana-cloud/datasources"

if [ ! -d "$DATASOURCES_DIR" ]; then
  echo "ERROR: Datasources directory not found: $DATASOURCES_DIR"
  exit 1
fi

for datasource_file in "$DATASOURCES_DIR"/*.json; do
  if [ ! -f "$datasource_file" ]; then
    echo "No datasource files found in $DATASOURCES_DIR"
    continue
  fi

  echo "Processing: $datasource_file"
  
  # Extract datasource name and UID from JSON
  DATASOURCE_NAME=$(jq -r '.name' "$datasource_file")
  DATASOURCE_UID=$(jq -r '.uid' "$datasource_file")
  
  echo "  Name: $DATASOURCE_NAME"
  echo "  UID: $DATASOURCE_UID"
  
  # Check if datasource exists
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
    -H "Content-Type: application/json" \
    "${GRAFANA_CLOUD_URL}/api/datasources/uid/${DATASOURCE_UID}")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "  Datasource exists, updating..."
    # Update existing datasource
    curl -X PUT \
      -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
      -H "Content-Type: application/json" \
      -d @"$datasource_file" \
      "${GRAFANA_CLOUD_URL}/api/datasources/uid/${DATASOURCE_UID}"
  else
    echo "  Datasource does not exist, creating..."
    # Create new datasource
    curl -X POST \
      -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
      -H "Content-Type: application/json" \
      -d @"$datasource_file" \
      "${GRAFANA_CLOUD_URL}/api/datasources"
  fi
  
  echo "  ✓ Done"
  echo ""
done

echo "All datasources deployed successfully!"
