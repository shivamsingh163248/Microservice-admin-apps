# Jenkins Configuration Guide for Microservice Admin App

## 📋 Table of Contents
- [Plugin Configuration](#plugin-configuration)
- [Security Configuration](#security-configuration)
- [Tool Integration](#tool-integration)
- [Notification Setup](#notification-setup)
- [Monitoring Configuration](#monitoring-configuration)
- [Backup and Maintenance](#backup-and-maintenance)
- [Performance Tuning](#performance-tuning)
- [Environment Variables](#environment-variables)
- [Webhook Configuration](#webhook-configuration)
- [Advanced Settings](#advanced-settings)

## 🔌 Plugin Configuration

### Essential Plugins Detailed Setup

#### 1. Git Plugin Configuration
```text
Navigate: Manage Jenkins → Configure System → Git

Global Config:
  Name: Jenkins User
  Email: jenkins@yourcompany.com

Additional Behaviors:
  - Clean before checkout
  - Checkout to specific local branch
  - Advanced clone behaviors
    - Honor refspec on initial clone: true
    - Shallow clone: false
    - Clone timeout: 10 minutes
```

#### 2. GitHub Plugin Configuration
```text
Navigate: Manage Jenkins → Configure System → GitHub

GitHub Servers:
  Name: GitHub.com
  API URL: https://api.github.com
  Credentials: github-token
  
  Advanced Settings:
    - Manage hooks: true
    - Override hook URL: false
    - Convert login to lowercase: false
    - Cache connection: true
    - Client cache size: 20
```

#### 3. Docker Plugin Configuration
```text
Navigate: Manage Jenkins → Configure System → Docker

Docker Cloud:
  Name: docker-local
  Docker Host URI: unix:///var/run/docker.sock
  Enabled: true
  
  Docker Agent Templates:
    Labels: docker-agent
    Docker Image: jenkins/ssh-agent:latest
    Instance Capacity: 10
    Remote Filing System Root: /home/jenkins
    
    Connect Method: Connect with SSH
    SSH Key: Use configured SSH credentials
    
    Container Settings:
      Memory Limit: 1GB
      CPU Limit: 1.0
      Network: bridge
```

#### 4. Pipeline Plugin Configuration
```text
Navigate: Manage Jenkins → Configure System → Pipeline

Global Pipeline Libraries:
  Name: shared-library
  Default version: main
  Retrieval method: Modern SCM
  Source Code Management: Git
    Repository URL: https://github.com/your-org/jenkins-shared-library.git
    Credentials: github-credentials
    
  Library Behavior:
    - Allow default version to be overridden: true
    - Include @Library changes in job recent changes: true
```

#### 5. Blue Ocean Configuration
```text
Navigate: Blue Ocean → Settings

GitHub Integration:
  Connect to GitHub: github-credentials
  Organization: shivamsingh163248
  
Appearance:
  Theme: Dark (optional)
  Language: English
  
Pipeline Creation:
  Default SCM: GitHub
  Default Organization: shivamsingh163248
```

#### 6. Ansible Plugin Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → Ansible

Ansible Installations:
  Name: Ansible-Latest
  Path to ansible executables directory: /usr/bin/
  
  Installation Method: Install automatically
  Version: Latest
  
SSH Connection:
  SSH Key: ssh-private-key
  Disable host SSH key check: true
  Unbuffered output: true
```

#### 7. Kubernetes Plugin Configuration
```text
Navigate: Manage Jenkins → Configure System → Cloud → Kubernetes

Kubernetes Cloud:
  Name: kubernetes
  Kubernetes URL: https://kubernetes.default.svc.cluster.local
  Kubernetes Namespace: jenkins
  
  Credentials: kubeconfig
  
  Connection Test: ✅ Should show "Connected to Kubernetes"
  
Pod Templates:
  Name: jenkins-agent
  Namespace: jenkins
  Labels: kubernetes-agent
  
  Containers:
    - Name: jnlp
      Docker Image: jenkins/inbound-agent:latest
      Command to run: <empty>
      Arguments to pass: <empty>
      
    - Name: docker
      Docker Image: docker:dind
      Command to run: dockerd-entrypoint.sh
      Arguments to pass: <empty>
      Privileged: true
```

#### 8. Terraform Plugin Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → Terraform

Terraform Installations:
  Name: Terraform-Latest
  Installation Method: Install automatically
  Version: 1.5.0
  
  Installation Directory: /usr/local/bin
  
Environment Variables:
  TF_LOG: INFO
  TF_CLI_ARGS: -no-color
```

#### 9. SonarQube Scanner Configuration
```text
Navigate: Manage Jenkins → Configure System → SonarQube servers

SonarQube Installations:
  Name: SonarQube-Server
  Server URL: https://sonarcloud.io
  Server authentication token: sonarqube-token
  
Quality Gates:
  Enable webhooks: true
  Webhook URL: http://jenkins-url/sonarqube-webhook/
```

#### 10. Artifactory Plugin Configuration
```text
Navigate: Manage Jenkins → Configure System → JFrog

Artifactory Servers:
  Server ID: artifactory-server
  URL: https://yourcompany.jfrog.io/artifactory
  Credentials: artifactory-credentials
  
  Connection Test: ✅ Should show "Found JFrog Artifactory"
  
  Deployment:
    Default Deployer Credentials: artifactory-credentials
    Timeout: 300 seconds
    
  Resolution:
    Default Resolver Credentials: artifactory-credentials
    Repository for resolution: libs-release
```

### Notification Plugins Configuration

#### 1. Email Extension Plugin
```text
Navigate: Manage Jenkins → Configure System → Extended E-mail Notification

SMTP Server: smtp.gmail.com
SMTP Port: 587
Username: jenkins@yourcompany.com
Password: app-specific-password
Use SSL: false
Use TLS: true

Default Recipients: $DEFAULT_RECIPIENTS
Default Subject: $PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!
Default Content: 
$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:

Check console output at $BUILD_URL to view the results.

Changes:
$CHANGES

Failed Tests:
$FAILED_TESTS

Advanced Settings:
  Default Triggers:
    - Failure - Any
    - Unstable - Any  
    - Success
    - Fixed
```

#### 2. Slack Notification Plugin
```text
Navigate: Manage Jenkins → Configure System → Slack

Workspace: yourcompany
Credential: slack-token
Default channel: #jenkins
Custom message: 
🚀 *$JOB_NAME* - Build #$BUILD_NUMBER
📋 Status: $BUILD_STATUS
🔗 <$BUILD_URL|View Build>
👤 Started by: $BUILD_USER
⏱️ Duration: $BUILD_DURATION

Test Connection: ✅ Should show "Success"
```

#### 3. Microsoft Teams Plugin
```text
Navigate: Manage Jenkins → Configure System → Microsoft Teams

Webhook URL: https://outlook.office.com/webhook/your-webhook-url
Macro Template:
**$JOB_NAME** - Build #$BUILD_NUMBER
**Status:** $BUILD_STATUS  
**Started by:** $BUILD_USER
**Duration:** $BUILD_DURATION
[View Build]($BUILD_URL)

Notify Success: true
Notify Failure: true
Notify Unstable: true
Notify Back To Normal: true
```

## 🔐 Security Configuration

### 1. Authentication Configuration

#### LDAP Integration
```text
Navigate: Manage Jenkins → Configure Global Security → Security Realm

Security Realm: LDAP

LDAP Settings:
  Server: ldap://ldap.yourcompany.com:389
  Root DN: dc=yourcompany,dc=com
  User search base: ou=users
  User search filter: uid={0}
  Group search base: ou=groups
  Group search filter: cn={0}
  Group membership filter: (member={0})
  
  Manager DN: cn=jenkins,ou=service-accounts,dc=yourcompany,dc=com
  Manager Password: your-ldap-password
  
Advanced Settings:
  Display Name LDAP attribute: displayName
  Email Address LDAP attribute: mail
```

#### OAuth (GitHub) Configuration
```text
Navigate: Manage Jenkins → Configure Global Security → Security Realm

Security Realm: GitHub Authentication Plugin

GitHub Web URI: https://github.com
GitHub API URI: https://api.github.com
Client ID: your-github-oauth-app-client-id
Client Secret: your-github-oauth-app-secret

Advanced Settings:
  Scope: read:org,user:email
  Organizations: yourcompany
  Admin User Names: admin,jenkins-admin
```

### 2. Authorization Configuration

#### Role-Based Matrix Authorization
```text
Navigate: Manage Jenkins → Configure Global Security → Authorization

Authorization: Role-based Matrix Authorization Strategy

Global Roles:
  admin:
    - Overall/Administer
    - Agent/Build
    - Agent/Configure
    - Agent/Connect
    - Agent/Create
    - Agent/Delete
    - Agent/Disconnect
    - Credentials/Create
    - Credentials/Delete
    - Credentials/ManageDomains
    - Credentials/Update
    - Credentials/UseItem
    - Credentials/UseOwn
    - Job/Build
    - Job/Cancel
    - Job/Configure
    - Job/Create
    - Job/Delete
    - Job/Discover
    - Job/Move
    - Job/Read
    - Job/Workspace
    - Run/Delete
    - Run/Update
    - View/Configure
    - View/Create
    - View/Delete
    - View/Read
    - SCM/Tag
    
  developer:
    - Overall/Read
    - Job/Build
    - Job/Cancel
    - Job/Read
    - Job/Workspace
    - Run/Update
    - View/Read
    
  viewer:
    - Overall/Read
    - Job/Read
    - View/Read

Project Roles:
  project-admin (Pattern: microservice-.*):
    - Job/Build
    - Job/Cancel
    - Job/Configure
    - Job/Read
    - Job/Workspace
    - Run/Delete
    - Run/Update
    
  project-developer (Pattern: microservice-.*):
    - Job/Build
    - Job/Cancel
    - Job/Read
    - Job/Workspace
```

### 3. Security Hardening

#### Configure Content Security Policy
```text
Navigate: Manage Jenkins → Configure System → Markup Formatter

Markup Formatter: Safe HTML
Additional allowed elements: style
Additional allowed attributes: class,id,style

System Properties (Add to jenkins startup):
-Dhudson.model.DirectoryBrowserSupport.CSP="default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
```

#### Agent to Master Security
```text
Navigate: Manage Jenkins → Configure Global Security → Agents

Agent protocols:
  ✅ Inbound TCP Agent Protocol/4 (TLS encryption)
  ❌ Inbound TCP Agent Protocol/3 (deprecated)
  ❌ Inbound TCP Agent Protocol/2 (deprecated)
  ❌ Inbound TCP Agent Protocol/1 (deprecated)

Agent → Master Access Control:
  ✅ Enable Agent → Master Access Control
  
File Access Rules:
  allow java.io.File read,write,delete /var/jenkins_home/workspace/**
  allow java.io.File read /usr/bin/**
  allow java.io.File read /usr/local/bin/**
  deny java.io.File read,write,delete /etc/**
  deny java.io.File read,write,delete /var/**
  deny java.io.File read,write,delete /home/**
```

#### CSRF Protection
```text
Navigate: Manage Jenkins → Configure Global Security → CSRF Protection

✅ Enable CSRF Protection
Crumb Algorithm: Default Crumb Issuer
Advanced:
  ✅ Enable proxy compatibility
  ❌ Check session ID
```

## 🛠️ Tool Integration

### 1. Git Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → Git

Git Installations:
  Name: Default
  Path to Git executable: git
  
  Installation Method: Install automatically
  Version: Latest
  
Global Config Properties:
  Name: jenkins
  Email: jenkins@yourcompany.com
```

### 2. JDK Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → JDK

JDK Installations:
  Name: OpenJDK-11
  JAVA_HOME: /usr/lib/jvm/java-11-openjdk-amd64
  
  Installation Method: Install automatically
  Installer: Extract *.zip/*.tar.gz
  Download URL: https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.19%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.19_7.tar.gz
  Subdirectory: jdk-11.0.19+7
  
  Name: OpenJDK-17
  Installation Method: Install automatically
  Version: jdk-17.0.7+7
```

### 3. Node.js Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → NodeJS

NodeJS Installations:
  Name: NodeJS-18
  Installation Method: Install automatically from nodejs.org
  Version: NodeJS 18.17.0
  
  Global npm packages to install:
    - npm@latest
    - yarn@latest
    - typescript@latest
    - @angular/cli@latest
    - create-react-app@latest
    
  Name: NodeJS-16
  Version: NodeJS 16.20.1
  
  Name: NodeJS-Latest
  Version: Latest LTS
```

### 4. Maven Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → Maven

Maven Installations:
  Name: Maven-3.9
  Installation Method: Install automatically from Apache
  Version: 3.9.3
  
  Name: Maven-3.8
  Version: 3.8.8
```

### 5. Gradle Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → Gradle

Gradle Installations:
  Name: Gradle-8
  Installation Method: Install automatically from Gradle.org
  Version: 8.2.1
  
  Name: Gradle-7
  Version: 7.6.2
```

### 6. Docker Configuration
```text
Navigate: Manage Jenkins → Global Tool Configuration → Docker

Docker Installations:
  Name: Docker-Latest
  Installation Method: Install automatically from docker.com
  
  Download URL for binary archive: https://download.docker.com/linux/static/stable/x86_64/docker-24.0.5.tgz
  Subdirectory of extracted archive: docker
```

## 📊 Monitoring Configuration

### 1. Build Monitoring
```text
Navigate: Manage Jenkins → Configure System → System Information

System Properties to Monitor:
  - java.version
  - java.vm.name
  - java.vm.info
  - os.name
  - os.version
  - user.timezone
  - file.encoding
  - java.class.path
  - jenkins.version
  - hudson.node.monitors.Architecture$DescriptorImpl.monitoring
  - hudson.node.monitors.Clock$DescriptorImpl.monitoring
  - hudson.node.monitors.DiskSpaceMonitor$DescriptorImpl.monitoring
  - hudson.node.monitors.ResponseTimeMonitor$DescriptorImpl.monitoring
  - hudson.node.monitors.SwapSpaceMonitor$DescriptorImpl.monitoring
  - hudson.node.monitors.TemporarySpaceMonitor$DescriptorImpl.monitoring
```

### 2. Node Monitoring
```text
Navigate: Manage Jenkins → Manage Nodes and Clouds → Configure Clouds

Node Monitors:
  Architecture: ✅
  Clock Difference: ✅ (Threshold: 5000ms)
  Disk Space: ✅ (Free Space Threshold: 1GB)
  Response Time: ✅ (Threshold: 5000ms)
  Swap Space: ✅ (Free Space Threshold: 1GB)
  Temporary Space: ✅ (Free Space Threshold: 1GB)
```

### 3. Log Configuration
```text
Navigate: Manage Jenkins → System Log → All Jenkins Logs

Loggers to Configure:
  - hudson.model.Run (Level: INFO)
  - hudson.model.Job (Level: INFO)
  - hudson.plugins.git.GitSCM (Level: INFO)
  - org.jenkinsci.plugins.workflow (Level: INFO)
  - hudson.slaves.SlaveComputer (Level: INFO)
  - hudson.model.Computer (Level: INFO)
  - jenkins.security (Level: WARNING)
  - hudson.security (Level: WARNING)
  - org.springframework.security (Level: WARNING)

Log Recorders:
  Name: Git-Operations
  Loggers:
    - hudson.plugins.git (Level: FINE)
    - org.eclipse.jgit (Level: FINE)
    
  Name: Pipeline-Execution
  Loggers:
    - org.jenkinsci.plugins.workflow.cps (Level: FINE)
    - org.jenkinsci.plugins.workflow.job (Level: FINE)
    - org.jenkinsci.plugins.workflow.steps (Level: FINE)
```

### 4. Performance Monitoring
```text
Jenkins Performance Monitoring Setup:

System Properties:
  -Dcom.sun.management.jmxremote=true
  -Dcom.sun.management.jmxremote.port=9999
  -Dcom.sun.management.jmxremote.authenticate=false
  -Dcom.sun.management.jmxremote.ssl=false
  -Djava.rmi.server.hostname=your-jenkins-host

Metrics to Monitor:
  JVM Metrics:
    - Memory usage (heap/non-heap)
    - Garbage collection frequency/duration
    - Thread count and deadlocks
    - CPU usage percentage
    
  Jenkins Metrics:
    - Queue length
    - Build duration trends
    - Success/failure rates
    - Active executors
    - Plugin performance
```

## 💾 Backup and Maintenance

### 1. Automated Backup Configuration
```bash
# Create backup script
cat > /usr/local/bin/jenkins-backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/var/backups/jenkins"
JENKINS_HOME="/var/jenkins_home"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Stop Jenkins (optional, for consistent backup)
# systemctl stop jenkins

# Create backup
tar -czf ${BACKUP_DIR}/jenkins-backup-${DATE}.tar.gz \
  --exclude="${JENKINS_HOME}/workspace/*" \
  --exclude="${JENKINS_HOME}/builds/*/workspace" \
  --exclude="${JENKINS_HOME}/logs/*" \
  --exclude="${JENKINS_HOME}/.gradle/*" \
  --exclude="${JENKINS_HOME}/.m2/repository/*" \
  ${JENKINS_HOME}

# Restart Jenkins
# systemctl start jenkins

# Upload to S3 (optional)
if command -v aws &> /dev/null; then
    aws s3 cp ${BACKUP_DIR}/jenkins-backup-${DATE}.tar.gz s3://your-backup-bucket/jenkins/
fi

# Cleanup old backups
find ${BACKUP_DIR} -name "jenkins-backup-*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: jenkins-backup-${DATE}.tar.gz"
EOF

chmod +x /usr/local/bin/jenkins-backup.sh
```

### 2. Backup Scheduling
```bash
# Add to crontab
cat > /etc/cron.d/jenkins-backup << 'EOF'
# Jenkins backup - daily at 2 AM
0 2 * * * jenkins /usr/local/bin/jenkins-backup.sh >> /var/log/jenkins-backup.log 2>&1

# Jenkins backup - weekly full backup on Sunday at 1 AM
0 1 * * 0 jenkins /usr/local/bin/jenkins-full-backup.sh >> /var/log/jenkins-backup.log 2>&1
EOF
```

### 3. Maintenance Scripts
```bash
# Cleanup old builds script
cat > /usr/local/bin/jenkins-cleanup.sh << 'EOF'
#!/bin/bash

JENKINS_HOME="/var/jenkins_home"
DAYS_TO_KEEP=30

# Clean workspace
find ${JENKINS_HOME}/workspace -name "*" -type d -mtime +${DAYS_TO_KEEP} -exec rm -rf {} + 2>/dev/null || true

# Clean build artifacts
find ${JENKINS_HOME}/jobs/*/builds -name "*" -type d -mtime +${DAYS_TO_KEEP} -exec rm -rf {} + 2>/dev/null || true

# Clean logs
find ${JENKINS_HOME}/logs -name "*.log" -mtime +${DAYS_TO_KEEP} -delete 2>/dev/null || true

# Clean temporary files
find /tmp -name "jenkins*" -mtime +1 -delete 2>/dev/null || true

echo "Cleanup completed for files older than ${DAYS_TO_KEEP} days"
EOF

chmod +x /usr/local/bin/jenkins-cleanup.sh

# Schedule cleanup weekly
echo "0 3 * * 0 jenkins /usr/local/bin/jenkins-cleanup.sh >> /var/log/jenkins-cleanup.log 2>&1" >> /etc/cron.d/jenkins-maintenance
```

## ⚡ Performance Tuning

### 1. JVM Optimization
```bash
# Jenkins JVM configuration
cat > /etc/default/jenkins << 'EOF'
# Java arguments for Jenkins
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true \
  -Xmx4g \
  -Xms2g \
  -XX:+UseG1GC \
  -XX:+DisableExplicitGC \
  -XX:+ParallelRefProcEnabled \
  -XX:+UseStringDeduplication \
  -XX:MaxGCPauseMillis=200 \
  -XX:G1HeapRegionSize=16m \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+UseCGroupMemoryLimitForHeap \
  -Dhudson.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';\" \
  -Djenkins.install.runSetupWizard=false \
  -Dpermissive-script-security.enabled=true"

# Additional system properties
JAVA_ARGS="-server \
  -Dfile.encoding=UTF-8 \
  -Dsun.jnu.encoding=UTF-8 \
  -Djava.net.preferIPv4Stack=true \
  -Djava.io.tmpdir=/var/cache/jenkins/tmp \
  -Dorg.apache.commons.jelly.tags.fmt.timeZone=America/New_York"
EOF
```

### 2. System Optimization
```bash
# System limits for Jenkins
cat > /etc/security/limits.d/jenkins.conf << 'EOF'
jenkins soft nofile 65536
jenkins hard nofile 65536
jenkins soft nproc 32768
jenkins hard nproc 32768
EOF

# Systemd service optimization
cat > /etc/systemd/system/jenkins.service.d/override.conf << 'EOF'
[Service]
LimitNOFILE=65536
LimitNPROC=32768
EOF

systemctl daemon-reload
systemctl restart jenkins
```

### 3. Build Optimization
```text
Navigate: Manage Jenkins → Configure System

Build Optimization Settings:
  # of executors: 2 (for master node, keep low)
  Quiet period: 5 seconds
  SCM checkout retry count: 3
  
Environment Variables:
  MAVEN_OPTS: -Xmx1g -XX:+TieredCompilation -XX:TieredStopAtLevel=1
  GRADLE_OPTS: -Xmx2g -XX:+HeapDumpOnOutOfMemoryError
  NODE_OPTIONS: --max-old-space-size=4096
  
Jenkins Location:
  Jenkins URL: https://jenkins.yourcompany.com/
  System Admin e-mail address: jenkins-admin@yourcompany.com
```

## 🌐 Environment Variables

### Global Environment Variables
```text
Navigate: Manage Jenkins → Configure System → Global properties

Environment variables:
  JAVA_HOME: /usr/lib/jvm/java-11-openjdk-amd64
  MAVEN_HOME: /usr/share/maven
  GRADLE_HOME: /opt/gradle/gradle-8.2.1
  NODE_HOME: /usr/local/node
  DOCKER_HOST: unix:///var/run/docker.sock
  
  # Application specific
  APP_NAME: microservice-admin-app
  DEFAULT_REGISTRY: ghcr.io/shivamsingh163248
  SONAR_HOST_URL: https://sonarcloud.io
  ARTIFACTORY_URL: https://yourcompany.jfrog.io/artifactory
  
  # Environment URLs
  DEV_URL: https://dev.yourapp.com
  STAGING_URL: https://staging.yourapp.com
  PROD_URL: https://yourapp.com
  
  # AWS Configuration
  AWS_DEFAULT_REGION: us-east-1
  AWS_DEFAULT_OUTPUT: json
  
  # Kubernetes Configuration
  KUBECONFIG: /var/jenkins_home/.kube/config
  KUBERNETES_NAMESPACE: default
```

### Pipeline-specific Variables
```groovy
// In Jenkinsfile - Environment section
pipeline {
    agent any
    environment {
        // Build Variables
        BUILD_VERSION = sh(
            script: "echo \${BUILD_NUMBER}",
            returnStdout: true
        ).trim()
        
        // Registry Configuration
        DOCKER_REGISTRY = "ghcr.io"
        DOCKER_NAMESPACE = "shivamsingh163248"
        
        // Application Configuration
        APP_NAME = "microservice-admin-app"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/nginx_frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/flask_backend"
        DATABASE_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/mysql_db"
        
        // Credentials
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_TOKEN = credentials('github-token')
        AWS_CREDENTIALS = credentials('aws-credentials')
        SONAR_TOKEN = credentials('sonarqube-token')
        
        // Environment Configuration
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : env.BRANCH_NAME == 'develop' ? 'staging' : 'development'}"
        DEPLOY_HOST = "${env.BRANCH_NAME == 'main' ? '54.234.122.255' : '10.0.1.100'}"
    }
}
```

## 🔗 Webhook Configuration

### GitHub Webhooks
```text
GitHub Repository Settings → Webhooks → Add webhook

Payload URL: https://jenkins.yourcompany.com/github-webhook/
Content type: application/json
Secret: [webhook-secret-token]

Events to trigger:
  ✅ Pushes
  ✅ Pull requests
  ✅ Branch or tag creation
  ✅ Branch or tag deletion
  ✅ Release published

Active: ✅
```

### Jenkins GitHub Webhook Configuration
```text
Navigate: Manage Jenkins → Configure System → GitHub

GitHub Hook Configuration:
  Override Hook URL: false
  Shared secrets: webhook-secret-token
  
Advanced:
  Additional actions: Re-register hooks for all jobs
  Admin list: admin,jenkins-admin
  Use cache: true
  Client cache size: 20
```

### Generic Webhook Configuration
```groovy
// In Jenkinsfile for generic webhooks
pipeline {
    agent any
    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'ref', value: '$.ref'],
                [key: 'repository', value: '$.repository.name'],
                [key: 'action', value: '$.action'],
                [key: 'pusher', value: '$.pusher.name']
            ],
            causeString: 'Triggered by $pusher on $repository',
            token: 'generic-webhook-token',
            tokenCredentialId: '',
            printContributedVariables: true,
            printPostContent: true,
            silentResponse: false,
            regexpFilterText: '$ref',
            regexpFilterExpression: 'refs/heads/(main|develop|feature/.*)'
        )
    }
    stages {
        stage('Process Webhook') {
            steps {
                script {
                    echo "Repository: ${repository}"
                    echo "Reference: ${ref}"
                    echo "Action: ${action}"
                    echo "Pusher: ${pusher}"
                }
            }
        }
    }
}
```

## 🔧 Advanced Settings

### Script Console Usage
```groovy
// Navigate: Manage Jenkins → Script Console

// Useful Groovy scripts for Jenkins administration

// 1. List all installed plugins
Jenkins.instance.pluginManager.plugins.each { plugin ->
    println("${plugin.getShortName()}: ${plugin.getVersion()}")
}

// 2. Update all job configurations
Jenkins.instance.getAllItems(Job.class).each { job ->
    if (job.getProperty(ParametersDefinitionProperty.class) != null) {
        println("Job: ${job.name}")
        job.getProperty(ParametersDefinitionProperty.class).parameterDefinitions.each { param ->
            println("  Parameter: ${param.name} = ${param.defaultParameterValue?.value}")
        }
    }
}

// 3. Clean up old builds
Jenkins.instance.getAllItems(Job.class).each { job ->
    println("Processing job: ${job.name}")
    job.getBuilds().each { build ->
        if (build.number < (job.getNextBuildNumber() - 50)) {
            println("  Deleting build #${build.number}")
            build.delete()
        }
    }
}

// 4. List all credentials
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*

def creds = CredentialsProvider.lookupCredentials(
    StandardUsernameCredentials.class,
    Jenkins.instance,
    null,
    null
)

creds.each { cred ->
    println("ID: ${cred.id}, Description: ${cred.description}, Username: ${cred.username}")
}

// 5. Set system properties
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';")
System.setProperty("jenkins.security.ApiTokenProperty.adminCanGenerateNewTokens", "true")
```

### Configuration as Code (JCasC)
```yaml
# jenkins.yaml - Configuration as Code
jenkins:
  systemMessage: "Jenkins configured automatically by Configuration as Code plugin"
  numExecutors: 2
  mode: NORMAL
  scmCheckoutRetryCount: 3
  labelString: "master"
  
  remotingSecurity:
    enabled: true
    
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "${JENKINS_ADMIN_PASSWORD}"
          
  authorizationStrategy:
    roleBased:
      roles:
        global:
          - name: "admin"
            description: "Jenkins administrators"
            permissions:
              - "Overall/Administer"
            assignments:
              - "admin"
          - name: "readonly"
            description: "Read-only users"
            permissions:
              - "Overall/Read"
              - "Job/Read"
            assignments:
              - "authenticated"

  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://kubernetes.default"
        namespace: "jenkins"
        jenkinsUrl: "http://jenkins:8080"
        podLabels:
          - key: "jenkins"
            value: "agent"

credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: "github-credentials"
              username: "${GITHUB_USERNAME}"
              password: "${GITHUB_TOKEN}"
              description: "GitHub Credentials"
          - string:
              scope: GLOBAL
              id: "github-token"
              secret: "${GITHUB_TOKEN}"
              description: "GitHub Personal Access Token"

tool:
  git:
    installations:
      - name: "Default"
        home: "git"
  jdk:
    installations:
      - name: "OpenJDK-11"
        properties:
          - installSource:
              installers:
                - adoptOpenJdkInstaller:
                    id: "jdk-11.0.19+7"
  nodejs:
    installations:
      - name: "NodeJS-18"
        properties:
          - installSource:
              installers:
                - nodeJSInstaller:
                    id: "18.17.0"
                    npmPackages: "npm@latest yarn@latest"

unclassified:
  location:
    url: "${JENKINS_URL}"
    adminAddress: "${JENKINS_ADMIN_EMAIL}"
    
  gitHubPluginConfig:
    configs:
      - name: "GitHub"
        apiUrl: "https://api.github.com"
        credentialsId: "github-token"
        manageHooks: true
        
  email-ext:
    defaultSubject: "$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!"
    defaultBody: |
      $PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:
      
      Check console output at $BUILD_URL to view the results.
      
      Changes:
      $CHANGES
    smtpServer: "smtp.gmail.com"
    smtpPort: 587
    charset: "UTF-8"
    defaultContentType: "text/plain"
```

### Disaster Recovery Configuration
```bash
# Disaster recovery setup script
cat > /usr/local/bin/jenkins-dr-setup.sh << 'EOF'
#!/bin/bash

# Variables
BACKUP_BUCKET="s3://your-jenkins-dr-bucket"
JENKINS_HOME="/var/jenkins_home"
DR_SITE="jenkins-dr.yourcompany.com"

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

# Sync configuration to DR site
sync_to_dr() {
    echo "Syncing Jenkins configuration to DR site..."
    
    # Backup current configuration
    tar -czf /tmp/jenkins-config-$(date +%Y%m%d).tar.gz \
        ${JENKINS_HOME}/config.xml \
        ${JENKINS_HOME}/jobs \
        ${JENKINS_HOME}/users \
        ${JENKINS_HOME}/secrets \
        ${JENKINS_HOME}/plugins
    
    # Upload to S3
    aws s3 cp /tmp/jenkins-config-$(date +%Y%m%d).tar.gz ${BACKUP_BUCKET}/config/
    
    # Sync to DR Jenkins
    rsync -avz --delete ${JENKINS_HOME}/jobs/ jenkins@${DR_SITE}:${JENKINS_HOME}/jobs/
    rsync -avz --delete ${JENKINS_HOME}/users/ jenkins@${DR_SITE}:${JENKINS_HOME}/users/
}

# Restore from DR backup
restore_from_dr() {
    echo "Restoring Jenkins from DR backup..."
    
    # Download latest backup
    latest_backup=$(aws s3 ls ${BACKUP_BUCKET}/config/ | sort | tail -n 1 | awk '{print $4}')
    aws s3 cp ${BACKUP_BUCKET}/config/${latest_backup} /tmp/
    
    # Stop Jenkins
    systemctl stop jenkins
    
    # Extract backup
    cd ${JENKINS_HOME}
    tar -xzf /tmp/${latest_backup}
    
    # Fix permissions
    chown -R jenkins:jenkins ${JENKINS_HOME}
    
    # Start Jenkins
    systemctl start jenkins
    
    echo "Restore completed from ${latest_backup}"
}

case "$1" in
    sync)
        sync_to_dr
        ;;
    restore)
        restore_from_dr
        ;;
    *)
        echo "Usage: $0 {sync|restore}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/jenkins-dr-setup.sh

# Schedule DR sync
echo "0 */6 * * * jenkins /usr/local/bin/jenkins-dr-setup.sh sync >> /var/log/jenkins-dr.log 2>&1" >> /etc/cron.d/jenkins-dr
```

---

**⚙️ Jenkins Configuration Complete! Your enterprise-grade CI/CD system is fully configured and ready for production use!** 🚀

**Next Steps:**
1. Follow the step-by-step guide in [`JENKINS-STEP-BY-STEP.md`](JENKINS-STEP-BY-STEP.md)
2. Implement advanced features from [`JENKINS-ADVANCED.md`](JENKINS-ADVANCED.md)
3. Use the asset templates and scripts for automation
4. Set up monitoring and alerting
5. Plan for scaling and disaster recovery