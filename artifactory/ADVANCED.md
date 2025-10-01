# 🚀 JFrog Artifactory Advanced Features Guide

## 📋 Table of Contents

1. [Advanced Repository Management](#-advanced-repository-management)
2. [Enterprise Security Features](#-enterprise-security-features)
3. [High Availability & Clustering](#-high-availability--clustering)
4. [Performance Optimization](#-performance-optimization)
5. [Advanced Integrations](#-advanced-integrations)
6. [Automation & Scripting](#-automation--scripting)
7. [Multi-Site Replication](#-multi-site-replication)
8. [Advanced Monitoring](#-advanced-monitoring)
9. [Disaster Recovery](#-disaster-recovery)
10. [Cloud-Native Features](#-cloud-native-features)

## 🗄️ Advanced Repository Management

### **Smart Repository Layouts**

#### **Custom Repository Layouts**
```json
{
  "name": "microservice-maven-layout",
  "artifactPathPattern": "[orgPath]/[module]/[baseRev](-[folderItegRev])/[module]-[baseRev](-[fileItegRev])(-[classifier]).[ext]",
  "distinctiveDescriptorPathPattern": true,
  "descriptorPathPattern": "[orgPath]/[module]/[baseRev](-[folderItegRev])/[module]-[baseRev](-[fileItegRev])(-[classifier]).pom",
  "folderIntegrationRevisionRegExp": "SNAPSHOT",
  "fileIntegrationRevisionRegExp": "SNAPSHOT|(?:(?:[0-9]{8}.[0-9]{6})-(?:[0-9]+))"
}
```

#### **Repository Promotion Rules**
```bash
# Advanced promotion with quality gates
curl -X POST "${ARTIFACTORY_URL}/api/build/promote/microservice-admin-app/${BUILD_NUMBER}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "status": "Released",
    "comment": "Promoted after successful integration tests",
    "ciUser": "jenkins-service",
    "timestamp": "'$(date -Iseconds)'",
    "dryRun": false,
    "targetRepo": "release-local",
    "sourceRepo": "generic-local-staging",
    "copy": true,
    "artifacts": true,
    "dependencies": false,
    "scopes": ["compile", "runtime"],
    "properties": {
      "promotion.status": "released",
      "promotion.timestamp": "'$(date -Iseconds)'",
      "quality.gate": "passed"
    },
    "failFast": true
  }'
```

### **Repository Replication**

#### **Multi-Push Replication**
```yaml
# Replication configuration
replications:
  - replicationKey: "prod-to-dr-replication"
    cronExp: "0 */6 * * *"  # Every 6 hours
    enableEventReplication: true
    enabled: true
    pathPrefix: ""
    repoKey: "docker-local-prod"
    serverId: "dr-site-artifactory"
    syncDeletes: true
    syncProperties: true
    syncStatistics: false
    url: "https://dr-artifactory.company.com/artifactory/docker-local-prod"
    username: "replication-user"
    password: "replication-password"
    socketTimeoutMillis: 15000
    includePathPrefixPattern: "**"
    excludePathPrefixPattern: "temp/**,cache/**"
```

#### **Pull Replication Setup**
```bash
# Configure pull replication from central site
curl -X POST "${ARTIFACTORY_URL}/api/replications/docker-local" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "replicationKey": "central-pull-replication",
    "cronExp": "0 2 * * *",
    "enableEventReplication": false,
    "enabled": true,
    "pathPrefix": "",
    "repoKey": "docker-local",
    "url": "https://central-artifactory.company.com/artifactory/docker-local",
    "username": "central-replication-user",
    "password": "central-replication-password",
    "socketTimeoutMillis": 30000,
    "syncDeletes": false,
    "syncProperties": true
  }'
```

### **Advanced Repository Policies**

#### **Cleanup Policies with AQL**
```json
{
  "name": "advanced-cleanup-policy",
  "description": "Advanced cleanup based on multiple criteria",
  "repositories": ["docker-local-dev", "generic-local"],
  "retentionPolicies": [
    {
      "retentionPolicyType": "aql",
      "aql": "items.find({\"repo\":{\"$match\":\"docker-local-dev\"},\"name\":{\"$nmatch\":\"*latest*\"},\"created\":{\"$before\":\"30d\"},\"stat.downloaded\":{\"$before\":\"7d\"}})",
      "dryRun": false
    }
  ],
  "cronExp": "0 3 * * 0"
}
```

#### **Property-Based Management**
```bash
# Set advanced properties on artifacts
curl -X PUT "${ARTIFACTORY_URL}/api/storage/docker-local/nginx/1.21/manifest.json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d "properties=security.scan.status=passed;quality.gate=green;deployment.env=production;retention.policy=long-term"

# Search by properties
curl -X POST "${ARTIFACTORY_URL}/api/search/aql" \
  -H "Content-Type: text/plain" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d 'items.find({
    "repo": "docker-local",
    "@security.scan.status": "passed",
    "@quality.gate": "green"
  }).include("name", "path", "property")'
```

## 🔐 Enterprise Security Features

### **Advanced Authentication**

#### **SAML SSO Configuration**
```yaml
# SAML configuration in system.yaml
access:
  security:
    saml:
      enabled: true
      loginUrl: "https://sso.company.com/saml/login"
      logoutUrl: "https://sso.company.com/saml/logout"
      serviceProviderName: "Artifactory"
      certificate: |
        -----BEGIN CERTIFICATE-----
        MIIDXTCCAkWgAwIBAgIJAKoK/OvvumdSMA0GCSqGSIb3DQEBCwUAMEUx...
        -----END CERTIFICATE-----
      noAutoUserCreation: false
      allowUserToAccessProfile: true
      autoRedirect: true
      syncGroups: true
      groupAttribute: "groups"
      emailAttribute: "email"
      userDisplayNameAttribute: "displayName"
```

#### **OAuth Integration**
```bash
# Configure OAuth provider
curl -X PUT "${ARTIFACTORY_URL}/api/security/oauth/settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "enableIntegration": true,
    "persistUsers": true,
    "providers": [
      {
        "name": "github-oauth",
        "type": "github",
        "enabled": true,
        "clientId": "${GITHUB_CLIENT_ID}",
        "clientSecret": "${GITHUB_CLIENT_SECRET}",
        "apiUrl": "https://api.github.com",
        "authUrl": "https://github.com/login/oauth/authorize",
        "tokenUrl": "https://github.com/login/oauth/access_token",
        "basicUrl": "https://github.com",
        "domain": "company.com"
      }
    ]
  }'
```

### **Advanced Access Control**

#### **Path-Based Permissions**
```bash
# Create granular path-based permissions
curl -X POST "${ARTIFACTORY_URL}/api/v2/security/permissions/path-based-permissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "path-based-permissions",
    "repo": {
      "include-patterns": [
        "production/**",
        "release/**"
      ],
      "exclude-patterns": [
        "**/*-SNAPSHOT*",
        "**/temp/**"
      ],
      "repositories": ["docker-local", "generic-local"],
      "actions": {
        "groups": {
          "production-deployers": ["read", "write", "deploy"],
          "developers": ["read"]
        },
        "users": {
          "release-manager": ["read", "write", "deploy", "delete", "manage"]
        }
      }
    }
  }'
```

#### **Time-Based Access Control**
```bash
# Configure time-based access restrictions
curl -X POST "${ARTIFACTORY_URL}/api/security/permissions/time-based-access" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "time-based-access",
    "description": "Restrict production deployments to business hours",
    "repo": {
      "repositories": ["docker-local-prod", "release-local"],
      "include-patterns": ["**"],
      "actions": {
        "groups": {
          "production-deployers": ["read", "write", "deploy"]
        }
      }
    },
    "schedule": {
      "timezone": "America/New_York",
      "allowedTimes": [
        {
          "dayOfWeek": ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"],
          "startTime": "09:00",
          "endTime": "17:00"
        }
      ]
    }
  }'
```

### **Advanced Security Scanning**

#### **Xray Policy Configuration**
```json
{
  "name": "microservice-security-policy",
  "type": "security",
  "description": "Comprehensive security policy for microservices",
  "rules": [
    {
      "name": "critical-vulnerabilities",
      "priority": 1,
      "criteria": {
        "minSeverity": "Critical",
        "fix_available": true
      },
      "actions": {
        "webhooks": ["security-webhook"],
        "mails": ["security-team@company.com"],
        "block_download": {
          "unscanned": false,
          "active": true
        },
        "block_release_bundle_distribution": true,
        "fail_build": true,
        "notify_watch_recipients": true,
        "notify_deployer": true,
        "create_ticket_enabled": false,
        "build_failure_grace_period_in_days": 5,
        "block_release_bundle_promotion": true
      }
    }
  ],
  "watches": [
    {
      "name": "production-watch",
      "description": "Monitor production repositories",
      "active": true,
      "repositories": {
        "type": "repository",
        "repositories": ["docker-local-prod", "release-local"]
      },
      "builds": {
        "type": "build",
        "bin_mgr_id": "default",
        "names": ["microservice-admin-app"]
      }
    }
  ]
}
```

## 🏢 High Availability & Clustering

### **Artifactory HA Configuration**

#### **HA Cluster Setup**
```yaml
# system.yaml for HA node
shared:
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: jdbc:postgresql://ha-db-cluster.company.com:5432/artifactory_ha
    username: artifactory_ha
    password: "${DB_PASSWORD}"
    maxOpenConnections: 80
    
  node:
    id: "${NODE_ID}"  # Unique per node
    name: "${NODE_NAME}"
    haEnabled: true
    primary: false  # Set to true for primary node only
    
  cluster:
    home: "/var/opt/jfrog/artifactory/data/ha"
    
  # Shared storage configuration
  binarystore:
    type: "cluster-file-system"
    provider: "s3-storage-v3"
    bucketName: "artifactory-ha-binaries"
    region: "us-west-2"
    path: "filestore"
    
router:
  entrypoints:
    internalPort: 8082
    externalPort: 80
    
  # Load balancer health check
  healthCheck:
    enabled: true
    path: "/router/api/v1/system/health"
```

#### **Load Balancer Configuration (HAProxy)**
```bash
# HAProxy configuration for Artifactory HA
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    daemon
    maxconn 4096
    log stdout local0

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog

# Artifactory UI Load Balancer
frontend artifactory_ui_frontend
    bind *:80
    bind *:443 ssl crt /etc/ssl/certs/artifactory.pem
    redirect scheme https if !{ ssl_fc }
    default_backend artifactory_ui_backend

backend artifactory_ui_backend
    balance roundrobin
    option httpchk GET /ui/api/v1/system/ping
    server art1 artifactory-node1:8082 check
    server art2 artifactory-node2:8082 check
    server art3 artifactory-node3:8082 check

# Artifactory API Load Balancer
frontend artifactory_api_frontend
    bind *:8081
    default_backend artifactory_api_backend

backend artifactory_api_backend
    balance roundrobin
    option httpchk GET /artifactory/api/system/ping
    server art1 artifactory-node1:8081 check
    server art2 artifactory-node2:8081 check
    server art3 artifactory-node3:8081 check

# Statistics
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
EOF
```

### **Database HA Configuration**

#### **PostgreSQL Cluster Setup**
```yaml
# PostgreSQL streaming replication
# Primary server postgresql.conf
listen_addresses = '*'
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
synchronous_commit = on
synchronous_standby_names = 'standby1,standby2'

# Primary server pg_hba.conf
host replication replicator 10.0.0.0/24 md5

# Standby server recovery.conf
standby_mode = 'on'
primary_conninfo = 'host=primary-db.company.com port=5432 user=replicator'
restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'
recovery_target_timeline = 'latest'
```

## ⚡ Performance Optimization

### **Advanced JVM Tuning**

#### **Production JVM Settings**
```bash
# High-performance JVM configuration
export JAVA_OPTIONS="-server \
    -Xms16g \
    -Xmx32g \
    -XX:NewRatio=3 \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=50 \
    -XX:G1HeapRegionSize=32m \
    -XX:G1ReservePercent=15 \
    -XX:InitiatingHeapOccupancyPercent=20 \
    -XX:G1MixedGCCountTarget=16 \
    -XX:G1OldCSetRegionThreshold=10 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+UseStringDeduplication \
    -XX:+OptimizeStringConcat \
    -XX:+UseFastAccessorMethods \
    -XX:+AggressiveOpts \
    -Djava.awt.headless=true \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF8 \
    -Dartifactory.async.corePoolSize=64 \
    -Dartifactory.async.maxPoolSize=512 \
    -Dartifactory.async.queueCapacity=2000 \
    -Dartifactory.pool.maxActive=200 \
    -Dartifactory.pool.maxIdle=50"

# GC tuning for large heaps
export JAVA_OPTIONS="$JAVA_OPTIONS \
    -XX:+UnlockDiagnosticVMOptions \
    -XX:+LogVMOutput \
    -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=5 \
    -XX:GCLogFileSize=100M \
    -Xloggc:/var/opt/jfrog/artifactory/logs/gc-%t.log \
    -XX:+PrintGC \
    -XX:+PrintGCDetails \
    -XX:+PrintGCTimeStamps \
    -XX:+PrintGCApplicationStoppedTime \
    -XX:+PrintStringDeduplicationStatistics"
```

### **Database Performance Optimization**

#### **PostgreSQL Production Settings**
```sql
-- PostgreSQL configuration for high-performance Artifactory
-- postgresql.conf

-- Memory settings
shared_buffers = '8GB'
effective_cache_size = '24GB'
maintenance_work_mem = '2GB'
work_mem = '256MB'

-- Checkpoint and WAL settings
checkpoint_completion_target = 0.9
wal_buffers = '64MB'
min_wal_size = '4GB'
max_wal_size = '16GB'
checkpoint_timeout = '15min'

-- Query planner settings
default_statistics_target = 500
random_page_cost = 1.1
effective_io_concurrency = 300

-- Connection settings
max_connections = 500
shared_preload_libraries = 'pg_stat_statements'

-- Logging and monitoring
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 10MB

-- Autovacuum tuning
autovacuum_max_workers = 6
autovacuum_naptime = '30s'
autovacuum_vacuum_threshold = 1000
autovacuum_analyze_threshold = 500
autovacuum_vacuum_scale_factor = 0.1
autovacuum_analyze_scale_factor = 0.05
```

### **Storage Optimization**

#### **Tiered Storage Configuration**
```xml
<!-- Advanced binarystore.xml with tiered storage -->
<?xml version="1.0" encoding="UTF-8"?>
<config version="v1">
    <chain template="cluster-file-system">
        <!-- Hot storage (NVMe SSD) -->
        <provider id="hot-storage" type="file-system">
            <dir>/var/opt/jfrog/artifactory/data/hot-storage</dir>
            <maxCacheSize>500GB</maxCacheSize>
        </provider>
        
        <!-- Warm storage (SSD) -->
        <provider id="warm-storage" type="file-system">
            <dir>/var/opt/jfrog/artifactory/data/warm-storage</dir>
        </provider>
        
        <!-- Cold storage (S3) -->
        <provider id="cold-storage" type="s3-storage-v3">
            <bucketName>artifactory-cold-storage</bucketName>
            <region>us-west-2</region>
            <path>filestore</path>
            <storageClass>STANDARD_IA</storageClass>
        </provider>
        
        <!-- Archive storage (Glacier) -->
        <provider id="archive-storage" type="s3-storage-v3">
            <bucketName>artifactory-archive</bucketName>
            <region>us-west-2</region>
            <path>archive</path>
            <storageClass>GLACIER</storageClass>
        </provider>
        
        <!-- Tiered cache provider -->
        <provider id="tiered-cache" type="cache-fs">
            <provider>cold-storage</provider>
            <maxCacheSize>100GB</maxCacheSize>
            <cacheProviderDir>/var/opt/jfrog/artifactory/data/cache</cacheProviderDir>
            <ageThreshold>7</ageThreshold>
        </provider>
        
        <!-- Sharding configuration -->
        <provider id="sharded-storage" type="sharding">
            <sub-providers>
                <sub-provider>hot-storage</sub-provider>
                <sub-provider>warm-storage</sub-provider>
            </sub-providers>
            <algorithm>modulo</algorithm>
        </provider>
    </chain>
</config>
```

## 🔌 Advanced Integrations

### **Kubernetes Integration**

#### **Helm Chart Values**
```yaml
# values.yaml for production Artifactory deployment
artifactory:
  name: artifactory-ha
  image:
    repository: releases-docker.jfrog.io/jfrog/artifactory-pro
    tag: latest
  
  # Resource allocation
  resources:
    requests:
      memory: "16Gi"
      cpu: "4"
    limits:
      memory: "32Gi"
      cpu: "8"
      
  # Persistence
  persistence:
    enabled: true
    storageClass: "fast-ssd"
    size: "1Ti"
    
  # Database configuration
  postgresql:
    enabled: false  # Use external database
  database:
    type: postgresql
    host: postgresql-ha.database.svc.cluster.local
    port: 5432
    database: artifactory_k8s
    
  # JVM configuration
  extraEnvironmentVariables:
    - name: EXTRA_JAVA_OPTS
      value: "-Xms16g -Xmx32g -XX:+UseG1GC"
      
  # Ingress configuration
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "nginx"
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    hosts:
      - host: artifactory.company.com
        paths:
          - /
    tls:
      - secretName: artifactory-tls
        hosts:
          - artifactory.company.com
          
  # Horizontal Pod Autoscaler
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

#### **Kubernetes Operator Configuration**
```yaml
apiVersion: artifactory.jfrog.io/v1alpha1
kind: Artifactory
metadata:
  name: artifactory-cluster
  namespace: jfrog
spec:
  size: 3
  version: "7.55.10"
  
  database:
    type: postgresql
    url: "postgresql://postgres-ha.database.svc.cluster.local:5432/artifactory"
    
  storage:
    type: s3
    config:
      bucketName: "k8s-artifactory-storage"
      region: "us-west-2"
      
  monitoring:
    enabled: true
    prometheus:
      enabled: true
      
  security:
    tls:
      enabled: true
      secretName: "artifactory-tls"
      
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### **Terraform Integration**

#### **Infrastructure as Code**
```hcl
# Terraform configuration for Artifactory infrastructure
resource "aws_instance" "artifactory_ha" {
  count                  = 3
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = "c5.2xlarge"
  key_name             = var.key_name
  vpc_security_group_ids = [aws_security_group.artifactory.id]
  subnet_id            = aws_subnet.private[count.index].id
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
  }
  
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 500
    encrypted   = true
  }
  
  user_data = templatefile("${path.module}/user-data.sh", {
    node_id   = "artifactory-${count.index + 1}"
    db_host   = aws_rds_cluster.artifactory.endpoint
    s3_bucket = aws_s3_bucket.artifactory_storage.bucket
  })
  
  tags = {
    Name = "artifactory-ha-${count.index + 1}"
    Role = "artifactory"
  }
}

resource "aws_rds_cluster" "artifactory" {
  cluster_identifier      = "artifactory-cluster"
  engine                 = "aurora-postgresql"
  engine_version         = "13.7"
  availability_zones     = ["us-west-2a", "us-west-2b", "us-west-2c"]
  database_name          = "artifactory"
  master_username        = "artifactory"
  master_password        = var.db_password
  backup_retention_period = 30
  preferred_backup_window = "07:00-09:00"
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.artifactory.name
  
  storage_encrypted = true
  
  tags = {
    Name = "artifactory-database"
  }
}

resource "aws_s3_bucket" "artifactory_storage" {
  bucket = "artifactory-ha-storage-${random_string.suffix.result}"
  
  tags = {
    Name = "artifactory-storage"
  }
}

resource "aws_s3_bucket_versioning" "artifactory_storage" {
  bucket = aws_s3_bucket.artifactory_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

## 🤖 Automation & Scripting

### **Advanced Build Information**

#### **Comprehensive Build Info Collection**
```bash
#!/bin/bash
# Advanced build info collection script

BUILD_NAME="microservice-admin-app"
BUILD_NUMBER="${JENKINS_BUILD_NUMBER:-$(date +%s)}"
BUILD_URL="${JENKINS_BUILD_URL:-http://jenkins.company.com/job/build/$BUILD_NUMBER}"

# Start build info collection
jf rt build-collect-env "$BUILD_NAME" "$BUILD_NUMBER"

# Add Git information
jf rt build-add-git "$BUILD_NAME" "$BUILD_NUMBER" --config=.jfrog

# Collect Docker build info
for component in frontend backend database; do
    echo "Building $component Docker image..."
    
    # Build Docker image
    docker build -t "artifactory.company.com/docker-local/$component:$BUILD_NUMBER" \
        --label "build.name=$BUILD_NAME" \
        --label "build.number=$BUILD_NUMBER" \
        --label "git.commit=$(git rev-parse HEAD)" \
        --label "git.branch=$(git rev-parse --abbrev-ref HEAD)" \
        --label "build.timestamp=$(date -Iseconds)" \
        "./$component"
    
    # Push image
    docker push "artifactory.company.com/docker-local/$component:$BUILD_NUMBER"
    
    # Add to build info
    jf rt build-docker-create "$BUILD_NAME" "$BUILD_NUMBER" \
        --image-file "$component-image.json" \
        --server-id artifactory-server
done

# Create source archive
tar -czf "source-$BUILD_NUMBER.tar.gz" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    .

# Upload source archive
jf rt upload "source-$BUILD_NUMBER.tar.gz" \
    "generic-local/microservice-admin-app/$BUILD_NUMBER/" \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --server-id=artifactory-server

# Add properties to artifacts
jf rt set-props "generic-local/microservice-admin-app/$BUILD_NUMBER/*" \
    "build.name=$BUILD_NAME;build.number=$BUILD_NUMBER;component=source;type=archive" \
    --server-id=artifactory-server

# Run security scan
echo "Running security scan..."
jf audit --format=json > security-report.json

# Upload security report
jf rt upload "security-report.json" \
    "generic-local/microservice-admin-app/$BUILD_NUMBER/reports/" \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --server-id=artifactory-server

# Run tests and upload results
npm test -- --reporter=json > test-results.json
jf rt upload "test-results.json" \
    "generic-local/microservice-admin-app/$BUILD_NUMBER/reports/" \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --server-id=artifactory-server

# Publish build info
jf rt build-publish "$BUILD_NAME" "$BUILD_NUMBER" --server-id=artifactory-server

echo "Build info published for $BUILD_NAME #$BUILD_NUMBER"
```

### **Automated Quality Gates**

#### **Quality Gate Script**
```bash
#!/bin/bash
# Automated quality gate validation

BUILD_NAME="$1"
BUILD_NUMBER="$2"
TARGET_REPO="${3:-release-local}"

# Quality gate criteria
MAX_CRITICAL_VULNERABILITIES=0
MAX_HIGH_VULNERABILITIES=2
MIN_TEST_COVERAGE=80
REQUIRED_SECURITY_SCAN=true

echo "Running quality gates for $BUILD_NAME #$BUILD_NUMBER"

# Check security scan results
SECURITY_SCAN=$(jf rt curl -XPOST "/api/search/aql" \
    -H "Content-Type: text/plain" \
    -d "items.find({\"@build.name\":\"$BUILD_NAME\",\"@build.number\":\"$BUILD_NUMBER\",\"name\":\"security-report.json\"})")

if [ "$REQUIRED_SECURITY_SCAN" = true ] && [ -z "$SECURITY_SCAN" ]; then
    echo "❌ Quality Gate FAILED: Security scan not found"
    exit 1
fi

# Check vulnerability count
VULNERABILITIES=$(curl -s "http://localhost:8081/artifactory/api/search/aql" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: text/plain" \
    -d "items.find({\"@build.name\":\"$BUILD_NAME\",\"@build.number\":\"$BUILD_NUMBER\"})" | \
    jq -r '.results[] | select(.name | contains("security-report")) | .properties[] | select(.key == "vulnerabilities.critical") | .value')

CRITICAL_VULNS=${VULNERABILITIES:-0}

if [ "$CRITICAL_VULNS" -gt "$MAX_CRITICAL_VULNERABILITIES" ]; then
    echo "❌ Quality Gate FAILED: $CRITICAL_VULNS critical vulnerabilities found (max: $MAX_CRITICAL_VULNERABILITIES)"
    exit 1
fi

# Check test coverage
TEST_COVERAGE=$(jf rt curl -XGET "/api/search/prop" \
    -H "Content-Type: application/json" \
    -d "build.name=$BUILD_NAME;build.number=$BUILD_NUMBER;test.coverage=*" | \
    jq -r '.results[0].properties.coverage // "0"')

if [ "${TEST_COVERAGE%.*}" -lt "$MIN_TEST_COVERAGE" ]; then
    echo "❌ Quality Gate FAILED: Test coverage $TEST_COVERAGE% is below minimum $MIN_TEST_COVERAGE%"
    exit 1
fi

echo "✅ All quality gates passed!"
echo "   - Critical vulnerabilities: $CRITICAL_VULNS/$MAX_CRITICAL_VULNERABILITIES"
echo "   - Test coverage: $TEST_COVERAGE%"

# Promote build to release repository
echo "Promoting build to $TARGET_REPO..."
jf rt build-promote "$BUILD_NAME" "$BUILD_NUMBER" "$TARGET_REPO" \
    --status="Released" \
    --comment="Promoted after passing quality gates" \
    --copy=true \
    --server-id=artifactory-server

echo "✅ Build promoted to $TARGET_REPO"
```

## 🌐 Multi-Site Replication

### **Cross-Region Replication**

#### **Replication Configuration**
```json
{
  "replicationConfigs": [
    {
      "replicationKey": "us-west-to-eu-west",
      "cronExp": "0 */4 * * *",
      "enableEventReplication": true,
      "enabled": true,
      "repoKey": "docker-local-prod",
      "serverId": "eu-west-artifactory",
      "url": "https://eu-west-artifactory.company.com/artifactory/docker-local-prod",
      "socketTimeoutMillis": 30000,
      "username": "replication-service",
      "password": "replication-password",
      "syncDeletes": false,
      "syncProperties": true,
      "syncStatistics": false,
      "pathPrefix": "production/",
      "includePathPrefixPattern": "production/**",
      "excludePathPrefixPattern": "production/temp/**,production/cache/**"
    },
    {
      "replicationKey": "us-west-to-asia-pacific",
      "cronExp": "0 2 * * *",
      "enableEventReplication": false,
      "enabled": true,
      "repoKey": "generic-local",
      "serverId": "apac-artifactory",
      "url": "https://apac-artifactory.company.com/artifactory/generic-local",
      "socketTimeoutMillis": 60000,
      "username": "replication-service",
      "password": "replication-password",
      "syncDeletes": true,
      "syncProperties": true,
      "pathPrefix": "releases/",
      "bandwidth": "50MB"
    }
  ]
}
```

### **Federated Repository Setup**

#### **Federation Configuration**
```bash
# Create federated repository
curl -X POST "${ARTIFACTORY_URL}/api/federation/migrate/docker-local" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "members": [
      {
        "url": "https://us-east-artifactory.company.com/artifactory",
        "enabled": true
      },
      {
        "url": "https://eu-west-artifactory.company.com/artifactory", 
        "enabled": true
      },
      {
        "url": "https://apac-artifactory.company.com/artifactory",
        "enabled": true
      }
    ],
    "repositories": ["docker-local"]
  }'
```

## 📊 Advanced Monitoring

### **Custom Metrics Collection**

#### **Prometheus Metrics Exporter**
```python
#!/usr/bin/env python3
"""
Advanced Artifactory metrics collector for Prometheus
"""

import requests
import json
import time
from prometheus_client import CollectorRegistry, Gauge, Counter, start_http_server

class ArtifactoryMetricsCollector:
    def __init__(self, artifactory_url, username, password):
        self.artifactory_url = artifactory_url
        self.auth = (username, password)
        self.registry = CollectorRegistry()
        
        # Define metrics
        self.storage_used = Gauge('artifactory_storage_used_bytes', 
                                'Storage used in bytes', 
                                ['repository'], registry=self.registry)
        
        self.artifacts_count = Gauge('artifactory_artifacts_total',
                                   'Total number of artifacts',
                                   ['repository', 'type'], registry=self.registry)
        
        self.downloads_total = Counter('artifactory_downloads_total',
                                     'Total downloads',
                                     ['repository', 'path'], registry=self.registry)
        
        self.uploads_total = Counter('artifactory_uploads_total',
                                   'Total uploads', 
                                   ['repository', 'path'], registry=self.registry)
        
        self.response_time = Gauge('artifactory_api_response_time_seconds',
                                 'API response time in seconds',
                                 ['endpoint'], registry=self.registry)
    
    def collect_storage_metrics(self):
        """Collect storage usage metrics"""
        try:
            response = requests.get(
                f"{self.artifactory_url}/api/storageinfo",
                auth=self.auth,
                timeout=30
            )
            data = response.json()
            
            for repo in data.get('repositoriesSummaryList', []):
                repo_key = repo['repoKey']
                used_space = int(repo['usedSpace'])
                self.storage_used.labels(repository=repo_key).set(used_space)
                
        except Exception as e:
            print(f"Error collecting storage metrics: {e}")
    
    def collect_artifact_metrics(self):
        """Collect artifact count metrics using AQL"""
        aql_query = """
        items.find({
            "type": "file"
        }).include("repo", "name", "type", "size")
        """
        
        try:
            response = requests.post(
                f"{self.artifactory_url}/api/search/aql",
                auth=self.auth,
                headers={'Content-Type': 'text/plain'},
                data=aql_query,
                timeout=60
            )
            
            data = response.json()
            repo_counts = {}
            
            for item in data.get('results', []):
                repo = item['repo']
                artifact_type = item['name'].split('.')[-1] if '.' in item['name'] else 'unknown'
                
                key = (repo, artifact_type)
                repo_counts[key] = repo_counts.get(key, 0) + 1
            
            for (repo, artifact_type), count in repo_counts.items():
                self.artifacts_count.labels(repository=repo, type=artifact_type).set(count)
                
        except Exception as e:
            print(f"Error collecting artifact metrics: {e}")
    
    def collect_performance_metrics(self):
        """Collect API performance metrics"""
        endpoints = [
            '/api/system/ping',
            '/api/repositories',
            '/api/storageinfo'
        ]
        
        for endpoint in endpoints:
            try:
                start_time = time.time()
                response = requests.get(
                    f"{self.artifactory_url}{endpoint}",
                    auth=self.auth,
                    timeout=10
                )
                end_time = time.time()
                
                response_time = end_time - start_time
                self.response_time.labels(endpoint=endpoint).set(response_time)
                
            except Exception as e:
                print(f"Error collecting performance metrics for {endpoint}: {e}")
    
    def collect_all_metrics(self):
        """Collect all metrics"""
        print("Collecting storage metrics...")
        self.collect_storage_metrics()
        
        print("Collecting artifact metrics...")
        self.collect_artifact_metrics()
        
        print("Collecting performance metrics...")
        self.collect_performance_metrics()

if __name__ == "__main__":
    collector = ArtifactoryMetricsCollector(
        "http://localhost:8081/artifactory",
        "admin", 
        "password"
    )
    
    # Start Prometheus metrics server
    start_http_server(8000, registry=collector.registry)
    
    # Collect metrics every 60 seconds
    while True:
        try:
            collector.collect_all_metrics()
            print("Metrics collection completed")
        except Exception as e:
            print(f"Error in metrics collection: {e}")
        
        time.sleep(60)
```

### **Advanced Alerting**

#### **Alertmanager Rules**
```yaml
# alerting-rules.yml
groups:
  - name: artifactory.rules
    rules:
      - alert: ArtifactoryDown
        expr: up{job="artifactory"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Artifactory is down"
          description: "Artifactory has been down for more than 1 minute"
          
      - alert: ArtifactoryHighCPU
        expr: artifactory_cpu_usage > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Artifactory high CPU usage"
          description: "CPU usage is {{ $value }}% for 5 minutes"
          
      - alert: ArtifactoryHighMemory
        expr: artifactory_memory_usage > 90
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "Artifactory high memory usage"
          description: "Memory usage is {{ $value }}% for 3 minutes"
          
      - alert: ArtifactoryStorageFull
        expr: artifactory_storage_used_bytes / artifactory_storage_total_bytes > 0.85
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Artifactory storage almost full"
          description: "Storage usage is {{ $value | humanizePercentage }}"
          
      - alert: ArtifactorySlowResponse
        expr: artifactory_api_response_time_seconds > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Artifactory slow API response"
          description: "API response time is {{ $value }}s"
          
      - alert: ArtifactoryFailedReplication
        expr: increase(artifactory_replication_failures_total[1h]) > 0
        labels:
          severity: critical
        annotations:
          summary: "Artifactory replication failed"
          description: "{{ $value }} replication failures in the last hour"
```

## 🔄 Disaster Recovery

### **Comprehensive Backup Strategy**

#### **Advanced Backup Script**
```bash
#!/bin/bash
# Comprehensive disaster recovery backup script

set -euo pipefail

# Configuration
BACKUP_ROOT="/backup/artifactory"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"
RETENTION_DAYS=90
S3_BUCKET="artifactory-dr-backups"
ENCRYPTION_KEY="/etc/artifactory/backup-key.gpg"

# Logging
LOG_FILE="/var/log/artifactory-dr-backup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"/{system,database,repositories,metadata}

log "Starting comprehensive Artifactory backup"

# 1. System configuration backup
log "Backing up system configuration"
docker exec artifactory tar -czf - /var/opt/jfrog/artifactory/etc > "$BACKUP_DIR/system/config.tar.gz"

# 2. Database backup with consistent snapshot
log "Creating database backup"
pg_dump -h localhost -U artifactory -d artifactory \
    --format=custom \
    --compress=9 \
    --verbose \
    --file="$BACKUP_DIR/database/artifactory.pgdump"

# 3. Critical repository backup
log "Backing up critical repositories"
CRITICAL_REPOS=("docker-local-prod" "release-local" "generic-local")

for repo in "${CRITICAL_REPOS[@]}"; do
    log "Backing up repository: $repo"
    jf rt download "$repo/*" "$BACKUP_DIR/repositories/$repo/" \
        --flat=false \
        --server-id=artifactory-server \
        --threads=5 \
        --retries=3
done

# 4. Metadata and build info backup
log "Backing up build information"
curl -u admin:password \
    "http://localhost:8081/artifactory/api/build" \
    | jq '.' > "$BACKUP_DIR/metadata/builds.json"

# 5. Security configuration backup
log "Backing up security configuration"
{
    echo "=== USERS ==="
    curl -s -u admin:password "http://localhost:8081/artifactory/api/security/users"
    
    echo -e "\n=== GROUPS ==="
    curl -s -u admin:password "http://localhost:8081/artifactory/api/security/groups"
    
    echo -e "\n=== PERMISSIONS ==="
    curl -s -u admin:password "http://localhost:8081/artifactory/api/v2/security/permissions"
    
    echo -e "\n=== REPOSITORIES ==="
    curl -s -u admin:password "http://localhost:8081/artifactory/api/repositories"
} > "$BACKUP_DIR/metadata/security.json"

# 6. Create backup manifest
log "Creating backup manifest"
cat > "$BACKUP_DIR/manifest.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "artifactory_version": "$(curl -s -u admin:password http://localhost:8081/artifactory/api/system/version | jq -r '.version')",
    "backup_size": "$(du -sh $BACKUP_DIR | cut -f1)",
    "repositories_backed_up": $(printf '%s\n' "${CRITICAL_REPOS[@]}" | jq -R . | jq -s .),
    "backup_type": "full",
    "retention_policy": "${RETENTION_DAYS}_days"
}
EOF

# 7. Encrypt backup
log "Encrypting backup archive"
tar -czf - -C "$BACKUP_ROOT" "$DATE" | \
    gpg --cipher-algo AES256 --compress-algo 2 \
        --symmetric --armor \
        --batch --yes --passphrase-file "$ENCRYPTION_KEY" \
        --output "$BACKUP_DIR.tar.gz.gpg"

# 8. Upload to S3 with versioning
log "Uploading to S3"
aws s3 cp "$BACKUP_DIR.tar.gz.gpg" "s3://$S3_BUCKET/full-backups/" \
    --storage-class STANDARD_IA \
    --metadata "backup-date=$(date -Iseconds),retention-days=$RETENTION_DAYS"

# 9. Verify backup integrity
log "Verifying backup integrity"
if gpg --batch --yes --passphrase-file "$ENCRYPTION_KEY" \
       --decrypt "$BACKUP_DIR.tar.gz.gpg" | tar -tzf - > /dev/null; then
    log "✅ Backup integrity verified"
else
    log "❌ Backup integrity check failed"
    exit 1
fi

# 10. Cleanup local backup
rm -rf "$BACKUP_DIR"
rm -f "$BACKUP_DIR.tar.gz.gpg"

# 11. Cleanup old S3 backups
log "Cleaning up old S3 backups"
aws s3 ls "s3://$S3_BUCKET/full-backups/" \
    --recursive \
    --output text | \
    awk '{print $4}' | \
    while read -r file; do
        file_date=$(aws s3api head-object --bucket "$S3_BUCKET" --key "$file" \
                    --query 'LastModified' --output text)
        if [[ $(date -d "$file_date" +%s) -lt $(date -d "$RETENTION_DAYS days ago" +%s) ]]; then
            aws s3 rm "s3://$S3_BUCKET/$file"
            log "Deleted old backup: $file"
        fi
    done

log "Backup completed successfully: s3://$S3_BUCKET/full-backups/$(basename $BACKUP_DIR).tar.gz.gpg"
```

### **Disaster Recovery Procedures**

#### **Recovery Automation Script**
```bash
#!/bin/bash
# Disaster recovery restoration script

set -euo pipefail

BACKUP_FILE="$1"
RECOVERY_DIR="/recovery/artifactory"
ENCRYPTION_KEY="/etc/artifactory/backup-key.gpg"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Starting Artifactory disaster recovery from: $BACKUP_FILE"

# 1. Stop services
log "Stopping Artifactory services"
docker-compose -f /opt/artifactory/docker-compose.yml down

# 2. Create recovery directory
mkdir -p "$RECOVERY_DIR"

# 3. Download and decrypt backup
if [[ "$BACKUP_FILE" =~ ^s3:// ]]; then
    log "Downloading backup from S3"
    aws s3 cp "$BACKUP_FILE" "$RECOVERY_DIR/backup.tar.gz.gpg"
    BACKUP_FILE="$RECOVERY_DIR/backup.tar.gz.gpg"
fi

log "Decrypting and extracting backup"
gpg --batch --yes --passphrase-file "$ENCRYPTION_KEY" \
    --decrypt "$BACKUP_FILE" | \
    tar -xzf - -C "$RECOVERY_DIR"

BACKUP_DATE=$(ls -1 "$RECOVERY_DIR" | head -1)
BACKUP_PATH="$RECOVERY_DIR/$BACKUP_DATE"

# 4. Restore database
log "Restoring database"
dropdb --if-exists -h localhost -U postgres artifactory
createdb -h localhost -U postgres artifactory
pg_restore -h localhost -U postgres -d artifactory \
    --verbose --clean --if-exists \
    "$BACKUP_PATH/database/artifactory.pgdump"

# 5. Restore system configuration
log "Restoring system configuration"
docker run --rm -v /opt/artifactory/data:/restore-target \
    ubuntu:20.04 \
    tar -xzf - -C /restore-target < "$BACKUP_PATH/system/config.tar.gz"

# 6. Restore repositories
log "Restoring critical repositories"
for repo_backup in "$BACKUP_PATH/repositories"/*; do
    repo_name=$(basename "$repo_backup")
    log "Restoring repository: $repo_name"
    
    # Upload artifacts back to repository
    jf rt upload "$repo_backup/*" "$repo_name/" \
        --flat=false \
        --server-id=artifactory-server \
        --threads=5 \
        --retries=3
done

# 7. Restore security configuration (manual verification required)
log "Security configuration available at: $BACKUP_PATH/metadata/security.json"
log "Please manually verify and restore security settings"

# 8. Start services
log "Starting Artifactory services"
docker-compose -f /opt/artifactory/docker-compose.yml up -d

# 9. Wait for services to be ready
log "Waiting for Artifactory to be ready"
for i in {1..30}; do
    if curl -f -s http://localhost:8081/artifactory/api/system/ping > /dev/null; then
        log "✅ Artifactory is ready"
        break
    fi
    sleep 30
done

# 10. Verification
log "Performing post-recovery verification"
{
    echo "System ping: $(curl -s http://localhost:8081/artifactory/api/system/ping)"
    echo "Repository count: $(curl -s -u admin:password http://localhost:8081/artifactory/api/repositories | jq '. | length')"
    echo "Storage info available: $(curl -s -u admin:password http://localhost:8081/artifactory/api/storageinfo | jq -r '.repositoriesSummaryList | length') repositories"
} > "$RECOVERY_DIR/verification.log"

log "✅ Disaster recovery completed successfully"
log "Verification results available at: $RECOVERY_DIR/verification.log"
log "Manual verification of security settings required"
```

## ☁️ Cloud-Native Features

### **Service Mesh Integration**

#### **Istio Configuration**
```yaml
# Istio configuration for Artifactory
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: artifactory-vs
  namespace: jfrog
spec:
  hosts:
  - artifactory.company.com
  gateways:
  - artifactory-gateway
  http:
  - match:
    - uri:
        prefix: "/v2/"
    route:
    - destination:
        host: artifactory-service
        port:
          number: 8081
    timeout: 300s
    headers:
      request:
        add:
          docker-content-digest: "true"
  - match:
    - uri:
        prefix: "/artifactory/"
    route:
    - destination:
        host: artifactory-service
        port:
          number: 8081
    timeout: 60s
  - match:
    - uri:
        prefix: "/ui/"
    route:
    - destination:
        host: artifactory-service
        port:
          number: 8082
    timeout: 30s
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: artifactory-dr
  namespace: jfrog
spec:
  host: artifactory-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 10
        maxRetries: 3
        consecutiveGatewayErrors: 5
        interval: 30s
        baseEjectionTime: 30s
```

### **GitOps Integration**

#### **ArgoCD Application**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: artifactory
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://charts.jfrog.io
    chart: artifactory
    targetRevision: 107.55.10
    helm:
      valueFiles:
      - values-production.yaml
      parameters:
      - name: artifactory.image.tag
        value: "7.55.10"
      - name: database.host
        value: "postgresql-ha.database.svc.cluster.local"
  destination:
    server: https://kubernetes.default.svc
    namespace: jfrog
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

---

**🎯 Advanced Features Summary**

This guide covers enterprise-grade Artifactory features including:

- ✅ **Advanced Repository Management** with custom layouts and promotion rules
- ✅ **Enterprise Security** with SAML SSO, OAuth, and advanced access controls  
- ✅ **High Availability** clustering and load balancing
- ✅ **Performance Optimization** with advanced JVM tuning and tiered storage
- ✅ **Advanced Integrations** with Kubernetes, Terraform, and service mesh
- ✅ **Automation & Scripting** for build info and quality gates
- ✅ **Multi-Site Replication** and federated repositories
- ✅ **Advanced Monitoring** with custom metrics and alerting
- ✅ **Disaster Recovery** with comprehensive backup and restoration
- ✅ **Cloud-Native Features** with service mesh and GitOps integration

These advanced features enable enterprise-scale artifact management with high availability, security, and performance.

---

**Last Updated**: October 2, 2025  
**Version**: 1.0.0  
**Maintainer**: Advanced Features Team
