# 🐳 Jenkins Docker Hub Pipeline Setup Guide

## 📋 Complete Step-by-Step Configuration

### 🏗️ **Project Information**
- **Repository**: https://github.com/shivamsingh163248/Microservice-admin-apps.git
- **Branch**: Jenkins_Ansible_Deployment_Workflow
- **Docker Hub Images**:
  - `shivamsingh163248/mysql_db`
  - `shivamsingh163248/nginx_frontend`  
  - `shivamsingh163248/flask_backend`

---

## 🔌 **Step 1: Required Plugin Installation**

### **Essential Plugins List**
Navigate to: `Manage Jenkins` → `Manage Plugins` → `Available`

#### **Core Plugins** ⭐
```bash
✅ Pipeline
✅ Pipeline: Stage View  
✅ Pipeline: Declarative Agent API
✅ Pipeline: Groovy
✅ Pipeline: Basic Steps
✅ Pipeline: Build Step
✅ Pipeline: Input Step
✅ Pipeline: Milestone Step
✅ Pipeline: Model API
✅ Pipeline: Multibranch
✅ Pipeline: SCM Step
✅ Pipeline: Stage Step
✅ Pipeline: Stage Tags Metadata
✅ Blue Ocean (Optional - Modern UI)
```

#### **Git Integration Plugins** 🔗
```bash
✅ Git
✅ GitHub
✅ GitHub Branch Source
✅ GitHub API
✅ GitHub Authentication
✅ GitHub Integration
✅ GitHub Pull Request Builder (Optional)
```

#### **Docker Integration Plugins** 🐳
```bash
✅ Docker
✅ Docker Pipeline
✅ Docker Build Step
✅ Docker Commons
✅ CloudBees Docker Build and Publish
```

#### **Build & Test Plugins** 🧪
```bash
✅ JUnit
✅ HTML Publisher
✅ Cobertura (Code Coverage)
✅ Test Results Analyzer
✅ Performance
```

#### **Utility Plugins** 🛠️
```bash
✅ Build Timeout
✅ Timestamper
✅ Workspace Cleanup
✅ AnsiColor (Colored Console Output)
✅ Email Extension
✅ Slack Notification (Optional)
```

#### **Security & Credentials** 🔐
```bash
✅ Credentials
✅ Credentials Binding
✅ Plain Credentials
✅ SSH Credentials
✅ SSH Agent
```

### **Plugin Installation Steps**
1. Select all required plugins from the list above
2. Click "Install without restart" 
3. Wait for installation to complete
4. Restart Jenkins: `Manage Jenkins` → `Restart Safely`

---

## 🔐 **Step 2: Credentials Setup**

### **2.1 Docker Hub Credentials**
Navigate to: `Manage Jenkins` → `Manage Credentials` → `Global` → `Add Credentials`

```yaml
Kind: Username with password
Scope: Global (Jenkins, nodes, items, all child items, etc)
Username: shivamsingh163248
Password: [Your Docker Hub Access Token]
ID: docker-hub-credentials
Description: Docker Hub Registry Credentials for shivamsingh163248
```

**📝 Note**: Use Docker Hub Access Token instead of password for better security.

### **2.2 GitHub Credentials (Optional - For Private Repos)**
```yaml
Kind: Username with password
Scope: Global
Username: shivamsingh163248  
Password: [Your GitHub Personal Access Token]
ID: github-credentials
Description: GitHub Repository Access
```

**🔒 Security Tip**: Since your repo is public, GitHub credentials are optional.

---

## 🚀 **Step 3: Create Multibranch Pipeline**

### **3.1 Create New Item**
1. Click `New Item` in Jenkins Dashboard
2. **Enter item name**: `microservice-admin-app-dockerhub`
3. **Select**: `Multibranch Pipeline`
4. Click `OK`

### **3.2 General Configuration**

#### **Display Name**
```text
Display Name: Microservice Admin App - Docker Hub Pipeline
```

