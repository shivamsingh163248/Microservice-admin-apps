# ⚙️ JFrog Artifactory Configuration Guide

## 📋 Table of Contents

1. [Configuration Overview](#-configuration-overview)
2. [System Configuration](#-system-configuration)
3. [Repository Configuration](#-repository-configuration)
4. [Security Configuration](#-security-configuration)
5. [Integration Configuration](#-integration-configuration)
6. [Performance Configuration](#-performance-configuration)
7. [Backup Configuration](#-backup-configuration)
8. [Monitoring Configuration](#-monitoring-configuration)
9. [Environment-Specific Configs](#-environment-specific-configs)
10. [Troubleshooting Configs](#-troubleshooting-configs)

## 🎯 Configuration Overview

### **Configuration Hierarchy**

```
Artifactory Configuration Structure
├── System Level Configuration
│   ├── system.yaml              # Core system settings
│   ├── artifactory.config.xml   # Legacy XML configuration
│   └── binarystore.xml          # Storage configuration
├── Repository Configuration
│   ├── Repository definitions
│   ├── Virtual repository setup
│   └── Remote repository proxies
├── Security Configuration
│   ├── User management
│   ├── Group permissions
│   ├── Access tokens
│   └── Security policies
├── Integration Configuration
│   ├── CI/CD tool integration
│   ├── LDAP/SSO configuration
│   ├── Webhook setup
│   └── External tool configs
└── Runtime Configuration
    ├── JVM settings
    ├── Database connections
    ├── Cache settings
    └── Performance tuning
```

### **Configuration Management Strategy**

```yaml
Configuration Philosophy:
  - Infrastructure as Code (IaC)
  - Version controlled configurations
  - Environment-specific overrides
  - Automated configuration deployment
  - Configuration validation
  - Rollback capabilities

Tools Used:
  - Ansible playbooks
  - Terraform modules  
  - Helm charts
  - Configuration templates
  - Environment variables
  - External secret management
```

## 🖥️ System Configuration

### **Primary System Configuration (system.yaml)**

```yaml
# /opt/artifactory/var/etc/system.yaml
shared:
  # Security settings
  security:
    joinKey: "${ARTIFACTORY_JOIN_KEY}"
    masterKey: "${ARTIFACTORY_MASTER_KEY}"
    
  # Database configuration
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: "${DB_URL:jdbc:postgresql://postgresql:5432/artifactory}"
    username: "${DB_USERNAME:artifactory}"
    password: "${DB_PASSWORD}"
    maxOpenConnections: 80
    maxIdleConnections: 20
    
  # Node configuration
  node:
    id: "${ARTIFACTORY_NODE_ID:art-node-1}"
    name: "${ARTIFACTORY_NODE_NAME:artifactory-primary}"
    haEnabled: "${HA_ENABLED:false}"
    
  # Logging configuration
  logging:
    consoleLog:
      enabled: true
    applicationLog:
      enabled: true
      level: INFO
    accessLog:
      enabled: true
    requestLog:
      enabled: true
      
# Router configuration
router:
  entrypoints:
    internalPort: 8082
    internalPortTls: 8443
    externalPort: ${EXTERNAL_PORT:80}
    externalPortTls: ${EXTERNAL_PORT_TLS:443}
    
  # SSL/TLS configuration
  tlsConfig:
    cert: "${TLS_CERT_PATH:/var/opt/jfrog/artifactory/etc/ssl/tls.crt}"
    key: "${TLS_KEY_PATH:/var/opt/jfrog/artifactory/etc/ssl/tls.key}"
    
# Access configuration  
access:
  # LDAP integration
  ldap:
    enabled: ${LDAP_ENABLED:false}
    url: "${LDAP_URL}"
    userDnPattern: "${LDAP_USER_DN_PATTERN}"
    search:
      searchFilter: "${LDAP_SEARCH_FILTER:(uid={0})}"
      searchBase: "${LDAP_SEARCH_BASE}"
      managerDn: "${LDAP_MANAGER_DN}"
      managerPassword: "${LDAP_MANAGER_PASSWORD}"
      
# Frontend configuration
frontend:
  session:
    timeout: ${SESSION_TIMEOUT:1800}
    
# Metadata configuration
metadata:
  application:
    ci:
      notifyOnArtifactDeletion: true
```

### **JVM Configuration**

```bash
# /opt/artifactory/var/etc/artifactory.default
# JVM Memory Settings
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
    -XX:+UseCGroupMemoryLimitForHeap \
    -Djava.awt.headless=true \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF8 \
    -Dartifactory.async.corePoolSize=16 \
    -Dartifactory.async.maxPoolSize=128"

# GC Logging (for performance tuning)
export JAVA_OPTIONS="$JAVA_OPTIONS \
    -Xloggc:/var/opt/jfrog/artifactory/logs/gc.log \
    -XX:+PrintGCDetails \
    -XX:+PrintGCTimeStamps \
    -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=10 \
    -XX:GCLogFileSize=10M"

# Additional JVM Options
export JAVA_OPTIONS="$JAVA_OPTIONS \
    -Dartifactory.home=/var/opt/jfrog/artifactory \
    -Dartifactory.logs.dir=/var/opt/jfrog/artifactory/logs \
    -Dspring.profiles.active=production"
```

### **Binary Store Configuration**

```xml
<!-- /var/opt/jfrog/artifactory/etc/binarystore.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<config version="v1">
    <chain template="cluster-file-system">
        <!-- File system binary store -->
        <provider id="file-system" type="file-system">
            <dir>/var/opt/jfrog/artifactory/data/filestore</dir>
        </provider>
        
        <!-- S3 binary store (for cloud deployment) -->
        <provider id="s3" type="s3-storage-v3">
            <bucketName>${S3_BUCKET_NAME:artifactory-binaries}</bucketName>
            <region>${S3_REGION:us-west-2}</region>
            <path>${S3_PATH:filestore}</path>
            <accessKey>${S3_ACCESS_KEY}</accessKey>
            <secretKey>${S3_SECRET_KEY}</secretKey>
        </provider>
        
        <!-- Cache provider -->
        <provider id="cache-fs" type="cache-fs">
            <provider>s3</provider>
            <maxCacheSize>50GB</maxCacheSize>
            <cacheProviderDir>/var/opt/jfrog/artifactory/data/cache</cacheProviderDir>
        </provider>
        
        <!-- Redundant storage -->
        <provider id="redundant" type="redundant">
            <sub-provider>file-system</sub-provider>
            <sub-provider>s3</sub-provider>
        </provider>
    </chain>
</config>
```

## 🗄️ Repository Configuration

### **Repository Creation via REST API**

#### **Docker Repository Configuration**

```bash
# Create Docker Local Repository
curl -X PUT "${ARTIFACTORY_URL}/api/repositories/docker-local-dev" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "rclass": "local",
    "packageType": "docker",
    "description": "Local Docker repository for development images",
    "notes": "Development environment Docker images",
    "includesPattern": "**/*",
    "excludesPattern": "",
    "repoLayoutRef": "simple-default",
    "dockerApiVersion": "V2",
    "maxUniqueSnapshots": 10,
    "dockerTagRetention": 3,
    "dockerMaxUniqueTags": 10,
    "blockPushingSchema1": true,
    "blackedOut": false,
    "xrayConfig": {
      "enabled": true,
      "allowDownloadsXrayUnavailable": true,
      "allowBlockedArtifactsDownload": false
    },
    "propertySets": ["artifactory"],
    "archiveBrowsingEnabled": false,
    "calculateYumMetadata": false,
    "yumRootDepth": 0,
    "enableFileListsIndexing": false
  }'

# Create Docker Remote Repository (Docker Hub Proxy)
curl -X PUT "${ARTIFACTORY_URL}/api/repositories/docker-remote" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "rclass": "remote",
    "packageType": "docker",
    "url": "https://registry-1.docker.io/",
    "description": "Docker Hub proxy repository",
    "notes": "Proxy to Docker Hub with caching",
    "includesPattern": "**/*",
    "excludesPattern": "",
    "repoLayoutRef": "simple-default",
    "dockerApiVersion": "V2",
    "enableTokenAuthentication": true,
    "registryUrl": "https://index.docker.io/v1/",
    "offline": false,
    "hardFail": false,
    "storeArtifactsLocally": true,
    "socketTimeoutMillis": 15000,
    "localAddress": "",
    "retrievalCachePeriodSecs": 7200,
    "failedRetrievalCachePeriodSecs": 1800,
    "missedRetrievalCachePeriodSecs": 10800,
    "unusedArtifactsCleanupEnabled": true,
    "unusedArtifactsCleanupPeriodHours": 168,
    "assumedOfflinePeriodSecs": 300,
    "fetchJarsEagerly": false,
    "fetchSourcesEagerly": false,
    "shareConfiguration": false,
    "synchronizeProperties": false,
    "maxUniqueSnapshots": 0,
    "blackedOut": false,
    "allowAnyHostAuth": false,
    "enableCookieManagement": false,
    "xrayConfig": {
      "enabled": true,
      "allowDownloadsXrayUnavailable": true,
      "allowBlockedArtifactsDownload": false
    }
  }'

# Create Docker Virtual Repository
curl -X PUT "${ARTIFACTORY_URL}/api/repositories/docker-virtual" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "rclass": "virtual",
    "packageType": "docker",
    "description": "Virtual Docker repository aggregating local and remote",
    "notes": "Unified access to Docker repositories",
    "includesPattern": "**/*",
    "excludesPattern": "",
    "repoLayoutRef": "simple-default",
    "repositories": [
      "docker-local-dev",
      "docker-local-staging", 
      "docker-local-prod",
      "docker-remote"
    ],
    "defaultDeploymentRepo": "docker-local-dev",
    "dockerApiVersion": "V2",
    "enableTokenAuthentication": true,
    "artifactoryRequestsCanRetrieveRemoteArtifacts": true,
    "keyPair": "",
    "pomRepositoryReferencesCleanupPolicy": "discard_active_reference",
    "virtualRetrievalCachePeriodSecs": 600
  }'
```

#### **Generic Repository Configuration**

```bash
# Create Generic Local Repository
curl -X PUT "${ARTIFACTORY_URL}/api/repositories/generic-local-dev" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "rclass": "local",
    "packageType": "generic", 
    "description": "Local generic repository for development artifacts",
    "notes": "Application binaries, source archives, and reports",
    "includesPattern": "**/*",
    "excludesPattern": "*.tmp,*.log",
    "repoLayoutRef": "simple-default",
    "checksumPolicyType": "client-checksums",
    "handleReleases": true,
    "handleSnapshots": true,
    "maxUniqueSnapshots": 5,
    "snapshotVersionBehavior": "unique",
    "suppressPomConsistencyChecks": false,
    "blackedOut": false,
    "propertySets": ["artifactory"],
    "archiveBrowsingEnabled": true,
    "calculateYumMetadata": false,
    "yumRootDepth": 0,
    "enableFileListsIndexing": true,
    "optionalIndexCompressionFormats": ["bz2", "lzma", "xz"],
    "xrayConfig": {
      "enabled": true,
      "allowDownloadsXrayUnavailable": true,
      "allowBlockedArtifactsDownload": false
    }
  }'
```

#### **NPM Repository Configuration**

```bash
# Create NPM Local Repository
curl -X PUT "${ARTIFACTORY_URL}/api/repositories/npm-local" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "rclass": "local",
    "packageType": "npm",
    "description": "Local NPM repository for private packages",
    "notes": "Private NPM packages for microservice frontend",
    "includesPattern": "**/*",
    "excludesPattern": "",
    "repoLayoutRef": "npm-default",
    "blackedOut": false,
    "xrayConfig": {
      "enabled": true,
      "allowDownloadsXrayUnavailable": true,
      "allowBlockedArtifactsDownload": false
    }
  }'

# Create NPM Remote Repository  
curl -X PUT "${ARTIFACTORY_URL}/api/repositories/npm-remote" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "rclass": "remote",
    "packageType": "npm",
    "url": "https://registry.npmjs.org/",
    "description": "NPM registry proxy",
    "notes": "Proxy to public NPM registry",
    "includesPattern": "**/*",
    "excludesPattern": "",
    "repoLayoutRef": "npm-default",
    "offline": false,
    "hardFail": false,
    "storeArtifactsLocally": true,
    "socketTimeoutMillis": 15000,
    "retrievalCachePeriodSecs": 7200,
    "missedRetrievalCachePeriodSecs": 10800,
    "unusedArtifactsCleanupEnabled": true,
    "unusedArtifactsCleanupPeriodHours": 168,
    "blackedOut": false,
    "xrayConfig": {
      "enabled": true,
      "allowDownloadsXrayUnavailable": true,
      "allowBlockedArtifactsDownload": false
    }
  }'
```

### **Repository Layout Configuration**

```json
{
  "name": "microservice-layout",
  "artifactPathPattern": "[orgPath]/[module]/[baseRev](-[folderItegRev])/[module]-[baseRev](-[fileItegRev])(-[classifier]).[ext]",
  "distinctiveDescriptorPathPattern": true,
  "descriptorPathPattern": "[orgPath]/[module]/[baseRev](-[folderItegRev])/[module]-[baseRev](-[fileItegRev])(-[classifier]).pom",
  "folderIntegrationRevisionRegExp": "SNAPSHOT",
  "fileIntegrationRevisionRegExp": "SNAPSHOT|(?:(?:[0-9]{8}.[0-9]{6})-(?:[0-9]+))"
}
```

### **Repository Properties Configuration**

```yaml
# Custom properties for microservice artifacts
Property Sets:
  microservice-properties:
    - component: [frontend, backend, database]
    - environment: [dev, staging, prod]
    - version: [semantic version]
    - build_number: [CI build number]
    - git_commit: [Git commit hash]
    - build_timestamp: [ISO timestamp]
    - security_scan: [passed, failed, pending]
    - test_results: [passed, failed, skipped]
    - deployment_status: [pending, deployed, failed]
```

## 🔐 Security Configuration

### **User Management Configuration**

#### **Create Users via REST API**

```bash
# Create DevOps user
curl -X POST "${ARTIFACTORY_URL}/api/security/users/devops-user" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "devops-user",
    "email": "devops@company.com",
    "password": "secure_password_123",
    "admin": false,
    "profileUpdatable": true,
    "disableUIAccess": false,
    "internalPasswordDisabled": false,
    "groups": ["devops-group", "docker-users"]
  }'

# Create CI/CD service account
curl -X POST "${ARTIFACTORY_URL}/api/security/users/jenkins-service" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "jenkins-service",
    "email": "jenkins@company.com", 
    "password": "jenkins_secure_password",
    "admin": false,
    "profileUpdatable": false,
    "disableUIAccess": true,
    "internalPasswordDisabled": false,
    "groups": ["ci-cd-group"]
  }'

# Create readonly user for monitoring
curl -X POST "${ARTIFACTORY_URL}/api/security/users/monitor-user" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "monitor-user",
    "email": "monitor@company.com",
    "password": "monitor_password",
    "admin": false,
    "profileUpdatable": false,
    "disableUIAccess": true,
    "internalPasswordDisabled": false,
    "groups": ["monitoring-group"]
  }'
```

#### **Group Management Configuration**

```bash
# Create DevOps group
curl -X POST "${ARTIFACTORY_URL}/api/security/groups/devops-group" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "devops-group",
    "description": "DevOps team with deployment permissions",
    "autoJoin": false,
    "adminPrivileges": false,
    "realm": "internal",
    "realmAttributes": ""
  }'

# Create CI/CD group
curl -X POST "${ARTIFACTORY_URL}/api/security/groups/ci-cd-group" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "ci-cd-group", 
    "description": "CI/CD systems with automated deployment permissions",
    "autoJoin": false,
    "adminPrivileges": false,
    "realm": "internal"
  }'

# Create developers group
curl -X POST "${ARTIFACTORY_URL}/api/security/groups/developers-group" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "developers-group",
    "description": "Development team with read access",
    "autoJoin": false,
    "adminPrivileges": false,
    "realm": "internal"
  }'
```

### **Permission Configuration**

```bash
# DevOps permissions
curl -X POST "${ARTIFACTORY_URL}/api/v2/security/permissions/devops-permissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "devops-permissions",
    "repo": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["ANY LOCAL", "ANY REMOTE"],
      "actions": {
        "groups": {
          "devops-group": ["read", "write", "annotate", "delete", "manage", "managedXrayMeta", "distribute"]
        }
      }
    },
    "build": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["artifactory-build-info"],
      "actions": {
        "groups": {
          "devops-group": ["read", "write", "delete", "manage"]
        }
      }
    }
  }'

# CI/CD permissions
curl -X POST "${ARTIFACTORY_URL}/api/v2/security/permissions/cicd-permissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "cicd-permissions",
    "repo": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": [
        "docker-local-dev",
        "docker-local-staging", 
        "docker-local-prod",
        "generic-local-dev",
        "generic-local-staging",
        "generic-local-prod",
        "npm-local",
        "pypi-local"
      ],
      "actions": {
        "groups": {
          "ci-cd-group": ["read", "write", "annotate", "delete"]
        }
      }
    },
    "build": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["artifactory-build-info"],
      "actions": {
        "groups": {
          "ci-cd-group": ["read", "write", "delete"]
        }
      }
    }
  }'

# Developer permissions (read-only)
curl -X POST "${ARTIFACTORY_URL}/api/v2/security/permissions/developer-permissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "name": "developer-permissions",
    "repo": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["ANY"],
      "actions": {
        "groups": {
          "developers-group": ["read"]
        }
      }
    },
    "build": {
      "include-patterns": ["**"],
      "exclude-patterns": [],
      "repositories": ["artifactory-build-info"],
      "actions": {
        "groups": {
          "developers-group": ["read"]
        }
      }
    }
  }'
```

### **API Key Configuration**

```bash
# Generate API key for automation
curl -X POST "${ARTIFACTORY_URL}/api/security/apiKey" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -u admin:password

# Create scoped tokens
curl -X POST "${ARTIFACTORY_URL}/api/security/token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{
    "scope": "applied-permissions/user",
    "username": "jenkins-service",
    "expires_in": 31536000,
    "refreshable": true,
    "audience": "*/artifactory"
  }'
```

### **LDAP Integration Configuration**

```yaml
# LDAP Configuration in system.yaml
access:
  ldap:
    enabled: true
    url: "ldap://company-ldap.internal:389"
    search:
      searchFilter: "(uid={0})"
      searchBase: "ou=people,dc=company,dc=com"
      managerDn: "cn=artifactory,ou=services,dc=company,dc=com"
      managerPassword: "${LDAP_BIND_PASSWORD}"
    userDnPattern: "uid={0},ou=people,dc=company,dc=com"
    emailAttribute: "mail"
    autoCreateUser: true
    
# LDAP Group Mapping
ldapGroupSettings:
  - name: "developers"
    groupBaseDn: "ou=groups,dc=company,dc=com"
    groupNameAttribute: "cn"
    groupMemberAttribute: "memberUid"
    filter: "(objectClass=posixGroup)"
    descriptionAttribute: "description"
    strategy: "STATIC"
```

## 🔗 Integration Configuration

### **Jenkins Integration**

#### **Artifactory Plugin Configuration**

```groovy
// Jenkins Global Tool Configuration
def artifactoryServer = [
    serverId: 'artifactory-server',
    url: 'http://artifactory.company.com/artifactory',
    credentialsId: 'artifactory-credentials',
    bypassProxy: false,
    timeout: 300,
    retry: 3
]

// Pipeline Configuration
pipeline {
    agent any
    
    environment {
        ARTIFACTORY_SERVER = 'artifactory-server'
        DOCKER_REGISTRY = 'artifactory.company.com:5000'
    }
    
    stages {
        stage('Configure Artifactory') {
            steps {
                script {
                    def server = Artifactory.server env.ARTIFACTORY_SERVER
                    def rtMaven = Artifactory.newMavenBuild()
                    def rtDocker = Artifactory.docker server: server
                    def buildInfo = Artifactory.newBuildInfo()
                    
                    // Configure Maven build
                    rtMaven.tool = 'Maven-3.8'
                    rtMaven.deployer releaseRepo: 'libs-release-local', snapshotRepo: 'libs-snapshot-local', server: server
                    rtMaven.resolver releaseRepo: 'libs-release', snapshotRepo: 'libs-snapshot', server: server
                    
                    // Set build info
                    buildInfo.env.capture = true
                    buildInfo.env.filter.addInclude("*")
                    buildInfo.name = 'microservice-admin-app'
                    buildInfo.number = env.BUILD_NUMBER
                }
            }
        }
    }
}
```

#### **Docker Registry Configuration**

```yaml
# Docker daemon configuration for Artifactory registry
# /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://artifactory.company.com/artifactory/docker-virtual"
  ],
  "insecure-registries": [
    "artifactory.company.com:5000",
    "artifactory.company.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
```

### **JFrog CLI Configuration**

```yaml
# ~/.jfrog/jfrog-cli.conf.v6
{
  "servers": [
    {
      "serverId": "artifactory-server",
      "url": "https://artifactory.company.com/artifactory",
      "artifactoryUrl": "https://artifactory.company.com/artifactory", 
      "distributionUrl": "https://artifactory.company.com/distribution",
      "xrayUrl": "https://artifactory.company.com/xray",
      "missionControlUrl": "https://artifactory.company.com/mc",
      "pipelinesUrl": "https://artifactory.company.com/pipelines",
      "user": "service-account",
      "password": "encrypted-password",
      "accessToken": "access-token",
      "refreshToken": "refresh-token",
      "clientCertPath": "/path/to/client.crt",
      "clientCertKeyPath": "/path/to/client.key",
      "sshKeyPath": "/path/to/ssh.key",
      "sshPassphrase": "ssh-passphrase"
    }
  ],
  "version": "2"
}
```

### **Build Tool Integration**

#### **Maven Configuration**

```xml
<!-- ~/.m2/settings.xml -->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
          
  <servers>
    <server>
      <id>artifactory-server</id>
      <username>${artifactory.username}</username>
      <password>${artifactory.password}</password>
    </server>
    <server>
      <id>artifactory-snapshots</id>
      <username>${artifactory.username}</username>
      <password>${artifactory.password}</password>
    </server>
  </servers>
  
  <mirrors>
    <mirror>
      <id>artifactory-mirror</id>
      <mirrorOf>*</mirrorOf>
      <name>Artifactory Maven Repository</name>
      <url>https://artifactory.company.com/artifactory/libs-release</url>
    </mirror>
  </mirrors>
  
  <profiles>
    <profile>
      <id>artifactory</id>
      <repositories>
        <repository>
          <id>artifactory-server</id>
          <name>Artifactory Release Repository</name>
          <url>https://artifactory.company.com/artifactory/libs-release</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
        <repository>
          <id>artifactory-snapshots</id>
          <name>Artifactory Snapshot Repository</name>
          <url>https://artifactory.company.com/artifactory/libs-snapshot</url>
          <releases>
            <enabled>false</enabled>
          </releases>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>artifactory-server</id>
          <name>Artifactory Plugin Repository</name>
          <url>https://artifactory.company.com/artifactory/plugins-release</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>artifactory</activeProfile>
  </activeProfiles>
</settings>
```

#### **NPM Configuration**

```bash
# Configure NPM to use Artifactory
npm config set registry https://artifactory.company.com/artifactory/api/npm/npm-virtual/
npm config set always-auth true
npm config set //artifactory.company.com/artifactory/api/npm/npm-virtual/:_password $(echo -n "password" | base64)
npm config set //artifactory.company.com/artifactory/api/npm/npm-virtual/:username "username"
npm config set //artifactory.company.com/artifactory/api/npm/npm-virtual/:email "email@company.com"

# .npmrc file content
registry=https://artifactory.company.com/artifactory/api/npm/npm-virtual/
//artifactory.company.com/artifactory/api/npm/npm-virtual/:_password=base64-encoded-password
//artifactory.company.com/artifactory/api/npm/npm-virtual/:username=username
//artifactory.company.com/artifactory/api/npm/npm-virtual/:email=email@company.com
//artifactory.company.com/artifactory/api/npm/npm-virtual/:always-auth=true
```

#### **Docker Build Configuration**

```dockerfile
# Dockerfile with Artifactory registry
FROM artifactory.company.com/docker-virtual/node:16-alpine AS frontend-builder

# Set npm registry
RUN npm config set registry https://artifactory.company.com/artifactory/api/npm/npm-virtual/

# Copy package files
COPY frontend/package*.json ./
RUN npm ci --only=production

# Build stage
FROM artifactory.company.com/docker-virtual/python:3.9-slim AS backend

# Install Python packages from Artifactory PyPI
RUN pip config set global.index-url https://artifactory.company.com/artifactory/api/pypi/pypi-virtual/simple
RUN pip config set global.trusted-host artifactory.company.com

COPY backend/requirements.txt .
RUN pip install -r requirements.txt

# Final stage
FROM artifactory.company.com/docker-virtual/nginx:alpine
COPY --from=frontend-builder /app/dist /usr/share/nginx/html
COPY --from=backend /app /app

LABEL maintainer="devops@company.com"
LABEL version="${BUILD_VERSION}"
LABEL commit="${GIT_COMMIT}"
```

## 🚀 Performance Configuration

### **JVM Performance Tuning**

```bash
# High-performance JVM settings
export JAVA_OPTIONS="-server \
    -Xms8g \
    -Xmx16g \
    -Xss256k \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=100 \
    -XX:G1HeapRegionSize=32m \
    -XX:G1ReservePercent=20 \
    -XX:InitiatingHeapOccupancyPercent=25 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+UseCGroupMemoryLimitForHeap \
    -XX:+UseStringDeduplication \
    -XX:+OptimizeStringConcat \
    -Djava.awt.headless=true \
    -Djava.security.egd=file:/dev/./urandom \
    -Dfile.encoding=UTF8 \
    -Dartifactory.async.corePoolSize=32 \
    -Dartifactory.async.maxPoolSize=256 \
    -Dartifactory.async.queueCapacity=1000"

# Database connection pool tuning
export JAVA_OPTIONS="$JAVA_OPTIONS \
    -Dartifactory.pool.maxActive=100 \
    -Dartifactory.pool.maxIdle=25 \
    -Dartifactory.pool.minIdle=5 \
    -Dartifactory.pool.initialSize=10"
```

### **Database Performance Configuration**

#### **PostgreSQL Configuration**

```sql
-- postgresql.conf optimizations
shared_buffers = '4GB'
effective_cache_size = '12GB'
maintenance_work_mem = '1GB'
checkpoint_completion_target = 0.7
wal_buffers = '16MB'
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = '64MB'
min_wal_size = '1GB'
max_wal_size = '4GB'
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8

# Connection settings
max_connections = 200
shared_preload_libraries = 'pg_stat_statements'

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

### **Caching Configuration**

```yaml
# Redis configuration for Artifactory
# /etc/redis/redis.conf
maxmemory 8gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename artifactory.rdb
dir /var/lib/redis
timeout 300
keepalive 300
tcp-backlog 511
databases 16

# Network
bind 127.0.0.1
port 6379
tcp-keepalive 60

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log
```

### **Nginx Reverse Proxy Configuration**

```nginx
# /etc/nginx/sites-available/artifactory
upstream artifactory {
    server 127.0.0.1:8081 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8082 max_fails=3 fail_timeout=30s backup;
}

upstream artifactory-ui {
    server 127.0.0.1:8082 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name artifactory.company.com;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/artifactory.crt;
    ssl_certificate_key /etc/nginx/ssl/artifactory.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Performance settings
    client_max_body_size 1G;
    client_body_buffer_size 128k;
    client_header_buffer_size 4k;
    large_client_header_buffers 4 16k;
    
    # Timeouts
    proxy_connect_timeout 90s;
    proxy_send_timeout 90s;
    proxy_read_timeout 90s;
    send_timeout 90s;
    
    # Compression
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
    
    # Docker registry
    location ~ ^/(v1|v2)/ {
        proxy_pass http://artifactory;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
        
        # Docker specific
        proxy_set_header Docker-Content-Digest $upstream_http_docker_content_digest;
        proxy_set_header Docker-Distribution-API-Version $upstream_http_docker_distribution_api_version;
    }
    
    # Artifactory API
    location /artifactory/ {
        proxy_pass http://artifactory;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_request_buffering off;
        
        # Buffer settings
        proxy_buffering off;
        proxy_buffer_size 128k;
        proxy_buffers 100 128k;
        proxy_busy_buffers_size 256k;
        proxy_temp_file_write_size 256k;
    }
    
    # UI
    location /ui/ {
        proxy_pass http://artifactory-ui;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket support for UI
    location /ui/websocket {
        proxy_pass http://artifactory-ui;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## 💾 Backup Configuration

### **Automated Backup Strategy**

```bash
#!/bin/bash
# /opt/artifactory/scripts/backup.sh

BACKUP_DIR="/backup/artifactory"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

# Backup system configuration
echo "Backing up system configuration..."
cp -r /var/opt/jfrog/artifactory/etc "$BACKUP_DIR/$DATE/"

# Backup database
echo "Backing up database..."
pg_dump -h localhost -U artifactory -d artifactory | gzip > "$BACKUP_DIR/$DATE/database_backup.sql.gz"

# Backup filestore (if using filesystem storage)
echo "Backing up filestore..."
tar -czf "$BACKUP_DIR/$DATE/filestore_backup.tar.gz" /var/opt/jfrog/artifactory/data/filestore/

# Backup repository configurations
echo "Backing up repository configurations..."
curl -u admin:password "http://localhost:8081/artifactory/api/repositories" > "$BACKUP_DIR/$DATE/repositories.json"

# Backup user and group configurations
echo "Backing up security configurations..."
curl -u admin:password "http://localhost:8081/artifactory/api/security/users" > "$BACKUP_DIR/$DATE/users.json"
curl -u admin:password "http://localhost:8081/artifactory/api/security/groups" > "$BACKUP_DIR/$DATE/groups.json"

# Cleanup old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "Backup completed: $BACKUP_DIR/$DATE"
```

### **Backup Cron Configuration**

```bash
# /etc/cron.d/artifactory-backup
# Daily backup at 2 AM
0 2 * * * root /opt/artifactory/scripts/backup.sh >> /var/log/artifactory-backup.log 2>&1

# Weekly full backup on Sunday at 1 AM
0 1 * * 0 root /opt/artifactory/scripts/full-backup.sh >> /var/log/artifactory-backup.log 2>&1
```

## 📊 Monitoring Configuration

### **Prometheus Metrics Configuration**

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'artifactory'
    static_configs:
      - targets: ['localhost:8081']
    metrics_path: '/artifactory/api/v1/metrics'
    basic_auth:
      username: 'prometheus-user'
      password: 'prometheus-password'
    scrape_interval: 30s
    
  - job_name: 'artifactory-system'
    static_configs:
      - targets: ['localhost:8081']
    metrics_path: '/artifactory/api/system/info'
    basic_auth:
      username: 'prometheus-user'
      password: 'prometheus-password'
    scrape_interval: 60s
```

### **Grafana Dashboard Configuration**

```json
{
  "dashboard": {
    "title": "Artifactory Monitoring Dashboard",
    "panels": [
      {
        "title": "Storage Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "artifactory_storage_used_bytes"
          }
        ]
      },
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(artifactory_http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph", 
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(artifactory_http_request_duration_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Active Users",
        "type": "stat",
        "targets": [
          {
            "expr": "artifactory_active_users"
          }
        ]
      }
    ]
  }
}
```

### **Logging Configuration**

```xml
<!-- /var/opt/jfrog/artifactory/etc/logback.xml -->
<configuration debug="false">
    <contextName>artifactory</contextName>
    
    <!-- Console appender -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder">
            <layout class="org.jfrog.common.logging.logback.layout.BacktracePatternLayout">
                <pattern>%date{ISO8601} [%level] [%thread] [%logger{32}:%line] - %message%n</pattern>
            </layout>
        </encoder>
    </appender>
    
    <!-- File appender -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${artifactory.logs.dir}/artifactory.log</File>
        <encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder">
            <layout class="org.jfrog.common.logging.logback.layout.BacktracePatternLayout">
                <pattern>%date{ISO8601} [%level] [%thread] [%logger{32}:%line] - %message%n</pattern>
            </layout>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy">
            <FileNamePattern>${artifactory.logs.dir}/artifactory.%i.log.gz</FileNamePattern>
            <maxIndex>13</maxIndex>
        </rollingPolicy>
        <triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
            <MaxFileSize>25MB</MaxFileSize>
        </triggeringPolicy>
    </appender>
    
    <!-- Access log -->
    <appender name="ACCESS" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <File>${artifactory.logs.dir}/access.log</File>
        <encoder>
            <pattern>%date{ISO8601}|%X{clientAddress}|%X{username}|%X{method}|%X{path}|%X{protocol}|%X{responseCode}|%X{contentLength}|%X{duration}</pattern>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${artifactory.logs.dir}/access.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>25MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
    </appender>
    
    <!-- Logger configurations -->
    <logger name="org.artifactory" level="INFO"/>
    <logger name="org.jfrog.access" level="INFO"/>
    <logger name="org.springframework" level="WARN"/>
    <logger name="org.apache" level="WARN"/>
    
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="FILE"/>
    </root>
    
    <logger name="org.artifactory.traffic" level="INFO" additivity="false">
        <appender-ref ref="ACCESS"/>
    </logger>
</configuration>
```

## 🌍 Environment-Specific Configurations

### **Development Environment**

```yaml
# development.yaml
shared:
  database:
    type: derby
    url: "jdbc:derby:${artifactory.home}/data/derby;create=true"
    
  security:
    passwordSettings:
      encryptionPolicy: "supported"
      
router:
  entrypoints:
    internalPort: 8082
    externalPort: 80
    
# Relaxed security for development
access:
  security:
    passwordSettings:
      expirationDays: 0
      resetPolicy: "permissive"
```

### **Staging Environment**

```yaml  
# staging.yaml
shared:
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: "jdbc:postgresql://staging-db:5432/artifactory"
    username: "${DB_USERNAME}"
    password: "${DB_PASSWORD}"
    maxOpenConnections: 50
    
  security:
    passwordSettings:
      encryptionPolicy: "required"
      
router:
  entrypoints:
    internalPort: 8082
    internalPortTls: 8443
    externalPort: 80
    externalPortTls: 443
    
# Moderate security for staging
access:
  security:
    passwordSettings:
      expirationDays: 90
      resetPolicy: "moderate"
```

### **Production Environment**

```yaml
# production.yaml
shared:
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: "jdbc:postgresql://prod-db-cluster:5432/artifactory"
    username: "${DB_USERNAME}"
    password: "${DB_PASSWORD}"
    maxOpenConnections: 100
    
  security:
    passwordSettings:
      encryptionPolicy: "required"
      
  extraJavaOpts: "-Xms8g -Xmx16g -XX:+UseG1GC"
  
router:
  entrypoints:
    internalPort: 8082
    internalPortTls: 8443
    externalPort: 80
    externalPortTls: 443
    
  tlsConfig:
    cert: "/var/opt/jfrog/artifactory/etc/ssl/prod.crt"
    key: "/var/opt/jfrog/artifactory/etc/ssl/prod.key"

# Strict security for production    
access:
  security:
    passwordSettings:
      expirationDays: 60
      resetPolicy: "strict"
  ldap:
    enabled: true
```

## 🐛 Troubleshooting Configuration

### **Debug Configuration**

```yaml
# debug.yaml - Enable debug logging
shared:
  logging:
    consoleLog:
      enabled: true
    applicationLog:
      enabled: true
      level: DEBUG
    accessLog:
      enabled: true
    requestLog:
      enabled: true
      
# Specific logger levels for troubleshooting
loggers:
  org.artifactory: DEBUG
  org.jfrog.access: DEBUG
  org.springframework.security: DEBUG
  org.apache.http: INFO
  ROOT: INFO
```

### **Health Check Configuration**

```bash
#!/bin/bash
# /opt/artifactory/scripts/health-check.sh

ARTIFACTORY_URL="http://localhost:8081/artifactory"
API_KEY="${ARTIFACTORY_API_KEY}"

# System ping
echo "Checking system health..."
curl -f -s "${ARTIFACTORY_URL}/api/system/ping" || exit 1

# Database connectivity
echo "Checking database connectivity..."
curl -f -s -H "Authorization: Bearer ${API_KEY}" "${ARTIFACTORY_URL}/api/storageinfo" > /dev/null || exit 1

# License check (for Pro/Enterprise)
echo "Checking license status..."
curl -f -s -H "Authorization: Bearer ${API_KEY}" "${ARTIFACTORY_URL}/api/system/licenses" > /dev/null || exit 1

# Repository accessibility
echo "Checking repository accessibility..."
curl -f -s -H "Authorization: Bearer ${API_KEY}" "${ARTIFACTORY_URL}/api/repositories" > /dev/null || exit 1

echo "All health checks passed!"
```

---

**Last Updated**: October 2, 2025  
**Version**: 1.0.0  
**Maintainer**: Configuration Team
