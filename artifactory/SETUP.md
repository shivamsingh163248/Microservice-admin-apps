# 🚀 JFrog Artifactory Setup Guide

## 📋 Table of Contents

1. [Overview](#-overview)
2. [System Requirements](#-system-requirements)
3. [Installation Methods](#-installation-methods)
4. [Initial Configuration](#-initial-configuration)
5. [Repository Setup](#-repository-setup)
6. [Security Configuration](#-security-configuration)
7. [Integration Setup](#-integration-setup)
8. [Verification & Testing](#-verification--testing)
9. [Troubleshooting](#-troubleshooting)

## 🎯 Overview

This guide provides comprehensive instructions for setting up JFrog Artifactory for the Microservice Admin App project. It covers everything from initial installation to complete configuration for enterprise-grade artifact management.

### **Setup Objectives**

- ✅ Complete Artifactory installation and configuration
- ✅ Repository structure for multi-component application
- ✅ Docker registry integration
- ✅ Security and access control setup
- ✅ CI/CD pipeline integration
- ✅ Monitoring and maintenance configuration

## 🖥️ System Requirements

### **Minimum Hardware Requirements**

```yaml
Production Environment:
  CPU: 8 cores (2.4 GHz)
  RAM: 16 GB
  Storage: 500 GB SSD
  Network: 1 Gbps

Development Environment:
  CPU: 4 cores (2.0 GHz)
  RAM: 8 GB
  Storage: 100 GB SSD
  Network: 100 Mbps
```

### **Software Prerequisites**

```bash
# Operating System
- Ubuntu 20.04 LTS or higher
- CentOS 7/8 or RHEL 7/8
- Windows Server 2019 or higher

# Java Requirements
- OpenJDK 11 or higher
- Oracle JDK 11 or higher

# Database (Optional)
- PostgreSQL 12.x or higher
- MySQL 8.0 or higher
- Oracle 12c or higher
```

### **Network Requirements**

```yaml
Ports Required:
  - 8082: Artifactory Web UI (HTTP)
  - 8081: Artifactory API (HTTP)
  - 443: HTTPS (if SSL configured)
  - 22: SSH (for remote management)

Firewall Rules:
  - Allow inbound on ports 8081, 8082
  - Allow outbound HTTP/HTTPS
  - Allow Docker registry access
```

## 🔧 Installation Methods

### **Method 1: Docker Installation (Recommended)**

#### **Step 1: Install Docker**

```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker installation
docker --version
docker-compose --version
```

#### **Step 2: Create Docker Compose Configuration**

```yaml
# docker-compose-artifactory.yml
version: '3.8'

services:
  artifactory:
    image: docker.bintray.io/jfrog/artifactory-oss:latest
    container_name: artifactory
    ports:
      - "8081:8081"
      - "8082:8082"
    volumes:
      - artifactory_data:/var/opt/jfrog/artifactory
      - artifactory_logs:/var/opt/jfrog/artifactory/logs
      - artifactory_backup:/var/opt/jfrog/artifactory/backup
    environment:
      - JF_SHARED_DATABASE_TYPE=postgresql
      - JF_SHARED_DATABASE_USERNAME=artifactory
      - JF_SHARED_DATABASE_PASSWORD=password
      - JF_SHARED_DATABASE_URL=jdbc:postgresql://postgresql:5432/artifactory
    restart: unless-stopped
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000

  postgresql:
    image: postgres:13
    container_name: postgresql
    environment:
      - POSTGRES_DB=artifactory
      - POSTGRES_USER=artifactory
      - POSTGRES_PASSWORD=password
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: artifactory-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - artifactory
    restart: unless-stopped

volumes:
  artifactory_data:
  artifactory_logs:
  artifactory_backup:
  postgresql_data:

networks:
  default:
    driver: bridge
```

#### **Step 3: Deploy Artifactory**

```bash
# Create deployment directory
mkdir -p /opt/artifactory
cd /opt/artifactory

# Download and save docker-compose file
wget -O docker-compose.yml https://raw.githubusercontent.com/your-repo/artifactory/main/docker-compose-artifactory.yml

# Start Artifactory
docker-compose up -d

# Verify deployment
docker-compose ps
docker logs artifactory
```

### **Method 2: Helm Installation (Kubernetes)**

#### **Step 1: Add JFrog Helm Repository**

```bash
# Add JFrog Helm repository
helm repo add jfrog https://charts.jfrog.io
helm repo update

# Create namespace
kubectl create namespace artifactory

# Create values file
cat > artifactory-values.yaml << 'EOF'
artifactory:
  image:
    repository: docker.bintray.io/jfrog/artifactory-oss
    tag: latest
  
  service:
    type: LoadBalancer
    
  persistence:
    enabled: true
    size: 500Gi
    storageClass: "fast-ssd"
    
  resources:
    requests:
      memory: "4Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"

postgresql:
  enabled: true
  persistence:
    size: 100Gi
    storageClass: "fast-ssd"

nginx:
  enabled: true
  service:
    type: LoadBalancer
    
ingress:
  enabled: true
  hosts:
    - host: artifactory.company.com
      paths:
        - /
  tls:
    - secretName: artifactory-tls
      hosts:
        - artifactory.company.com
EOF
```

#### **Step 2: Deploy with Helm**

```bash
# Install Artifactory
helm install artifactory jfrog/artifactory \
  --namespace artifactory \
  --values artifactory-values.yaml \
  --wait

# Verify deployment
kubectl get pods -n artifactory
kubectl get services -n artifactory
kubectl get ingress -n artifactory
```

### **Method 3: Binary Installation**

#### **Step 1: Download and Extract**

```bash
# Create artifactory user
sudo useradd -r -m -s /bin/bash artifactory

# Download Artifactory
cd /opt
sudo wget https://releases.jfrog.io/artifactory/artifactory-oss/org/artifactory/oss/jfrog-artifactory-oss/[RELEASE]/jfrog-artifactory-oss-[RELEASE]-linux.tar.gz

# Extract
sudo tar -xzf jfrog-artifactory-oss-*-linux.tar.gz
sudo mv artifactory-oss-* artifactory
sudo chown -R artifactory:artifactory /opt/artifactory
```

#### **Step 2: Configure Service**

```bash
# Create systemd service file
sudo cat > /etc/systemd/system/artifactory.service << 'EOF'
[Unit]
Description=JFrog Artifactory
After=network.target

[Service]
Type=forking
User=artifactory
Group=artifactory
ExecStart=/opt/artifactory/bin/artifactory.sh start
ExecStop=/opt/artifactory/bin/artifactory.sh stop
ExecReload=/opt/artifactory/bin/artifactory.sh restart
PIDFile=/opt/artifactory/run/artifactory.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable artifactory
sudo systemctl start artifactory
sudo systemctl status artifactory
```

## ⚙️ Initial Configuration

### **Step 1: Access Web Interface**

```bash
# Default URLs
Web UI: http://localhost:8082/ui/
API: http://localhost:8081/artifactory/

# Default Credentials
Username: admin
Password: password
```

### **Step 2: Initial Setup Wizard**

#### **Welcome Screen**
1. Accept the End User License Agreement
2. Set administrator password
3. Configure base URL
4. Set proxy settings (if required)

#### **Create Admin User**
```yaml
Username: admin
Email: admin@company.com
Full Name: Artifactory Administrator
Password: [Strong Password]
```

#### **Configure Base URL**
```yaml
Server Name: artifactory.company.com
HTTP Port: 8081
Context Path: /artifactory
```

### **Step 3: License Configuration**

#### **OSS Version**
- No license required
- Limited to 3 users
- Basic features only

#### **Pro/Enterprise Version**
```bash
# Upload license file through UI
1. Go to Administration > General > Licenses
2. Click "Add License"
3. Upload license file or paste license text
4. Activate license
```

### **Step 4: Database Configuration**

#### **PostgreSQL Setup**
```sql
-- Create database
CREATE DATABASE artifactory;
CREATE USER artifactory WITH PASSWORD 'strong_password';
GRANT ALL PRIVILEGES ON DATABASE artifactory TO artifactory;
```

#### **Update System Configuration**
```yaml
# $ARTIFACTORY_HOME/etc/system.yaml
shared:
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: jdbc:postgresql://localhost:5432/artifactory
    username: artifactory
    password: strong_password
```

## 🗄️ Repository Setup

### **Step 1: Create Repository Structure**

#### **Docker Repositories**
```bash
# Create via REST API
curl -X PUT "http://localhost:8081/artifactory/api/repositories/docker-local" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "local",
    "packageType": "docker",
    "description": "Local Docker repository for microservice images",
    "dockerApiVersion": "V2",
    "maxUniqueSnapshots": 10,
    "dockerTagRetention": 1,
    "dockerMaxUniqueTags": 0
  }'

# Create Docker remote repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/docker-remote" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "remote",
    "packageType": "docker",
    "url": "https://registry-1.docker.io/",
    "dockerApiVersion": "V2",
    "enableTokenAuthentication": true,
    "description": "Docker Hub proxy repository"
  }'

# Create Docker virtual repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/docker-virtual" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "virtual",
    "packageType": "docker",
    "repositories": ["docker-local", "docker-remote"],
    "defaultDeploymentRepo": "docker-local",
    "description": "Virtual Docker repository"
  }'
```

#### **Generic Repositories**
```bash
# Create generic local repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/generic-local" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "local",
    "packageType": "generic",
    "description": "Local generic repository for application artifacts",
    "checksumPolicyType": "client-checksums",
    "handleReleases": true,
    "handleSnapshots": true,
    "maxUniqueSnapshots": 0,
    "snapshotVersionBehavior": "unique",
    "suppressPomConsistencyChecks": false
  }'

# Create release repository
curl -X PUT "http://localhost:8081/artifactory/api/repositories/release-local" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "local",
    "packageType": "generic",
    "description": "Release artifacts repository",
    "checksumPolicyType": "client-checksums",
    "handleReleases": true,
    "handleSnapshots": false
  }'
```

#### **Package Manager Repositories**
```bash
# NPM repositories
curl -X PUT "http://localhost:8081/artifactory/api/repositories/npm-local" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "local",
    "packageType": "npm",
    "description": "Local NPM repository"
  }'

# PyPI repositories  
curl -X PUT "http://localhost:8081/artifactory/api/repositories/pypi-local" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "rclass": "local",
    "packageType": "pypi",
    "description": "Local PyPI repository"
  }'
```

### **Step 2: Repository Configuration**

#### **Retention Policies**
```json
{
  "cronExp": "0 0 2 ? * SUN",
  "durationInMinutes": 60,
  "enabled": true,
  "retentionPolicies": [
    {
      "retentionPolicyType": "countLimit",
      "countLimit": 10,
      "includeReleaseSnapshots": false
    },
    {
      "retentionPolicyType": "lastDownloaded",
      "lastDownloaded": {
        "timeUnit": "day",
        "count": 30
      }
    }
  ]
}
```

## 🔐 Security Configuration

### **Step 1: User Management**

#### **Create Service Accounts**
```bash
# Jenkins service account
curl -X POST "http://localhost:8081/artifactory/api/security/users/jenkins-user" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "name": "jenkins-user",
    "email": "jenkins@company.com",
    "password": "jenkins_password",
    "admin": false,
    "profileUpdatable": false,
    "disableUIAccess": true,
    "internalPasswordDisabled": false,
    "groups": ["jenkins-group"]
  }'

# Docker service account
curl -X POST "http://localhost:8081/artifactory/api/security/users/docker-user" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "name": "docker-user",
    "email": "docker@company.com",
    "password": "docker_password",
    "admin": false,
    "profileUpdatable": false,
    "disableUIAccess": true,
    "internalPasswordDisabled": false,
    "groups": ["docker-group"]
  }'
```

#### **Create Groups and Permissions**
```bash
# Create Jenkins group
curl -X POST "http://localhost:8081/artifactory/api/security/groups/jenkins-group" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "name": "jenkins-group",
    "description": "Jenkins CI/CD group",
    "autoJoin": false,
    "adminPrivileges": false
  }'

# Create permission targets
curl -X POST "http://localhost:8081/artifactory/api/security/permissions/jenkins-permissions" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "name": "jenkins-permissions",
    "repositories": ["docker-local", "generic-local"],
    "principals": {
      "groups": {
        "jenkins-group": ["read", "write", "deploy", "delete"]
      }
    }
  }'
```

### **Step 2: API Key Management**

```bash
# Generate API key for automation
curl -X POST "http://localhost:8081/artifactory/api/security/apiKey" \
  -u admin:password

# Revoke API key
curl -X DELETE "http://localhost:8081/artifactory/api/security/apiKey" \
  -u admin:password
```

### **Step 3: SSL/TLS Configuration**

#### **Generate SSL Certificate**
```bash
# Generate self-signed certificate (for testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout artifactory.key \
  -out artifactory.crt \
  -subj "/C=US/ST=State/L=City/O=Company/CN=artifactory.company.com"

# Copy certificates
sudo cp artifactory.crt /opt/artifactory/etc/ssl/
sudo cp artifactory.key /opt/artifactory/etc/ssl/
sudo chown artifactory:artifactory /opt/artifactory/etc/ssl/*
```

#### **Configure HTTPS**
```yaml
# $ARTIFACTORY_HOME/etc/system.yaml
router:
  entrypoints:
    internalPort: 8082
    internalPortTls: 8443
    externalPort: 80
    externalPortTls: 443
  
  tlsConfig:
    cert: /opt/artifactory/etc/ssl/artifactory.crt
    key: /opt/artifactory/etc/ssl/artifactory.key
```

## 🔗 Integration Setup

### **Step 1: JFrog CLI Configuration**

```bash
# Install JFrog CLI
curl -fL https://getcli.jfrog.io | sh
sudo mv jfrog /usr/local/bin/jf

# Configure server
jf config add artifactory-server \
  --artifactory-url=http://localhost:8081/artifactory \
  --user=admin \
  --password=password \
  --interactive=false

# Test connection
jf rt ping
```

### **Step 2: Docker Registry Setup**

```bash
# Configure Docker daemon
cat > /etc/docker/daemon.json << 'EOF'
{
  "insecure-registries": [
    "localhost:8081",
    "artifactory.company.com"
  ],
  "registry-mirrors": [
    "http://localhost:8081/artifactory/docker-virtual"
  ]
}
EOF

# Restart Docker
sudo systemctl restart docker

# Login to registry
echo "password" | docker login localhost:8081 -u admin --password-stdin
```

### **Step 3: Build Tool Integration**

#### **Maven Configuration**
```xml
<!-- ~/.m2/settings.xml -->
<settings>
  <servers>
    <server>
      <id>artifactory-server</id>
      <username>admin</username>
      <password>password</password>
    </server>
  </servers>
  
  <mirrors>
    <mirror>
      <id>artifactory-mirror</id>
      <mirrorOf>*</mirrorOf>
      <name>Artifactory Mirror</name>
      <url>http://localhost:8081/artifactory/libs-release</url>
    </mirror>
  </mirrors>
  
  <profiles>
    <profile>
      <id>artifactory</id>
      <repositories>
        <repository>
          <id>artifactory-server</id>
          <url>http://localhost:8081/artifactory/libs-release</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>artifactory</activeProfile>
  </activeProfiles>
</settings>
```

#### **NPM Configuration**
```bash
# Set registry
npm config set registry http://localhost:8081/artifactory/api/npm/npm-virtual/

# Set authentication
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:_password $(echo -n "password" | base64)
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:username admin
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:email admin@company.com
npm config set //localhost:8081/artifactory/api/npm/npm-virtual/:always-auth true
```

### **Step 4: Jenkins Integration**

#### **Install Jenkins Plugins**
```bash
# Required plugins
- Artifactory Plugin
- Docker Pipeline Plugin
- Pipeline Plugin
- Credentials Plugin
- Git Plugin
```

#### **Configure Jenkins Credentials**
```groovy
// Jenkins Pipeline Script
pipeline {
    agent any
    
    environment {
        ARTIFACTORY_SERVER = credentials('artifactory-server')
        DOCKER_REGISTRY = 'localhost:8081'
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    // Configure Artifactory server
                    def server = Artifactory.server 'artifactory-server'
                    def rtDocker = Artifactory.docker server: server
                }
            }
        }
    }
}
```

## ✅ Verification & Testing

### **Step 1: Basic Functionality Tests**

```bash
# Test API access
curl -u admin:password "http://localhost:8081/artifactory/api/system/ping"

# Test repository access
curl -u admin:password "http://localhost:8081/artifactory/api/repositories"

# Test upload
echo "test content" > test.txt
curl -u admin:password -X PUT "http://localhost:8081/artifactory/generic-local/test.txt" -T test.txt

# Test download
curl -u admin:password "http://localhost:8081/artifactory/generic-local/test.txt"
```

### **Step 2: Docker Registry Tests**

```bash
# Pull base image through Artifactory
docker pull localhost:8081/docker-virtual/nginx:latest

# Tag and push test image
docker tag nginx:latest localhost:8081/docker-local/test-nginx:v1.0.0
docker push localhost:8081/docker-local/test-nginx:v1.0.0

# Verify image in repository
curl -u admin:password "http://localhost:8081/artifactory/api/docker/docker-local/v2/_catalog"
```

### **Step 3: Build Integration Tests**

```bash
# Test JFrog CLI
jf rt ping
jf rt upload "*.txt" generic-local/test/
jf rt download generic-local/test/ ./downloads/

# Test search functionality
jf rt search "generic-local/*"
```

## 🐛 Troubleshooting

### **Common Installation Issues**

#### **Permission Denied**
```bash
# Fix file permissions
sudo chown -R artifactory:artifactory /opt/artifactory
sudo chmod -R 755 /opt/artifactory
```

#### **Port Already in Use**
```bash
# Check port usage
sudo netstat -tlnp | grep :8081
sudo lsof -i :8081

# Change ports in system.yaml
router:
  entrypoints:
    internalPort: 8083
```

#### **Database Connection Issues**
```bash
# Test database connection
psql -h localhost -U artifactory -d artifactory

# Check database logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### **Performance Issues**

#### **Memory Configuration**
```bash
# Increase Java heap size
export JAVA_OPTS="-Xms2g -Xmx8g -XX:+UseG1GC"
```

#### **Storage Issues**
```bash
# Check disk space
df -h /opt/artifactory

# Clean up logs
find /opt/artifactory/logs -name "*.log" -mtime +7 -delete
```

### **Security Issues**

#### **Reset Admin Password**
```bash
# Stop Artifactory
sudo systemctl stop artifactory

# Reset password using utility
/opt/artifactory/bin/artifactory.sh -reset-admin-password new_password

# Start Artifactory
sudo systemctl start artifactory
```

### **Network Connectivity Issues**

```bash
# Test connectivity
telnet localhost 8081
curl -v http://localhost:8081/artifactory/api/system/ping

# Check firewall
sudo ufw status
sudo iptables -L
```

## 📋 Post-Installation Checklist

### **Security Hardening**
- [ ] Change default admin password
- [ ] Create service accounts
- [ ] Configure proper permissions
- [ ] Enable HTTPS/SSL
- [ ] Set up API key authentication
- [ ] Configure audit logging

### **Performance Optimization**
- [ ] Configure appropriate JVM settings
- [ ] Set up database optimization
- [ ] Configure storage cleanup policies
- [ ] Monitor resource usage
- [ ] Set up log rotation

### **Backup and Recovery**
- [ ] Configure automated backups
- [ ] Test backup restoration
- [ ] Document recovery procedures
- [ ] Set up monitoring alerts

### **Integration Validation**
- [ ] Test Docker registry functionality
- [ ] Verify CI/CD pipeline integration
- [ ] Test build tool configurations
- [ ] Validate security scanning

## 📚 Next Steps

After completing the setup:

1. **Review Architecture Documentation**: `ARCHITECTURE.md`
2. **Configure Advanced Features**: `CONFIGURATION.md`
3. **Follow Step-by-Step Guide**: `STEP-BY-STEP.md`
4. **Explore Advanced Features**: `ADVANCED.md`

## 📞 Support

For setup issues:
- **Documentation**: Check other .md files in this directory
- **Community**: JFrog Community Forums
- **Support**: enterprise-support@jfrog.com
- **Training**: JFrog University

---

**Last Updated**: October 2, 2025  
**Version**: 1.0.0  
**Maintainer**: DevOps Team
