#!/bin/bash
set -euo pipefail

echo "Deploying alert rules to Grafana Cloud..."

: "${GRAFANA_CLOUD_URL:?Environment variable GRAFANA_CLOUD_URL is required}"
: "${GRAFANA_CLOUD_API_KEY:?Environment variable GRAFANA_CLOUD_API_KEY is required}"

ALERTS_DIR="grafana-cloud/alerts"

if [ ! -d "$ALERTS_DIR" ]; then
  echo "No alerts directory found, skipping alert deployment"
  exit 0
fi

for alert_file in "$ALERTS_DIR"/*.json; do
  if [ ! -f "$alert_file" ]; then
    echo "No alert files found in $ALERTS_DIR"
    continue
  fi

  echo "Processing: $alert_file"
  
  # Deploy alert rule (Grafana Unified Alerting API)
  RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $GRAFANA_CLOUD_API_KEY" \
    -H "Content-Type: application/json" \
    -d @"$alert_file" \
    "${GRAFANA_CLOUD_URL}/api/v1/provisioning/alert-rules")
  
  echo "  Response: $RESPONSE"
  echo "  ✓ Done"
  echo ""
done

echo "All alert rules deployed successfully!"
