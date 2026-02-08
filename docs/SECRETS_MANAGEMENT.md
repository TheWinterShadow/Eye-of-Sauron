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
- `GRAFANA_CLOUD_API_KEY` - Grafana Cloud API key with Admin or Editor role

To create Grafana Cloud API key:
1. Go to Grafana Cloud → Administration → API Keys
2. Click "Add API key"
3. Name: "GitHub Actions Deployment"
4. Role: Editor (or Admin for full control)
5. Copy the key immediately (you won't see it again)

### 2. Raspberry Pi Secrets (for runtime)
These secrets are used by the Docker containers running on your Pi.

Create a `.env` file on your Raspberry Pi with:

```bash
# GitLab
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_GROUP=your-gitlab-group

# GitHub
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_ORGAS=your-org,another-org
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

**GitLab PAT:** `read_api` scope only
**GitHub PAT:** `repo` + `read:org` scopes
**Grafana Cloud API Key (for Actions):** Editor role (to create/update dashboards)
**Grafana Cloud API Key (for Alloy):** MetricsPublisher role (to push metrics)

Note: You can use different Grafana Cloud API keys for GitHub Actions vs Alloy, or use the same key with both permissions.
