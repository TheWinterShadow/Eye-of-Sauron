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

## Step 3: Create API Keys

### API Key for GitHub Actions (Dashboard Deployment)
1. Navigate to: Grafana Cloud → Administration → API Keys
2. Click "Add API key"
3. Configure:
   - **Name:** GitHub Actions Deployment
   - **Role:** Editor (or Admin for full control)
   - **Time to live:** Leave empty for no expiration
4. Click "Add" and **copy the key immediately** (you won't see it again)
5. Add this as `GRAFANA_CLOUD_API_KEY` in GitHub repository secrets

### API Key for Alloy (Metrics Publishing)
1. Navigate to: Grafana Cloud → Connections → Hosted Prometheus metrics
2. Find the "Remote Write Endpoint" section
3. Copy:
   - **Remote Write URL:** This is your `GRAFANA_CLOUD_PROMETHEUS_URL`
   - **User ID:** This is your `GRAFANA_CLOUD_PROMETHEUS_USER`
   - **API Key:** Click "Generate now" or use existing key
     - This is your `GRAFANA_CLOUD_API_KEY` for Alloy
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
# Test API key works
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://yourorg.grafana.net/api/org

# Should return JSON with your org details
```

## Troubleshooting

### API Key Not Working
- Verify the key hasn't expired
- Check the role has sufficient permissions (Editor or Admin)
- Ensure you're using the correct Grafana Cloud URL

### Metrics Not Appearing
- Verify Alloy is running and connected
- Check Alloy logs: `docker logs grafana-alloy`
- Verify `GRAFANA_CLOUD_PROMETHEUS_URL` is correct
- Check Grafana Cloud → Explore → Query metrics

### Dashboards Not Deploying
- Check GitHub Actions workflow logs
- Verify `GRAFANA_CLOUD_URL` and `GRAFANA_CLOUD_API_KEY` are set correctly
- Ensure API key has Editor or Admin role

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
