# GitHub Packages Deployment Guide

This document explains how to use GitHub Packages (GitHub Container Registry) with your microservices project.

## Overview

The GitHub Packages workflow automatically builds and pushes your Docker images to GitHub Container Registry (GHCR) whenever you push code to the main branch.

## Workflow Features

- **Automatic versioning**: Uses `v1.0.{run_number}` format
- **Latest tags**: Also pushes `latest` tags for easy deployment
- **Multi-service support**: Builds Backend, Frontend, and MySQL images
- **Secure authentication**: Uses GitHub tokens automatically

## Generated Images

After running the workflow, these images will be available:

1. **Backend (Flask)**: `ghcr.io/shivamsingh163248/flask_backend:latest`
2. **Frontend (Nginx)**: `ghcr.io/shivamsingh163248/nginx_frontend:latest`
3. **Database (MySQL)**: `ghcr.io/shivamsingh163248/mysql_db:latest`

## Usage

### 1. Using GitHub Packages Images

```bash
# Pull and run using the GitHub packages docker-compose file
docker-compose -f docker-compose.github.yml up -d

# Or pull individual images
docker pull ghcr.io/shivamsingh163248/flask_backend:latest
docker pull ghcr.io/shivamsingh163248/nginx_frontend:latest
docker pull ghcr.io/shivamsingh163248/mysql_db:latest
```

### 2. Authentication (if images are private)

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Or create a personal access token with `read:packages` scope
```

### 3. Deployment Commands

```bash
# Development (local build)
docker-compose up -d

# Production (GitHub Packages)
docker-compose -f docker-compose.github.yml up -d

# Update to latest images
docker-compose -f docker-compose.github.yml pull
docker-compose -f docker-compose.github.yml up -d
```

## Repository Settings

### Making Packages Public

1. Go to your repository on GitHub
2. Navigate to the **Packages** section
3. Click on each package (flask_backend, nginx_frontend, mysql_db)
4. Go to **Package settings**
5. Change visibility to **Public** if you want them to be publicly accessible

### Workflow Permissions

The workflow includes these permissions:
- `contents: read` - To checkout the repository
- `packages: write` - To push to GitHub Container Registry

## Environment Variables

The workflow uses these environment variables:
- `IMAGE_VERSION`: Automatic versioning (v1.0.{run_number})
- `GHCR`: GitHub Container Registry URL (ghcr.io)
- `OWNER`: Repository owner (shivamsingh163248)

## Monitoring

- View workflow runs in the **Actions** tab
- Check package status in the **Packages** section
- Monitor image sizes and download statistics

## Troubleshooting

### Common Issues

1. **Permission denied**: Ensure workflow has `packages: write` permission
2. **Image not found**: Check if package is public or you're authenticated
3. **Build failures**: Check Dockerfile syntax and build context

### Useful Commands

```bash
# Check workflow status
gh workflow list

# View package details
gh api /user/packages/container/flask_backend

# Delete old package versions (if needed)
gh api -X DELETE /user/packages/container/flask_backend/versions/VERSION_ID
```
