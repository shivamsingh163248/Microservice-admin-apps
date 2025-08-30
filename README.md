# 🚀 Microservice Admin App - Complete CI/CD Guide

A comprehensive microservice application with automated CI/CD deployment using GitHub Actions, Docker, Ansible, and Jenkins integration.

## 📋 Table of Contents

- [🏗️ Architecture](#️-architecture)
- [🔧 Prerequisites](#-prerequisites)
- [⚙️ Setup & Configuration](#️-setup--configuration)
- [🚀 GitHub Actions Workflows](#-github-actions-workflows)
- [� Jenkins Integration](#-jenkins-integration)
- [�📦 Docker Images & Registry](#-docker-images--registry)
- [🎯 Ansible Deployment](#-ansible-deployment)
- [🔍 Monitoring & Troubleshooting](#-monitoring--troubleshooting)
- [🌐 Access Points](#-access-points)
- [📚 Additional Resources](#-additional-resources)

## 🏗️ Architecture

### Microservices Components
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │    Database     │
│   (Nginx)       │    │    (Flask)      │    │    (MySQL)      │
│   Port: 8080    │────│   Port: 5000    │────│   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### CI/CD Pipeline Architecture
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │    │   GitHub    │    │   Ansible   │    │   AWS EC2   │
│   Repository│────│   Actions   │────│ Deployment  │────│   Server    │
│             │    │   Workflow  │    │             │    │54.234.122.255│
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Services Overview
- **Frontend**: Nginx-based web interface serving admin panel
- **Backend**: Flask REST API with authentication and admin features
- **Database**: MySQL with persistent data storage
- **Registry**: GitHub Container Registry (GHCR) for image storage
- **Deployment**: Automated via Ansible on AWS EC2

## 🔧 Prerequisites

### Development Environment
```bash
# Required Software
- Docker 20.10+
- Docker Compose 2.0+
- Git 2.30+
- Python 3.8+
- Node.js 16+ (optional)

# System Requirements
- 8GB RAM minimum
- 20GB free disk space
- Ubuntu 20.04+ or macOS 10.15+
```

### Production Environment
```bash
# AWS EC2 Instance
- Ubuntu 24.04 LTS
- t2.medium or larger
- Security Groups: SSH (22), HTTP (80), Custom (8080, 5000)
- Elastic IP (recommended)

# GitHub Repository
- Actions enabled
- Container Registry access
- Secrets configured
```

## ⚙️ Setup & Configuration

### 1. 🗝️ SSH Key Configuration

#### For AWS EC2 Access
```bash
# Generate SSH key pair (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-microservice-key

# Copy public key to EC2 instance
ssh-copy-id -i ~/.ssh/aws-microservice-key.pub ubuntu@54.234.122.255

# Test connection
ssh -i ~/.ssh/aws-microservice-key ubuntu@54.234.122.255
```

#### For GitHub Actions
1. **Get your private key content**:
   ```bash
   cat ~/.ssh/aws-microservice-key
   ```

2. **Add to GitHub Secrets**:
   - Go to Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `SSH_PRIVATE_KEY`
   - Value: (paste entire private key including BEGIN/END lines)

### 2. 🐳 Docker Setup

#### Local Development
```bash
# Clone repository
git clone https://github.com/shivamsingh163248/Microservice-admin-apps.git
cd Microservice-admin-apps

# Build and run locally
docker-compose up -d

# Access services
curl http://localhost:8080  # Frontend
curl http://localhost:5000  # Backend API
```

#### Production Images
```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/shivamsingh163248/flask_backend:latest
docker pull ghcr.io/shivamsingh163248/nginx_frontend:latest
docker pull ghcr.io/shivamsingh163248/mysql_db:latest
```

### 3. 🎯 GitHub Secrets Configuration

Add these secrets to your GitHub repository:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `SSH_PRIVATE_KEY` | AWS EC2 SSH private key | `-----BEGIN RSA PRIVATE KEY-----...` |
| `GITHUB_TOKEN` | GitHub personal access token | `ghp_xxxxxxxxxxxx` |
| `GHCR_TOKEN` | GitHub Container Registry token | `ghp_xxxxxxxxxxxx` |
| `AWS_SERVER_IP` | Production server IP | `54.234.122.255` |

## 🚀 GitHub Actions Workflows

### Workflow Files Structure
```
.github/workflows/
├── docker-build-push.yml      # Docker Hub deployment
├── github-packages.yml        # GitHub Packages deployment  
└── ansible-deploy.yml         # Full CI/CD with Ansible
```

### Main Deployment Workflow (ansible-deploy.yml)

#### Workflow Triggers
```yaml
on:
  push:
    branches: [ Ansible_Workflow ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'production'
```

#### Build and Push Job
```yaml
build-and-push:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
    - name: Set up Docker Buildx
    - name: Login to GitHub Container Registry
    - name: Build and push Docker images
    - name: Update compose files with new versions
    - name: Commit updated files
```

#### Deploy Job
```yaml
deploy-with-ansible:
  needs: build-and-push
  runs-on: ubuntu-latest
  steps:
    - name: Setup SSH connection
    - name: Install Ansible
    - name: Run Ansible playbook
    - name: Verify deployment health
```

### Workflow Execution Process

1. **Trigger**: Push to `Ansible_Workflow` branch
2. **Build**: Create Docker images with version `v1.0.${{ github.run_number }}`
3. **Push**: Upload images to GitHub Container Registry
4. **Update**: Modify docker-compose files with new image versions
5. **Deploy**: Use Ansible to deploy to AWS EC2 server
6. **Verify**: Check application health and accessibility

## 🔄 Jenkins Integration

For comprehensive Jenkins setup, see [PULLING.md](PULLING.md) which includes:

### Jenkins Pipeline Features
- **Freestyle Projects**: Step-by-step configuration
- **Pipeline Scripts**: Complete Groovy pipeline
- **Docker Integration**: Build, push, and deploy images
- **GitHub Integration**: Webhook triggers and SCM polling
- **Multi-environment**: Dev, staging, and production deployments

### Jenkins Pipeline Example
```groovy
pipeline {
    agent any
    environment {
        REGISTRY = 'ghcr.io'
        OWNER = 'shivamsingh163248'
        BUILD_VERSION = "v1.0.${BUILD_NUMBER}"
    }
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION backend/'
            }
        }
        stage('Deploy') {
            steps {
                sh 'ansible-playbook ansible/deploy-production.yml'
            }
        }
    }
}
```

## 📦 Docker Images & Registry

### Image Repository Structure
```
GitHub Container Registry (ghcr.io/shivamsingh163248/)
├── flask_backend:latest
├── flask_backend:v1.0.X
├── nginx_frontend:latest  
├── nginx_frontend:v1.0.X
├── mysql_db:latest
└── mysql_db:v1.0.X
```

### Image Details

#### Backend (Flask API)
```dockerfile
# Base: python:3.9-slim
# Port: 5000
# Features:
# - REST API endpoints
# - MySQL database integration
# - Authentication system
# - Admin panel API
```

#### Frontend (Nginx Web Server)
```dockerfile
# Base: nginx:alpine
# Port: 80 (mapped to 8080)
# Features:
# - Static file serving
# - Admin interface
# - Reverse proxy to backend
# - Responsive design
```

#### Database (MySQL)
```dockerfile
# Base: mysql:8.0
# Port: 3306
# Features:
# - Persistent data storage
# - Admin user management
# - Database initialization scripts
# - Backup and recovery support
```

## 🎯 Ansible Deployment

### Deployment Process Overview
```
1. System Setup → 2. Docker Installation → 3. User Configuration → 4. App Deployment → 5. Health Check
```

### Key Playbook Features
- **Automated Docker Compose installation**
- **SSH connection reset for permissions**
- **GitHub Container Registry integration**
- **Health verification and monitoring**
- **Error handling and recovery**

## 🔍 Monitoring & Troubleshooting

### Health Check Endpoints
- **Frontend**: http://54.234.122.255:8080
- **Backend**: http://54.234.122.255:5000/health
- **Database**: Connection via backend API

### Common Issues & Solutions
1. **SSH Permission Denied**: Check SSH key format in GitHub Secrets
2. **Docker Permission Error**: Reset SSH connection after docker group addition
3. **Image Pull Failed**: Verify GitHub Container Registry authentication
4. **Deployment Timeout**: Check server resources and network connectivity

## 🌐 Access Points

### Production Environment
- **Application URL**: http://54.234.122.255:8080
- **API Endpoint**: http://54.234.122.255:5000
- **Admin Credentials**: admin/admin123

### Development Environment  
- **Local Frontend**: http://localhost:8080
- **Local Backend**: http://localhost:5000
- **Local Database**: localhost:3306

## 📚 Additional Resources

### Documentation Files
- **[PULLING.md](PULLING.md)**: Complete Jenkins CI/CD integration guide
- **[SSH_KEY_SETUP_GUIDE.md](SSH_KEY_SETUP_GUIDE.md)**: SSH key configuration
- **[DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)**: Troubleshooting guide

### Quick Start Commands

#### Local Development
```bash
git clone https://github.com/shivamsingh163248/Microservice-admin-apps.git
cd Microservice-admin-apps
docker-compose up -d
```

#### Production Deployment
```bash
# Push to trigger deployment
git push origin Ansible_Workflow

# Monitor progress
# GitHub → Actions → View workflow run

# Verify deployment
curl http://54.234.122.255:8080
```

## 🎯 Quick Start Checklist

- [ ] Clone repository
- [ ] Configure GitHub Secrets (SSH_PRIVATE_KEY, GITHUB_TOKEN)  
- [ ] Update inventory.ini with your server IP
- [ ] Push to Ansible_Workflow branch
- [ ] Monitor GitHub Actions workflow
- [ ] Verify application at http://your-server-ip:8080
- [ ] Check troubleshooting guides if issues occur

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License.

---

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/shivamsingh163248/Microservice-admin-apps/issues)
- **Email**: admin@yourdomain.com

---

**Last Updated**: August 30, 2025  
**Version**: 2.0  
**Maintainer**: DevOps Team

**Happy Deploying! 🚀**
```

#### Add Public Key to EC2
1. Copy public key content:
```bash
cat ~/.ssh/aws-microservice-key.pub
```
2. Add to EC2 instance: `~/.ssh/authorized_keys`

#### Configure GitHub Secrets
Go to Repository → Settings → Secrets and variables → Actions

Add the following secrets:
```
SSH_PRIVATE_KEY: [Your complete private key content]
```

**Private Key Format:**
```
-----BEGIN RSA PRIVATE KEY-----
[Your key content here]
-----END RSA PRIVATE KEY-----
```

### 2. 🖥️ Server Configuration

#### Update Inventory File
Edit `ansible/inventory.ini`:
```ini
[webservers]
production ansible_host=YOUR_EC2_IP ansible_user=ubuntu

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
docker_compose_version=v2.21.0
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

#### EC2 Security Groups
Ensure these ports are open:
- **Port 22**: SSH access
- **Port 8080**: Frontend application
- **Port 5000**: Backend API (optional)

### 3. 🔧 GitHub Actions Configuration

The repository includes three main workflows:

#### Workflow Files
- `.github/workflows/docker-build-push.yml` - Docker Hub deployment
- `.github/workflows/github-packages.yml` - GitHub Packages deployment  
- `.github/workflows/ansible-deploy.yml` - Main production deployment

## 🚀 Deployment Workflows

### Automatic Deployment Process

#### Trigger Deployment
Push to the `Ansible_Workflow` branch:
```bash
git checkout Ansible_Workflow
git add .
git commit -m "Deploy new version"
git push origin Ansible_Workflow
```

#### Workflow Execution
1. **Build Job** (2-3 minutes):
   ```
   ✅ Checkout code
   ✅ Build Docker images
   ✅ Push to GitHub Container Registry
   ✅ Update docker-compose files
   ✅ Commit version updates
   ```

2. **Deploy Job** (3-5 minutes):
   ```
   ✅ Setup SSH connection
   ✅ Install Ansible
   ✅ Configure target server
   ✅ Install Docker & Docker Compose
   ✅ Deploy microservices
   ✅ Verify deployment health
   ```

#### Version Management
Each deployment gets an automatic version tag:
- Format: `v1.0.{BUILD_NUMBER}`
- Example: `v1.0.15` for build #15

### Manual Deployment (Alternative)

#### Using Ansible Directly
```bash
cd ansible
ansible-playbook -i inventory.ini deploy-production.yml
```

#### Using Docker Compose Locally
```bash
# Development
docker-compose up -d

# Production
docker-compose -f docker-compose.production.yml up -d
```

## 📦 Docker Images

### Image Registry
All images are stored in GitHub Container Registry:
- **Registry**: `ghcr.io/shivamsingh163248`
- **Images**:
  - `flask_backend:v1.0.X`
  - `nginx_frontend:v1.0.X`
  - `mysql_db:v1.0.X`

### Image Build Process
```yaml
# Automatic versioning in GitHub Actions
IMAGE_VERSION: v1.0.${{ github.run_number }}
```

### Manual Image Management
```bash
# Build images locally
docker build -t microservice-backend ./backend
docker build -t microservice-frontend ./frontend
docker build -t microservice-database ./database

# Push to registry
docker tag microservice-backend ghcr.io/shivamsingh163248/flask_backend:latest
docker push ghcr.io/shivamsingh163248/flask_backend:latest
```

## 🔍 Monitoring & Troubleshooting

### Deployment Status
Monitor deployment in GitHub Actions:
1. Go to repository → Actions tab
2. Look for "Build, Push, and Deploy Microservices"
3. Check both build and deploy job status

### Common Issues & Solutions

#### SSH Connection Issues
```bash
# Test SSH connection manually
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Check GitHub secret format
# Ensure SSH_PRIVATE_KEY includes full key with headers
```

#### Docker Permission Issues
```bash
# On EC2 instance
sudo usermod -aG docker ubuntu
# Then logout/login or restart SSH session
```

#### Service Health Checks
```bash
# Check running containers
docker ps

# Check logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs database

# Check service status
curl http://YOUR_EC2_IP:8080  # Frontend
curl http://YOUR_EC2_IP:5000/health  # Backend API
```

### Log Files
Access logs on the server:
```bash
# Application logs
cd /opt/microservice-admin-app
docker-compose logs -f

# System logs
sudo journalctl -u docker
```

### Troubleshooting Guides
- 📋 `DEPLOYMENT_TROUBLESHOOTING.md` - Common deployment issues
- 🔑 `SSH_KEY_SETUP_GUIDE.md` - SSH configuration guide

## 🌐 Access Points

### Production Application
- **Frontend**: http://YOUR_EC2_IP:8080
- **Backend API**: http://YOUR_EC2_IP:5000
- **Health Check**: http://YOUR_EC2_IP:5000/health

### Development Environment
```bash
# Start local development
docker-compose up -d

# Access points
# Frontend: http://localhost:8080
# Backend: http://localhost:5000
# Database: localhost:3306
```

### Application Features
- **Admin Dashboard**: User management interface
- **Authentication**: Login/register functionality
- **Database Management**: MySQL with persistent storage
- **API Endpoints**: RESTful backend services

## 🔄 Workflow Branches

### Branch Structure
- **`main`**: Stable production code
- **`Ansible_Workflow`**: Deployment branch (triggers CI/CD)
- **`Ansible_GithubAction_Workflow`**: Default branch

### Deployment Strategy
```bash
# Development work
git checkout main
git pull origin main
# Make changes
git checkout -b feature/new-feature
# Commit changes

# Deploy to production
git checkout Ansible_Workflow
git merge main
git push origin Ansible_Workflow  # Triggers deployment
```

## 📊 Monitoring Dashboard

### GitHub Actions Dashboard
Track deployment metrics:
- Build success rate
- Deployment frequency  
- Average deployment time
- Failed deployment alerts

### Server Monitoring
```bash
# Resource usage
docker stats

# Disk usage
df -h

# Memory usage
free -h

# Process monitoring
htop
```

## 🚨 Emergency Procedures

### Rollback Deployment
```bash
# Option 1: Revert to previous version
git revert HEAD
git push origin Ansible_Workflow

# Option 2: Manual rollback on server
cd /opt/microservice-admin-app
docker-compose down
# Edit docker-compose.production.yml with previous version
docker-compose up -d
```

### Server Recovery
```bash
# Restart all services
docker-compose restart

# Full cleanup and redeploy
docker-compose down
docker system prune -a
# Trigger new deployment from GitHub
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
1. Check [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)
2. Review GitHub Actions logs
3. Check server logs: `docker-compose logs`
4. Create GitHub issue with error details

---

**🎉 Happy Deploying!** 🚀 
