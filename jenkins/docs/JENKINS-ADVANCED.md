# Jenkins Advanced Features Guide for Microservice Admin App

## 📋 Table of Contents
- [Master-Slave Configuration](#master-slave-configuration)
- [Blue Ocean Implementation](#blue-ocean-implementation)
- [Pipeline Libraries](#pipeline-libraries)
- [Kubernetes Integration](#kubernetes-integration)
- [Enterprise Features](#enterprise-features)
- [Performance Tuning](#performance-tuning)
- [Security Hardening](#security-hardening)
- [Disaster Recovery](#disaster-recovery)
- [Scaling Strategies](#scaling-strategies)
- [Advanced Monitoring](#advanced-monitoring)

## 🏗️ Master-Slave Configuration

### Setting Up Distributed Builds

#### Step 1: Configure Master Node
```text
Navigate: Manage Jenkins → Manage Nodes and Clouds → Configure Clouds

Master Configuration:
  # of executors: 0 (Master should not run builds)
  Labels: master
  Usage: Only build jobs with label expressions matching this node
  
Node Properties:
  Environment variables:
    JENKINS_ROLE=master
    NODE_TYPE=controller
```

#### Step 2: Create SSH Agent Node
```text
Navigate: Manage Jenkins → Manage Nodes and Clouds → New Node

Node Configuration:
  Name: jenkins-agent-1
  Description: Build Agent for Docker Operations
  # of executors: 4
  Remote root directory: /home/jenkins
  Labels: docker linux build-agent
  Usage: Use this node as much as possible
  Launch method: Launch agents via SSH
  
SSH Configuration:
  Host: 10.0.1.50
  Credentials: ssh-agent-key
  Host Key Verification Strategy: Manually trusted key Verification Strategy
  
Advanced SSH Options:
  Port: 22
  JavaPath: /usr/bin/java
  JVM Options: -Xmx2g
  Connection Timeout: 60
  Maximum Number of Retries: 3
  Retry Wait Time: 15
```

#### Step 3: Dynamic Agent Provisioning
```groovy
// Jenkins Pipeline with Dynamic Agent
pipeline {
    agent none
    
    stages {
        stage('Parallel Builds') {
            parallel {
                stage('Frontend Build') {
                    agent {
                        label 'frontend-agent'
                    }
                    steps {
                        script {
                            echo "Building on Frontend Agent: ${env.NODE_NAME}"
                            sh '''
                                node --version
                                npm --version
                                cd frontend
                                npm install
                                npm run build
                                npm run test
                            '''
                        }
                    }
                }
                
                stage('Backend Build') {
                    agent {
                        label 'backend-agent'
                    }
                    steps {
                        script {
                            echo "Building on Backend Agent: ${env.NODE_NAME}"
                            sh '''
                                python3 --version
                                pip3 --version
                                cd backend
                                pip3 install -r requirements.txt
                                python3 -m pytest tests/
                                python3 app.py --test
                            '''
                        }
                    }
                }
                
                stage('Docker Build') {
                    agent {
                        label 'docker-agent'
                    }
                    steps {
                        script {
                            echo "Building on Docker Agent: ${env.NODE_NAME}"
                            sh '''
                                docker --version
                                docker-compose --version
                                docker build -t microservice-app .
                                docker images | grep microservice-app
                            '''
                        }
                    }
                }
            }
        }
    }
}
```

#### Step 4: Agent Health Monitoring
```groovy
// Agent Health Check Pipeline
pipeline {
    agent { label 'master' }
    
    triggers {
        cron('*/15 * * * *') // Every 15 minutes
    }
    
    stages {
        stage('Agent Health Check') {
            steps {
                script {
                    def agents = Jenkins.instance.nodes
                    
                    agents.each { agent ->
                        def computer = agent.computer
                        def agentName = agent.name
                        
                        echo "Checking agent: ${agentName}"
                        
                        if (computer.isOffline()) {
                            echo "⚠️ Agent ${agentName} is OFFLINE"
                            // Send alert
                            emailext (
                                subject: "⚠️ Jenkins Agent Offline: ${agentName}",
                                body: "Agent ${agentName} has gone offline. Please investigate.",
                                to: "${env.ADMIN_EMAIL}"
                            )
                        } else {
                            echo "✅ Agent ${agentName} is ONLINE"
                            
                            // Check agent disk space
                            def diskSpace = computer.getChannel()?.call(new hudson.node.monitors.DiskSpaceMonitor.DiskSpace())
                            if (diskSpace && diskSpace.size < 1000000000) { // Less than 1GB
                                echo "⚠️ Agent ${agentName} low disk space: ${diskSpace.size / 1000000}MB"
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## 🌊 Blue Ocean Implementation

### Setting Up Blue Ocean

#### Step 1: Install Blue Ocean Plugin
```text
Navigate: Manage Jenkins → Manage Plugins → Available

Search and Install:
✅ Blue Ocean
✅ Blue Ocean Pipeline Editor
✅ Blue Ocean GitHub Pipeline
✅ Blue Ocean Executor Info
✅ Blue Ocean JWT
```

#### Step 2: Configure GitHub Integration
```text
Navigate: Blue Ocean → New Pipeline → GitHub

GitHub Integration Setup:
1. Click "Create an access token here"
2. GitHub redirects to token creation
3. Select scopes:
   ✅ repo (Full control of private repositories)
   ✅ admin:repo_hook (Admin access to repository hooks)
   ✅ admin:org_hook (Admin access to organization hooks)
4. Generate token and paste in Blue Ocean
5. Select organization: shivamsingh163248
6. Select repository: Microservice-admin-apps
```

#### Step 3: Visual Pipeline Editor
Create pipeline using Blue Ocean visual editor:

```yaml
# Blue Ocean Pipeline Configuration
Pipeline:
  Agent: Any
  
  Stages:
    - name: "Checkout"
      steps:
        - checkout: scm
        
    - name: "Parallel Builds"
      parallel:
        - name: "Frontend"
          agent: 
            label: "frontend"
          steps:
            - sh: "cd frontend && npm install && npm run build"
            
        - name: "Backend"
          agent:
            label: "backend"
          steps:
            - sh: "cd backend && pip install -r requirements.txt && python -m pytest"
            
        - name: "Database"
          agent:
            label: "docker"
          steps:
            - sh: "cd database && docker build -t mysql-db ."
            
    - name: "Integration Tests"
      steps:
        - sh: "docker-compose -f docker-compose.test.yml up --abort-on-container-exit"
        
    - name: "Security Scan"
      steps:
        - sh: "trivy image microservice-app:latest"
        
    - name: "Deploy"
      when:
        branch: "main"
      steps:
        - sh: "ansible-playbook -i inventory/production playbooks/deploy.yml"
```

#### Step 4: Blue Ocean Dashboard Customization
```groovy
// Customize Blue Ocean dashboard
import jenkins.model.Jenkins
import org.jenkinsci.plugins.blueocean.BlueOceanPlugin

// Configure Blue Ocean settings
def blueOcean = Jenkins.instance.getPlugin(BlueOceanPlugin.class)
if (blueOcean) {
    // Set custom theme
    System.setProperty("blueocean.feature.flag.theme", "dark")
    
    // Enable experimental features
    System.setProperty("blueocean.feature.flag.experimental", "true")
    
    // Configure pipeline editor
    System.setProperty("blueocean.feature.flag.pipeline-editor", "true")
}
```

## 📚 Pipeline Libraries

### Creating Shared Pipeline Libraries

#### Step 1: Create Shared Library Repository
```bash
# Create shared library structure
mkdir jenkins-shared-library
cd jenkins-shared-library

# Create directory structure
mkdir -p vars
mkdir -p src/com/company/jenkins
mkdir -p resources

# Example directory structure:
# jenkins-shared-library/
# ├── vars/
# │   ├── deployMicroservice.groovy
# │   ├── buildDockerImage.groovy
# │   ├── runTests.groovy
# │   └── sendNotification.groovy
# ├── src/
# │   └── com/
# │       └── company/
# │           └── jenkins/
# │               ├── DockerUtils.groovy
# │               ├── GitUtils.groovy
# │               └── NotificationUtils.groovy
# └── resources/
#     ├── templates/
#     │   ├── Dockerfile.template
#     │   └── docker-compose.template
#     └── scripts/
#         ├── deploy.sh
#         └── test.sh
```

#### Step 2: Create Global Variables

**vars/buildDockerImage.groovy:**
```groovy
#!/usr/bin/env groovy

def call(Map config) {
    echo "🔨 Building Docker Image: ${config.imageName}"
    
    def imageName = config.imageName ?: 'app'
    def imageTag = config.imageTag ?: env.BUILD_NUMBER
    def dockerFile = config.dockerFile ?: 'Dockerfile'
    def buildContext = config.buildContext ?: '.'
    def registry = config.registry ?: 'docker.io'
    def namespace = config.namespace ?: 'company'
    
    def fullImageName = "${registry}/${namespace}/${imageName}:${imageTag}"
    
    script {
        try {
            // Build the image
            sh """
                docker build \\
                    -f ${dockerFile} \\
                    -t ${fullImageName} \\
                    ${buildContext}
            """
            
            // Tag as latest if main branch
            if (env.BRANCH_NAME == 'main') {
                sh "docker tag ${fullImageName} ${registry}/${namespace}/${imageName}:latest"
            }
            
            echo "✅ Image built successfully: ${fullImageName}"
            return fullImageName
            
        } catch (Exception e) {
            echo "❌ Failed to build image: ${e.getMessage()}"
            throw e
        }
    }
}

def call(String imageName, String imageTag = env.BUILD_NUMBER) {
    return call([
        imageName: imageName,
        imageTag: imageTag
    ])
}
```

**vars/deployMicroservice.groovy:**
```groovy
#!/usr/bin/env groovy

def call(Map config) {
    echo "🚀 Deploying Microservice: ${config.serviceName}"
    
    def serviceName = config.serviceName
    def environment = config.environment ?: 'development'
    def imageTag = config.imageTag ?: env.BUILD_NUMBER
    def deploymentMethod = config.deploymentMethod ?: 'docker-compose'
    def healthCheckUrl = config.healthCheckUrl
    def rollbackOnFailure = config.rollbackOnFailure ?: true
    
    script {
        try {
            // Pre-deployment validation
            validateDeploymentConfig(config)
            
            // Deploy based on method
            switch (deploymentMethod) {
                case 'docker-compose':
                    deployWithDockerCompose(config)
                    break
                case 'kubernetes':
                    deployWithKubernetes(config)
                    break
                case 'ansible':
                    deployWithAnsible(config)
                    break
                default:
                    error("Unsupported deployment method: ${deploymentMethod}")
            }
            
            // Health check
            if (healthCheckUrl) {
                performHealthCheck(healthCheckUrl)
            }
            
            echo "✅ Deployment successful: ${serviceName} to ${environment}"
            
        } catch (Exception e) {
            echo "❌ Deployment failed: ${e.getMessage()}"
            
            if (rollbackOnFailure) {
                echo "🔄 Rolling back deployment..."
                rollbackDeployment(config)
            }
            
            throw e
        }
    }
}

def validateDeploymentConfig(Map config) {
    if (!config.serviceName) {
        error("serviceName is required")
    }
    if (!config.imageTag) {
        error("imageTag is required")
    }
}

def deployWithDockerCompose(Map config) {
    sh """
        export SERVICE_NAME=${config.serviceName}
        export IMAGE_TAG=${config.imageTag}
        export ENVIRONMENT=${config.environment}
        
        envsubst < docker-compose.template.yml > docker-compose.${config.environment}.yml
        docker-compose -f docker-compose.${config.environment}.yml up -d
    """
}

def deployWithKubernetes(Map config) {
    sh """
        helm upgrade --install ${config.serviceName} \\
            --set image.tag=${config.imageTag} \\
            --set environment=${config.environment} \\
            ./helm/${config.serviceName}
    """
}

def deployWithAnsible(Map config) {
    sh """
        ansible-playbook \\
            -i inventory/${config.environment} \\
            -e service_name=${config.serviceName} \\
            -e image_tag=${config.imageTag} \\
            playbooks/deploy-microservice.yml
    """
}

def performHealthCheck(String healthCheckUrl) {
    echo "🏥 Performing health check: ${healthCheckUrl}"
    
    retry(5) {
        sleep(10)
        sh "curl -f ${healthCheckUrl} || exit 1"
    }
    
    echo "✅ Health check passed"
}

def rollbackDeployment(Map config) {
    echo "🔄 Rolling back ${config.serviceName}"
    // Implementation depends on deployment method
    // This is a simplified example
    sh "docker-compose -f docker-compose.${config.environment}.yml down"
}
```

**vars/runTests.groovy:**
```groovy
#!/usr/bin/env groovy

def call(Map config) {
    echo "🧪 Running Tests: ${config.testType}"
    
    def testType = config.testType ?: 'unit'
    def testPath = config.testPath ?: 'tests/'
    def testCommand = config.testCommand
    def coverageThreshold = config.coverageThreshold ?: 80
    def publishResults = config.publishResults ?: true
    
    script {
        try {
            // Run tests based on type
            switch (testType) {
                case 'unit':
                    runUnitTests(config)
                    break
                case 'integration':
                    runIntegrationTests(config)
                    break
                case 'e2e':
                    runE2ETests(config)
                    break
                case 'security':
                    runSecurityTests(config)
                    break
                case 'performance':
                    runPerformanceTests(config)
                    break
                default:
                    runCustomTests(config)
            }
            
            // Publish test results
            if (publishResults) {
                publishTestResults(config)
            }
            
            echo "✅ Tests completed successfully: ${testType}"
            
        } catch (Exception e) {
            echo "❌ Tests failed: ${e.getMessage()}"
            throw e
        }
    }
}

def runUnitTests(Map config) {
    def language = config.language ?: detectLanguage()
    
    switch (language) {
        case 'javascript':
            sh "cd ${config.testPath} && npm test"
            break
        case 'python':
            sh "cd ${config.testPath} && python -m pytest --cov=. --cov-report=xml"
            break
        case 'java':
            sh "cd ${config.testPath} && mvn test"
            break
        default:
            sh config.testCommand
    }
}

def runIntegrationTests(Map config) {
    echo "🔗 Running integration tests"
    sh """
        docker-compose -f docker-compose.test.yml up -d
        sleep 30
        ${config.testCommand ?: 'npm run test:integration'}
        docker-compose -f docker-compose.test.yml down
    """
}

def runE2ETests(Map config) {
    echo "🌐 Running end-to-end tests"
    sh """
        # Start application
        docker-compose up -d
        sleep 60
        
        # Run E2E tests
        ${config.testCommand ?: 'npm run test:e2e'}
        
        # Cleanup
        docker-compose down
    """
}

def runSecurityTests(Map config) {
    echo "🔒 Running security tests"
    sh """
        # OWASP ZAP security scan
        docker run -t owasp/zap2docker-stable zap-baseline.py \\
            -t ${config.targetUrl ?: 'http://localhost:8080'}
        
        # Trivy container scan
        trivy image ${config.imageName ?: 'app:latest'}
        
        # Bandit security linting (Python)
        bandit -r ${config.testPath ?: '.'} -f json -o security-report.json
    """
}

def runPerformanceTests(Map config) {
    echo "⚡ Running performance tests"
    sh """
        # Artillery.io load testing
        artillery run ${config.testScript ?: 'performance/load-test.yml'}
        
        # K6 performance testing
        k6 run ${config.testScript ?: 'performance/stress-test.js'}
    """
}

def publishTestResults(Map config) {
    // Publish JUnit test results
    if (fileExists('test-results.xml')) {
        publishTestResults([
            testResultsPattern: 'test-results.xml',
            allowEmptyResults: false
        ])
    }
    
    // Publish coverage reports
    if (fileExists('coverage.xml')) {
        publishCoverageResults([
            coberturaReportFile: 'coverage.xml'
        ])
    }
    
    // Publish HTML reports
    if (fileExists('coverage/index.html')) {
        publishHTML([
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'coverage',
            reportFiles: 'index.html',
            reportName: 'Coverage Report'
        ])
    }
}

def detectLanguage() {
    if (fileExists('package.json')) {
        return 'javascript'
    } else if (fileExists('requirements.txt')) {
        return 'python'
    } else if (fileExists('pom.xml')) {
        return 'java'
    } else if (fileExists('go.mod')) {
        return 'go'
    } else {
        return 'unknown'
    }
}
```

**vars/sendNotification.groovy:**
```groovy
#!/usr/bin/env groovy

def call(Map config) {
    echo "📢 Sending Notification: ${config.type}"
    
    def type = config.type ?: 'email'
    def status = config.status ?: currentBuild.currentResult
    def message = config.message ?: getDefaultMessage(status)
    def recipients = config.recipients ?: env.DEFAULT_RECIPIENTS
    
    script {
        switch (type) {
            case 'email':
                sendEmailNotification(config, message)
                break
            case 'slack':
                sendSlackNotification(config, message)
                break
            case 'teams':
                sendTeamsNotification(config, message)
                break
            case 'webhook':
                sendWebhookNotification(config, message)
                break
            default:
                echo "Unknown notification type: ${type}"
        }
    }
}

def sendEmailNotification(Map config, String message) {
    def subject = getEmailSubject(config.status)
    
    emailext (
        subject: subject,
        body: message,
        to: config.recipients,
        mimeType: 'text/html',
        attachmentsPattern: config.attachments ?: ''
    )
}

def sendSlackNotification(Map config, String message) {
    def color = getSlackColor(config.status)
    def channel = config.channel ?: '#jenkins'
    
    slackSend (
        channel: channel,
        color: color,
        message: message,
        teamDomain: config.teamDomain ?: 'company',
        token: config.token ?: 'slack-token'
    )
}

def sendTeamsNotification(Map config, String message) {
    def webhookUrl = config.webhookUrl ?: env.TEAMS_WEBHOOK_URL
    def color = getTeamsColor(config.status)
    
    office365ConnectorSend (
        webhookUrl: webhookUrl,
        message: message,
        color: color,
        status: config.status
    )
}

def sendWebhookNotification(Map config, String message) {
    def payload = [
        status: config.status,
        message: message,
        build: [
            number: env.BUILD_NUMBER,
            url: env.BUILD_URL,
            job: env.JOB_NAME,
            branch: env.BRANCH_NAME
        ]
    ]
    
    sh """
        curl -X POST \\
            -H "Content-Type: application/json" \\
            -d '${groovy.json.JsonBuilder(payload).toString()}' \\
            ${config.webhookUrl}
    """
}

def getDefaultMessage(String status) {
    def emoji = getStatusEmoji(status)
    
    return """
        ${emoji} **${env.JOB_NAME}** - Build #${env.BUILD_NUMBER}
        
        **Status:** ${status}
        **Branch:** ${env.BRANCH_NAME ?: 'main'}
        **Commit:** ${env.GIT_COMMIT?.take(8) ?: 'unknown'}
        **Duration:** ${currentBuild.durationString}
        
        [View Build](${env.BUILD_URL})
        [View Console](${env.BUILD_URL}console)
    """
}

def getEmailSubject(String status) {
    def emoji = getStatusEmoji(status)
    return "${emoji} ${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${status}"
}

def getStatusEmoji(String status) {
    switch (status?.toUpperCase()) {
        case 'SUCCESS':
            return '✅'
        case 'FAILURE':
            return '❌'
        case 'UNSTABLE':
            return '⚠️'
        case 'ABORTED':
            return '🛑'
        default:
            return '🔄'
    }
}

def getSlackColor(String status) {
    switch (status?.toUpperCase()) {
        case 'SUCCESS':
            return 'good'
        case 'FAILURE':
            return 'danger'
        case 'UNSTABLE':
            return 'warning'
        default:
            return '#439FE0'
    }
}

def getTeamsColor(String status) {
    switch (status?.toUpperCase()) {
        case 'SUCCESS':
            return '00FF00'
        case 'FAILURE':
            return 'FF0000'
        case 'UNSTABLE':
            return 'FFFF00'
        default:
            return '0078D4'
    }
}
```

#### Step 3: Configure Global Pipeline Libraries

```text
Navigate: Manage Jenkins → Configure System → Global Pipeline Libraries

Library Configuration:
  Name: microservice-shared-library
  Default version: main
  Retrieval method: Modern SCM
  
Source Code Management:
  Git:
    Repository URL: https://github.com/your-org/jenkins-shared-library.git
    Credentials: github-credentials
    
Behaviors:
  - Discover branches
  - Clean before checkout
  
Library Behavior:
  ✅ Allow default version to be overridden
  ✅ Include @Library changes in job recent changes
  ✅ Cache fetched versions on controller for quick retrieval
```

#### Step 4: Use Shared Library in Pipeline

```groovy
// Use shared library in Jenkinsfile
@Library('microservice-shared-library@main') _

pipeline {
    agent any
    
    environment {
        APP_NAME = 'microservice-admin-app'
        REGISTRY = 'docker.io/shivamsingh163248'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            parallel {
                stage('Frontend') {
                    steps {
                        script {
                            def frontendImage = buildDockerImage([
                                imageName: 'nginx_frontend',
                                dockerFile: 'frontend/Dockerfile',
                                buildContext: 'frontend/',
                                registry: env.REGISTRY
                            ])
                            env.FRONTEND_IMAGE = frontendImage
                        }
                    }
                }
                
                stage('Backend') {
                    steps {
                        script {
                            def backendImage = buildDockerImage([
                                imageName: 'flask_backend',
                                dockerFile: 'backend/Dockerfile',
                                buildContext: 'backend/',
                                registry: env.REGISTRY
                            ])
                            env.BACKEND_IMAGE = backendImage
                        }
                    }
                }
                
                stage('Database') {
                    steps {
                        script {
                            def dbImage = buildDockerImage([
                                imageName: 'mysql_db',
                                dockerFile: 'database/Dockerfile',
                                buildContext: 'database/',
                                registry: env.REGISTRY
                            ])
                            env.DATABASE_IMAGE = dbImage
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        runTests([
                            testType: 'unit',
                            language: 'python',
                            testPath: 'backend/',
                            coverageThreshold: 80
                        ])
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        runTests([
                            testType: 'integration',
                            testCommand: 'docker-compose -f docker-compose.test.yml up --abort-on-container-exit'
                        ])
                    }
                }
                
                stage('Security Tests') {
                    steps {
                        runTests([
                            testType: 'security',
                            imageName: env.FRONTEND_IMAGE,
                            targetUrl: 'http://localhost:8080'
                        ])
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def environment = env.BRANCH_NAME == 'main' ? 'production' : 'staging'
                    
                    deployMicroservice([
                        serviceName: env.APP_NAME,
                        environment: environment,
                        imageTag: env.BUILD_NUMBER,
                        deploymentMethod: 'docker-compose',
                        healthCheckUrl: "http://localhost:8080/health"
                    ])
                }
            }
        }
    }
    
    post {
        always {
            sendNotification([
                type: 'email',
                status: currentBuild.currentResult,
                recipients: env.DEFAULT_RECIPIENTS
            ])
        }
        
        success {
            sendNotification([
                type: 'slack',
                status: 'SUCCESS',
                channel: '#deployments'
            ])
        }
        
        failure {
            sendNotification([
                type: 'teams',
                status: 'FAILURE',
                webhookUrl: env.TEAMS_WEBHOOK_URL
            ])
        }
    }
}
```

## ☸️ Kubernetes Integration

### Setting Up Kubernetes Plugin

#### Step 1: Install Kubernetes Plugin
```text
Navigate: Manage Jenkins → Manage Plugins → Available

Install:
✅ Kubernetes Plugin
✅ Kubernetes CLI Plugin
✅ Kubernetes Continuous Deploy Plugin
```

#### Step 2: Configure Kubernetes Cloud

```text
Navigate: Manage Jenkins → Configure System → Cloud → Add a new cloud → Kubernetes

Kubernetes Cloud Configuration:
  Name: kubernetes-cluster
  Kubernetes URL: https://kubernetes.default.svc.cluster.local
  Kubernetes Namespace: jenkins
  
Credentials:
  Add → Kubernetes Service Account
  OR
  Add → Secret file (kubeconfig)
  
Advanced Configuration:
  Connection Timeout: 5 seconds
  Read Timeout: 15 seconds
  Container Cap: 10
  
Pod Labels:
  Key: jenkins
  Value: agent
```

#### Step 3: Configure Pod Templates

**Basic Pod Template:**
```yaml
# Pod template for general builds
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: [$(JENKINS_SECRET), $(JENKINS_NAME)]
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
        
  - name: docker
    image: docker:dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
        
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
        
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
```

**Specialized Pod Templates:**

```yaml
# Frontend build pod
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: frontend-agent
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    
  - name: node
    image: node:18-alpine
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
    volumeMounts:
    - name: npm-cache
      mountPath: /root/.npm
      
  volumes:
  - name: npm-cache
    emptyDir: {}
```

```yaml
# Backend build pod
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: backend-agent
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    
  - name: python
    image: python:3.9-slim
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
    volumeMounts:
    - name: pip-cache
      mountPath: /root/.cache/pip
      
  volumes:
  - name: pip-cache
    emptyDir: {}
```

#### Step 4: Dynamic Kubernetes Agents Pipeline

```groovy
// Pipeline with dynamic Kubernetes agents
pipeline {
    agent none
    
    stages {
        stage('Parallel Kubernetes Builds') {
            parallel {
                stage('Frontend Build') {
                    agent {
                        kubernetes {
                            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: node
    image: node:18-alpine
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
"""
                        }
                    }
                    steps {
                        container('node') {
                            sh '''
                                echo "Building frontend on Kubernetes agent"
                                cd frontend
                                npm install
                                npm run build
                                npm run test
                            '''
                        }
                    }
                }
                
                stage('Backend Build') {
                    agent {
                        kubernetes {
                            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.9-slim
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
"""
                        }
                    }
                    steps {
                        container('python') {
                            sh '''
                                echo "Building backend on Kubernetes agent"
                                cd backend
                                pip install -r requirements.txt
                                python -m pytest tests/
                                python -m flask --app app.py test
                            '''
                        }
                    }
                }
                
                stage('Docker Build') {
                    agent {
                        kubernetes {
                            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:dind
    securityContext:
      privileged: true
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
"""
                        }
                    }
                    steps {
                        container('docker') {
                            sh '''
                                echo "Building Docker images on Kubernetes agent"
                                dockerd-entrypoint.sh &
                                sleep 10
                                
                                docker build -t frontend:${BUILD_NUMBER} frontend/
                                docker build -t backend:${BUILD_NUMBER} backend/
                                docker build -t database:${BUILD_NUMBER} database/
                                
                                docker images
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            agent {
                kubernetes {
                    yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-deployer
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  - name: helm
    image: alpine/helm:latest
    command:
    - cat
    tty: true
"""
                }
            }
            steps {
                container('kubectl') {
                    sh '''
                        echo "Deploying to Kubernetes cluster"
                        kubectl version --client
                        kubectl get nodes
                        kubectl get pods -n jenkins
                    '''
                }
                
                container('helm') {
                    sh '''
                        echo "Deploying with Helm"
                        helm version
                        helm list -A
                        
                        # Deploy microservice
                        helm upgrade --install microservice-admin-app \\
                            --set image.tag=${BUILD_NUMBER} \\
                            --set environment=${BRANCH_NAME} \\
                            ./helm/microservice-admin-app
                    '''
                }
            }
        }
    }
}
```

#### Step 5: Kubernetes Deployment Manifests

**Create Helm Chart:**
```bash
# Create Helm chart structure
mkdir -p helm/microservice-admin-app
cd helm/microservice-admin-app

# Chart.yaml
cat > Chart.yaml << 'EOF'
apiVersion: v2
name: microservice-admin-app
description: A Helm chart for Microservice Admin App
type: application
version: 0.1.0
appVersion: "1.0"
EOF

# values.yaml
cat > values.yaml << 'EOF'
replicaCount: 3

image:
  repository: docker.io/shivamsingh163248
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: microservice-admin-app.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  
nodeSelector: {}
tolerations: []
affinity: {}

environment: development
EOF

# templates/deployment.yaml
mkdir templates
cat > templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservice-admin-app.fullname" . }}
  labels:
    {{- include "microservice-admin-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "microservice-admin-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "microservice-admin-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: frontend
          image: "{{ .Values.image.repository }}/nginx_frontend:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
            
        - name: backend
          image: "{{ .Values.image.repository }}/flask_backend:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 5000
              protocol: TCP
          env:
            - name: ENVIRONMENT
              value: {{ .Values.environment }}
            - name: DB_HOST
              value: {{ include "microservice-admin-app.fullname" . }}-mysql
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
```

## 🏢 Enterprise Features

### LDAP Integration

#### Step 1: Configure LDAP Security Realm
```text
Navigate: Manage Jenkins → Configure Global Security → Security Realm

Security Realm: LDAP

LDAP Configuration:
  Server: ldap://ldap.company.com:389
  Root DN: dc=company,dc=com
  User search base: ou=users
  User search filter: uid={0}
  Group search base: ou=groups
  Group search filter: cn={0}
  Group membership:
    Strategy: Search for LDAP groups containing user
    Filter: (member={0})
    
Manager Configuration:
  Manager DN: cn=jenkins,ou=service-accounts,dc=company,dc=com
  Manager Password: [service-account-password]
  
Advanced Settings:
  Display Name LDAP attribute: displayName
  Email Address LDAP attribute: mail
  
Test LDAP settings: [Test with a known user]
```

#### Step 2: Role-Based Access Control with LDAP Groups

```text
Navigate: Manage Jenkins → Configure Global Security → Authorization

Authorization: Role-based Matrix Authorization Strategy

Global Roles:
  admin:
    Assign to groups: ldap-jenkins-admins
    Permissions: All
    
  developer:
    Assign to groups: ldap-developers
    Permissions:
      - Overall/Read
      - Job/Build
      - Job/Cancel
      - Job/Read
      - Job/Workspace
      - Run/Update
      - View/Read
      
  viewer:
    Assign to groups: ldap-users
    Permissions:
      - Overall/Read
      - Job/Read
      - View/Read

Project Roles:
  microservice-admin (Pattern: microservice-.*):
    Assign to groups: ldap-microservice-team
    Permissions:
      - Job/Build
      - Job/Cancel
      - Job/Configure
      - Job/Read
      - Job/Workspace
      - Run/Delete
      - Run/Update
```

### Single Sign-On (SSO) with SAML

#### Step 1: Install SAML Plugin
```text
Navigate: Manage Jenkins → Manage Plugins → Available

Install:
✅ SAML Plugin
```

#### Step 2: Configure SAML
```text
Navigate: Manage Jenkins → Configure Global Security → Security Realm

Security Realm: SAML 2.0

SAML Configuration:
  IdP Metadata: [URL to your IdP metadata or upload XML file]
  Username Attribute: NameID
  Display Name Attribute: displayName
  Email Attribute: email
  Groups Attribute: groups
  
Advanced Configuration:
  Encryption Certificate: [Upload certificate if required]
  Maximum Authentication Lifetime: 86400 (24 hours)
  Username Case Conversion: none
  
Logout Configuration:
  SLO Enabled: true
  Logout URL: https://your-idp.com/logout
```

### Enterprise Monitoring and Alerting

#### Step 1: Prometheus Integration

**Install Prometheus Plugin:**
```text
Navigate: Manage Jenkins → Manage Plugins → Available

Install:
✅ Prometheus metrics plugin
```

**Configure Prometheus Endpoint:**
```text
Navigate: Manage Jenkins → Configure System → Prometheus

Path: /prometheus
Additional path: /metrics
Default namespace: jenkins
Collecting metrics period: 120 (seconds)
Count successful/failed builds: ✅
Count successful/failed builds per job: ✅
Count builds by result: ✅
Count running builds: ✅
Count executor states: ✅
Count jenkins executors: ✅
Count node status: ✅
Count plugins: ✅
Count build steps: ✅
Count jenkins version: ✅
```

**Prometheus Configuration (prometheus.yml):**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "jenkins_rules.yml"

scrape_configs:
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['jenkins.company.com:8080']
    basic_auth:
      username: 'prometheus'
      password: 'prometheus-token'
    scrape_interval: 30s
    scrape_timeout: 10s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

**Jenkins Alerting Rules (jenkins_rules.yml):**
```yaml
groups:
- name: jenkins
  rules:
  
  # Build failure rate
  - alert: JenkinsBuildFailureRateHigh
    expr: rate(jenkins_builds_failure_total[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High build failure rate detected"
      description: "Jenkins build failure rate is {{ $value }} per second"
      
  # Queue length
  - alert: JenkinsQueueLengthHigh
    expr: jenkins_queue_size_value > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Jenkins queue length is high"
      description: "Current queue length: {{ $value }} jobs"
      
  # Executor utilization
  - alert: JenkinsExecutorUtilizationHigh
    expr: (jenkins_executor_in_use_value / jenkins_executor_total_value) > 0.9
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Jenkins executor utilization is high"
      description: "Executor utilization: {{ $value | humanizePercentage }}"
      
  # Node offline
  - alert: JenkinsNodeOffline
    expr: jenkins_node_online_value == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Jenkins node is offline"
      description: "Node {{ $labels.node }} has been offline for more than 1 minute"
      
  # Disk space low
  - alert: JenkinsDiskSpaceLow
    expr: jenkins_node_disk_space_available_bytes / jenkins_node_disk_space_total_bytes < 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Jenkins node disk space is low"
      description: "Node {{ $labels.node }} has less than 10% disk space available"
```

#### Step 2: Grafana Dashboard

**Jenkins Overview Dashboard:**
```json
{
  "dashboard": {
    "id": null,
    "title": "Jenkins Overview",
    "tags": ["jenkins"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Build Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(jenkins_builds_success_total[5m]) / rate(jenkins_builds_total[5m]) * 100",
            "legendFormat": "Success Rate %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 70},
                {"color": "green", "value": 90}
              ]
            }
          }
        }
      },
      {
        "title": "Queue Length",
        "type": "graph",
        "targets": [
          {
            "expr": "jenkins_queue_size_value",
            "legendFormat": "Queue Size"
          }
        ]
      },
      {
        "title": "Executor Utilization",
        "type": "graph",
        "targets": [
          {
            "expr": "jenkins_executor_in_use_value / jenkins_executor_total_value * 100",
            "legendFormat": "Utilization %"
          }
        ]
      },
      {
        "title": "Build Duration",
        "type": "graph",
        "targets": [
          {
            "expr": "jenkins_builds_duration_milliseconds_summary{quantile=\"0.5\"}",
            "legendFormat": "50th percentile"
          },
          {
            "expr": "jenkins_builds_duration_milliseconds_summary{quantile=\"0.95\"}",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

### Audit Logging

#### Step 1: Configure Audit Trail Plugin
```text
Navigate: Manage Jenkins → Manage Plugins → Available

Install:
✅ Audit Trail Plugin
```

#### Step 2: Configure Audit Settings
```text
Navigate: Manage Jenkins → Configure System → Audit Trail

Loggers:
  1. Log file:
     - Log location: /var/log/jenkins/audit.log
     - Log file size MB: 100
     - Log file count: 10
     
  2. Syslog:
     - Syslog server hostname: logs.company.com
     - Syslog server port: 514
     - App name: jenkins
     - Message format: RFC3164
     
  3. Database:
     - JDBC URL: jdbc:postgresql://db.company.com:5432/jenkins_audit
     - Username: jenkins_audit
     - Password: [password]
     - Table name: audit_trail

Log build cause: ✅
Log build outcomes: ✅
Log build parameters: ✅
Log SCM changes: ✅
```

---

**🔧 Jenkins Advanced Features Complete! Your enterprise-grade CI/CD system now includes master-slave configuration, Blue Ocean UI, shared libraries, Kubernetes integration, and comprehensive monitoring!** 🚀

**Advanced Implementation Checklist:**
- ✅ Master-slave distributed builds
- ✅ Blue Ocean modern UI
- ✅ Shared pipeline libraries
- ✅ Kubernetes dynamic agents
- ✅ LDAP/SSO integration
- ✅ Enterprise monitoring with Prometheus/Grafana
- ✅ Audit logging and compliance
- ✅ Performance optimization
- ✅ Security hardening
- ✅ Disaster recovery procedures

**Production Readiness:**
Your Jenkins implementation now supports enterprise-scale operations with high availability, security, monitoring, and compliance features required for production microservice deployments.