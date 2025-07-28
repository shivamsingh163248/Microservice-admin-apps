# Ansible Deployment for Microservices

This directory contains Ansible playbooks and configuration for automated deployment of the microservices application.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.ini           # Server inventory
├── deploy.yml             # Basic deployment playbook
├── deploy-production.yml  # Enhanced production playbook
├── group_vars/
│   └── all.yml           # Global variables
├── templates/
│   ├── docker-compose.deploy.yml.j2      # Basic deployment template
│   └── docker-compose.production.yml.j2  # Production template
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Ansible installed** on your local machine or CI/CD runner
2. **SSH access** to target servers
3. **Docker** installed on target servers
4. **GitHub Container Registry access** (for private images)

### Setup

1. **Configure Inventory**
   ```bash
   # Edit ansible/inventory.ini
   [webservers]
   production-server ansible_host=YOUR_SERVER_IP ansible_user=ubuntu
   ```

2. **Setup SSH Key**
   ```bash
   # Add your SSH private key to GitHub Secrets as SSH_PRIVATE_KEY
   # Or place it in ~/.ssh/id_rsa on your local machine
   ```

3. **Test Connection**
   ```bash
   cd ansible
   ansible -i inventory.ini webservers -m ping
   ```

## 🎯 Deployment Methods

### Method 1: GitHub Actions (Automated)

The deployment runs automatically when you push to main branch via:
- `.github/workflows/ansible-deploy.yml`

**Required GitHub Secrets:**
- `SSH_PRIVATE_KEY`: Your SSH private key for server access

### Method 2: Manual Deployment

```bash
# Navigate to ansible directory
cd ansible

# Basic deployment
ansible-playbook -i inventory.ini deploy.yml \
  --extra-vars "image_version=v1.0.123" \
  --extra-vars "ghcr_owner=shivamsingh163248"

# Production deployment (enhanced)
ansible-playbook -i inventory.ini deploy-production.yml \
  --extra-vars "image_version=v1.0.123" \
  --extra-vars "ghcr_owner=shivamsingh163248"
```

## 🔧 Configuration Files

### Inventory Configuration (`inventory.ini`)

Configure your target servers:
```ini
[webservers]
# AWS EC2 Example
production ansible_host=3.15.123.456 ansible_user=ubuntu

# Multiple servers
server1 ansible_host=192.168.1.100 ansible_user=ubuntu
server2 ansible_host=192.168.1.101 ansible_user=ubuntu

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Variables (`group_vars/all.yml`)

Key variables you can customize:
- `app_name`: Application name
- `ghcr_owner`: GitHub Container Registry owner
- `mysql_config`: Database configuration
- `app_base_dir`: Base installation directory

## 📋 Available Playbooks

### 1. Basic Deployment (`deploy.yml`)
- Simple deployment workflow
- Basic server setup
- Suitable for development/testing

### 2. Production Deployment (`deploy-production.yml`)
- Enhanced production features
- Comprehensive health checks
- Error handling and rollback
- Detailed logging and monitoring

## 🔍 What the Deployment Does

1. **System Setup**
   - Updates system packages
   - Installs Docker and required tools
   - Configures Docker service

2. **Application Deployment**
   - Clones/updates repository
   - Logs into GitHub Container Registry
   - Pulls latest Docker images
   - Stops old containers
   - Starts new containers with updated images

3. **Health Checks**
   - Waits for services to be ready
   - Verifies frontend accessibility
   - Validates all ports are responding

4. **Cleanup**
   - Removes old Docker images
   - Cleans up unused containers

## 🎛️ Deployment Variables

Pass these via `--extra-vars`:

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `image_version` | Docker image version | `latest` | `v1.0.123` |
| `ghcr_owner` | GitHub Container Registry owner | `shivamsingh163248` | `your-username` |
| `app_name` | Application name | `microservice-admin-app` | `my-app` |

## 🚨 Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Test SSH connection
   ssh -i ~/.ssh/id_rsa ubuntu@YOUR_SERVER_IP
   
   # Check SSH key permissions
   chmod 600 ~/.ssh/id_rsa
   ```

2. **Docker Permission Denied**
   ```bash
   # Add user to docker group (run on server)
   sudo usermod -aG docker $USER
   sudo systemctl restart docker
   ```

3. **Image Pull Failed**
   ```bash
   # Login to GHCR manually on server
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

### Debug Commands

```bash
# Run with verbose output
ansible-playbook -i inventory.ini deploy.yml -v

# Check specific task
ansible-playbook -i inventory.ini deploy.yml --start-at-task="Start services"

# Dry run (check mode)
ansible-playbook -i inventory.ini deploy.yml --check
```

## 🌐 Post-Deployment

After successful deployment, your services will be available at:

- **Frontend**: `http://YOUR_SERVER_IP:8080`
- **Backend API**: `http://YOUR_SERVER_IP:5000`
- **Database**: `YOUR_SERVER_IP:3306` (if needed)

## 🔒 Security Considerations

1. **SSH Keys**: Use key-based authentication instead of passwords
2. **Firewall**: Configure appropriate firewall rules
3. **SSL/TLS**: Consider adding reverse proxy with SSL certificates
4. **Secrets**: Store sensitive data in GitHub Secrets or Ansible Vault

## 📊 Monitoring

Consider adding monitoring solutions:
- Docker health checks
- Application logs
- System resource monitoring
- Service availability checks
