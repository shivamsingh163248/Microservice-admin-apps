# 🚀 Microservice Admin App

A comprehensive microservice application with automated CI/CD deployment using GitHub Actions, Docker, and Ansible.

## 📋 Table of Contents

- [🏗️ Architecture](#️-architecture)
- [🔧 Prerequisites](#-prerequisites)
- [⚙️ Setup & Configuration](#️-setup--configuration)
- [🚀 Deployment Workflows](#-deployment-workflows)
- [📦 Docker Images](#-docker-images)
- [🔍 Monitoring & Troubleshooting](#-monitoring--troubleshooting)
- [🌐 Access Points](#-access-points)

## 🏗️ Architecture

This application consists of three main components:

### Services
- **Frontend**: Nginx-based web interface (Port 8080)
- **Backend**: Flask API server (Port 5000)
- **Database**: MySQL database (Port 3306)

### Infrastructure
- **Container Registry**: GitHub Container Registry (GHCR)
- **CI/CD**: GitHub Actions workflows
- **Deployment**: Ansible automation
- **Target Server**: AWS EC2 Ubuntu instance

## 🔧 Prerequisites

### Local Development
- Docker & Docker Compose
- Git
- Node.js (for frontend development)
- Python 3.x (for backend development)

### Production Deployment
- AWS EC2 instance (Ubuntu 24.04)
- SSH key pair for server access
- GitHub repository with Actions enabled
- Docker Hub account (optional)

## ⚙️ Setup & Configuration

### 1. 🗝️ SSH Key Setup

#### Generate SSH Key (if needed)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-microservice-key
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
