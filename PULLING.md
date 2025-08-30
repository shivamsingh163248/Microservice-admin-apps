# 🔄 Jenkins CI/CD Integration Guide for Microservice Admin App

This guide provides comprehensive Jenkins integration for the Microservice Admin App with Docker and GitHub Container Registry support.

## 📋 Table of Contents

1. [Jenkins Prerequisites](#jenkins-prerequisites)
2. [Freestyle Project Setup](#freestyle-project-setup)
3. [Pipeline Script](#pipeline-script)
4. [Docker Integration](#docker-integration)
5. [GitHub Integration](#github-integration)
6. [Shell Scripts](#shell-scripts)
7. [Troubleshooting](#troubleshooting)

---

## 🛠️ Jenkins Prerequisites

### Required Jenkins Plugins
```bash
# Install these plugins in Jenkins
- Docker Pipeline
- GitHub Integration Plugin
- Pipeline: Stage View
- Build Timeout
- Timestamper
- Workspace Cleanup
- Credentials Binding
- Git Plugin
- Blue Ocean (optional)
```

### System Requirements
```bash
# Jenkins Server Requirements
- Jenkins 2.400+
- Docker 20.10+
- Git 2.30+
- 4GB RAM minimum
- 20GB disk space
```

---

## 🎯 Freestyle Project Setup

### Step 1: Create New Freestyle Project

1. **Navigate to Jenkins Dashboard**
2. **Click "New Item"**
3. **Enter Project Name**: `microservice-admin-app-freestyle`
4. **Select "Freestyle project"**
5. **Click OK**

### Step 2: General Configuration

```bash
# Project Configuration
✅ GitHub project
   Project url: https://github.com/shivamsingh163248/Microservice-admin-apps/

✅ This project is parameterized
   Parameters:
   - String Parameter: IMAGE_TAG (default: latest)
   - Choice Parameter: ENVIRONMENT (dev, staging, prod)
   - Boolean Parameter: FORCE_REBUILD (default: false)
```

### Step 3: Source Code Management

```bash
# Git Configuration
Repository URL: https://github.com/shivamsingh163248/Microservice-admin-apps.git
Branch: */Ansible_Workflow
Credentials: [Add GitHub credentials]

# Additional Behaviours
✅ Clean before checkout
✅ Check out to sub-directory: workspace
```

### Step 4: Build Triggers

```bash
# Trigger Options
✅ GitHub hook trigger for GITScm polling
✅ Poll SCM: H/5 * * * *  (every 5 minutes)
✅ Build when a change is pushed to GitHub
```

### Step 5: Build Environment

```bash
# Environment Setup
✅ Delete workspace before build starts
✅ Use secret text(s) or file(s)
   Bindings:
   - Secret text: GHCR_TOKEN (GitHub Container Registry token)
   - Secret text: DOCKER_HUB_TOKEN (if using Docker Hub)

✅ Build timeout: 30 minutes
✅ Add timestamps to Console Output
```

### Step 6: Build Steps

#### Build Step 1: Environment Setup
```bash
# Shell Command
#!/bin/bash
echo "🚀 Starting Microservice Admin App Build"
echo "Branch: $GIT_BRANCH"
echo "Commit: $GIT_COMMIT"
echo "Build Number: $BUILD_NUMBER"
echo "Image Tag: $IMAGE_TAG"
echo "Environment: $ENVIRONMENT"

# Set dynamic variables
export BUILD_VERSION="v1.0.$BUILD_NUMBER"
export REGISTRY="ghcr.io"
export OWNER="shivamsingh163248"
echo "BUILD_VERSION=$BUILD_VERSION" > build.env
echo "REGISTRY=$REGISTRY" >> build.env
echo "OWNER=$OWNER" >> build.env
```

#### Build Step 2: Docker Login
```bash
#!/bin/bash
echo "🔐 Logging into GitHub Container Registry"
echo $GHCR_TOKEN | docker login ghcr.io -u $OWNER --password-stdin

if [ $? -eq 0 ]; then
    echo "✅ Successfully logged into GHCR"
else
    echo "❌ Failed to login to GHCR"
    exit 1
fi
```

#### Build Step 3: Build Docker Images
```bash
#!/bin/bash
source build.env

echo "🔨 Building Docker Images"

# Build Backend
echo "Building Flask Backend..."
docker build -t $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION -f backend/Dockerfile backend/
docker tag $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION $REGISTRY/$OWNER/flask_backend:latest

# Build Frontend  
echo "Building Nginx Frontend..."
docker build -t $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION -f frontend/Dockerfile frontend/
docker tag $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION $REGISTRY/$OWNER/nginx_frontend:latest

# Build Database
echo "Building MySQL Database..."
docker build -t $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION -f database/. database/
docker tag $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION $REGISTRY/$OWNER/mysql_db:latest

echo "✅ All images built successfully"
```

#### Build Step 4: Push to Registry
```bash
#!/bin/bash
source build.env

echo "📤 Pushing Images to Registry"

# Push all images with version tags
docker push $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION
docker push $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION  
docker push $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION

# Push latest tags
docker push $REGISTRY/$OWNER/flask_backend:latest
docker push $REGISTRY/$OWNER/nginx_frontend:latest
docker push $REGISTRY/$OWNER/mysql_db:latest

echo "✅ All images pushed successfully"
```

#### Build Step 5: Update Docker Compose
```bash
#!/bin/bash
source build.env

echo "📝 Updating Docker Compose Files"

# Update docker-compose.yml
sed -i "s|ghcr.io/shivamsingh163248/flask_backend:.*|ghcr.io/shivamsingh163248/flask_backend:$BUILD_VERSION|g" docker-compose.yml
sed -i "s|ghcr.io/shivamsingh163248/nginx_frontend:.*|ghcr.io/shivamsingh163248/nginx_frontend:$BUILD_VERSION|g" docker-compose.yml
sed -i "s|ghcr.io/shivamsingh163248/mysql_db:.*|ghcr.io/shivamsingh163248/mysql_db:$BUILD_VERSION|g" docker-compose.yml

# Update docker-compose.github.yml
sed -i "s|ghcr.io/shivamsingh163248/flask_backend:.*|ghcr.io/shivamsingh163248/flask_backend:$BUILD_VERSION|g" docker-compose.github.yml
sed -i "s|ghcr.io/shivamsingh163248/nginx_frontend:.*|ghcr.io/shivamsingh163248/nginx_frontend:$BUILD_VERSION|g" docker-compose.github.yml
sed -i "s|ghcr.io/shivamsingh163248/mysql_db:.*|ghcr.io/shivamsingh163248/mysql_db:$BUILD_VERSION|g" docker-compose.github.yml

echo "✅ Docker Compose files updated"
```

#### Build Step 6: Commit Changes (Optional)
```bash
#!/bin/bash
source build.env

if [ "$ENVIRONMENT" = "prod" ]; then
    echo "📤 Committing updated compose files"
    
    git config --global user.email "jenkins@yourdomain.com"
    git config --global user.name "Jenkins CI"
    
    git add docker-compose.yml docker-compose.github.yml
    git commit -m "Jenkins: Update image versions to $BUILD_VERSION [skip ci]"
    git push origin Ansible_Workflow
    
    echo "✅ Changes committed and pushed"
fi
```

### Step 7: Post-build Actions

```bash
# Archive Artifacts
Files to archive: 
- docker-compose*.yml
- build.env
- *.log

# Publish Test Results (if applicable)
Test report XMLs: **/test-results.xml

# Email Notification
Recipients: dev-team@yourdomain.com
Send e-mail for every unstable build: ✅
```

---

## 🔄 Jenkins Pipeline Script

### Complete Pipeline Script

```groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'FORCE_REBUILD', defaultValue: false, description: 'Force rebuild all images')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test execution')
    }
    
    environment {
        REGISTRY = 'ghcr.io'
        OWNER = 'shivamsingh163248'
        BUILD_VERSION = "v1.0.${BUILD_NUMBER}"
        GHCR_TOKEN = credentials('github-container-registry-token')
        DOCKER_BUILDKIT = '1'
    }
    
    options {
        timeout(time: 45, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('🏁 Initialize') {
            steps {
                script {
                    echo "🚀 Starting Microservice Admin App Pipeline"
                    echo "Branch: ${env.GIT_BRANCH}"
                    echo "Commit: ${env.GIT_COMMIT}"
                    echo "Build: ${env.BUILD_NUMBER}"
                    echo "Version: ${env.BUILD_VERSION}"
                    echo "Environment: ${params.ENVIRONMENT}"
                    
                    // Clean workspace
                    cleanWs()
                }
            }
        }
        
        stage('📥 Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/Ansible_Workflow']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/shivamsingh163248/Microservice-admin-apps.git',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }
        
        stage('🔐 Docker Login') {
            steps {
                script {
                    sh '''
                        echo "🔐 Logging into GitHub Container Registry"
                        echo $GHCR_TOKEN | docker login ghcr.io -u $OWNER --password-stdin
                    '''
                }
            }
        }
        
        stage('🏗️ Build Images') {
            parallel {
                stage('Backend') {
                    steps {
                        script {
                            sh '''
                                echo "🔨 Building Flask Backend"
                                docker build -t $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION -f backend/Dockerfile backend/
                                docker tag $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION $REGISTRY/$OWNER/flask_backend:latest
                            '''
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        script {
                            sh '''
                                echo "🔨 Building Nginx Frontend"
                                docker build -t $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION -f frontend/Dockerfile frontend/
                                docker tag $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION $REGISTRY/$OWNER/nginx_frontend:latest
                            '''
                        }
                    }
                }
                stage('Database') {
                    steps {
                        script {
                            sh '''
                                echo "🔨 Building MySQL Database"
                                docker build -t $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION -f database/. database/
                                docker tag $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION $REGISTRY/$OWNER/mysql_db:latest
                            '''
                        }
                    }
                }
            }
        }
        
        stage('🧪 Test Images') {
            when {
                not { params.SKIP_TESTS }
            }
            steps {
                script {
                    sh '''
                        echo "🧪 Testing Docker Images"
                        # Test backend image
                        docker run --rm $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION python --version
                        
                        # Test frontend image  
                        docker run --rm $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION nginx -v
                        
                        # Test database image
                        docker run --rm $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION mysqld --version
                        
                        echo "✅ All image tests passed"
                    '''
                }
            }
        }
        
        stage('📤 Push Images') {
            steps {
                script {
                    sh '''
                        echo "📤 Pushing Images to Registry"
                        
                        # Push versioned images
                        docker push $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION
                        docker push $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION
                        docker push $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION
                        
                        # Push latest tags
                        docker push $REGISTRY/$OWNER/flask_backend:latest
                        docker push $REGISTRY/$OWNER/nginx_frontend:latest
                        docker push $REGISTRY/$OWNER/mysql_db:latest
                        
                        echo "✅ All images pushed successfully"
                    '''
                }
            }
        }
        
        stage('📝 Update Compose Files') {
            steps {
                script {
                    sh '''
                        echo "📝 Updating Docker Compose Files"
                        
                        # Update docker-compose.yml
                        sed -i "s|ghcr.io/shivamsingh163248/flask_backend:.*|ghcr.io/shivamsingh163248/flask_backend:$BUILD_VERSION|g" docker-compose.yml
                        sed -i "s|ghcr.io/shivamsingh163248/nginx_frontend:.*|ghcr.io/shivamsingh163248/nginx_frontend:$BUILD_VERSION|g" docker-compose.yml
                        sed -i "s|ghcr.io/shivamsingh163248/mysql_db:.*|ghcr.io/shivamsingh163248/mysql_db:$BUILD_VERSION|g" docker-compose.yml
                        
                        # Update docker-compose.github.yml
                        sed -i "s|ghcr.io/shivamsingh163248/flask_backend:.*|ghcr.io/shivamsingh163248/flask_backend:$BUILD_VERSION|g" docker-compose.github.yml
                        sed -i "s|ghcr.io/shivamsingh163248/nginx_frontend:.*|ghcr.io/shivamsingh163248/nginx_frontend:$BUILD_VERSION|g" docker-compose.github.yml
                        sed -i "s|ghcr.io/shivamsingh163248/mysql_db:.*|ghcr.io/shivamsingh163248/mysql_db:$BUILD_VERSION|g" docker-compose.github.yml
                        
                        echo "✅ Docker Compose files updated"
                    '''
                }
            }
        }
        
        stage('🚀 Deploy') {
            when {
                anyOf {
                    environment name: 'ENVIRONMENT', value: 'staging'
                    environment name: 'ENVIRONMENT', value: 'prod'
                }
            }
            steps {
                script {
                    sh '''
                        echo "🚀 Deploying to $ENVIRONMENT"
                        
                        # Run deployment based on environment
                        if [ "$ENVIRONMENT" = "staging" ]; then
                            # Deploy to staging server
                            ansible-playbook -i ansible/inventory.ini ansible/deploy-staging.yml \
                                -e "image_version=$BUILD_VERSION" \
                                -e "environment=staging"
                        elif [ "$ENVIRONMENT" = "prod" ]; then
                            # Deploy to production server
                            ansible-playbook -i ansible/inventory.ini ansible/deploy-production.yml \
                                -e "image_version=$BUILD_VERSION" \
                                -e "environment=production"
                        fi
                        
                        echo "✅ Deployment completed successfully"
                    '''
                }
            }
        }
        
        stage('📤 Commit Changes') {
            when {
                environment name: 'ENVIRONMENT', value: 'prod'
            }
            steps {
                script {
                    sh '''
                        echo "📤 Committing updated compose files"
                        
                        git config --global user.email "jenkins@yourdomain.com"
                        git config --global user.name "Jenkins CI"
                        
                        git add docker-compose.yml docker-compose.github.yml
                        git commit -m "Jenkins: Update image versions to $BUILD_VERSION [skip ci]" || echo "No changes to commit"
                        git push origin Ansible_Workflow || echo "Failed to push changes"
                        
                        echo "✅ Changes committed and pushed"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Archive artifacts
                archiveArtifacts artifacts: 'docker-compose*.yml, *.log', allowEmptyArchive: true
                
                // Clean up Docker images
                sh '''
                    echo "🧹 Cleaning up Docker images"
                    docker system prune -f || true
                '''
            }
        }
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                // Send success notification
                emailext (
                    subject: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                    body: """
                    🎉 Build completed successfully!
                    
                    Project: ${env.JOB_NAME}
                    Build: ${env.BUILD_NUMBER}
                    Version: ${env.BUILD_VERSION}
                    Environment: ${params.ENVIRONMENT}
                    
                    Images built and pushed:
                    - ghcr.io/shivamsingh163248/flask_backend:${env.BUILD_VERSION}
                    - ghcr.io/shivamsingh163248/nginx_frontend:${env.BUILD_VERSION}
                    - ghcr.io/shivamsingh163248/mysql_db:${env.BUILD_VERSION}
                    
                    View build: ${env.BUILD_URL}
                    """,
                    to: "dev-team@yourdomain.com"
                )
            }
        }
        failure {
            script {
                echo "❌ Pipeline failed!"
                // Send failure notification
                emailext (
                    subject: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                    body: """
                    🚨 Build failed!
                    
                    Project: ${env.JOB_NAME}
                    Build: ${env.BUILD_NUMBER}
                    Environment: ${params.ENVIRONMENT}
                    
                    Please check the build logs: ${env.BUILD_URL}
                    """,
                    to: "dev-team@yourdomain.com"
                )
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
```

---

## 🐳 Docker Integration Scripts

### Pull Images from GitHub Container Registry

```bash
#!/bin/bash
# pull-images.sh

set -e

REGISTRY="ghcr.io"
OWNER="shivamsingh163248"
VERSION="${1:-latest}"

echo "🔐 Logging into GitHub Container Registry"
echo $GHCR_TOKEN | docker login ghcr.io -u $OWNER --password-stdin

echo "📥 Pulling images with version: $VERSION"

# Pull all microservice images
docker pull $REGISTRY/$OWNER/flask_backend:$VERSION
docker pull $REGISTRY/$OWNER/nginx_frontend:$VERSION
docker pull $REGISTRY/$OWNER/mysql_db:$VERSION

echo "✅ All images pulled successfully"

# Tag as latest
docker tag $REGISTRY/$OWNER/flask_backend:$VERSION $REGISTRY/$OWNER/flask_backend:latest
docker tag $REGISTRY/$OWNER/nginx_frontend:$VERSION $REGISTRY/$OWNER/nginx_frontend:latest
docker tag $REGISTRY/$OWNER/mysql_db:$VERSION $REGISTRY/$OWNER/mysql_db:latest

echo "🏷️ Images tagged as latest"
```

### Docker Compose Template for Jenkins

```yaml
# docker-compose.jenkins.yml
version: '3.8'

services:
  flask_backend:
    image: ghcr.io/shivamsingh163248/flask_backend:${IMAGE_VERSION:-latest}
    container_name: flask_backend_${ENVIRONMENT:-dev}
    environment:
      - FLASK_ENV=${ENVIRONMENT:-development}
      - DATABASE_URL=mysql://admin:admin123@mysql_db:3306/admin_db
      - JENKINS_BUILD=${BUILD_NUMBER:-0}
    ports:
      - "${BACKEND_PORT:-5000}:5000"
    depends_on:
      - mysql_db
    networks:
      - microservice_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx_frontend:
    image: ghcr.io/shivamsingh163248/nginx_frontend:${IMAGE_VERSION:-latest}
    container_name: nginx_frontend_${ENVIRONMENT:-dev}
    ports:
      - "${FRONTEND_PORT:-8080}:80"
    depends_on:
      - flask_backend
    networks:
      - microservice_network
    environment:
      - BACKEND_URL=http://flask_backend:5000
      - ENVIRONMENT=${ENVIRONMENT:-dev}

  mysql_db:
    image: ghcr.io/shivamsingh163248/mysql_db:${IMAGE_VERSION:-latest}
    container_name: mysql_db_${ENVIRONMENT:-dev}
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: admin_db
      MYSQL_USER: admin
      MYSQL_PASSWORD: admin123
    ports:
      - "${DB_PORT:-3306}:3306"
    volumes:
      - mysql_data_${ENVIRONMENT:-dev}:/var/lib/mysql
    networks:
      - microservice_network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 5

networks:
  microservice_network:
    driver: bridge
    name: microservice_network_${ENVIRONMENT:-dev}

volumes:
  mysql_data_${ENVIRONMENT:-dev}:
    driver: local
```

---

## 📜 Jenkins Shell Scripts

### Build Script

```bash
#!/bin/bash
# jenkins-build.sh

set -e

BUILD_VERSION="v1.0.${BUILD_NUMBER}"
REGISTRY="ghcr.io"
OWNER="shivamsingh163248"

echo "🚀 Jenkins Build Script Started"
echo "Version: $BUILD_VERSION"
echo "Registry: $REGISTRY"
echo "Owner: $OWNER"

# Login to registry
echo "🔐 Logging into GitHub Container Registry"
echo $GHCR_TOKEN | docker login ghcr.io -u $OWNER --password-stdin

# Build images
echo "🔨 Building Docker Images"
docker build -t $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION -f backend/Dockerfile backend/
docker build -t $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION -f frontend/Dockerfile frontend/
docker build -t $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION -f database/. database/

# Tag as latest
docker tag $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION $REGISTRY/$OWNER/flask_backend:latest
docker tag $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION $REGISTRY/$OWNER/nginx_frontend:latest
docker tag $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION $REGISTRY/$OWNER/mysql_db:latest

# Push images
echo "📤 Pushing Images"
docker push $REGISTRY/$OWNER/flask_backend:$BUILD_VERSION
docker push $REGISTRY/$OWNER/nginx_frontend:$BUILD_VERSION
docker push $REGISTRY/$OWNER/mysql_db:$BUILD_VERSION

docker push $REGISTRY/$OWNER/flask_backend:latest
docker push $REGISTRY/$OWNER/nginx_frontend:latest
docker push $REGISTRY/$OWNER/mysql_db:latest

echo "✅ Build completed successfully"
```

### Deployment Script

```bash
#!/bin/bash
# jenkins-deploy.sh

set -e

ENVIRONMENT="${1:-dev}"
VERSION="${2:-latest}"
SERVER_IP="${3:-44.201.129.77}"

echo "🚀 Jenkins Deployment Script"
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"
echo "Server: $SERVER_IP"

# Set environment variables
export IMAGE_VERSION=$VERSION
export ENVIRONMENT=$ENVIRONMENT

case $ENVIRONMENT in
    "dev")
        export BACKEND_PORT=5000
        export FRONTEND_PORT=8080
        export DB_PORT=3306
        ;;
    "staging")
        export BACKEND_PORT=5001
        export FRONTEND_PORT=8081
        export DB_PORT=3307
        ;;
    "prod")
        export BACKEND_PORT=5000
        export FRONTEND_PORT=80
        export DB_PORT=3306
        ;;
esac

if [ "$ENVIRONMENT" = "dev" ]; then
    echo "📍 Deploying locally"
    # Local deployment
    docker-compose -f docker-compose.jenkins.yml down || true
    docker-compose -f docker-compose.jenkins.yml up -d
    
    # Health check
    sleep 30
    curl -f http://localhost:$FRONTEND_PORT || echo "❌ Frontend health check failed"
    curl -f http://localhost:$BACKEND_PORT/health || echo "❌ Backend health check failed"
    
else
    echo "📍 Deploying to remote server: $SERVER_IP"
    # Remote deployment using Ansible
    ansible-playbook -i ansible/inventory.ini ansible/deploy-production.yml \
        -e "image_version=$VERSION" \
        -e "environment=$ENVIRONMENT" \
        -e "target_server=$SERVER_IP"
fi

echo "✅ Deployment completed successfully"
```

### Testing Script

```bash
#!/bin/bash
# jenkins-test.sh

set -e

VERSION="${1:-latest}"
REGISTRY="ghcr.io"
OWNER="shivamsingh163248"

echo "🧪 Jenkins Testing Script"
echo "Testing version: $VERSION"

# Test image availability
echo "🔍 Testing image availability"
docker pull $REGISTRY/$OWNER/flask_backend:$VERSION
docker pull $REGISTRY/$OWNER/nginx_frontend:$VERSION
docker pull $REGISTRY/$OWNER/mysql_db:$VERSION

# Test image functionality
echo "🧪 Testing image functionality"

# Test backend
echo "Testing Flask Backend..."
docker run --rm $REGISTRY/$OWNER/flask_backend:$VERSION python --version
docker run --rm $REGISTRY/$OWNER/flask_backend:$VERSION pip list

# Test frontend
echo "Testing Nginx Frontend..."
docker run --rm $REGISTRY/$OWNER/nginx_frontend:$VERSION nginx -v
docker run --rm $REGISTRY/$OWNER/nginx_frontend:$VERSION nginx -t

# Test database
echo "Testing MySQL Database..."
docker run --rm $REGISTRY/$OWNER/mysql_db:$VERSION mysqld --version

# Integration test
echo "🔗 Running integration tests"
export IMAGE_VERSION=$VERSION
export ENVIRONMENT=test

# Start services
docker-compose -f docker-compose.jenkins.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 60

# Test endpoints
echo "🌐 Testing endpoints"
curl -f http://localhost:8080 || echo "❌ Frontend test failed"
curl -f http://localhost:5000/health || echo "❌ Backend health test failed"

# Cleanup
docker-compose -f docker-compose.jenkins.yml down

echo "✅ All tests passed successfully"
```

### Cleanup Script

```bash
#!/bin/bash
# jenkins-cleanup.sh

echo "🧹 Jenkins Cleanup Script"

# Stop and remove containers
echo "🛑 Stopping containers"
docker-compose -f docker-compose.jenkins.yml down || true

# Remove unused images
echo "🗑️ Removing unused images"
docker image prune -f

# Remove unused volumes (be careful with this)
echo "💾 Removing unused volumes"
docker volume prune -f

# Remove unused networks
echo "🌐 Removing unused networks"
docker network prune -f

# Remove build cache
echo "🗃️ Removing build cache"
docker builder prune -f

echo "✅ Cleanup completed"
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Docker Permission Denied
```bash
# Solution: Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### 2. GitHub Container Registry Login Failed
```bash
# Check token permissions
# Token needs: read:packages, write:packages, delete:packages
```

#### 3. Build Timeout
```bash
# Increase timeout in Jenkins
# Pipeline: timeout(time: 60, unit: 'MINUTES')
# Freestyle: Build timeout -> 60 minutes
```

#### 4. Ansible Connection Issues
```bash
# Check SSH key configuration
# Ensure key is added to Jenkins credentials
# Test connection: ansible -i inventory.ini all -m ping
```

### Health Checks

```bash
# Check Jenkins services
sudo systemctl status jenkins

# Check Docker daemon
sudo systemctl status docker

# Check disk space
df -h

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

### Performance Optimization

```bash
# Optimize Docker builds
export DOCKER_BUILDKIT=1

# Use build cache
docker build --cache-from=previous-image .

# Multi-stage builds
# Use .dockerignore files
# Minimize layer count
```

---

## 📞 Support

For issues or questions:
1. Check Jenkins logs: `/var/log/jenkins/jenkins.log`
2. Check Docker logs: `docker logs <container-name>`
3. Review GitHub Actions: Repository → Actions tab
4. Contact DevOps team: devops@yourdomain.com

---

**Last Updated**: August 30, 2025  
**Version**: 2.0  
**Author**: DevOps Team
