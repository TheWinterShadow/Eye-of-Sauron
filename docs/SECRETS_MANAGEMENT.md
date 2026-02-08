# Secrets Management Guide

## Two Sets of Secrets

### 1. GitHub Repository Secrets (for CI/CD)
These secrets are used by GitHub Actions to build images and deploy to Grafana Cloud.

Navigate to: Repository → Settings → Secrets and variables → Actions

Add these secrets:

**Docker Hub:**
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token (create at hub.docker.com/settings/security)

**Grafana Cloud:**
- `GRAFANA_CLOUD_URL` - Your Grafana Cloud instance URL (e.g., https://yourorg.grafana.net)
- `GRAFANA_CLOUD_API_KEY` - Grafana Cloud Service Account Token (starts with `glsa_`)

To create Grafana Cloud Service Account Token:
1. Go to Grafana Cloud → Administration → **Service accounts**
2. Click "Add service account"
3. Name: "GitHub Actions", Role: **Editor** (needs dashboards:create/write permissions)
4. Click "Add service account token"
5. Copy the token immediately (starts with `glsa_`, you won't see it again)

### 2. Raspberry Pi Secrets (for runtime)
These secrets are used by the Docker containers running on your Pi.

Create a `.env` file on your Raspberry Pi with:

```bash
# GitHub
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_ORGAS=TheWinterShadow,HorizonSec
GITHUB_REPOS=

# Grafana Cloud (for Alloy to push metrics)
GRAFANA_CLOUD_PROMETHEUS_URL=https://prometheus-prod-XX-prod-us-east-0.grafana.net/api/prom/push
GRAFANA_CLOUD_PROMETHEUS_USER=123456
GRAFANA_CLOUD_API_KEY=glc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Security:**
```bash
chmod 600 .env
```

## Token Permissions

**GitHub PAT:** `repo` + `read:org` scopes
**Grafana Cloud (for GitHub Actions):** Service Account Token with Editor role (`glsa_*`)
**Grafana Cloud (for Alloy metrics):** Cloud Access Policy token with MetricsPublisher role (`glc_*`)

Note: These are two different types of Grafana tokens:
- Service Account Token (for API/dashboard management)
- Cloud Access Policy token (for pushing metrics to Prometheus)
