# 📝 JFrog Artifactory Step-by-Step Implementation Guide

## 📋 Table of Contents

1. [Quick Start Overview](#-quick-start-overview)
2. [Phase 1: Environment Setup](#-phase-1-environment-setup)
3. [Phase 2: Artifactory Installation](#-phase-2-artifactory-installation)
4. [Phase 3: Initial Configuration](#-phase-3-initial-configuration)
5. [Phase 4: Repository Setup](#-phase-4-repository-setup)
6. [Phase 5: Security Implementation](#-phase-5-security-implementation)
7. [Phase 6: Integration Setup](#-phase-6-integration-setup)
8. [Phase 7: Testing & Validation](#-phase-7-testing--validation)
9. [Phase 8: Production Deployment](#-phase-8-production-deployment)
10. [Phase 9: Monitoring & Maintenance](#-phase-9-monitoring--maintenance)

## 🚀 Quick Start Overview

### **Implementation Timeline**

```
Week 1: Environment & Installation
├── Day 1-2: Infrastructure setup
├── Day 3-4: Artifactory installation  
└── Day 5: Initial configuration

Week 2: Configuration & Security
├── Day 1-2: Repository structure
├── Day 3-4: Security setup
└── Day 5: Integration configuration

Week 3: Integration & Testing
├── Day 1-2: CI/CD integration
├── Day 3-4: Comprehensive testing
└── Day 5: Performance tuning

Week 4: Production Deployment
├── Day 1-2: Production setup
├── Day 3-4: Monitoring implementation
└── Day 5: Documentation & handover
```

### **Prerequisites Checklist**

```bash
# Infrastructure Requirements
□ Server hardware/VM provisioned
□ Network connectivity configured
□ DNS entries created
□ SSL certificates obtained
□ Firewall rules configured

# Software Requirements  
□ Operating system installed and updated
□ Docker and Docker Compose installed
□ Database server ready (PostgreSQL/MySQL)
□ Load balancer configured (if applicable)
□ Backup storage configured

# Access Requirements
□ Administrative access to servers
□ Database credentials available
□ SSL certificate files available
□ Integration service accounts created
□ CI/CD system access configured
```

## 🏗️ Phase 1: Environment Setup

### **Step 1.1: Server Preparation**

#### **Update System**
```bash
# Update package repositories
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip vim htop net-tools

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

#### **Configure Firewall**
```bash
# Configure UFW firewall
sudo ufw enable
sudo ufw allow 22/tcp        # SSH
sudo ufw allow 80/tcp        # HTTP  
sudo ufw allow 443/tcp       # HTTPS
sudo ufw allow 8081/tcp      # Artifactory API
sudo ufw allow 8082/tcp      # Artifactory UI
sudo ufw status
```

#### **Create Directory Structure**
```bash
# Create Artifactory directories
sudo mkdir -p /opt/artifactory/{data,logs,backup,config,scripts}
sudo mkdir -p /opt/artifactory/data/{filestore,cache,tmp}

# Set permissions
sudo useradd -r -m -s /bin/bash artifactory
sudo chown -R artifactory:artifactory /opt/artifactory
sudo chmod -R 755 /opt/artifactory
```

### **Step 1.2: Database Setup**

#### **Install PostgreSQL**
```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create Artifactory database and user
sudo -u postgres psql << 'EOF'
CREATE DATABASE artifactory;
CREATE USER artifactory WITH PASSWORD 'secure_password_123';
GRANT ALL PRIVILEGES ON DATABASE artifactory TO artifactory;
ALTER USER artifactory CREATEDB;
\q
EOF

# Test database connection
psql -h localhost -U artifactory -d artifactory -c "SELECT version();"
```

#### **Configure PostgreSQL**
```bash
# Edit PostgreSQL configuration
sudo nano /etc/postgresql/*/main/postgresql.conf

# Add/modify these settings:
listen_addresses = 'localhost'
port = 5432
shared_buffers = '256MB'
effective_cache_size = '1GB'
maintenance_work_mem = '64MB'
checkpoint_completion_target = 0.7
wal_buffers = '16MB'
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### **Step 1.3: SSL Certificate Setup**

#### **Generate Self-Signed Certificate (Development)**
```bash
# Create SSL directory
sudo mkdir -p /opt/artifactory/ssl

# Generate private key
sudo openssl genrsa -out /opt/artifactory/ssl/artifactory.key 2048

# Generate certificate signing request
sudo openssl req -new -key /opt/artifactory/ssl/artifactory.key -out /opt/artifactory/ssl/artifactory.csr -subj "/C=US/ST=State/L=City/O=Company/CN=artifactory.company.com"

# Generate self-signed certificate
sudo openssl x509 -req -days 365 -in /opt/artifactory/ssl/artifactory.csr -signkey /opt/artifactory/ssl/artifactory.key -out /opt/artifactory/ssl/artifactory.crt

# Set permissions
sudo chown artifactory:artifactory /opt/artifactory/ssl/*
sudo chmod 600 /opt/artifactory/ssl/artifactory.key
sudo chmod 644 /opt/artifactory/ssl/artifactory.crt
```

#### **Install Let's Encrypt Certificate (Production)**
```bash
# Install Certbot
sudo apt install -y certbot

# Generate certificate
sudo certbot certonly --standalone -d artifactory.company.com

# Copy certificates
sudo cp /etc/letsencrypt/live/artifactory.company.com/fullchain.pem /opt/artifactory/ssl/artifactory.crt
sudo cp /etc/letsencrypt/live/artifactory.company.com/privkey.pem /opt/artifactory/ssl/artifactory.key

# Set permissions
sudo chown artifactory:artifactory /opt/artifactory/ssl/*
```

## 📦 Phase 2: Artifactory Installation

### **Step 2.1: Docker Compose Setup**

#### **Create Docker Compose File**
```bash
# Create docker-compose.yml
cat > /opt/artifactory/docker-compose.yml << 'EOF'
version: '3.8'

services:
  artifactory:
    image: releases-docker.jfrog.io/jfrog/artifactory-oss:latest
    container_name: artifactory
    restart: unless-stopped
    ports:
      - "8081:8081"
      - "8082:8082"
    volumes:
      - artifactory_data:/var/opt/jfrog/artifactory
      - artifactory_logs:/var/opt/jfrog/artifactory/logs
      - artifactory_backup:/var/opt/jfrog/artifactory/backup
      - /opt/artifactory/ssl:/var/opt/jfrog/artifactory/etc/ssl:ro
    environment:
      - JF_SHARED_DATABASE_TYPE=postgresql
      - JF_SHARED_DATABASE_USERNAME=artifactory
      - JF_SHARED_DATABASE_PASSWORD=secure_password_123
      - JF_SHARED_DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/artifactory
      - JF_SHARED_DATABASE_DRIVER=org.postgresql.Driver
      - ENABLE_MIGRATION=y
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "10"

  nginx:
    image: nginx:alpine
    container_name: artifactory-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /opt/artifactory/ssl:/etc/nginx/ssl:ro
    depends_on:
      - artifactory
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  artifactory_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/artifactory/data
  artifactory_logs:
    driver: local
    driver_opts:
      type: none
      o: bind  
      device: /opt/artifactory/logs
  artifactory_backup:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/artifactory/backup

networks:
  default:
    driver: bridge
EOF
```

#### **Create Nginx Configuration**
```bash
# Create nginx.conf
cat > /opt/artifactory/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 1G;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    upstream artifactory {
        server artifactory:8081;
    }
    
    upstream artifactory-ui {
        server artifactory:8082;
    }
    
    # HTTP redirect to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }
    
    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name artifactory.company.com;
        
        ssl_certificate /etc/nginx/ssl/artifactory.crt;
        ssl_certificate_key /etc/nginx/ssl/artifactory.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        
        access_log /var/log/nginx/artifactory_access.log main;
        error_log /var/log/nginx/artifactory_error.log;
        
        # Docker API
        location ~ ^/(v1|v2)/ {
            proxy_pass http://artifactory;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Authorization $http_authorization;
            proxy_pass_header Authorization;
        }
        
        # Artifactory API
        location /artifactory/ {
            proxy_pass http://artifactory/artifactory/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_request_buffering off;
        }
        
        # UI
        location /ui/ {
            proxy_pass http://artifactory-ui/ui/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Root redirect to UI
        location / {
            return 301 https://$host/ui/;
        }
    }
}
EOF
```

### **Step 2.2: Deploy Artifactory**

#### **Start Services**
```bash
# Navigate to Artifactory directory
cd /opt/artifactory

# Create required directories
sudo mkdir -p data logs backup
sudo chown -R 1030:1030 data logs backup

# Start Artifactory
docker-compose up -d

# Monitor startup
docker-compose logs -f artifactory

# Verify services are running
docker-compose ps
```

#### **Wait for Startup**
```bash
# Check Artifactory startup status
echo "Waiting for Artifactory to start..."
for i in {1..30}; do
    if curl -f -s http://localhost:8081/artifactory/api/system/ping > /dev/null; then
        echo "Artifactory is ready!"
        break
    fi
    echo "Attempt $i/30: Artifactory not ready, waiting..."
    sleep 30
done

# Verify UI access
curl -f http://localhost:8082/ui/
```

## ⚙️ Phase 3: Initial Configuration

### **Step 3.1: Initial Setup Wizard**

#### **Access Web Interface**
```bash
# Open web browser and navigate to:
echo "Access Artifactory at: https://artifactory.company.com/ui/"
echo "Default credentials: admin / password"
```

#### **Complete Setup Wizard**
1. **Welcome Screen**
   - Accept End User License Agreement
   - Click "Get Started"

2. **Set Admin Password**
   ```bash
   # Change default password immediately
   New Password: [Enter strong password]
   Confirm Password: [Confirm password]
   ```

3. **Configure Base URL**
   ```bash
   Server Name: artifactory.company.com
   HTTP Port: 80
   HTTPS Port: 443
   Use HTTPS: Yes
   ```

4. **Configure Proxy (if needed)**
   ```bash
   Proxy Host: proxy.company.com
   Proxy Port: 8080
   Username: [proxy username]
   Password: [proxy password]
   ```

### **Step 3.2: System Configuration**

#### **Create system.yaml**
```bash
# Create system configuration
sudo -u artifactory cat > /opt/artifactory/data/etc/system.yaml << 'EOF'
shared:
  # Security configuration
  security:
    joinKey: "generated-join-key-here"
    
  # Database configuration
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: jdbc:postgresql://host.docker.internal:5432/artifactory
    username: artifactory
    password: secure_password_123
    maxOpenConnections: 80
    maxIdleConnections: 20
    
  # Node configuration
  node:
    id: "artifactory-node-1"
    name: "artifactory-primary"
    
# Router configuration
router:
  entrypoints:
    internalPort: 8082
    internalPortTls: 8443
    externalPort: 80
    externalPortTls: 443
    
  tlsConfig:
    cert: /var/opt/jfrog/artifactory/etc/ssl/artifactory.crt
    key: /var/opt/jfrog/artifactory/etc/ssl/artifactory.key

# Access configuration
access:
  # Session timeout (30 minutes)
  session:
    timeout: 1800
EOF
```

#### **Restart Artifactory**
```bash
# Restart to apply configuration
docker-compose restart artifactory

# Wait for restart
sleep 60

# Verify configuration
curl -f http://localhost:8081/artifactory/api/system/ping
```

### **Step 3.3: License Configuration (Pro/Enterprise)**

```bash
# Upload license via API (Pro/Enterprise only)
curl -X POST "http://localhost:8081/artifactory/api/system/licenses" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "licenseKey": "your-license-key-here"
  }'
```

## 🗄️ Phase 4: Repository Setup

### **Step 4.1: Create Docker Repositories**

#### **Docker Local Repository**
```bash
# Create Docker local repository for development
curl -X PUT "http://localhost:8081/artifactory/api/repositories/docker-local-dev" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "local",
    "packageType": "docker",
    "description": "Local Docker repository for development images",
    "dockerApiVersion": "V2",
    "maxUniqueSnapshots": 10,
    "dockerTagRetention": 3,
    "dockerMaxUniqueTags": 10,
    "xrayConfig": {
      "enabled": true
    }
  }'

# Verify repository creation
curl -X GET "http://localhost:8081/artifactory/api/repositories/docker-local-dev" \
  -u admin:new_password
```

#### **Docker Remote Repository**
```bash
# Create Docker Hub proxy
curl -X PUT "http://localhost:8081/artifactory/api/repositories/docker-remote" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "remote",
    "packageType": "docker",
    "url": "https://registry-1.docker.io/",
    "description": "Docker Hub proxy repository",
    "dockerApiVersion": "V2",
    "enableTokenAuthentication": true,
    "storeArtifactsLocally": true,
    "retrievalCachePeriodSecs": 7200,
    "xrayConfig": {
      "enabled": true
    }
  }'
```

#### **Docker Virtual Repository**
```bash
# Create Docker virtual repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/docker-virtual" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "virtual",
    "packageType": "docker",
    "description": "Virtual Docker repository",
    "repositories": ["docker-local-dev", "docker-remote"],
    "defaultDeploymentRepo": "docker-local-dev",
    "dockerApiVersion": "V2",
    "enableTokenAuthentication": true
  }'
```

### **Step 4.2: Create Generic Repositories**

#### **Generic Local Repository**
```bash
# Create generic repository for application artifacts
curl -X PUT "http://localhost:8081/artifactory/api/repositories/generic-local" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "local",
    "packageType": "generic",
    "description": "Local generic repository for application artifacts",
    "checksumPolicyType": "client-checksums",
    "handleReleases": true,
    "handleSnapshots": true,
    "archiveBrowsingEnabled": true,
    "xrayConfig": {
      "enabled": true
    }
  }'
```

#### **Release Repository**
```bash
# Create release repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/release-local" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "local",
    "packageType": "generic",
    "description": "Release artifacts repository",
    "checksumPolicyType": "client-checksums",
    "handleReleases": true,
    "handleSnapshots": false,
    "xrayConfig": {
      "enabled": true
    }
  }'
```

### **Step 4.3: Create Package Manager Repositories**

#### **NPM Repositories**
```bash
# NPM local repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/npm-local" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "local",
    "packageType": "npm",
    "description": "Local NPM repository"
  }'

# NPM remote repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/npm-remote" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "remote",
    "packageType": "npm",
    "url": "https://registry.npmjs.org/",
    "description": "NPM registry proxy"
  }'

# NPM virtual repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/npm-virtual" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "virtual",
    "packageType": "npm",
    "repositories": ["npm-local", "npm-remote"],
    "defaultDeploymentRepo": "npm-local",
    "description": "Virtual NPM repository"
  }'
```

#### **PyPI Repositories**
```bash
# PyPI local repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/pypi-local" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "local",
    "packageType": "pypi",
    "description": "Local PyPI repository"
  }'

# PyPI remote repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/pypi-remote" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "rclass": "remote",
    "packageType": "pypi",
    "url": "https://pypi.org/",
    "description": "PyPI proxy repository"
  }'
```

### **Step 4.4: Verify Repository Setup**

```bash
# List all repositories
curl -X GET "http://localhost:8081/artifactory/api/repositories" \
  -u admin:new_password | jq '.[].key'

# Test repository access
curl -X GET "http://localhost:8081/artifactory/docker-local-dev/v2/_catalog" \
  -u admin:new_password
```

## 🔐 Phase 5: Security Implementation

### **Step 5.1: User Management**

#### **Create Service Users**
```bash
# Create Jenkins service user
curl -X POST "http://localhost:8081/artifactory/api/security/users/jenkins-service" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "jenkins-service",
    "email": "jenkins@company.com",
    "password": "jenkins_secure_password_123",
    "admin": false,
    "profileUpdatable": false,
    "disableUIAccess": true,
    "groups": ["ci-cd-users"]
  }'

# Create DevOps user
curl -X POST "http://localhost:8081/artifactory/api/security/users/devops-user" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "devops-user",
    "email": "devops@company.com",
    "password": "devops_secure_password_123",
    "admin": false,
    "profileUpdatable": true,
    "disableUIAccess": false,
    "groups": ["devops-team"]
  }'

# Create developer user
curl -X POST "http://localhost:8081/artifactory/api/security/users/developer" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "developer",
    "email": "developer@company.com", 
    "password": "developer_password_123",
    "admin": false,
    "profileUpdatable": true,
    "disableUIAccess": false,
    "groups": ["developers"]
  }'
```

### **Step 5.2: Group Management**

#### **Create Groups**
```bash
# Create CI/CD group
curl -X POST "http://localhost:8081/artifactory/api/security/groups/ci-cd-users" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "ci-cd-users",
    "description": "CI/CD systems with deployment permissions",
    "autoJoin": false,
    "adminPrivileges": false
  }'

# Create DevOps group
curl -X POST "http://localhost:8081/artifactory/api/security/groups/devops-team" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "devops-team",
    "description": "DevOps team with administrative permissions",
    "autoJoin": false,
    "adminPrivileges": false
  }'

# Create Developers group
curl -X POST "http://localhost:8081/artifactory/api/security/groups/developers" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "developers",
    "description": "Development team with read access",
    "autoJoin": false,
    "adminPrivileges": false
  }'
```

### **Step 5.3: Permission Setup**

#### **CI/CD Permissions**
```bash
# Create CI/CD permissions
curl -X POST "http://localhost:8081/artifactory/api/v2/security/permissions/cicd-permissions" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "cicd-permissions",
    "repo": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": [
        "docker-local-dev",
        "generic-local",
        "npm-local",
        "pypi-local"
      ],
      "actions": {
        "groups": {
          "ci-cd-users": ["read", "write", "annotate", "delete"]
        }
      }
    }
  }'
```

#### **DevOps Permissions**
```bash
# Create DevOps permissions
curl -X POST "http://localhost:8081/artifactory/api/v2/security/permissions/devops-permissions" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "devops-permissions",
    "repo": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["ANY LOCAL", "ANY REMOTE"],
      "actions": {
        "groups": {
          "devops-team": ["read", "write", "annotate", "delete", "manage"]
        }
      }
    }
  }'
```

#### **Developer Permissions**
```bash
# Create Developer permissions (read-only)
curl -X POST "http://localhost:8081/artifactory/api/v2/security/permissions/developer-permissions" \
  -H "Content-Type: application/json" \
  -u admin:new_password \
  -d '{
    "name": "developer-permissions",
    "repo": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["ANY"],
      "actions": {
        "groups": {
          "developers": ["read"]
        }
      }
    }
  }'
```

### **Step 5.4: API Key Generation**

```bash
# Generate API key for Jenkins service user
API_KEY=$(curl -X POST "http://localhost:8081/artifactory/api/security/apiKey" \
  -u jenkins-service:jenkins_secure_password_123 | jq -r '.apiKey')

echo "Jenkins API Key: $API_KEY"

# Store API key securely
echo "$API_KEY" | sudo tee /opt/artifactory/config/jenkins-api-key.txt
sudo chmod 600 /opt/artifactory/config/jenkins-api-key.txt
```

## 🔗 Phase 6: Integration Setup

### **Step 6.1: Docker Registry Integration**

#### **Configure Docker Daemon**
```bash
# Configure Docker to use Artifactory registry
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "insecure-registries": [
    "artifactory.company.com",
    "localhost:8081"
  ],
  "registry-mirrors": [
    "https://artifactory.company.com/artifactory/docker-virtual"
  ]
}
EOF

# Restart Docker
sudo systemctl restart docker

# Login to Artifactory Docker registry
echo "jenkins_secure_password_123" | docker login artifactory.company.com -u jenkins-service --password-stdin
```

#### **Test Docker Registry**
```bash
# Pull image through Artifactory
docker pull artifactory.company.com/docker-virtual/nginx:alpine

# Tag and push test image
docker tag nginx:alpine artifactory.company.com/docker-local-dev/test-nginx:v1.0.0
docker push artifactory.company.com/docker-local-dev/test-nginx:v1.0.0

# Verify image in repository
curl -u jenkins-service:jenkins_secure_password_123 \
  "http://localhost:8081/artifactory/api/docker/docker-local-dev/v2/_catalog"
```

### **Step 6.2: JFrog CLI Setup**

#### **Install and Configure JFrog CLI**
```bash
# Install JFrog CLI
curl -fL https://getcli.jfrog.io | sh
sudo mv jfrog /usr/local/bin/jf

# Configure Artifactory server
jf config add artifactory-server \
  --artifactory-url=http://localhost:8081/artifactory \
  --user=jenkins-service \
  --password=jenkins_secure_password_123 \
  --interactive=false

# Test connection
jf rt ping --server-id=artifactory-server
```

#### **Test Artifact Upload/Download**
```bash
# Create test artifact
echo "This is a test artifact" > test-artifact.txt

# Upload artifact
jf rt upload test-artifact.txt generic-local/test/ --server-id=artifactory-server

# Download artifact
jf rt download generic-local/test/test-artifact.txt ./downloads/ --server-id=artifactory-server

# Verify download
cat downloads/test-artifact.txt
```

### **Step 6.3: Build Tool Integration**

#### **NPM Configuration**
```bash
# Configure NPM to use Artifactory
npm config set registry http://localhost:8081/artifactory/api/npm/npm-virtual/

# Set authentication
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:_password $(echo -n "jenkins_secure_password_123" | base64)
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:username jenkins-service
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:email jenkins@company.com
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:always-auth true

# Test NPM installation
npm install express
```

#### **Python/pip Configuration**
```bash
# Configure pip to use Artifactory PyPI
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'EOF'
[global]
index-url = http://jenkins-service:jenkins_secure_password_123@localhost:8081/artifactory/api/pypi/pypi-virtual/simple
trusted-host = localhost
EOF

# Test Python package installation
pip install requests
```

## ✅ Phase 7: Testing & Validation

### **Step 7.1: Functionality Testing**

#### **API Testing**
```bash
# System health check
curl -f "http://localhost:8081/artifactory/api/system/ping"

# Repository listing
curl -u jenkins-service:jenkins_secure_password_123 \
  "http://localhost:8081/artifactory/api/repositories" | jq '.[].key'

# Storage information
curl -u jenkins-service:jenkins_secure_password_123 \
  "http://localhost:8081/artifactory/api/storageinfo"
```

#### **Upload/Download Testing**
```bash
# Test file upload
echo "Test content $(date)" > test-file-$(date +%s).txt
jf rt upload test-file-*.txt generic-local/tests/ --server-id=artifactory-server

# Test file download
jf rt download generic-local/tests/* ./test-downloads/ --server-id=artifactory-server

# Test Docker operations
docker pull artifactory.company.com/docker-virtual/alpine:latest
docker tag alpine:latest artifactory.company.com/docker-local-dev/test-alpine:latest
docker push artifactory.company.com/docker-local-dev/test-alpine:latest
```

### **Step 7.2: Security Testing**

#### **Permission Testing**
```bash
# Test developer read-only access
curl -u developer:developer_password_123 \
  "http://localhost:8081/artifactory/api/repositories" | jq '.[].key'

# Test developer cannot upload (should fail)
echo "Test" > developer-test.txt
curl -X PUT -u developer:developer_password_123 \
  "http://localhost:8081/artifactory/generic-local/developer-test.txt" \
  -T developer-test.txt
```

#### **API Key Testing**
```bash
# Test API key authentication
curl -H "X-JFrog-Art-Api: $API_KEY" \
  "http://localhost:8081/artifactory/api/system/ping"
```

### **Step 7.3: Performance Testing**

#### **Load Testing Script**
```bash
# Create load test script
cat > /opt/artifactory/scripts/load-test.sh << 'EOF'
#!/bin/bash

# Load test parameters
CONCURRENT_USERS=10
DURATION=300  # 5 minutes
API_KEY="your-api-key-here"

# Create test files
for i in {1..100}; do
    echo "Test file content $i $(date)" > test-file-$i.txt
done

# Upload test
echo "Starting upload load test..."
for i in {1..100}; do
    (
        jf rt upload test-file-$i.txt generic-local/load-test/ \
          --server-id=artifactory-server &
    )
    if [ $((i % $CONCURRENT_USERS)) -eq 0 ]; then
        wait
    fi
done

# Download test  
echo "Starting download load test..."
for i in {1..50}; do
    (
        jf rt download generic-local/load-test/test-file-$i.txt \
          ./downloads/ --server-id=artifactory-server &
    )
    if [ $((i % $CONCURRENT_USERS)) -eq 0 ]; then
        wait
    fi
done

echo "Load test completed"
EOF

chmod +x /opt/artifactory/scripts/load-test.sh
```

### **Step 7.4: Backup Testing**

#### **Test Backup Process**
```bash
# Create backup script
cat > /opt/artifactory/scripts/test-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/artifactory/backup/test-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Testing backup process..."

# Backup configuration
docker cp artifactory:/var/opt/jfrog/artifactory/etc "$BACKUP_DIR/"

# Backup database
pg_dump -h localhost -U artifactory -d artifactory | gzip > "$BACKUP_DIR/database.sql.gz"

# Test restore (dry run)
echo "Backup test completed: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
EOF

chmod +x /opt/artifactory/scripts/test-backup.sh
/opt/artifactory/scripts/test-backup.sh
```

## 🚀 Phase 8: Production Deployment

### **Step 8.1: Production Hardening**

#### **Security Hardening**
```bash
# Update system configuration for production
sudo -u artifactory cat > /opt/artifactory/data/etc/system.yaml << 'EOF'
shared:
  security:
    joinKey: "production-join-key-generate-new"
    
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: jdbc:postgresql://prod-db.company.com:5432/artifactory
    username: artifactory_prod
    password: "${DB_PASSWORD}"
    maxOpenConnections: 100
    maxIdleConnections: 25
    
  node:
    id: "artifactory-prod-1"
    name: "artifactory-production"
    
router:
  entrypoints:
    internalPort: 8082
    internalPortTls: 8443
    externalPort: 80
    externalPortTls: 443
    
  tlsConfig:
    cert: /var/opt/jfrog/artifactory/etc/ssl/prod.crt
    key: /var/opt/jfrog/artifactory/etc/ssl/prod.key

access:
  security:
    passwordSettings:
      expirationDays: 90
      encryptionPolicy: "required"
  session:
    timeout: 1800
EOF
```

#### **Production Docker Compose**
```bash
# Update docker-compose.yml for production
cat > /opt/artifactory/docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  artifactory:
    image: releases-docker.jfrog.io/jfrog/artifactory-pro:latest  # Use Pro for production
    container_name: artifactory-prod
    restart: always
    ports:
      - "8081:8081"
      - "8082:8082"
    volumes:
      - artifactory_data:/var/opt/jfrog/artifactory
      - artifactory_logs:/var/opt/jfrog/artifactory/logs
      - artifactory_backup:/var/opt/jfrog/artifactory/backup
      - /opt/artifactory/ssl:/var/opt/jfrog/artifactory/etc/ssl:ro
    environment:
      - JF_SHARED_DATABASE_TYPE=postgresql
      - JF_SHARED_DATABASE_USERNAME=artifactory_prod
      - JF_SHARED_DATABASE_PASSWORD=${DB_PASSWORD}
      - JF_SHARED_DATABASE_URL=jdbc:postgresql://prod-db.company.com:5432/artifactory
      - ENABLE_MIGRATION=y
      - JF_SHARED_EXTRAJAVAOPTS="-Xms8g -Xmx16g -XX:+UseG1GC"
    ulimits:
      nproc: 65535
      nofile:
        soft: 65536
        hard: 65536
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/artifactory/api/system/ping"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  artifactory_data:
    driver: local
  artifactory_logs:
    driver: local
  artifactory_backup:
    driver: local
EOF
```

### **Step 8.2: Monitoring Setup**

#### **Install Monitoring Stack**
```bash
# Create monitoring directory
mkdir -p /opt/monitoring/{prometheus,grafana}

# Create Prometheus configuration
cat > /opt/monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'artifactory'
    static_configs:
      - targets: ['artifactory.company.com:8081']
    metrics_path: '/artifactory/api/v1/metrics'
    basic_auth:
      username: 'jenkins-service'
      password: 'jenkins_secure_password_123'
EOF

# Deploy monitoring stack
cat > /opt/monitoring/docker-compose.yml << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123

volumes:
  prometheus_data:
  grafana_data:
EOF
```

### **Step 8.3: Backup Automation**

#### **Production Backup Script**
```bash
# Create production backup script
cat > /opt/artifactory/scripts/prod-backup.sh << 'EOF'
#!/bin/bash

# Configuration
BACKUP_ROOT="/backup/artifactory"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"
RETENTION_DAYS=30
LOG_FILE="/var/log/artifactory-backup.log"
S3_BUCKET="artifactory-backups-prod"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Starting Artifactory backup process"

# Backup configuration
log "Backing up configuration files"
docker cp artifactory-prod:/var/opt/jfrog/artifactory/etc "$BACKUP_DIR/"

# Backup database
log "Backing up database"
pg_dump -h prod-db.company.com -U artifactory_prod -d artifactory \
    | gzip > "$BACKUP_DIR/database.sql.gz"

# Backup important repositories (skip cache and temp)
log "Backing up critical repositories"
for repo in docker-local-prod generic-local release-local; do
    log "Backing up repository: $repo"
    jf rt download "$repo/*" "$BACKUP_DIR/repositories/$repo/" \
        --server-id=artifactory-server --quiet
done

# Upload to S3 (if configured)
if command -v aws &> /dev/null; then
    log "Uploading backup to S3"
    tar -czf "$BACKUP_DIR.tar.gz" -C "$BACKUP_ROOT" "$DATE"
    aws s3 cp "$BACKUP_DIR.tar.gz" "s3://$S3_BUCKET/"
    rm "$BACKUP_DIR.tar.gz"
fi

# Cleanup old backups
log "Cleaning up old backups"
find "$BACKUP_ROOT" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

log "Backup completed successfully"
EOF

chmod +x /opt/artifactory/scripts/prod-backup.sh
```

#### **Schedule Backups**
```bash
# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/artifactory/scripts/prod-backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 1 * * 0 /opt/artifactory/scripts/full-backup.sh") | crontab -
```

## 📊 Phase 9: Monitoring & Maintenance

### **Step 9.1: Health Monitoring**

#### **Health Check Script**
```bash
# Create comprehensive health check
cat > /opt/artifactory/scripts/health-check.sh << 'EOF'
#!/bin/bash

HEALTH_LOG="/var/log/artifactory-health.log"
ALERT_EMAIL="devops@company.com"

# Function to send alert
send_alert() {
    local message="$1"
    echo "$(date): $message" >> "$HEALTH_LOG"
    # Send email alert (configure mail server)
    echo "$message" | mail -s "Artifactory Health Alert" "$ALERT_EMAIL"
}

# Check Artifactory API
if ! curl -f -s "http://localhost:8081/artifactory/api/system/ping" > /dev/null; then
    send_alert "Artifactory API is not responding"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df /opt/artifactory | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    send_alert "Disk usage is at $DISK_USAGE%"
fi

# Check database connectivity
if ! pg_isready -h localhost -p 5432 -U artifactory; then
    send_alert "Database is not accessible"
    exit 1
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f%%", $3*100/$2}' | sed 's/%//')
if [ "${MEMORY_USAGE%.*}" -gt 90 ]; then
    send_alert "Memory usage is at $MEMORY_USAGE%"
fi

echo "$(date): All health checks passed" >> "$HEALTH_LOG"
EOF

chmod +x /opt/artifactory/scripts/health-check.sh

# Schedule health checks every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/artifactory/scripts/health-check.sh") | crontab -
```

### **Step 9.2: Log Management**

#### **Log Rotation Configuration**
```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/artifactory << 'EOF'
/opt/artifactory/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 artifactory artifactory
    postrotate
        docker-compose -f /opt/artifactory/docker-compose.yml restart artifactory
    endscript
}
EOF
```

### **Step 9.3: Performance Monitoring**

#### **Performance Monitoring Script**
```bash
# Create performance monitoring script
cat > /opt/artifactory/scripts/performance-monitor.sh << 'EOF'
#!/bin/bash

METRICS_LOG="/var/log/artifactory-metrics.log"

# Collect metrics
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
DISK_USAGE=$(df /opt/artifactory | awk 'NR==2 {print $5}' | sed 's/%//')

# API response time
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "http://localhost:8081/artifactory/api/system/ping")

# Storage info
STORAGE_INFO=$(curl -s -u admin:new_password "http://localhost:8081/artifactory/api/storageinfo" | jq -r '.binariesSummary.binariesSize')

# Log metrics
echo "$TIMESTAMP,CPU:$CPU_USAGE,Memory:$MEMORY_USAGE,Disk:$DISK_USAGE,ResponseTime:$RESPONSE_TIME,Storage:$STORAGE_INFO" >> "$METRICS_LOG"

# Send to monitoring system (e.g., Prometheus pushgateway)
if command -v curl &> /dev/null; then
    cat << EOF | curl --data-binary @- http://pushgateway:9091/metrics/job/artifactory
# HELP artifactory_cpu_usage CPU usage percentage
# TYPE artifactory_cpu_usage gauge
artifactory_cpu_usage $CPU_USAGE

# HELP artifactory_memory_usage Memory usage percentage  
# TYPE artifactory_memory_usage gauge
artifactory_memory_usage $MEMORY_USAGE

# HELP artifactory_disk_usage Disk usage percentage
# TYPE artifactory_disk_usage gauge
artifactory_disk_usage $DISK_USAGE

# HELP artifactory_response_time API response time in seconds
# TYPE artifactory_response_time gauge
artifactory_response_time $RESPONSE_TIME
EOF
fi
EOF

chmod +x /opt/artifactory/scripts/performance-monitor.sh

# Schedule performance monitoring every minute
(crontab -l 2>/dev/null; echo "* * * * * /opt/artifactory/scripts/performance-monitor.sh") | crontab -
```

### **Step 9.4: Maintenance Tasks**

#### **Regular Maintenance Script**
```bash
# Create maintenance script
cat > /opt/artifactory/scripts/maintenance.sh << 'EOF'
#!/bin/bash

MAINTENANCE_LOG="/var/log/artifactory-maintenance.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$MAINTENANCE_LOG"
}

log "Starting Artifactory maintenance tasks"

# Cleanup old artifacts (older than 90 days)
log "Cleaning up old artifacts"
jf rt delete "generic-local/" --quiet --recursive \
    --spec='{"files":[{"aql":{"items.find":{"repo":"generic-local","created":{"$before":"90d"}}}}]}' \
    --server-id=artifactory-server

# Cleanup Docker images (keep last 10 versions)
log "Cleaning up old Docker images"
for repo in docker-local-dev docker-local-staging; do
    log "Cleaning repository: $repo"
    # Custom cleanup logic based on your retention policies
done

# Update storage statistics
log "Updating storage statistics"
curl -X POST -u admin:new_password \
    "http://localhost:8081/artifactory/api/system/storage/gc"

# Vacuum database (if PostgreSQL)
log "Performing database maintenance"
psql -h localhost -U artifactory -d artifactory -c "VACUUM ANALYZE;"

# Restart services if needed (e.g., high memory usage)
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}' | cut -d. -f1)
if [ "$MEMORY_USAGE" -gt 95 ]; then
    log "High memory usage detected ($MEMORY_USAGE%), restarting Artifactory"
    docker-compose -f /opt/artifactory/docker-compose.yml restart artifactory
fi

log "Maintenance tasks completed"
EOF

chmod +x /opt/artifactory/scripts/maintenance.sh

# Schedule weekly maintenance on Sundays at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * 0 /opt/artifactory/scripts/maintenance.sh") | crontab -
```

## 🎯 Final Validation Checklist

### **System Validation**
```bash
# Run final validation
echo "=== Artifactory Final Validation ==="

# 1. System Health
echo "1. Checking system health..."
curl -f "http://localhost:8081/artifactory/api/system/ping" && echo "✓ System ping successful"

# 2. Repository Access
echo "2. Checking repository access..."
curl -u jenkins-service:jenkins_secure_password_123 \
    "http://localhost:8081/artifactory/api/repositories" > /dev/null && echo "✓ Repository access successful"

# 3. Docker Registry
echo "3. Testing Docker registry..."
docker pull artifactory.company.com/docker-virtual/hello-world && echo "✓ Docker registry working"

# 4. Artifact Upload/Download
echo "4. Testing artifact operations..."
echo "test" | jf rt upload - generic-local/validation-test.txt --server-id=artifactory-server && \
jf rt download generic-local/validation-test.txt ./temp/ --server-id=artifactory-server && \
echo "✓ Artifact operations working"

# 5. Security
echo "5. Testing security..."
curl -u developer:developer_password_123 \
    "http://localhost:8081/artifactory/api/repositories" > /dev/null && echo "✓ User authentication working"

echo "=== Validation Complete ==="
```

## 📚 Post-Implementation Tasks

### **Documentation**
- [ ] Update network diagrams
- [ ] Create user guides
- [ ] Document operational procedures
- [ ] Create troubleshooting runbook

### **Training**
- [ ] Train DevOps team on administration
- [ ] Train developers on artifact management
- [ ] Create video tutorials
- [ ] Schedule regular training sessions

### **Optimization**
- [ ] Monitor performance metrics
- [ ] Optimize repository structure
- [ ] Tune JVM settings based on usage
- [ ] Implement additional automation

---

**Implementation Complete!** 🎉

Your Artifactory installation is now fully operational with:
- ✅ Complete repository structure
- ✅ Robust security implementation  
- ✅ CI/CD integration
- ✅ Monitoring and alerting
- ✅ Automated backups
- ✅ Maintenance procedures

**Next Steps**: Review the [ADVANCED.md](./ADVANCED.md) guide for additional features and optimizations.

---

**Last Updated**: October 2, 2025  
**Version**: 1.0.0  
**Maintainer**: Implementation Team
