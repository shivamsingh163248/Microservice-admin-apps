# Jenkins Step-by-Step Implementation Guide for Microservice Admin App

## 📋 Table of Contents
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Complete Installation Walkthrough](#complete-installation-walkthrough)
- [Initial Setup and Configuration](#initial-setup-and-configuration)
- [Job Creation Step-by-Step](#job-creation-step-by-step)
- [Pipeline Development Guide](#pipeline-development-guide)
- [Environment Setup](#environment-setup)
- [Testing and Debugging](#testing-and-debugging)
- [Production Deployment](#production-deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting Guide](#troubleshooting-guide)

## ✅ Pre-Installation Checklist

### System Requirements Verification
```bash
# Step 1: Check system specifications
echo "=== System Information ==="
uname -a
cat /etc/os-release
free -h
df -h
nproc
```

**Expected Output:**
```text
✅ OS: Ubuntu 20.04+ or CentOS 7+
✅ RAM: Minimum 4GB (Recommended 8GB+)
✅ CPU: Minimum 2 cores (Recommended 4+)
✅ Disk: Minimum 50GB (Recommended 100GB+)
```

### Network Requirements
```bash
# Step 2: Verify network connectivity
echo "=== Network Connectivity Check ==="
curl -I https://github.com
curl -I https://registry-1.docker.io
curl -I https://pkg.jenkins.io

# Check ports availability
sudo netstat -tlnp | grep -E ':(8080|50000|22|443|80)'
```

**Expected Ports:**
- ✅ Port 8080: Available for Jenkins UI
- ✅ Port 50000: Available for Jenkins agents
- ✅ Port 22: SSH access
- ✅ Port 443/80: HTTPS/HTTP access

### Software Dependencies
```bash
# Step 3: Install required software
sudo apt update && sudo apt upgrade -y

# Install Java 11 (Required)
sudo apt install openjdk-11-jdk -y
java -version

# Install Git (Required)
sudo apt install git -y
git --version

# Install Docker (Required)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
docker --version

# Install Node.js (Required for frontend)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y
node --version
npm --version
```

**Verification Commands:**
```bash
echo "=== Software Versions ==="
java -version          # Should show OpenJDK 11.x
git --version         # Should show Git 2.x+
docker --version      # Should show Docker 20.x+
node --version        # Should show Node 18.x+
npm --version         # Should show npm 9.x+
```

## 🚀 Complete Installation Walkthrough

### Option A: Docker Installation (Recommended for Development)

#### Step 1: Prepare Docker Environment
```bash
# Create Jenkins home directory
mkdir -p $HOME/jenkins_home
sudo chown 1000:1000 $HOME/jenkins_home

# Create Docker network for Jenkins
docker network create jenkins-network

# Verify Docker daemon is running
sudo systemctl status docker
```

#### Step 2: Run Jenkins Container
```bash
# Run Jenkins with Docker-in-Docker support
docker run -d \
  --name jenkins-master \
  --network jenkins-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v $HOME/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  --group-add $(getent group docker | cut -d: -f3) \
  jenkins/jenkins:lts

# Verify container is running
docker ps | grep jenkins-master
```

#### Step 3: Get Initial Admin Password
```bash
# Wait for Jenkins to start (usually 2-3 minutes)
sleep 180

# Get the initial admin password
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
```

**Save this password! You'll need it for the initial setup.**

### Option B: Native Installation (Recommended for Production)

#### Step 1: Add Jenkins Repository
```bash
# Add Jenkins GPG key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

# Add Jenkins repository
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update package list
sudo apt update
```

#### Step 2: Install Jenkins
```bash
# Install Jenkins
sudo apt install jenkins -y

# Start and enable Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
```

#### Step 3: Configure Firewall
```bash
# Allow Jenkins ports through firewall
sudo ufw allow 8080/tcp
sudo ufw allow 50000/tcp
sudo ufw status

# Or for CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=50000/tcp
sudo firewall-cmd --reload
```

#### Step 4: Get Initial Admin Password
```bash
# Get the initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## ⚙️ Initial Setup and Configuration

### Step 1: Access Jenkins Web Interface

1. **Open your browser** and navigate to:
   ```
   http://your-server-ip:8080
   ```

2. **Unlock Jenkins** screen will appear:
   - Paste the initial admin password you retrieved earlier
   - Click **Continue**

### Step 2: Install Plugins

#### Choose Plugin Installation Method:
- **Option A**: Click **"Install suggested plugins"** (Recommended for beginners)
- **Option B**: Click **"Select plugins to install"** (For custom setup)

#### Essential Plugins to Install:
```text
Core Plugins:
✅ Git plugin
✅ GitHub plugin
✅ Pipeline plugin
✅ Pipeline: Stage View plugin
✅ Pipeline: GitHub Groovy Libraries
✅ Blue Ocean plugin
✅ Docker plugin
✅ Docker Pipeline plugin

Build & Test Plugins:
✅ JUnit plugin
✅ HTML Publisher plugin
✅ Cobertura plugin
✅ SonarQube Scanner plugin

Deployment Plugins:
✅ SSH Agent plugin
✅ Ansible plugin
✅ Kubernetes plugin
✅ Terraform plugin

Notification Plugins:
✅ Email Extension plugin
✅ Slack Notification plugin
✅ Microsoft Teams plugin

Artifact Management:
✅ Artifactory plugin
✅ Nexus Platform plugin

Security Plugins:
✅ Role-based Authorization Strategy
✅ OWASP Markup Formatter plugin

Utility Plugins:
✅ Build Timeout plugin
✅ Timestamper plugin
✅ Workspace Cleanup plugin
```

**Plugin Installation Time: 5-10 minutes**

### Step 3: Create First Admin User

Fill out the **Create First Admin User** form:
```text
Username: admin
Password: [your-secure-password]
Confirm password: [your-secure-password]
Full name: Jenkins Administrator
E-mail address: admin@yourcompany.com
```

Click **Save and Continue**

### Step 4: Instance Configuration

Set the **Jenkins URL**:
```text
Jenkins URL: http://your-server-ip:8080/
```

For production, use your domain:
```text
Jenkins URL: https://jenkins.yourcompany.com/
```

Click **Save and Finish**

### Step 5: Start Using Jenkins

Click **Start using Jenkins** - You'll be redirected to the Jenkins dashboard.

## 🔧 Job Creation Step-by-Step

### Creating Your First Multibranch Pipeline

#### Step 1: Create New Item
1. **Click**: "New Item" in the left sidebar
2. **Enter name**: `microservice-admin-app`
3. **Select**: "Multibranch Pipeline"
4. **Click**: "OK"

#### Step 2: Configure Branch Sources

**GitHub Configuration:**
1. **Click**: "Add source" → "GitHub"
2. **Repository HTTPS URL**: 
   ```
   https://github.com/shivamsingh163248/Microservice-admin-apps.git
   ```
3. **Credentials**: Select "Add" → "Jenkins"

**Add GitHub Credentials:**
```text
Kind: Username with password
Scope: Global
Username: shivamsingh163248
Password: [your-github-personal-access-token]
ID: github-credentials
Description: GitHub Credentials for microservice app
```

4. **Select the newly created credentials**

#### Step 3: Configure Behaviors
Add these behaviors:
- ✅ **Discover branches**
- ✅ **Discover pull requests from origin**
- ✅ **Clean before checkout**

#### Step 4: Build Configuration
```text
Mode: by Jenkinsfile
Script Path: jenkins/pipelines/Jenkinsfile-DockerHub
```

#### Step 5: Scan Multibranch Pipeline Triggers
```text
Periodically if not otherwise run: ✅
Interval: 1 day
```

#### Step 6: Orphaned Item Strategy
```text
Discard old items: ✅
Days to keep old items: 7
Max # of old items to keep: 10
```

**Click "Save"**

### Step 7: Verify Repository Scan

1. **Click**: "Scan Repository Now"
2. **Check**: Console output shows:
   ```
   Started by user admin
   [Wed Dec 06 10:30:00 UTC 2023] Starting branch indexing...
   Checking branches...
   Checking branch main
     Looking for Jenkinsfile at jenkins/pipelines/Jenkinsfile-DockerHub
     Met criteria
   Processed 1 branches
   [Wed Dec 06 10:30:15 UTC 2023] Finished branch indexing. Indexing took 15 sec
   Finished: SUCCESS
   ```

## 📝 Pipeline Development Guide

### Creating Your First Jenkinsfile

#### Step 1: Basic Pipeline Structure
Create `jenkins/pipelines/Jenkinsfile-DockerHub` in your repository:

```groovy
pipeline {
    agent any
    
    environment {
        // Application Configuration
        APP_NAME = 'microservice-admin-app'
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_NAMESPACE = 'shivamsingh163248'
        
        // Image Names
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/nginx_frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/flask_backend"
        DATABASE_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/mysql_db"
        
        // Build Configuration
        BUILD_VERSION = "v1.0.${BUILD_NUMBER}"
        
        // Credentials
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code from ${env.BRANCH_NAME} branch"
                checkout scm
            }
        }
        
        stage('Environment Info') {
            steps {
                script {
                    echo "🏗️ Build Information:"
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Build Number: ${env.BUILD_NUMBER}"
                    echo "Build Version: ${BUILD_VERSION}"
                    echo "Workspace: ${env.WORKSPACE}"
                }
            }
        }
        
        stage('Build Images') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        script {
                            echo "🔨 Building Frontend Image"
                            sh """
                                cd frontend
                                docker build -t ${FRONTEND_IMAGE}:${BUILD_VERSION} .
                                docker tag ${FRONTEND_IMAGE}:${BUILD_VERSION} ${FRONTEND_IMAGE}:latest
                            """
                        }
                    }
                }
                
                stage('Build Backend') {
                    steps {
                        script {
                            echo "🔨 Building Backend Image"
                            sh """
                                cd backend
                                docker build -t ${BACKEND_IMAGE}:${BUILD_VERSION} .
                                docker tag ${BACKEND_IMAGE}:${BUILD_VERSION} ${BACKEND_IMAGE}:latest
                            """
                        }
                    }
                }
                
                stage('Build Database') {
                    steps {
                        script {
                            echo "🔨 Building Database Image"
                            sh """
                                cd database
                                docker build -t ${DATABASE_IMAGE}:${BUILD_VERSION} .
                                docker tag ${DATABASE_IMAGE}:${BUILD_VERSION} ${DATABASE_IMAGE}:latest
                            """
                        }
                    }
                }
            }
        }
        
        stage('Test Images') {
            steps {
                script {
                    echo "🧪 Testing Built Images"
                    sh """
                        # Test that images were built successfully
                        docker images | grep ${DOCKER_NAMESPACE}
                        
                        # Basic image inspection
                        docker inspect ${FRONTEND_IMAGE}:${BUILD_VERSION} > /dev/null
                        docker inspect ${BACKEND_IMAGE}:${BUILD_VERSION} > /dev/null
                        docker inspect ${DATABASE_IMAGE}:${BUILD_VERSION} > /dev/null
                        
                        echo "✅ All images built successfully"
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    branch 'staging'
                }
            }
            steps {
                script {
                    echo "📤 Pushing images to Docker Hub"
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            # Push versioned images
                            docker push ${FRONTEND_IMAGE}:${BUILD_VERSION}
                            docker push ${BACKEND_IMAGE}:${BUILD_VERSION}
                            docker push ${DATABASE_IMAGE}:${BUILD_VERSION}
                            
                            # Push latest tags for main branch
                            if [ "${env.BRANCH_NAME}" = "main" ]; then
                                docker push ${FRONTEND_IMAGE}:latest
                                docker push ${BACKEND_IMAGE}:latest
                                docker push ${DATABASE_IMAGE}:latest
                            fi
                            
                            docker logout
                        """
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    echo "🧹 Cleaning up local images"
                    sh """
                        # Remove local images to save space
                        docker rmi ${FRONTEND_IMAGE}:${BUILD_VERSION} || true
                        docker rmi ${BACKEND_IMAGE}:${BUILD_VERSION} || true
                        docker rmi ${DATABASE_IMAGE}:${BUILD_VERSION} || true
                        
                        # Clean up dangling images
                        docker image prune -f
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "🏁 Pipeline execution completed"
            // Clean workspace
            cleanWs()
        }
        
        success {
            echo "✅ Pipeline executed successfully"
            // You can add notifications here
        }
        
        failure {
            echo "❌ Pipeline failed"
            // You can add failure notifications here
        }
    }
}
```

#### Step 2: Commit and Push Jenkinsfile
```bash
# In your repository
git add jenkins/pipelines/Jenkinsfile-DockerHub
git commit -m "Add initial Jenkinsfile for Docker Hub integration"
git push origin main
```

#### Step 3: Trigger First Build
1. **Go to Jenkins Dashboard**
2. **Click**: `microservice-admin-app`
3. **Click**: "Scan Repository Now"
4. **Verify**: Build starts automatically for main branch

## 🛠️ Environment Setup

### Development Environment Configuration

#### Step 1: Create Development Credentials

**Docker Hub Credentials:**
1. **Navigate**: Manage Jenkins → Manage Credentials
2. **Click**: "Global" → "Add Credentials"
3. **Fill out**:
   ```text
   Kind: Username with password
   Scope: Global
   Username: [your-dockerhub-username]
   Password: [your-dockerhub-password]
   ID: dockerhub-credentials
   Description: Docker Hub Credentials
   ```

**GitHub Personal Access Token:**
1. **Create token** at: https://github.com/settings/tokens
2. **Scopes**: `repo`, `read:org`, `admin:repo_hook`
3. **Add to Jenkins**:
   ```text
   Kind: Secret text
   Scope: Global
   Secret: [your-github-token]
   ID: github-token
   Description: GitHub Personal Access Token
   ```

#### Step 2: Configure Global Tools

**Git Configuration:**
1. **Navigate**: Manage Jenkins → Global Tool Configuration
2. **Git section**:
   ```text
   Name: Default
   Path to Git executable: git
   ```

**JDK Configuration:**
```text
Name: OpenJDK-11
JAVA_HOME: /usr/lib/jvm/java-11-openjdk-amd64
```

**Node.js Configuration:**
```text
Name: NodeJS-18
Installation: Install automatically from nodejs.org
Version: NodeJS 18.17.0
Global npm packages: npm@latest yarn@latest
```

**Docker Configuration:**
```text
Name: Docker
Installation: Download from docker.com
Version: latest
```

### Production Environment Setup

#### Step 1: SSH Credentials for Deployment
```text
Kind: SSH Username with private key
Scope: Global
ID: ec2-ssh-key
Username: ubuntu
Private Key: [paste your EC2 private key]
Description: EC2 SSH Private Key
```

#### Step 2: AWS Credentials
```text
Kind: AWS Credentials
Scope: Global
ID: aws-credentials
Access Key ID: [your-aws-access-key]
Secret Access Key: [your-aws-secret-key]
Description: AWS Credentials for Infrastructure
```

#### Step 3: Environment Variables
**Navigate**: Manage Jenkins → Configure System → Global properties

Add environment variables:
```text
PROD_SERVER: 54.234.122.255
STAGING_SERVER: 10.0.1.100
DEV_SERVER: localhost
APP_NAME: microservice-admin-app
DEFAULT_REGISTRY: docker.io/shivamsingh163248
```

## 🧪 Testing and Debugging

### Running Your First Build

#### Step 1: Manual Build Trigger
1. **Navigate**: Dashboard → microservice-admin-app → main
2. **Click**: "Build Now"
3. **Watch**: Console Output

**Expected Console Output:**
```text
Started by user admin
Checking out git https://github.com/shivamsingh163248/Microservice-admin-apps.git into /var/jenkins_home/workspace/microservice-admin-app_main@script
 > git rev-parse --is-inside-work-tree # timeout=10
 > git config remote.origin.url https://github.com/shivamsingh163248/Microservice-admin-apps.git # timeout=10
...
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] echo
🔄 Checking out code from main branch
[Pipeline] checkout
The recommended git tool is: NONE
...
[Pipeline] stage
[Pipeline] { (Build Images)
[Pipeline] parallel
[Pipeline] { (Build Frontend)
[Pipeline] { (Build Backend)
[Pipeline] { (Build Database)
...
Finished: SUCCESS
```

#### Step 2: Debug Common Issues

**Issue 1: Docker Permission Denied**
```bash
# Fix: Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# For Docker container
docker exec -u root jenkins-master usermod -aG docker jenkins
docker restart jenkins-master
```

**Issue 2: Git Authentication Failed**
```bash
# Verify GitHub token has correct permissions
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Test Git clone manually
git clone https://username:token@github.com/shivamsingh163248/Microservice-admin-apps.git
```

**Issue 3: Docker Build Fails**
```bash
# Check Docker daemon status
sudo systemctl status docker

# Test Docker build manually
cd /var/jenkins_home/workspace/microservice-admin-app_main
docker build -t test-image frontend/
```

#### Step 3: Pipeline Debugging

**Enable Debug Mode in Jenkinsfile:**
```groovy
pipeline {
    agent any
    
    options {
        // Enable timestamps in console output
        timestamps()
        // Set build timeout
        timeout(time: 30, unit: 'MINUTES')
        // Keep only last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('Debug Info') {
            steps {
                script {
                    echo "=== Debug Information ==="
                    echo "Node: ${env.NODE_NAME}"
                    echo "Workspace: ${env.WORKSPACE}"
                    echo "Build URL: ${env.BUILD_URL}"
                    echo "Git Branch: ${env.BRANCH_NAME}"
                    echo "Git Commit: ${env.GIT_COMMIT}"
                    
                    sh """
                        echo "=== System Information ==="
                        whoami
                        pwd
                        docker --version
                        git --version
                        node --version
                        npm --version
                        
                        echo "=== Environment Variables ==="
                        env | sort
                        
                        echo "=== Disk Space ==="
                        df -h
                        
                        echo "=== Docker Images ==="
                        docker images
                    """
                }
            }
        }
    }
}
```

### Build Analysis and Optimization

#### Step 1: Build Performance Analysis
1. **Navigate**: Build → "Performance" (if Build Performance plugin installed)
2. **Check**: Build duration trends
3. **Identify**: Bottlenecks in pipeline stages

#### Step 2: Optimize Build Time
```groovy
// Parallel builds for independent components
stage('Build Images') {
    parallel {
        stage('Build Frontend') {
            agent { label 'frontend-builder' }
            steps {
                // Frontend build steps
            }
        }
        stage('Build Backend') {
            agent { label 'backend-builder' }
            steps {
                // Backend build steps
            }
        }
    }
}
```

#### Step 3: Docker Layer Caching
```dockerfile
# Optimize Dockerfile for better caching
FROM node:18-alpine

# Copy package files first (better layer caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy source code last
COPY . .
RUN npm run build
```

## 🚀 Production Deployment

### Setting Up Production Pipeline

#### Step 1: Create Production Jenkinsfile

Create `jenkins/pipelines/Jenkinsfile-Production`:

```groovy
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Target deployment environment'
        )
        choice(
            name: 'ACTION',
            choices: ['deploy', 'rollback', 'status'],
            description: 'Deployment action'
        )
        string(
            name: 'VERSION',
            defaultValue: 'latest',
            description: 'Docker image version to deploy'
        )
    }
    
    environment {
        APP_NAME = 'microservice-admin-app'
        REGISTRY = 'docker.io/shivamsingh163248'
        
        // Environment-specific configurations
        DEPLOY_HOST = """${
            params.ENVIRONMENT == 'production' ? '54.234.122.255' :
            params.ENVIRONMENT == 'staging' ? '10.0.1.100' :
            'localhost'
        }"""
        
        FRONTEND_PORT = """${
            params.ENVIRONMENT == 'production' ? '8081' :
            params.ENVIRONMENT == 'staging' ? '8082' :
            '8080'
        }"""
        
        BACKEND_PORT = """${
            params.ENVIRONMENT == 'production' ? '5001' :
            params.ENVIRONMENT == 'staging' ? '5002' :
            '5000'
        }"""
    }
    
    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    echo "🔍 Validating deployment parameters"
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Action: ${params.ACTION}"
                    echo "Version: ${params.VERSION}"
                    echo "Deploy Host: ${DEPLOY_HOST}"
                    
                    if (params.ENVIRONMENT == 'production' && params.ACTION == 'deploy') {
                        def userInput = input(
                            message: 'Deploy to PRODUCTION?',
                            parameters: [
                                booleanParam(
                                    defaultValue: false,
                                    description: 'Confirm production deployment',
                                    name: 'CONFIRM_PROD_DEPLOY'
                                )
                            ]
                        )
                        if (!userInput) {
                            error('Production deployment cancelled by user')
                        }
                    }
                }
            }
        }
        
        stage('Prepare Deployment') {
            when {
                params.ACTION == 'deploy'
            }
            steps {
                script {
                    echo "📋 Preparing deployment configuration"
                    
                    // Create docker-compose.production.yml
                    writeFile file: 'docker-compose.production.yml', text: """
version: '3.8'

services:
  frontend:
    image: ${REGISTRY}/nginx_frontend:${params.VERSION}
    container_name: nginx_frontend_${params.ENVIRONMENT}
    ports:
      - "${FRONTEND_PORT}:80"
    depends_on:
      - backend
    networks:
      - app-network
    restart: unless-stopped

  backend:
    image: ${REGISTRY}/flask_backend:${params.VERSION}
    container_name: flask_backend_${params.ENVIRONMENT}
    ports:
      - "${BACKEND_PORT}:5000"
    environment:
      - DB_HOST=database
      - DB_PORT=3306
      - DB_NAME=microservice_db
      - DB_USER=root
      - DB_PASSWORD=password123
      - ENVIRONMENT=${params.ENVIRONMENT}
    depends_on:
      - database
    networks:
      - app-network
    restart: unless-stopped

  database:
    image: ${REGISTRY}/mysql_db:${params.VERSION}
    container_name: mysql_db_${params.ENVIRONMENT}
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=password123
      - MYSQL_DATABASE=microservice_db
    volumes:
      - mysql_data_${params.ENVIRONMENT}:/var/lib/mysql
    networks:
      - app-network
    restart: unless-stopped

volumes:
  mysql_data_${params.ENVIRONMENT}:

networks:
  app-network:
    driver: bridge
"""
                }
            }
        }
        
        stage('Deploy Application') {
            when {
                params.ACTION == 'deploy'
            }
            steps {
                script {
                    echo "🚀 Deploying to ${params.ENVIRONMENT} environment"
                    
                    if (DEPLOY_HOST == 'localhost') {
                        // Local deployment
                        sh """
                            docker-compose -f docker-compose.production.yml down || true
                            docker-compose -f docker-compose.production.yml pull
                            docker-compose -f docker-compose.production.yml up -d
                        """
                    } else {
                        // Remote deployment
                        sshagent(['ec2-ssh-key']) {
                            sh """
                                # Copy deployment files to remote server
                                scp -o StrictHostKeyChecking=no docker-compose.production.yml ubuntu@${DEPLOY_HOST}:/tmp/
                                
                                # Execute deployment on remote server
                                ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_HOST} '
                                    cd /tmp
                                    sudo docker-compose -f docker-compose.production.yml down || true
                                    sudo docker-compose -f docker-compose.production.yml pull
                                    sudo docker-compose -f docker-compose.production.yml up -d
                                    
                                    echo "Waiting for services to start..."
                                    sleep 30
                                    
                                    echo "Checking service status..."
                                    sudo docker-compose -f docker-compose.production.yml ps
                                '
                            """
                        }
                    }
                }
            }
        }
        
        stage('Health Check') {
            when {
                params.ACTION == 'deploy'
            }
            steps {
                script {
                    echo "🏥 Performing health checks"
                    
                    // Wait for services to start
                    sleep(time: 30, unit: 'SECONDS')
                    
                    def healthCheckCommands = [
                        "curl -f http://${DEPLOY_HOST}:${BACKEND_PORT}/health || exit 1",
                        "curl -f http://${DEPLOY_HOST}:${FRONTEND_PORT}/ || exit 1"
                    ]
                    
                    for (command in healthCheckCommands) {
                        retry(3) {
                            if (DEPLOY_HOST == 'localhost') {
                                sh command
                            } else {
                                sshagent(['ec2-ssh-key']) {
                                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_HOST} '${command}'"
                                }
                            }
                        }
                    }
                    
                    echo "✅ All health checks passed"
                }
            }
        }
        
        stage('Deployment Status') {
            when {
                params.ACTION == 'status'
            }
            steps {
                script {
                    echo "📊 Checking deployment status"
                    
                    if (DEPLOY_HOST == 'localhost') {
                        sh "docker ps --filter 'name=${params.ENVIRONMENT}' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
                    } else {
                        sshagent(['ec2-ssh-key']) {
                            sh """
                                ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_HOST} '
                                    sudo docker ps --filter "name=${params.ENVIRONMENT}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                                '
                            """
                        }
                    }
                }
            }
        }
        
        stage('Rollback') {
            when {
                params.ACTION == 'rollback'
            }
            steps {
                script {
                    echo "🔄 Rolling back deployment"
                    
                    def previousVersion = input(
                        message: 'Enter version to rollback to:',
                        parameters: [
                            string(name: 'ROLLBACK_VERSION', defaultValue: 'latest', description: 'Version to rollback to')
                        ]
                    )
                    
                    // Update docker-compose file with rollback version
                    sh """
                        sed -i 's/:${params.VERSION}/:${previousVersion}/g' docker-compose.production.yml
                    """
                    
                    // Deploy rollback version
                    if (DEPLOY_HOST == 'localhost') {
                        sh """
                            docker-compose -f docker-compose.production.yml down
                            docker-compose -f docker-compose.production.yml up -d
                        """
                    } else {
                        sshagent(['ec2-ssh-key']) {
                            sh """
                                scp -o StrictHostKeyChecking=no docker-compose.production.yml ubuntu@${DEPLOY_HOST}:/tmp/
                                ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_HOST} '
                                    cd /tmp
                                    sudo docker-compose -f docker-compose.production.yml down
                                    sudo docker-compose -f docker-compose.production.yml up -d
                                '
                            """
                        }
                    }
                    
                    echo "✅ Rollback completed to version: ${previousVersion}"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "📊 Deployment Summary:"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Action: ${params.ACTION}"
                echo "Version: ${params.VERSION}"
                echo "Host: ${DEPLOY_HOST}"
                echo "Frontend URL: http://${DEPLOY_HOST}:${FRONTEND_PORT}"
                echo "Backend URL: http://${DEPLOY_HOST}:${BACKEND_PORT}"
            }
            
            // Clean up temporary files
            sh "rm -f docker-compose.production.yml"
        }
        
        success {
            echo "✅ Deployment completed successfully"
            
            // Send success notification
            emailext (
                subject: "✅ Deployment Successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                Deployment Details:
                Environment: ${params.ENVIRONMENT}
                Version: ${params.VERSION}
                Frontend: http://${DEPLOY_HOST}:${FRONTEND_PORT}
                Backend: http://${DEPLOY_HOST}:${BACKEND_PORT}
                
                Build URL: ${env.BUILD_URL}
                """,
                to: "${env.DEFAULT_RECIPIENTS}"
            )
        }
        
        failure {
            echo "❌ Deployment failed"
            
            // Send failure notification
            emailext (
                subject: "❌ Deployment Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                Deployment failed for:
                Environment: ${params.ENVIRONMENT}
                Version: ${params.VERSION}
                
                Please check the build logs: ${env.BUILD_URL}console
                """,
                to: "${env.DEFAULT_RECIPIENTS}"
            )
        }
    }
}
```

#### Step 2: Create Production Job
1. **Click**: "New Item"
2. **Name**: `microservice-admin-app-production`
3. **Type**: "Pipeline"
4. **Pipeline Definition**: "Pipeline script from SCM"
5. **SCM**: Git
6. **Repository URL**: Your repo URL
7. **Script Path**: `jenkins/pipelines/Jenkinsfile-Production`

#### Step 3: Test Production Deployment
1. **Click**: "Build with Parameters"
2. **Environment**: development
3. **Action**: deploy
4. **Version**: latest
5. **Click**: "Build"

## 📊 Monitoring and Maintenance

### Setting Up Build Monitoring

#### Step 1: Install Monitoring Plugins
```text
Navigate: Manage Jenkins → Manage Plugins → Available

Install these plugins:
✅ Monitoring Plugin
✅ Build Metrics Plugin
✅ Performance Plugin
✅ Dashboard View Plugin
```

#### Step 2: Create Monitoring Dashboard
1. **Click**: "+" (New View)
2. **Name**: "Microservice Dashboard"
3. **Type**: "Dashboard"
4. **Add Portlets**:
   - Build Statistics
   - Latest Builds
   - Build Queue
   - Test Results Trend

#### Step 3: Configure Build Metrics
```text
Navigate: Manage Jenkins → Configure System → Build Metrics

Enable metrics:
✅ Build duration
✅ Build success/failure rate
✅ Queue time
✅ Test results
```

### Automated Maintenance

#### Step 1: Create Maintenance Pipeline

Create `jenkins/pipelines/Jenkinsfile-Maintenance`:

```groovy
pipeline {
    agent any
    
    triggers {
        // Run daily at 2 AM
        cron('0 2 * * *')
    }
    
    stages {
        stage('System Cleanup') {
            steps {
                script {
                    echo "🧹 Starting system cleanup"
                    
                    sh """
                        # Clean up Docker images
                        docker image prune -f
                        docker volume prune -f
                        docker network prune -f
                        
                        # Clean up workspace
                        find ${JENKINS_HOME}/workspace -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
                        
                        # Clean up old builds
                        find ${JENKINS_HOME}/jobs/*/builds -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
                        
                        # Clean up logs
                        find ${JENKINS_HOME}/logs -name "*.log" -mtime +14 -delete 2>/dev/null || true
                        
                        echo "✅ Cleanup completed"
                    """
                }
            }
        }
        
        stage('Backup Configuration') {
            steps {
                script {
                    echo "💾 Creating configuration backup"
                    
                    sh """
                        # Create backup directory
                        mkdir -p /var/backups/jenkins
                        
                        # Backup Jenkins configuration
                        tar -czf /var/backups/jenkins/jenkins-config-\$(date +%Y%m%d).tar.gz \\
                            ${JENKINS_HOME}/config.xml \\
                            ${JENKINS_HOME}/jobs \\
                            ${JENKINS_HOME}/users \\
                            ${JENKINS_HOME}/secrets \\
                            ${JENKINS_HOME}/plugins
                        
                        # Keep only last 7 backups
                        find /var/backups/jenkins -name "jenkins-config-*.tar.gz" -mtime +7 -delete
                        
                        echo "✅ Backup completed"
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Performing system health check"
                    
                    sh """
                        # Check disk space
                        df -h
                        
                        # Check memory usage
                        free -h
                        
                        # Check Jenkins process
                        ps aux | grep jenkins
                        
                        # Check Docker daemon
                        systemctl status docker
                        
                        echo "✅ Health check completed"
                    """
                }
            }
        }
    }
    
    post {
        failure {
            emailext (
                subject: "⚠️ Jenkins Maintenance Failed: ${env.BUILD_NUMBER}",
                body: "Jenkins maintenance pipeline failed. Please check the logs: ${env.BUILD_URL}console",
                to: "${env.ADMIN_EMAIL}"
            )
        }
    }
}
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Build Fails with "Permission Denied"

**Symptoms:**
```text
docker: Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# For Docker installation
docker exec -u root jenkins-master usermod -aG docker jenkins
docker restart jenkins-master

# Verify fix
docker exec jenkins-master docker ps
```

#### Issue 2: Git Authentication Failed

**Symptoms:**
```text
Couldn't find any revision to build. Verify that the repository is correct and that the specified refspecs/branches exist.
```

**Solution:**
1. **Check GitHub token permissions**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Ensure token has `repo` and `admin:repo_hook` permissions

2. **Test credentials in Jenkins**:
   ```bash
   # In Jenkins Script Console
   def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
       com.cloudbees.plugins.credentials.common.StandardUsernameCredentials.class,
       Jenkins.instance,
       null,
       null
   )
   
   creds.each { cred ->
       if (cred.id == 'github-credentials') {
           println("Username: ${cred.username}")
           println("ID: ${cred.id}")
       }
   }
   ```

#### Issue 3: Docker Build Timeout

**Symptoms:**
```text
Build timed out (after 10 minutes). Marking the build as failed.
```

**Solution:**
```groovy
// Add timeout to pipeline
pipeline {
    agent any
    
    options {
        timeout(time: 60, unit: 'MINUTES')
    }
    
    stages {
        stage('Build with Timeout') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    sh 'docker build -t myapp .'
                }
            }
        }
    }
}
```

#### Issue 4: Jenkins Won't Start

**Symptoms:**
```bash
sudo systemctl status jenkins
# Shows: failed (Result: exit-code)
```

**Diagnosis & Solution:**
```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Common causes and fixes:

# 1. Port already in use
sudo netstat -tlnp | grep 8080
sudo lsof -i :8080
# Kill process using port 8080

# 2. Java version issues
java -version
# Install correct Java version

# 3. Insufficient memory
free -h
# Add swap or increase RAM

# 4. Corrupted Jenkins home
sudo rm -rf /var/lib/jenkins/war
sudo systemctl restart jenkins

# 5. Permission issues
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo systemctl restart jenkins
```

#### Issue 5: Plugin Installation Fails

**Symptoms:**
```text
Plugin installation failed due to IOException
```

**Solution:**
```bash
# Update plugin center
curl -X POST http://admin:password@localhost:8080/updateCenter/byId/default/postBack

# Manual plugin installation
cd /var/lib/jenkins/plugins
sudo wget https://updates.jenkins.io/download/plugins/git/4.8.3/git.hpi
sudo chown jenkins:jenkins git.hpi
sudo systemctl restart jenkins

# Clear plugin cache
sudo rm -rf /var/lib/jenkins/plugins/*.pinned
sudo systemctl restart jenkins
```

### Performance Troubleshooting

#### Issue 1: Slow Build Performance

**Diagnosis:**
```groovy
// Add timing to pipeline stages
pipeline {
    agent any
    
    stages {
        stage('Timed Build') {
            steps {
                script {
                    def startTime = System.currentTimeMillis()
                    
                    sh 'docker build -t myapp .'
                    
                    def duration = (System.currentTimeMillis() - startTime) / 1000
                    echo "Build completed in ${duration} seconds"
                }
            }
        }
    }
}
```

**Solutions:**
1. **Use Docker layer caching**
2. **Parallel builds**
3. **Dedicated build agents**
4. **SSD storage**
5. **Increase memory allocation**

#### Issue 2: High Memory Usage

**Diagnosis:**
```bash
# Check Jenkins memory usage
ps aux | grep jenkins
top -p $(pgrep java)

# Check JVM memory
jstat -gc $(pgrep java)
```

**Solution:**
```bash
# Increase JVM heap size
sudo vim /etc/default/jenkins

# Add or modify:
JENKINS_JAVA_OPTIONS="-Xmx4g -Xms2g -XX:+UseG1GC"

sudo systemctl restart jenkins
```

### Network Troubleshooting

#### Issue 1: Can't Access Jenkins UI

**Diagnosis:**
```bash
# Check if Jenkins is running
sudo systemctl status jenkins

# Check port binding
sudo netstat -tlnp | grep 8080

# Check firewall
sudo ufw status
sudo iptables -L

# Check from another machine
curl -I http://your-jenkins-server:8080
```

**Solution:**
```bash
# Open firewall port
sudo ufw allow 8080/tcp

# For cloud providers, check security groups
# AWS: Security Groups
# Azure: Network Security Groups
# GCP: Firewall Rules
```

### Disaster Recovery

#### Backup Strategy
```bash
#!/bin/bash
# Complete Jenkins backup script

BACKUP_DIR="/var/backups/jenkins"
JENKINS_HOME="/var/lib/jenkins"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
mkdir -p ${BACKUP_DIR}

# Stop Jenkins for consistent backup
sudo systemctl stop jenkins

# Backup configuration
tar -czf ${BACKUP_DIR}/jenkins-full-backup-${DATE}.tar.gz \
    --exclude="${JENKINS_HOME}/workspace/*" \
    --exclude="${JENKINS_HOME}/builds/*/workspace" \
    ${JENKINS_HOME}

# Restart Jenkins
sudo systemctl start jenkins

# Upload to cloud storage
aws s3 cp ${BACKUP_DIR}/jenkins-full-backup-${DATE}.tar.gz s3://your-backup-bucket/

echo "Backup completed: jenkins-full-backup-${DATE}.tar.gz"
```

#### Recovery Process
```bash
#!/bin/bash
# Jenkins recovery script

BACKUP_FILE=$1
JENKINS_HOME="/var/lib/jenkins"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file>"
    exit 1
fi

# Stop Jenkins
sudo systemctl stop jenkins

# Backup current state
mv ${JENKINS_HOME} ${JENKINS_HOME}.backup.$(date +%Y%m%d)

# Restore from backup
tar -xzf ${BACKUP_FILE} -C /var/lib/

# Fix permissions
sudo chown -R jenkins:jenkins ${JENKINS_HOME}

# Start Jenkins
sudo systemctl start jenkins

echo "Recovery completed from ${BACKUP_FILE}"
```

---

**🚀 Jenkins Step-by-Step Implementation Complete! Your enterprise-grade CI/CD pipeline is ready for production deployment!** 🎉

**Next Steps:**
1. Implement advanced features from [`JENKINS-ADVANCED.md`](JENKINS-ADVANCED.md)
2. Set up monitoring and alerting
3. Plan for scaling and high availability
4. Create disaster recovery procedures
5. Train your team on pipeline management

**Quick Reference:**
- **Jenkins URL**: http://your-server:8080
- **Admin User**: admin
- **Main Pipeline**: microservice-admin-app
- **Production Pipeline**: microservice-admin-app-production
- **Maintenance Pipeline**: microservice-admin-app-maintenance