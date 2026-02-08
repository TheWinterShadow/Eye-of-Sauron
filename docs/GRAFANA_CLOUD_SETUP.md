# Grafana Cloud Setup Guide

## Overview
This guide walks you through setting up Grafana Cloud for CI/CD monitoring.

## Step 1: Create Grafana Cloud Account
1. Go to https://grafana.com/auth/sign-up/create-user
2. Sign up for the free tier (no credit card required)
3. Verify your email address

## Step 2: Get Your Grafana Cloud URL
1. After logging in, note your Grafana Cloud URL
   - Format: `https://yourorg.grafana.net`
   - This is your `GRAFANA_CLOUD_URL`

## Step 3: Create Tokens

### Service Account Token for GitHub Actions (Dashboard Deployment)
1. Navigate to: Grafana Cloud → Administration → **Service accounts**
2. Click "Add service account"
3. Configure:
   - **Name:** GitHub Actions
   - **Role:** Editor (needs dashboards:create and dashboards:write permissions)
4. Click "Add service account"
5. Click "Add service account token"
   - Name it "GitHub Actions Token"
6. **Copy the token immediately** (starts with `glsa_`, you won't see it again)
7. Add this as `GRAFANA_CLOUD_API_KEY` in GitHub repository secrets

### Cloud Access Policy Token for Alloy (Metrics Publishing)
1. Navigate to: Grafana Cloud → Connections → Hosted Prometheus metrics
2. Find the "Remote Write Endpoint" section
3. Copy:
   - **Remote Write URL:** This is your `GRAFANA_CLOUD_PROMETHEUS_URL`
   - **User ID:** This is your `GRAFANA_CLOUD_PROMETHEUS_USER`
   - **API Key:** Click "Generate now" or use existing Cloud Access Policy token
     - This is your `GRAFANA_CLOUD_API_KEY` for Alloy (starts with `glc_`)
     - **Copy immediately** (you won't see it again)

## Step 4: Verify Prometheus Datasource
1. Navigate to: Grafana Cloud → Connections → Data sources
2. Verify "Prometheus" datasource exists
3. This is automatically configured when you create a Grafana Cloud account

## Step 5: Create Dashboard Folder (Optional)
1. Navigate to: Dashboards → Manage
2. Click "New" → "New folder"
3. Name: `cicd-monitoring`
4. The deployment script will create this automatically if it doesn't exist

## Step 6: Test API Access
```bash
# Test service account token works
curl -H "Authorization: Bearer YOUR_SERVICE_ACCOUNT_TOKEN" \
  https://yourorg.grafana.net/api/org

# Should return JSON with your org details
```

## Troubleshooting

### Service Account Token Not Working
- Verify the token hasn't been revoked
- Check the service account has Editor role with dashboard permissions
- Ensure you're using the correct Grafana Cloud URL
- Verify you're using a Service Account Token (`glsa_*`), not the old API keys

### Metrics Not Appearing
- Verify Alloy is running and connected
- Check Alloy logs: `docker logs grafana-alloy`
- Verify `GRAFANA_CLOUD_PROMETHEUS_URL` is correct
- Check Grafana Cloud → Explore → Query metrics

### Dashboards Not Deploying
- Check GitHub Actions workflow logs
- Verify `GRAFANA_CLOUD_URL` and `GRAFANA_CLOUD_API_KEY` are set correctly
- Ensure you're using a Service Account Token (`glsa_*`) with Editor role
- Verify the service account has `dashboards:create` and `dashboards:write` permissions

## Free Tier Limits
- **10,000 active series** (typically using 300-600 for CI/CD monitoring)
- **50 GB logs** (not used in this setup)
- **14 days retention** for metrics
- **3 users** per organization

## Next Steps
1. Configure GitHub repository secrets (see [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md))
2. Push code to trigger first deployment
3. Verify dashboards appear in Grafana Cloud
4. Deploy containers to Raspberry Pi (see [RASPBERRY_PI_DEPLOYMENT.md](RASPBERRY_PI_DEPLOYMENT.md))
