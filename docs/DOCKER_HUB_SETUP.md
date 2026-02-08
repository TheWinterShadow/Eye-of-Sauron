# Docker Hub Setup Guide

## Overview
This guide walks you through setting up Docker Hub for publishing multi-arch Docker images.

## Step 1: Create Docker Hub Account
1. Go to https://hub.docker.com/signup
2. Create a free account (no credit card required)
3. Verify your email address

## Step 2: Create Access Token
1. Log in to Docker Hub
2. Navigate to: Account Settings → Security
3. Click "New Access Token"
4. Configure:
   - **Description:** GitHub Actions CI/CD
   - **Access permissions:** Read & Write
5. Click "Generate"
6. **Copy the token immediately** (you won't see it again)
   - Format: `dckr_pat_xxxxxxxxxxxxxxxxxxxx`

## Step 3: Add Token to GitHub Secrets
1. Go to your GitHub repository
2. Navigate to: Settings → Secrets and variables → Actions
3. Add these secrets:
   - `DOCKERHUB_USERNAME` - Your Docker Hub username
   - `DOCKERHUB_TOKEN` - The access token you just created

## Step 4: Update Image Names
Replace `thewintershadow` in these files:
- `.github/workflows/build-and-push.yml` (already uses `${{ secrets.DOCKERHUB_USERNAME }}`)
- `docker-compose.reference.yml`
- `docs/RASPBERRY_PI_DEPLOYMENT.md`

## Step 5: Verify Repositories
After the first GitHub Actions run, verify these repositories exist:
- `yourusername/gitlab-ci-exporter`
- `yourusername/github-actions-exporter`
- `yourusername/grafana-alloy`

Each should have:
- `:latest` tag
- `:1.0.0` tag (or current version)
- Multi-arch support (linux/amd64, linux/arm64)

## Free Tier Limits
- **Unlimited public repositories**
- **1 private repository** (free)
- **100 pulls per 6 hours** for anonymous users
- **200 pulls per 6 hours** for authenticated free users

## Troubleshooting

### Build Fails with Authentication Error
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are set correctly
- Check token hasn't expired
- Ensure token has Read & Write permissions

### Images Not Appearing on Docker Hub
- Check GitHub Actions workflow logs
- Verify build completed successfully
- Wait a few minutes for Docker Hub to process

### Rate Limiting Issues
- Free tier has pull rate limits
- Consider upgrading to Pro ($5/month) for higher limits
- Or use Docker Hub authentication on Raspberry Pi

### Multi-arch Build Fails
- QEMU emulation can be slow but should work
- Check GitHub Actions runner has sufficient resources
- Verify `docker/setup-qemu-action@v3` is used

## Testing Locally
```bash
# Login to Docker Hub
docker login -u YOUR_USERNAME

# Build and push manually (for testing)
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 \
  -t yourusername/test:latest \
  --push \
  ./docker/gitlab-ci-exporter
```

## Next Steps
1. Configure GitHub secrets (see [SECRETS_MANAGEMENT.md](SECRETS_MANAGEMENT.md))
2. Push code to trigger first build
3. Verify images on Docker Hub
4. Pull images on Raspberry Pi (see [RASPBERRY_PI_DEPLOYMENT.md](RASPBERRY_PI_DEPLOYMENT.md))
