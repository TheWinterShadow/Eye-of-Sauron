# CI/CD Monitoring Stack

GitOps-driven CI/CD monitoring using Grafana Cloud free tier, custom Docker images, and GitHub Actions.

## Architecture

```
GitHub Actions → Docker Hub (multi-arch images: AMD64 + ARM64)
                      ↓
              Raspberry Pi 5 (pulls images)
                      ↓
         Grafana Cloud (managed dashboards)
```

## Quick Start

### 1. Fork this repository

### 2. Configure GitHub Secrets
See [docs/SECRETS_MANAGEMENT.md](docs/SECRETS_MANAGEMENT.md)

Required secrets:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `GRAFANA_CLOUD_URL`
- `GRAFANA_CLOUD_API_KEY`

### 3. Update Docker image names
Replace `thewintershadow` in:
- `.github/workflows/build-and-push.yml`
- `docker-compose.reference.yml`
- `docs/RASPBERRY_PI_DEPLOYMENT.md`

### 4. Configure exporters
Edit these files with your GitLab/GitHub settings:
- `docker/gitlab-ci-exporter/config.yml`
- `docker/grafana-alloy/config.alloy`

### 5. Push to main branch
```bash
git add .
git commit -m "Initial configuration"
git push origin main
```

GitHub Actions will automatically:
- Build multi-arch Docker images
- Push to Docker Hub with `:latest` and `:1.0.0` tags
- Deploy dashboards to Grafana Cloud (if changed)

### 6. Deploy to Raspberry Pi
See [docs/RASPBERRY_PI_DEPLOYMENT.md](docs/RASPBERRY_PI_DEPLOYMENT.md)

## Updating

### Configuration Changes
1. Edit files in `docker/*/`
2. Commit and push to main
3. GitHub Actions rebuilds images
4. Pull new images on Pi and restart containers

### Version Bumps
```bash
make bump-patch  # Bug fixes: 1.0.0 → 1.0.1
make bump-minor  # New features: 1.0.0 → 1.1.0
make bump-major  # Breaking changes: 1.0.0 → 2.0.0
git add VERSION
git commit -m "Bump version"
git push
```

### Dashboard Changes
1. Edit files in `grafana-cloud/dashboards/`
2. Commit and push to main
3. GitHub Actions automatically updates Grafana Cloud

## Cost
**$0/month**
- Grafana Cloud free tier (10k series, using ~300-600)
- Docker Hub free tier (unlimited public images)
- GitHub Actions free tier (2000 minutes/month, using ~5-10)

## Documentation
- [Raspberry Pi Deployment](docs/RASPBERRY_PI_DEPLOYMENT.md)
- [Secrets Management](docs/SECRETS_MANAGEMENT.md)
- [Grafana Cloud Setup](docs/GRAFANA_CLOUD_SETUP.md)
- [Docker Hub Setup](docs/DOCKER_HUB_SETUP.md)

## Monitoring
- Grafana Cloud: https://yourorg.grafana.net
- Alloy UI (on Pi): http://raspberry-pi-ip:12345
- Docker Hub: https://hub.docker.com/r/yourusername

## Troubleshooting
```bash
# Check GitHub Actions status
# Repository → Actions tab

# View Pi container logs
docker logs grafana-alloy
docker logs gitlab-ci-exporter  
docker logs github-actions-exporter

# Verify metrics flowing to Grafana Cloud
# Grafana Cloud → Explore → Query: gitlab_ci_pipeline_status
```

## Repository Structure

```
ci-cd-monitoring/
├── .github/workflows/     # GitHub Actions CI/CD
├── docker/                # Custom Docker images
│   ├── gitlab-ci-exporter/
│   ├── github-actions-exporter/
│   └── grafana-alloy/
├── grafana-cloud/         # Grafana Cloud configs (GitOps)
│   ├── datasources/
│   ├── dashboards/
│   └── alerts/
├── scripts/               # Deployment scripts
└── docs/                  # Documentation
```

## License
MIT