#### **Description**
```text
Description: 
CI/CD Pipeline for Microservice Admin App
- Builds Docker images for Frontend (Nginx), Backend (Flask), and Database (MySQL)
- Runs comprehensive testing suite
- Pushes images to Docker Hub registry
- Supports multiple environments (dev, staging, production)
- Automated deployment capabilities

Repository: https://github.com/shivamsingh163248/Microservice-admin-apps.git
Branch: Jenkins_Ansible_Deployment_Workflow
Docker Hub: shivamsingh163248/*
```

---

## 📂 **Step 4: Branch Sources Configuration**

### **4.1 Add GitHub Branch Source**
Click `Add source` → `GitHub`

#### **Repository Configuration**
```yaml
Repository HTTPS URL: https://github.com/shivamsingh163248/Microservice-admin-apps.git

# OR use Repository Selection (Recommended)
Repository: 
  Owner: shivamsingh163248
  Repository: Microservice-admin-apps
```

#### **Credentials**
```yaml
Credentials: 
  - None (for public repository)
  # OR select 'github-credentials' if you added GitHub credentials
```

#### **Repository scan credentials**
```yaml
Scan credentials: Same as checkout credentials
```

---

## ⚙️ **Step 5: Behaviors Configuration**

### **5.1 Discover Branches**
```yaml
☑️ Discover branches
Strategy: Exclude branches that are also filed as PRs
```

**Options Explained**:
- **All branches**: Discovers all branches
- **Only branches that are not filed as PRs**: ✅ **Recommended** - Avoids duplicate builds
- **Only branches that are filed as PRs**: Only PR branches

### **5.2 Discover Pull Requests from Origin**
```yaml
☑️ Discover pull requests from origin
Strategy: Merging the pull request with the current target branch revision
```

**Trust Level Options**:
- **Nobody**: Most secure, no PR builds
- **Everyone**: ⚠️ Less secure, builds all PRs
- **From users with Admin or Write permission**: ✅ **Recommended**
- **From users with Admin permission**: Most secure for sensitive projects

### **5.3 Discover Pull Requests from Forks**
```yaml
☑️ Discover pull requests from forks  
Strategy: Merging the pull request with the current target branch revision
Trust: From users with Admin or Write permission
```

**Trust Options Explained**:
- **Nobody**: No fork PR builds
- **Forks in the same account**: Builds PRs from forks in same GitHub account
- **From users with Admin or Write permission**: ✅ **Recommended**
- **Everyone**: ⚠️ Security risk - builds from any fork

### **5.4 Additional Behaviors (Optional)**
```yaml
☑️ Clean before checkout
  ☑️ Delete untracked nested repositories

☑️ Clean after checkout  
  ☑️ Delete untracked nested repositories

☑️ Check out to matching local branch
  (Checks out to local branch matching remote branch name)

☑️ Wipe out repository & force clone
  (Forces fresh clone for each build - slower but cleaner)
```

---

## 🏗️ **Step 6: Build Configuration**

### **6.1 Mode Selection**
```yaml
Mode: by Jenkinsfile
```

### **6.2 Script Path**
```yaml
Script Path: jenkins/pipelines/Jenkinsfile-DockerHub
```

**📁 File Structure Verification**:
```
microservice-admin-app/
├── jenkins/
│   ├── pipelines/
│   │   ├── Jenkinsfile-DockerHub  ← This file should exist
│   │   ├── Jenkinsfile-Artifactory
│   │   └── Jenkinsfile-Kubernetes
│   └── setup/
└── other-folders/
```

---

## 🔧 **Step 7: Properties Configuration**

### **7.1 Discard Old Items**
```yaml
☑️ Discard old items
Strategy: Log Rotation
  Days to keep old items: 30
  Max # of old items to keep: 50
  Days to keep old artifacts: 7  
  Max # of artifacts to keep: 10
```

### **7.2 Suppress Automatic SCM Triggering**
```yaml
☐ Suppress automatic SCM triggering
(Leave unchecked to allow automatic builds on push)
```

---

## ⏰ **Step 8: Scan Multibranch Pipeline Triggers**

