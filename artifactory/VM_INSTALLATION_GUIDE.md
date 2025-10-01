# 🖥️ Artifactory VM Installation & Configuration Guide

## 📋 Table of Contents

1. [VM Requirements & Setup](#-vm-requirements--setup)
2. [VM Configuration](#-vm-configuration)
3. [Artifactory Installation on VM](#-artifactory-installation-on-vm)
4. [Project Structure Setup](#-project-structure-setup)
5. [Implementation Steps](#-implementation-steps)
6. [Configuration Management](#-configuration-management)
7. [VM Optimization](#-vm-optimization)
8. [Monitoring & Maintenance](#-monitoring--maintenance)
9. [Troubleshooting](#-troubleshooting)
10. [Security Hardening](#-security-hardening)

## 🖥️ VM Requirements & Setup

### **Minimum VM Specifications**

#### **Development Environment**
```yaml
VM Configuration:
  vCPUs: 4 cores
  RAM: 8 GB
  Storage: 
    - OS Disk: 50 GB SSD
    - Data Disk: 200 GB SSD
  Network: 1 Gbps
  OS: Ubuntu 20.04 LTS / CentOS 8

Resource Allocation:
  - Artifactory JVM: 4-6 GB RAM
  - Database: 1-2 GB RAM
  - System: 1-2 GB RAM
  - Storage: 150+ GB for artifacts
```

#### **Production Environment**
```yaml
VM Configuration:
  vCPUs: 8-16 cores
  RAM: 32-64 GB
  Storage:
    - OS Disk: 100 GB SSD
    - Data Disk: 1-2 TB NVMe SSD
    - Backup Disk: 2-4 TB HDD
  Network: 10 Gbps
  OS: Ubuntu 20.04 LTS / RHEL 8

Resource Allocation:
  - Artifactory JVM: 16-32 GB RAM
  - Database: 8-16 GB RAM
  - System: 4-8 GB RAM
  - Storage: 1+ TB for artifacts
```

### **VM Creation Steps**

#### **Step 1: Create VM Instance**

**For VMware vSphere:**
```bash
# VM Creation Checklist
□ Create VM with specified resources
□ Attach additional data disk for storage
□ Configure network with static IP
□ Enable VM tools installation
□ Set appropriate resource reservations
□ Configure backup policies
```

**For AWS EC2:**
```bash
# Launch EC2 instance
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type c5.2xlarge \
  --key-name artifactory-key \
  --security-group-ids sg-artifactory \
  --subnet-id subnet-12345 \
  --block-device-mappings '[
    {
      "DeviceName": "/dev/sda1",
      "Ebs": {
        "VolumeSize": 100,
        "VolumeType": "gp3",
        "Encrypted": true
      }
    },
    {
      "DeviceName": "/dev/sdf", 
      "Ebs": {
        "VolumeSize": 1000,
        "VolumeType": "gp3",
        "Encrypted": true
      }
    }
  ]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=artifactory-prod}]'
```

**For Azure VM:**
```bash
# Create Azure VM
az vm create \
  --resource-group artifactory-rg \
  --name artifactory-vm \
  --image UbuntuLTS \
  --size Standard_D8s_v3 \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --os-disk-size-gb 100 \
  --data-disk-sizes-gb 1000 \
  --public-ip-sku Standard
```

#### **Step 2: Network Configuration**
```bash
# Configure static IP (Ubuntu/Debian)
sudo tee /etc/netplan/01-netcfg.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - company.local
EOF

sudo netplan apply
```

## ⚙️ VM Configuration

### **Step 1: Operating System Setup**

#### **System Update and Package Installation**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    tree \
    rsync

# Install build tools
sudo apt install -y build-essential
```

#### **Configure Hostname and Hosts**
```bash
# Set hostname
sudo hostnamectl set-hostname artifactory.company.local

# Update /etc/hosts
sudo tee -a /etc/hosts << 'EOF'
127.0.0.1 localhost
192.168.1.100 artifactory.company.local artifactory

# Add other infrastructure hosts
192.168.1.101 jenkins.company.local jenkins
192.168.1.102 database.company.local database
EOF
```

### **Step 2: Storage Configuration**

#### **Disk Partitioning and Mounting**
```bash
# Check available disks
lsblk
fdisk -l

# Create partition on data disk (assuming /dev/sdb)
sudo fdisk /dev/sdb << 'EOF'
n
p
1


w
EOF

# Format the partition
sudo mkfs.ext4 /dev/sdb1

# Create mount point
sudo mkdir -p /opt/artifactory

# Mount the disk
sudo mount /dev/sdb1 /opt/artifactory

# Add to fstab for persistent mounting
echo '/dev/sdb1 /opt/artifactory ext4 defaults 0 2' | sudo tee -a /etc/fstab

# Verify mounting
df -h
```

#### **Directory Structure Creation**
```bash
# Create Artifactory directory structure
sudo mkdir -p /opt/artifactory/{
data,
logs,
backup,
config,
scripts,
ssl,
tmp
}

# Create data subdirectories
sudo mkdir -p /opt/artifactory/data/{
filestore,
cache,
etc,
plugins,
metadata
}

# Create logs subdirectories
sudo mkdir -p /opt/artifactory/logs/{
application,
access,
request,
gc
}

# Create backup subdirectories
sudo mkdir -p /opt/artifactory/backup/{
daily,
weekly,
monthly,
configuration
}

# Set proper permissions
sudo useradd -r -m -s /bin/bash artifactory
sudo chown -R artifactory:artifactory /opt/artifactory
sudo chmod -R 755 /opt/artifactory
```

### **Step 3: Java Installation**

#### **Install OpenJDK 11**
```bash
# Install OpenJDK 11
sudo apt install -y openjdk-11-jdk

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' | sudo tee -a /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' | sudo tee -a /etc/environment

# Source environment
source /etc/environment

# Verify Java installation
java -version
javac -version
echo $JAVA_HOME
```

### **Step 4: Database Setup**

#### **PostgreSQL Installation and Configuration**
```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configure PostgreSQL for Artifactory
sudo -u postgres psql << 'EOF'
CREATE DATABASE artifactory;
CREATE USER artifactory WITH PASSWORD 'SecurePassword123!';
GRANT ALL PRIVILEGES ON DATABASE artifactory TO artifactory;
ALTER USER artifactory CREATEDB;
\q
EOF

# Configure PostgreSQL settings
sudo tee /etc/postgresql/12/main/postgresql.conf << 'EOF'
# Basic settings
listen_addresses = 'localhost'
port = 5432
max_connections = 200
shared_buffers = '2GB'
effective_cache_size = '6GB'
work_mem = '64MB'
maintenance_work_mem = '512MB'

# WAL settings
wal_level = replica
checkpoint_completion_target = 0.7
wal_buffers = '16MB'
min_wal_size = '1GB'
max_wal_size = '4GB'

# Query tuning
random_page_cost = 1.1
effective_io_concurrency = 200
default_statistics_target = 100

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
EOF

# Restart PostgreSQL
sudo systemctl restart postgresql

# Test database connection
psql -h localhost -U artifactory -d artifactory -c "SELECT version();"
```

## 📦 Artifactory Installation on VM

### **Step 1: Download and Install Artifactory**

#### **Download Artifactory OSS**
```bash
# Create installation directory
cd /tmp

# Download Artifactory OSS (latest version)
ARTIFACTORY_VERSION="7.71.4"
wget "https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/${ARTIFACTORY_VERSION}/jfrog-artifactory-oss-${ARTIFACTORY_VERSION}-linux.tar.gz"

# Verify download
ls -la jfrog-artifactory-oss-*.tar.gz
```

#### **Extract and Install**
```bash
# Extract Artifactory
sudo tar -xzf jfrog-artifactory-oss-*.tar.gz -C /opt/

# Create symbolic link for easier management
sudo ln -sf /opt/artifactory-oss-* /opt/jfrog-artifactory

# Set ownership
sudo chown -R artifactory:artifactory /opt/jfrog-artifactory
sudo chown -R artifactory:artifactory /opt/artifactory

# Set permissions
sudo chmod +x /opt/jfrog-artifactory/bin/artifactory.sh
```

### **Step 2: System Configuration**

#### **Create System Configuration Files**
```bash
# Create system.yaml
sudo -u artifactory tee /opt/artifactory/data/etc/system.yaml << 'EOF'
configVersion: 1

shared:
  # Security settings
  security:
    joinKey: "REPLACE_WITH_GENERATED_KEY"
    
  # Database configuration  
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: "jdbc:postgresql://localhost:5432/artifactory"
    username: artifactory
    password: "SecurePassword123!"
    maxOpenConnections: 80
    maxIdleConnections: 20
    
  # Node settings
  node:
    id: "artifactory-vm-01"
    name: "artifactory-primary"
    
  # Logging configuration
  logging:
    consoleLog:
      enabled: true
    applicationLog:
      enabled: true
      level: INFO
      
# Router configuration
router:
  entrypoints:
    internalPort: 8082
    externalPort: 80
    internalPortTls: 8443
    externalPortTls: 443
    
# Access configuration
access:
  # Session configuration
  session:
    timeout: 1800  # 30 minutes
EOF

# Generate join key
JOIN_KEY=$(openssl rand -hex 32)
sudo sed -i "s/REPLACE_WITH_GENERATED_KEY/$JOIN_KEY/" /opt/artifactory/data/etc/system.yaml
```

#### **Configure JVM Settings**
```bash
# Create JVM configuration
sudo -u artifactory tee /opt/jfrog-artifactory/bin/artifactory.default << 'EOF'
# JFrog Artifactory JVM Settings

# Java executable
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# JVM Memory settings
export JAVA_OPTIONS="-server \
    -Xms4g \
    -Xmx8g \
    -Xss256k \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:G1HeapRegionSize=16m \
    -XX:G1ReservePercent=25 \
    -XX:InitiatingHeapOccupancyPercent=30 \
    -XX:+UnlockExperimentalVMOptions \
    -Djava.awt.headless=true \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF8 \
    -Dartifactory.home=/opt/artifactory \
    -Dartifactory.logs.dir=/opt/artifactory/logs"

# Artifactory specific settings
export ARTIFACTORY_HOME="/opt/artifactory"
export ARTIFACTORY_DATA="$ARTIFACTORY_HOME/data"
export ARTIFACTORY_LOGS="$ARTIFACTORY_HOME/logs"
export ARTIFACTORY_ETC="$ARTIFACTORY_DATA/etc"

# User settings
export ARTIFACTORY_USER="artifactory"
export ARTIFACTORY_PID="/var/run/artifactory.pid"
EOF
```

### **Step 3: Binary Store Configuration**

#### **Configure Storage Backend**
```bash
# Create binarystore.xml for file system storage
sudo -u artifactory tee /opt/artifactory/data/etc/binarystore.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<config version="v1">
    <chain template="file-system">
        <!-- Primary file system storage -->
        <provider id="file-system" type="file-system">
            <dir>/opt/artifactory/data/filestore</dir>
        </provider>
        
        <!-- Cache provider for performance -->
        <provider id="cache-fs" type="cache-fs">
            <provider>file-system</provider>
            <maxCacheSize>50GB</maxCacheSize>
            <cacheProviderDir>/opt/artifactory/data/cache</cacheProviderDir>
        </provider>
    </chain>
</config>
EOF
```

### **Step 4: Service Configuration**

#### **Create Systemd Service**
```bash
# Create systemd service file
sudo tee /etc/systemd/system/artifactory.service << 'EOF'
[Unit]
Description=JFrog Artifactory
Documentation=https://www.jfrog.com/confluence/display/JFROG/Installing+Artifactory
After=network.target

[Service]
Type=forking
User=artifactory
Group=artifactory
Environment=ARTIFACTORY_HOME=/opt/artifactory
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ExecStart=/opt/jfrog-artifactory/bin/artifactory.sh start
ExecStop=/opt/jfrog-artifactory/bin/artifactory.sh stop
ExecReload=/opt/jfrog-artifactory/bin/artifactory.sh restart
PIDFile=/var/run/artifactory.pid
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable artifactory
```

### **Step 5: Reverse Proxy Setup (Nginx)**

#### **Install and Configure Nginx**
```bash
# Install Nginx
sudo apt install -y nginx

# Create Artifactory configuration
sudo tee /etc/nginx/sites-available/artifactory << 'EOF'
# Artifactory Nginx Configuration

upstream artifactory {
    server 127.0.0.1:8081;
}

upstream artifactory-ui {
    server 127.0.0.1:8082;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name artifactory.company.local _;
    return 301 https://$server_name$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    server_name artifactory.company.local;
    
    # SSL Configuration (update paths as needed)
    ssl_certificate /opt/artifactory/ssl/artifactory.crt;
    ssl_certificate_key /opt/artifactory/ssl/artifactory.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # General settings
    client_max_body_size 1G;
    client_body_buffer_size 128k;
    proxy_connect_timeout 90s;
    proxy_send_timeout 90s;
    proxy_read_timeout 90s;
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Docker API (for Docker registry)
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
    
    # Artifactory UI
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
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/artifactory /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Start and enable Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
```

## 📁 Project Structure Setup

### **Complete Directory Structure**
```bash
# Create comprehensive project structure
sudo -u artifactory mkdir -p /opt/artifactory/{
app/{
  microservice-admin-app/{
    frontend,
    backend,
    database,
    docker-images,
    source-archives,
    test-reports,
    security-reports,
    build-artifacts
  }
},
repositories/{
  docker/{
    local/{
      development,
      staging,
      production
    },
    remote,
    virtual
  },
  generic/{
    local/{
      development,
      staging,
      production,
      releases
    },
    virtual
  },
  npm/{
    local,
    remote,
    virtual
  },
  pypi/{
    local,
    remote,
    virtual
  }
},
scripts/{
  backup,
  maintenance,
  monitoring,
  deployment
},
config/{
  environments/{
    development,
    staging,
    production
  },
  security,
  integration
},
documentation,
tools
}

# Create project-specific directories
sudo -u artifactory mkdir -p /opt/artifactory/app/microservice-admin-app/{
versions,
branches/{
  main,
  develop,
  feature,
  release,
  hotfix
},
environments/{
  dev,
  staging,
  prod
},
components/{
  frontend/{
    nginx,
    static-assets,
    builds
  },
  backend/{
    python-flask,
    dependencies,
    builds
  },
  database/{
    mysql,
    schemas,
    migrations,
    backups
  }
}
}
```

### **Directory Structure Documentation**
```bash
# Create directory structure documentation
sudo -u artifactory tee /opt/artifactory/documentation/DIRECTORY_STRUCTURE.md << 'EOF'
# Artifactory Directory Structure

## Root Structure
```
/opt/artifactory/
├── app/                          # Application-specific artifacts
│   └── microservice-admin-app/   # Main application
│       ├── frontend/             # Frontend artifacts
│       ├── backend/              # Backend artifacts
│       ├── database/             # Database artifacts
│       ├── docker-images/        # Container images
│       ├── source-archives/      # Source code archives
│       ├── test-reports/         # Test results
│       ├── security-reports/     # Security scan results
│       └── build-artifacts/      # Build outputs
├── repositories/                 # Repository configurations
│   ├── docker/                   # Docker repositories
│   ├── generic/                  # Generic repositories
│   ├── npm/                      # NPM repositories
│   └── pypi/                     # Python repositories
├── scripts/                      # Automation scripts
│   ├── backup/                   # Backup scripts
│   ├── maintenance/              # Maintenance scripts
│   ├── monitoring/               # Monitoring scripts
│   └── deployment/               # Deployment scripts
├── config/                       # Configuration files
│   ├── environments/             # Environment configs
│   ├── security/                 # Security configs
│   └── integration/              # Integration configs
├── data/                         # Artifactory data
│   ├── filestore/               # Binary storage
│   ├── cache/                   # Cache storage
│   ├── etc/                     # Configuration
│   └── metadata/                # Metadata storage
├── logs/                        # Log files
│   ├── application/             # Application logs
│   ├── access/                  # Access logs
│   └── gc/                      # GC logs
├── backup/                      # Backup storage
│   ├── daily/                   # Daily backups
│   ├── weekly/                  # Weekly backups
│   └── monthly/                 # Monthly backups
└── ssl/                         # SSL certificates
```

## Repository Layout

### Docker Repositories
- `docker-local-dev`: Development Docker images
- `docker-local-staging`: Staging Docker images  
- `docker-local-prod`: Production Docker images
- `docker-remote`: Docker Hub proxy
- `docker-virtual`: Unified Docker access

### Generic Repositories
- `generic-local-dev`: Development artifacts
- `generic-local-staging`: Staging artifacts
- `generic-local-prod`: Production artifacts
- `release-local`: Release artifacts
- `generic-virtual`: Unified generic access

### Package Repositories
- `npm-local/remote/virtual`: NPM packages
- `pypi-local/remote/virtual`: Python packages

## Artifact Organization

### Naming Conventions
- Docker images: `{component}:{version}-{build}`
- Source archives: `{component}-{version}-{build}.tar.gz`
- Test reports: `test-report-{component}-{build}.xml`
- Security reports: `security-scan-{component}-{build}.json`

### Version Management
- Semantic versioning: `major.minor.patch`
- Build numbers: Incremental integers
- Branch indicators: `feature-`, `release-`, `hotfix-`
EOF
```

## 🛠️ Implementation Steps

### **Step 1: Start Services**
```bash
# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl status postgresql

# Start Artifactory
sudo systemctl start artifactory

# Monitor startup
sudo journalctl -u artifactory -f

# Wait for startup (can take 2-5 minutes)
sleep 300

# Check service status
sudo systemctl status artifactory

# Start Nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

### **Step 2: Initial Configuration**

#### **Access Web Interface**
```bash
# Check if Artifactory is ready
curl -f http://localhost:8081/artifactory/api/system/ping

# If successful, access web UI
echo "Access Artifactory at: http://artifactory.company.local/ui/"
echo "Default credentials: admin / password"
```

#### **Complete Setup Wizard**
```bash
# 1. Accept license agreement
# 2. Set admin password (change from default)
# 3. Configure base URL: http://artifactory.company.local
# 4. Skip proxy configuration (if not needed)
# 5. Complete setup
```

### **Step 3: Repository Creation**

#### **Create Repository Structure Script**
```bash
# Create repository setup script
sudo -u artifactory tee /opt/artifactory/scripts/setup-repositories.sh << 'EOF'
#!/bin/bash

ARTIFACTORY_URL="http://localhost:8081/artifactory"
ADMIN_USER="admin"
ADMIN_PASS="your-new-password"  # Update with actual password

# Function to create repository
create_repository() {
    local repo_config="$1"
    local repo_key=$(echo "$repo_config" | jq -r '.key')
    
    echo "Creating repository: $repo_key"
    
    curl -X PUT "$ARTIFACTORY_URL/api/repositories/$repo_key" \
        -H "Content-Type: application/json" \
        -u "$ADMIN_USER:$ADMIN_PASS" \
        -d "$repo_config"
    
    if [ $? -eq 0 ]; then
        echo "✅ Repository $repo_key created successfully"
    else
        echo "❌ Failed to create repository $repo_key"
    fi
}

# Docker Local Development Repository
create_repository '{
    "key": "docker-local-dev",
    "rclass": "local",
    "packageType": "docker",
    "description": "Docker repository for development images",
    "dockerApiVersion": "V2",
    "maxUniqueSnapshots": 10,
    "dockerTagRetention": 5,
    "dockerMaxUniqueTags": 10
}'

# Docker Local Staging Repository  
create_repository '{
    "key": "docker-local-staging",
    "rclass": "local", 
    "packageType": "docker",
    "description": "Docker repository for staging images",
    "dockerApiVersion": "V2",
    "maxUniqueSnapshots": 5,
    "dockerTagRetention": 10,
    "dockerMaxUniqueTags": 20
}'

# Docker Local Production Repository
create_repository '{
    "key": "docker-local-prod",
    "rclass": "local",
    "packageType": "docker", 
    "description": "Docker repository for production images",
    "dockerApiVersion": "V2",
    "maxUniqueSnapshots": 3,
    "dockerTagRetention": 50,
    "dockerMaxUniqueTags": 100
}'

# Docker Remote Repository (Docker Hub)
create_repository '{
    "key": "docker-remote",
    "rclass": "remote",
    "packageType": "docker",
    "url": "https://registry-1.docker.io/",
    "description": "Docker Hub proxy repository",
    "dockerApiVersion": "V2",
    "enableTokenAuthentication": true
}'

# Docker Virtual Repository
create_repository '{
    "key": "docker-virtual", 
    "rclass": "virtual",
    "packageType": "docker",
    "description": "Virtual Docker repository",
    "repositories": ["docker-local-dev", "docker-local-staging", "docker-local-prod", "docker-remote"],
    "defaultDeploymentRepo": "docker-local-dev",
    "dockerApiVersion": "V2"
}'

# Generic Local Development Repository
create_repository '{
    "key": "generic-local-dev",
    "rclass": "local",
    "packageType": "generic",
    "description": "Generic repository for development artifacts",
    "checksumPolicyType": "client-checksums"
}'

# Generic Local Staging Repository
create_repository '{
    "key": "generic-local-staging", 
    "rclass": "local",
    "packageType": "generic",
    "description": "Generic repository for staging artifacts",
    "checksumPolicyType": "client-checksums"
}'

# Generic Local Production Repository  
create_repository '{
    "key": "generic-local-prod",
    "rclass": "local",
    "packageType": "generic",
    "description": "Generic repository for production artifacts", 
    "checksumPolicyType": "client-checksums"
}'

# Release Repository
create_repository '{
    "key": "release-local",
    "rclass": "local",
    "packageType": "generic",
    "description": "Repository for released artifacts",
    "checksumPolicyType": "client-checksums"
}'

# NPM Repositories
create_repository '{
    "key": "npm-local",
    "rclass": "local", 
    "packageType": "npm",
    "description": "Local NPM repository"
}'

create_repository '{
    "key": "npm-remote",
    "rclass": "remote",
    "packageType": "npm", 
    "url": "https://registry.npmjs.org/",
    "description": "NPM registry proxy"
}'

create_repository '{
    "key": "npm-virtual",
    "rclass": "virtual",
    "packageType": "npm",
    "description": "Virtual NPM repository", 
    "repositories": ["npm-local", "npm-remote"],
    "defaultDeploymentRepo": "npm-local"
}'

# PyPI Repositories
create_repository '{
    "key": "pypi-local",
    "rclass": "local",
    "packageType": "pypi",
    "description": "Local PyPI repository"
}'

create_repository '{
    "key": "pypi-remote", 
    "rclass": "remote",
    "packageType": "pypi",
    "url": "https://pypi.org/",
    "description": "PyPI proxy repository"
}'

create_repository '{
    "key": "pypi-virtual",
    "rclass": "virtual", 
    "packageType": "pypi",
    "description": "Virtual PyPI repository",
    "repositories": ["pypi-local", "pypi-remote"],
    "defaultDeploymentRepo": "pypi-local"
}'

echo "Repository creation completed!"
EOF

# Make script executable
sudo chmod +x /opt/artifactory/scripts/setup-repositories.sh
```

### **Step 4: Security Configuration**

#### **Create Users and Groups**
```bash
# Create security setup script
sudo -u artifactory tee /opt/artifactory/scripts/setup-security.sh << 'EOF'
#!/bin/bash

ARTIFACTORY_URL="http://localhost:8081/artifactory"
ADMIN_USER="admin"
ADMIN_PASS="your-new-password"

# Create DevOps user
curl -X POST "$ARTIFACTORY_URL/api/security/users/devops-user" \
    -H "Content-Type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d '{
        "name": "devops-user",
        "email": "devops@company.local",
        "password": "DevOpsSecure123!",
        "admin": false,
        "profileUpdatable": true,
        "disableUIAccess": false,
        "groups": ["devops-team"]
    }'

# Create Jenkins service user
curl -X POST "$ARTIFACTORY_URL/api/security/users/jenkins-service" \
    -H "Content-Type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d '{
        "name": "jenkins-service", 
        "email": "jenkins@company.local",
        "password": "JenkinsSecure123!",
        "admin": false,
        "profileUpdatable": false,
        "disableUIAccess": true,
        "groups": ["ci-cd-users"]
    }'

# Create developer user
curl -X POST "$ARTIFACTORY_URL/api/security/users/developer" \
    -H "Content-Type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d '{
        "name": "developer",
        "email": "developer@company.local", 
        "password": "DeveloperSecure123!",
        "admin": false,
        "profileUpdatable": true,
        "disableUIAccess": false,
        "groups": ["developers"]
    }'

# Create groups
curl -X POST "$ARTIFACTORY_URL/api/security/groups/devops-team" \
    -H "Content-Type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d '{
        "name": "devops-team",
        "description": "DevOps team with deployment permissions",
        "autoJoin": false,
        "adminPrivileges": false
    }'

curl -X POST "$ARTIFACTORY_URL/api/security/groups/ci-cd-users" \
    -H "Content-Type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d '{
        "name": "ci-cd-users",
        "description": "CI/CD automation users",
        "autoJoin": false,
        "adminPrivileges": false
    }'

curl -X POST "$ARTIFACTORY_URL/api/security/groups/developers" \
    -H "Content-Type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d '{
        "name": "developers", 
        "description": "Development team with read access",
        "autoJoin": false,
        "adminPrivileges": false
    }'

echo "Security configuration completed!"
EOF

# Make script executable
sudo chmod +x /opt/artifactory/scripts/setup-security.sh
```

### **Step 5: Integration Setup**

#### **Install JFrog CLI**
```bash
# Download and install JFrog CLI
curl -fL https://getcli.jfrog.io | sh
sudo mv jfrog /usr/local/bin/jf

# Verify installation
jf --version

# Configure JFrog CLI
jf config add artifactory-vm \
    --artifactory-url=http://localhost:8081/artifactory \
    --user=jenkins-service \
    --password=JenkinsSecure123! \
    --interactive=false

# Test connection
jf rt ping --server-id=artifactory-vm
```

#### **Configure Docker Registry**
```bash
# Configure Docker to use Artifactory registry
sudo tee /etc/docker/daemon.json << 'EOF'
{
    "insecure-registries": [
        "artifactory.company.local",
        "localhost:8081"
    ],
    "registry-mirrors": [
        "http://artifactory.company.local/artifactory/docker-virtual"
    ]
}
EOF

# Restart Docker
sudo systemctl restart docker

# Login to Artifactory Docker registry
echo "JenkinsSecure123!" | docker login artifactory.company.local -u jenkins-service --password-stdin
```

## ⚡ VM Optimization

### **Step 1: Performance Tuning**

#### **System Optimization**
```bash
# Create system optimization script
sudo tee /opt/artifactory/scripts/optimize-system.sh << 'EOF'
#!/bin/bash

# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "artifactory soft nofile 65536" >> /etc/security/limits.conf
echo "artifactory hard nofile 65536" >> /etc/security/limits.conf

# Optimize kernel parameters
tee -a /etc/sysctl.conf << 'SYSCTL'
# Network optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_window_scaling = 1
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# File system optimization
fs.file-max = 2097152
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
SYSCTL

# Apply sysctl settings
sysctl -p

# Optimize disk I/O scheduler
echo 'ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="deadline"' > /etc/udev/rules.d/60-scheduler.rules

echo "System optimization completed!"
EOF

sudo chmod +x /opt/artifactory/scripts/optimize-system.sh
sudo /opt/artifactory/scripts/optimize-system.sh
```

#### **JVM Optimization for VM**
```bash
# Update JVM settings for VM environment
sudo -u artifactory tee /opt/jfrog-artifactory/bin/artifactory.default << 'EOF'
# JFrog Artifactory JVM Settings - VM Optimized

export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# VM-optimized JVM settings
export JAVA_OPTIONS="-server \
    -Xms6g \
    -Xmx12g \
    -Xss256k \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=100 \
    -XX:G1HeapRegionSize=32m \
    -XX:G1ReservePercent=20 \
    -XX:InitiatingHeapOccupancyPercent=25 \
    -XX:G1MixedGCCountTarget=8 \
    -XX:G1OldCSetRegionThreshold=10 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+UseStringDeduplication \
    -XX:+OptimizeStringConcat \
    -Djava.awt.headless=true \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF8 \
    -Dartifactory.home=/opt/artifactory \
    -Dartifactory.logs.dir=/opt/artifactory/logs \
    -Dartifactory.async.corePoolSize=16 \
    -Dartifactory.async.maxPoolSize=64"

# GC Logging
export JAVA_OPTIONS="$JAVA_OPTIONS \
    -Xloggc:/opt/artifactory/logs/gc/gc.log \
    -XX:+PrintGC \
    -XX:+PrintGCDetails \
    -XX:+PrintGCTimeStamps \
    -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=5 \
    -XX:GCLogFileSize=10M"

# Artifactory paths
export ARTIFACTORY_HOME="/opt/artifactory"
export ARTIFACTORY_DATA="$ARTIFACTORY_HOME/data"
export ARTIFACTORY_LOGS="$ARTIFACTORY_HOME/logs"
export ARTIFACTORY_USER="artifactory"
export ARTIFACTORY_PID="/var/run/artifactory.pid"
EOF
```

### **Step 2: Backup Configuration**

#### **Create Backup Scripts**
```bash
# Create backup script
sudo -u artifactory tee /opt/artifactory/scripts/backup/daily-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/artifactory/backup/daily/$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS=7

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting daily backup: $BACKUP_DIR"

# Backup configuration
echo "Backing up configuration..."
cp -r /opt/artifactory/data/etc "$BACKUP_DIR/"

# Backup database
echo "Backing up database..."
pg_dump -h localhost -U artifactory -d artifactory | gzip > "$BACKUP_DIR/database.sql.gz"

# Backup critical repositories (development artifacts only)
echo "Backing up development artifacts..."
jf rt download "generic-local-dev/*" "$BACKUP_DIR/artifacts/" \
    --flat=false \
    --server-id=artifactory-vm

# Create backup manifest
cat > "$BACKUP_DIR/manifest.txt" << MANIFEST
Backup Date: $(date)
Backup Type: Daily
Configuration: Included
Database: Included  
Artifacts: Development only
Retention: $RETENTION_DAYS days
MANIFEST

# Cleanup old backups
find /opt/artifactory/backup/daily -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "Daily backup completed: $BACKUP_DIR"
EOF

# Create weekly backup script  
sudo -u artifactory tee /opt/artifactory/scripts/backup/weekly-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/artifactory/backup/weekly/$(date +%Y%m%d_%H%M%S)"
RETENTION_WEEKS=4

mkdir -p "$BACKUP_DIR"

echo "Starting weekly backup: $BACKUP_DIR"

# Full backup including all repositories
echo "Backing up all artifacts..."
jf rt download "*-local-*/*" "$BACKUP_DIR/artifacts/" \
    --flat=false \
    --server-id=artifactory-vm

# Backup system state
systemctl status artifactory > "$BACKUP_DIR/service-status.txt"
df -h > "$BACKUP_DIR/disk-usage.txt"

# Cleanup old backups  
find /opt/artifactory/backup/weekly -type d -mtime +$((RETENTION_WEEKS * 7)) -exec rm -rf {} \;

echo "Weekly backup completed: $BACKUP_DIR"
EOF

# Make scripts executable
sudo chmod +x /opt/artifactory/scripts/backup/*.sh

# Schedule backups with cron
(crontab -u artifactory -l 2>/dev/null; echo "0 2 * * * /opt/artifactory/scripts/backup/daily-backup.sh") | sudo crontab -u artifactory -
(crontab -u artifactory -l 2>/dev/null; echo "0 1 * * 0 /opt/artifactory/scripts/backup/weekly-backup.sh") | sudo crontab -u artifactory -
```

## 📊 Monitoring & Maintenance

### **System Monitoring Setup**
```bash
# Create monitoring script
sudo -u artifactory tee /opt/artifactory/scripts/monitoring/health-check.sh << 'EOF'
#!/bin/bash

LOG_FILE="/opt/artifactory/logs/health-check.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check Artifactory API
if curl -f -s http://localhost:8081/artifactory/api/system/ping > /dev/null; then
    log_message "✅ Artifactory API is healthy"
else
    log_message "❌ Artifactory API is not responding"
fi

# Check disk space
DISK_USAGE=$(df /opt/artifactory | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    log_message "✅ Disk usage is acceptable: ${DISK_USAGE}%"
else
    log_message "⚠️  Disk usage is high: ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}' | cut -d. -f1)
if [ "$MEMORY_USAGE" -lt 85 ]; then
    log_message "✅ Memory usage is acceptable: ${MEMORY_USAGE}%"
else
    log_message "⚠️  Memory usage is high: ${MEMORY_USAGE}%"
fi

# Check database connectivity
if pg_isready -h localhost -p 5432 -U artifactory >/dev/null 2>&1; then
    log_message "✅ Database is accessible"
else
    log_message "❌ Database is not accessible"
fi

# Check service status
if systemctl is-active artifactory >/dev/null 2>&1; then
    log_message "✅ Artifactory service is running"
else
    log_message "❌ Artifactory service is not running"
fi
EOF

sudo chmod +x /opt/artifactory/scripts/monitoring/health-check.sh

# Schedule health checks every 5 minutes
(crontab -u artifactory -l 2>/dev/null; echo "*/5 * * * * /opt/artifactory/scripts/monitoring/health-check.sh") | sudo crontab -u artifactory -
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Service Won't Start**
```bash
# Check service status
sudo systemctl status artifactory

# Check logs
sudo journalctl -u artifactory -n 50

# Check Java process
ps aux | grep artifactory

# Check port availability
sudo netstat -tulpn | grep :8081
sudo netstat -tulpn | grep :8082

# Check disk space
df -h /opt/artifactory

# Check permissions
ls -la /opt/artifactory/
sudo -u artifactory ls -la /opt/artifactory/data/
```

#### **Database Connection Issues**
```bash
# Test database connection
psql -h localhost -U artifactory -d artifactory -c "SELECT version();"

# Check PostgreSQL service
sudo systemctl status postgresql

# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log

# Reset database password
sudo -u postgres psql << 'EOF'
ALTER USER artifactory WITH PASSWORD 'NewSecurePassword123!';
\q
EOF
```

#### **Performance Issues**
```bash
# Check system resources
htop
iotop
free -h
df -h

# Check JVM garbage collection
tail -f /opt/artifactory/logs/gc/gc.log

# Check Artifactory logs
tail -f /opt/artifactory/logs/artifactory.log

# Check network connectivity
ping 8.8.8.8
curl -I http://localhost:8081/artifactory/api/system/ping
```

## 🔐 Security Hardening

### **VM Security Configuration**
```bash
# Create security hardening script
sudo tee /opt/artifactory/scripts/security-hardening.sh << 'EOF'
#!/bin/bash

echo "Applying security hardening..."

# Disable unnecessary services
systemctl disable avahi-daemon
systemctl disable cups
systemctl disable bluetooth

# Configure firewall
ufw --force enable
ufw default deny incoming
ufw default allow outgoing

# Allow necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8081/tcp  # Artifactory API
ufw allow 8082/tcp  # Artifactory UI

# SSH hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh

# Set up fail2ban
apt install -y fail2ban

# Create fail2ban configuration for Artifactory
tee /etc/fail2ban/jail.d/artifactory.conf << 'F2B'
[artifactory]
enabled = true
port = 8081,8082
filter = artifactory
logpath = /opt/artifactory/logs/access.log
maxretry = 5
bantime = 3600
F2B

# Create Artifactory fail2ban filter
tee /etc/fail2ban/filter.d/artifactory.conf << 'FILTER'
[Definition]
failregex = ^.*\|<HOST>\|.*\|.*\|.*\|401\|.*$
ignoreregex =
FILTER

# Restart fail2ban
systemctl restart fail2ban

# Setup automatic updates for security patches
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

echo "Security hardening completed!"
EOF

sudo chmod +x /opt/artifactory/scripts/security-hardening.sh
sudo /opt/artifactory/scripts/security-hardening.sh
```

### **SSL Certificate Setup**
```bash
# Generate self-signed certificate for development
sudo -u artifactory tee /opt/artifactory/scripts/generate-ssl.sh << 'EOF'
#!/bin/bash

SSL_DIR="/opt/artifactory/ssl"
mkdir -p "$SSL_DIR"

# Generate private key
openssl genrsa -out "$SSL_DIR/artifactory.key" 2048

# Generate certificate signing request
openssl req -new -key "$SSL_DIR/artifactory.key" \
    -out "$SSL_DIR/artifactory.csr" \
    -subj "/C=US/ST=State/L=City/O=Company/CN=artifactory.company.local"

# Generate self-signed certificate
openssl x509 -req -days 365 \
    -in "$SSL_DIR/artifactory.csr" \
    -signkey "$SSL_DIR/artifactory.key" \
    -out "$SSL_DIR/artifactory.crt"

# Set permissions
chmod 600 "$SSL_DIR/artifactory.key"
chmod 644 "$SSL_DIR/artifactory.crt"

echo "SSL certificate generated at $SSL_DIR"
EOF

sudo chmod +x /opt/artifactory/scripts/generate-ssl.sh
sudo -u artifactory /opt/artifactory/scripts/generate-ssl.sh
```

## ✅ Final Validation

### **Complete System Validation**
```bash
# Create validation script
sudo -u artifactory tee /opt/artifactory/scripts/validate-installation.sh << 'EOF'
#!/bin/bash

echo "=== Artifactory VM Installation Validation ==="

# 1. Service Status
echo "1. Checking service status..."
if systemctl is-active artifactory >/dev/null 2>&1; then
    echo "✅ Artifactory service is running"
else
    echo "❌ Artifactory service is not running"
fi

if systemctl is-active nginx >/dev/null 2>&1; then
    echo "✅ Nginx service is running"
else
    echo "❌ Nginx service is not running"  
fi

if systemctl is-active postgresql >/dev/null 2>&1; then
    echo "✅ PostgreSQL service is running"
else
    echo "❌ PostgreSQL service is not running"
fi

# 2. API Access
echo -e "\n2. Checking API access..."
if curl -f -s http://localhost:8081/artifactory/api/system/ping > /dev/null; then
    echo "✅ Artifactory API is accessible"
else
    echo "❌ Artifactory API is not accessible"
fi

# 3. Web UI Access
echo -e "\n3. Checking Web UI access..."  
if curl -f -s http://localhost:8082/ui/ > /dev/null; then
    echo "✅ Artifactory UI is accessible"
else
    echo "❌ Artifactory UI is not accessible"
fi

# 4. Repository Count
echo -e "\n4. Checking repositories..."
REPO_COUNT=$(curl -s -u admin:your-password http://localhost:8081/artifactory/api/repositories 2>/dev/null | jq '. | length' 2>/dev/null)
if [ "$REPO_COUNT" -gt 0 ] 2>/dev/null; then
    echo "✅ Repositories configured: $REPO_COUNT"
else
    echo "⚠️  No repositories found or authentication failed"
fi

# 5. Disk Space
echo -e "\n5. Checking disk space..."
DISK_USAGE=$(df /opt/artifactory | awk 'NR==2 {print $5}' | sed 's/%//')
echo "📊 Disk usage: ${DISK_USAGE}%"

# 6. Memory Usage  
echo -e "\n6. Checking memory usage..."
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
echo "📊 Memory usage: ${MEMORY_USAGE}%"

# 7. Network Connectivity
echo -e "\n7. Checking network..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ External network connectivity"
else
    echo "❌ No external network connectivity"
fi

echo -e "\n=== Validation Complete ==="
echo "For detailed logs, check: /opt/artifactory/logs/"
echo "Web UI: http://artifactory.company.local/ui/"
echo "API: http://artifactory.company.local/artifactory/"
EOF

sudo chmod +x /opt/artifactory/scripts/validate-installation.sh

# Run validation
sudo -u artifactory /opt/artifactory/scripts/validate-installation.sh
```

---

## 📋 Post-Installation Checklist

### **Immediate Tasks**
- [ ] Change default admin password
- [ ] Create service users (jenkins-service, devops-user)
- [ ] Configure repository structure
- [ ] Set up SSL certificates
- [ ] Configure firewall rules
- [ ] Test API and UI access
- [ ] Configure backup automation
- [ ] Set up monitoring scripts

### **Integration Tasks**
- [ ] Install and configure JFrog CLI
- [ ] Configure Docker registry integration
- [ ] Set up Jenkins integration
- [ ] Configure build tool integration (npm, pip)
- [ ] Test artifact upload/download
- [ ] Configure CI/CD pipeline integration

### **Maintenance Tasks**
- [ ] Schedule regular backups
- [ ] Set up log rotation
- [ ] Configure system monitoring
- [ ] Plan capacity monitoring
- [ ] Document access procedures
- [ ] Train team members

---

**🎉 Installation Complete!**

Your Artifactory VM is now fully configured and ready for use with the Microservice Admin App project. The installation includes:

- ✅ **Complete VM setup** with optimized performance
- ✅ **Full Artifactory installation** with PostgreSQL database
- ✅ **Comprehensive repository structure** for all artifact types
- ✅ **Security configuration** with users, groups, and permissions
- ✅ **Integration setup** with Docker registry and build tools
- ✅ **Automated backup and monitoring** systems
- ✅ **Production-ready configuration** with SSL and security hardening

**Next Steps**: Begin uploading artifacts and integrating with your CI/CD pipeline!

---

**Last Updated**: October 2, 2025  
**Version**: 1.0.0  
**Maintainer**: VM Infrastructure Team
