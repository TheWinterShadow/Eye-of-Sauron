# Raspberry Pi 5 Deployment Guide

## Overview
The Raspberry Pi pulls Docker images from Docker Hub and runs them using `docker run` commands.
This repository does NOT manage the Pi deployment - it only builds and publishes the images.

## Prerequisites on Raspberry Pi
- Docker installed (ARM64 version)
- Docker network created: `docker network create monitoring`
- Docker volume created: `docker volume create alloy_data`
- `.env` file with secrets (see .env.example)

## Deployment Commands

### 1. Pull latest images
```bash
docker pull thewintershadow/github-actions-exporter:latest
docker pull thewintershadow/grafana-alloy:latest
```

### 2. Stop and remove old containers
```bash
docker stop github-actions-exporter grafana-alloy || true
docker rm github-actions-exporter grafana-alloy || true
```

### 3. Run GitHub Actions Exporter
```bash
docker run -d \
  --name github-actions-exporter \
  --network monitoring \
  --env-file .env \
  --restart unless-stopped \
  thewintershadow/github-actions-exporter:latest
```

### 4. Run Grafana Alloy
```bash
docker run -d \
  --name grafana-alloy \
  --network monitoring \
  --env-file .env \
  -v alloy_data:/var/lib/alloy \
  -p 12345:12345 \
  --restart unless-stopped \
  thewintershadow/grafana-alloy:latest
```

## Verification
```bash
# Check all containers are running
docker ps

# Check Alloy UI
curl http://localhost:12345/ready

# View logs
docker logs grafana-alloy
docker logs github-actions-exporter
```

## Update Process
When new images are available:
1. Run steps 1-5 above
2. Containers will restart with new configuration

## Rollback
To rollback to a specific version:
```bash
docker pull thewintershadow/grafana-alloy:v1.0.0
docker stop grafana-alloy && docker rm grafana-alloy
# Then run step 5 with :v1.0.0 tag instead of :latest
```