### **8.1 Periodic Scan**
```yaml
☑️ Periodically if not otherwise run
Interval: 1 hour
```

**Options Available**:
- `1 minute` - Too frequent, not recommended
- `5 minutes` - Good for active development
- `15 minutes` - Balanced option
- `1 hour` - ✅ **Recommended** for production
- `1 day` - Too slow for CI/CD

### **8.2 Scan by Webhook**
```yaml
☑️ Scan by webhook
Token: microservice-admin-app-webhook-token
```

**Webhook URL for GitHub**:
```
https://your-jenkins-server/multibranch-webhook-trigger/invoke?token=microservice-admin-app-webhook-token
```

---

## 💾 **Step 9: Save and Initial Scan**

### **9.1 Save Configuration**
1. Click `Save` button
2. Jenkins will return to the pipeline main page

### **9.2 Initial Repository Scan**
1. Click `Scan Multibranch Pipeline Now`
2. Monitor the scan log in real-time
3. Verify branches are discovered

**Expected Scan Output**:
```bash
Started
[Fri Oct 05 10:30:00 UTC 2025] Starting branch indexing...
Checking branch Jenkins_Ansible_Deployment_Workflow
  'jenkins/pipelines/Jenkinsfile-DockerHub' found
  Met criteria
Processed 1 branch
[Fri Oct 05 10:30:05 UTC 2025] Finished branch indexing. Indexing took 5.2 sec
Finished: SUCCESS
```

---

## ✅ **Step 10: Verification and First Build**

### **10.1 Verify Branch Detection**
- Navigate to pipeline main page  
- Confirm `Jenkins_Ansible_Deployment_Workflow` branch is listed
- Status should show "Never Built" initially

### **10.2 Trigger First Build**
1. Click on the branch name: `Jenkins_Ansible_Deployment_Workflow`
2. Click `Build Now`
3. Monitor build progress in real-time

### **10.3 Build Status Verification**
**Expected Build Stages**:
```bash
✅ 🔍 Preparation
✅ 🏗️ Build Images (Parallel)
  ├── Build Frontend
  ├── Build Backend  
  └── Build Database
✅ 🧪 Testing Phase
✅ 🚀 Push to Docker Hub
✅ 🔍 Verify Docker Hub Images  
✅ 📊 Generate Reports
```

---

## 🔧 **Step 11: Advanced Configuration (Optional)**

### **11.1 Pipeline Libraries (Future Enhancement)**
```yaml
☑️ Pipeline Libraries
Library Name: microservice-shared-library
Default version: main
Retrieval method: Modern SCM
Source Code Management: Git
  Repository URL: https://github.com/shivamsingh163248/jenkins-shared-library.git
```

### **11.2 Folder-level Credentials**
Navigate to: Pipeline Folder → `Credentials` → `Folder`
- Add project-specific credentials
- Override global credentials if needed

### **11.3 Build Parameters (Per Branch)**
Configure in individual branch builds:
```yaml
ENVIRONMENT: [dev, staging, production]
SKIP_TESTS: [true/false]
DEPLOY_AFTER_BUILD: [true/false]  
DOCKER_TAG_PREFIX: custom-prefix
```

---

## 📊 **Step 12: Monitoring and Notifications**

### **12.1 Build Notifications**
Configure in `Manage Jenkins` → `Configure System`:

#### **Email Notifications**
```yaml
SMTP Server: smtp.gmail.com
SMTP Port: 587
Username: your-email@gmail.com
Password: [App Password]
Use SSL: ☑️

Default Recipients: devops-team@company.com
```

#### **Slack Integration (Optional)**
```yaml
Base URL: https://your-workspace.slack.com/services/hooks/jenkins-ci/
Team Subdomain: your-workspace  
Token: [Slack Bot Token]
Channel: #jenkins-builds
```

### **12.2 Build History Monitoring**
- Monitor build trends in Blue Ocean UI
- Set up build failure alerts
- Track build performance metrics

---

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: Repository Not Found**
```bash
Error: Repository not accessible
Solution: 
1. Verify repository URL is correct
2. Check GitHub credentials (if private repo)
3. Ensure repository exists and is accessible
```

### **Issue 2: Jenkinsfile Not Found**
```bash
Error: jenkins/pipelines/Jenkinsfile-DockerHub not found
Solution:
1. Verify file path in repository
2. Check branch name is correct
3. Ensure file exists in specified branch
```

### **Issue 3: Docker Build Failures**
```bash
Error: Docker daemon not accessible
Solution:
1. Ensure Docker is installed on Jenkins node
2. Add jenkins user to docker group
3. Restart Jenkins service
```

### **Issue 4: Credential Issues**
```bash
Error: docker login failed
Solution:
1. Verify Docker Hub credentials are correct
2. Use Access Token instead of password
3. Check credential ID matches Jenkinsfile
```

---

## 🎯 **Next Steps After Successful Setup**

### **Phase 1: Basic Functionality** ✅
- [x] Setup Multibranch Pipeline
- [x] Configure Docker Hub integration  
- [x] Verify automated builds
- [x] Test Docker image publishing

### **Phase 2: Advanced Configuration** 🚧
- [ ] Setup JFrog Artifactory integration
- [ ] Configure parallel execution optimization
- [ ] Implement advanced testing strategies
- [ ] Setup environment-specific deployments

### **Phase 3: Enterprise Features** 📈
- [ ] Shared Library implementation
- [ ] Advanced security scanning
- [ ] Multi-stage deployment pipelines
- [ ] Infrastructure as Code integration

---

## 📚 **Reference Documentation**

### **Jenkins Pipeline Syntax**
```groovy
// Environment Variables
environment {
    DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
    IMAGE_VERSION = "v1.0.${BUILD_NUMBER}"
}

// Parameters  
parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'])
    booleanParam(name: 'SKIP_TESTS', defaultValue: false)
}

// Parallel Execution
parallel {
    stage('Build Frontend') { /* ... */ }
    stage('Build Backend') { /* ... */ }  
    stage('Build Database') { /* ... */ }
}
```

### **Docker Hub Integration**
```bash
# Login
echo "${DOCKER_HUB_CREDENTIALS_PSW}" | docker login -u "${DOCKER_HUB_CREDENTIALS_USR}" --password-stdin

# Build and Push
docker build -t ${IMAGE_NAME}:${VERSION} .
docker push ${IMAGE_NAME}:${VERSION}
```

---

## ✅ **Configuration Checklist**

### **Pre-Setup Checklist**
- [ ] Jenkins server is running and accessible
- [ ] All required plugins are installed
- [ ] Docker is installed and configured
- [ ] GitHub repository is accessible
- [ ] Docker Hub account is ready

### **Configuration Checklist**  
- [ ] Multibranch pipeline created
- [ ] Display name and description configured
- [ ] GitHub branch source configured
- [ ] Repository URL is correct
- [ ] Branch behaviors are set appropriately
- [ ] Build configuration points to correct Jenkinsfile
- [ ] Docker Hub credentials are configured
- [ ] Scan triggers are configured
- [ ] Initial scan completed successfully

### **Validation Checklist**
- [ ] Branch is detected and listed
- [ ] Initial build triggered and completed
- [ ] Docker images are built successfully  
- [ ] Images are pushed to Docker Hub
- [ ] Build artifacts are archived
- [ ] Notifications are working (if configured)

---

**🎉 Configuration Complete!**

Your Jenkins Docker Hub pipeline is now fully configured and ready for automated CI/CD operations. The pipeline will automatically:

- ✅ **Detect new commits** on the Jenkins_Ansible_Deployment_Workflow branch
- ✅ **Build Docker images** for all three services
- ✅ **Run comprehensive tests** to ensure quality
- ✅ **Push images to Docker Hub** for distribution
- ✅ **Generate build reports** for monitoring

**Next**: Proceed to advanced configurations and JFrog Artifactory integration!

---

**Last Updated**: October 5, 2025  
**Version**: 1.0.0  
**Setup Guide**: Jenkins Docker Hub Pipeline
