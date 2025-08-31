# Jenkins Setup Guide for Microservice Admin App

## 📋 Table of Contents
- [Architecture Decision Matrix](#architecture-decision-matrix)
- [Prerequisites](#prerequisites)
- [Installation Options](#installation-options)
- [Initial Configuration](#initial-configuration)
- [Plugin Setup](#plugin-setup)
- [Credential Management](#credential-management)
- [First Pipeline Creation](#first-pipeline-creation)
- [Testing and Verification](#testing-and-verification)

## 🏗️ Architecture Decision Matrix

| Feature | Freestyle | Declarative Pipeline | Multibranch Pipeline | **Recommendation** |
|---------|-----------|---------------------|---------------------|-------------------|
| **Microservices Support** | ⚠️ Limited | ✅ Good | 🏆 Excellent | **Multibranch** |
| **Git Integration** | ⚠️ Basic | ✅ Good | 🏆 Native | **Multibranch** |
| **Scalability** | ❌ Poor | ✅ Good | 🏆 Excellent | **Multibranch** |
| **Configuration as Code** | ❌ No | ✅ Yes | 🏆 Yes + Auto-discovery | **Multibranch** |
| **Branch-based Deployment** | ❌ Manual | ⚠️ Manual | 🏆 Automatic | **Multibranch** |
| **Learning Curve** | 🏆 Easy | ⚠️ Medium | ⚠️ Medium | **Pipeline for learning** |
| **Maintenance** | ❌ High | ✅ Medium | 🏆 Low | **Multibranch** |
| **Industry Standard** | ❌ Legacy | ✅ Modern | 🏆 Modern | **Multibranch** |

### 🏆 **RECOMMENDATION: Multibranch Pipeline**

**For your microservice project, use Multibranch Pipeline because:**
- ✅ **Perfect for microservices**: Each service can have its own Jenkinsfile
- ✅ **Automatic branch detection**: New branches automatically get their own builds
- ✅ **GitOps workflow**: Pipeline configuration lives with code
- ✅ **Environment isolation**: Different branches = different environments
- ✅ **Scalable architecture**: Easy to add new services and environments

## 📋 Prerequisites

### System Requirements
```bash
# Minimum Requirements
CPU: 2 cores
RAM: 4GB
Disk: 50GB
OS: Ubuntu 20.04+ / CentOS 7+ / RHEL 8+

# Recommended for Production
CPU: 4+ cores
RAM: 8GB+
Disk: 100GB+ SSD
OS: Ubuntu 22.04 LTS
```

### Required Software
```bash
# Java (Required)
sudo apt update
sudo apt install openjdk-11-jdk

# Docker (Required for containerized builds)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker jenkins

# Git (Required)
sudo apt install git

# Node.js (Required for frontend builds)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs
```

## 🚀 Installation Options

### Option 1: Docker Installation (Recommended)
```bash
# Create Jenkins directory
mkdir -p ~/jenkins_home
sudo chown 1000:1000 ~/jenkins_home

# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v ~/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  jenkins/jenkins:lts

# Check Jenkins is running
docker logs jenkins
```

### Option 2: Native Installation (Ubuntu/Debian)
```bash
# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt update
sudo apt install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins
```

### Option 3: WAR File Installation
```bash
# Download Jenkins WAR
wget https://get.jenkins.io/war-stable/2.414.1/jenkins.war

# Run Jenkins
java -jar jenkins.war --httpPort=8080

# Or with custom settings
java -Xmx2g -Dhudson.model.DirectoryBrowserSupport.CSP="" \
  -jar jenkins.war --httpPort=8080
```

## ⚙️ Initial Configuration

### Step 1: Access Jenkins
1. Open browser: `http://your-server:8080`
2. Get initial admin password:
```bash
# For Docker installation
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# For native installation
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 2: Install Plugins
**Choose "Install suggested plugins" then add these essential plugins:**

#### Essential Plugins List
```text
# Core Plugins (Install these first)
- Git Plugin
- GitHub Plugin
- Pipeline Plugin
- Pipeline: Stage View Plugin
- Pipeline: GitHub Groovy Libraries
- Blue Ocean (Modern UI)

# Docker Integration
- Docker Plugin
- Docker Pipeline Plugin
- Docker Build Step Plugin

# Build & Test
- JUnit Plugin
- HTML Publisher Plugin
- Cobertura Plugin
- SonarQube Scanner Plugin

# Deployment & Infrastructure
- SSH Agent Plugin
- Ansible Plugin
- Kubernetes Plugin
- Terraform Plugin

# Artifact Management
- Artifactory Plugin
- Nexus Platform Plugin

# Notifications
- Email Extension Plugin
- Slack Notification Plugin
- Teams Notification Plugin

# Security
- OWASP Markup Formatter Plugin
- Role-based Authorization Strategy

# Utilities
- Build Timeout Plugin
- Timestamper Plugin
- Workspace Cleanup Plugin
- Green Balls Plugin (Optional UI improvement)
```

### Step 3: Create Admin User
```text
Username: admin
Password: [your-secure-password]
Full Name: Jenkins Administrator
Email: admin@yourcompany.com
```

### Step 4: Configure Jenkins URL
```text
Jenkins URL: http://your-server:8080/
```

## 🔐 Credential Management

### Step 1: Add GitHub Credentials
1. **Navigate**: `Manage Jenkins` → `Manage Credentials` → `Global` → `Add Credentials`

**GitHub Personal Access Token:**
```text
Kind: Secret text
Scope: Global
Secret: [your-github-token]
ID: github-token
Description: GitHub Personal Access Token
```

**GitHub Username/Password:**
```text
Kind: Username with password
Scope: Global
Username: [your-github-username]
Password: [your-github-token]
ID: github-credentials
Description: GitHub Credentials
```

### Step 2: Add Docker Hub Credentials
```text
Kind: Username with password
Scope: Global
Username: [your-dockerhub-username]
Password: [your-dockerhub-password]
ID: dockerhub-credentials
Description: Docker Hub Credentials
```

### Step 3: Add SSH Credentials
```text
Kind: SSH Username with private key
Scope: Global
ID: ssh-private-key
Username: ubuntu
Private Key: [paste your private key content]
Description: EC2 SSH Private Key
```

### Step 4: Add AWS Credentials
```text
Kind: AWS Credentials
Scope: Global
ID: aws-credentials
Access Key ID: [your-aws-access-key]
Secret Access Key: [your-aws-secret-key]
Description: AWS Credentials for Terraform
```

## 🔧 Global Tool Configuration

### Configure Git
1. **Navigate**: `Manage Jenkins` → `Global Tool Configuration`
2. **Git section**:
```text
Name: Default
Path to Git executable: git
```

### Configure JDK
```text
Name: JDK-11
JAVA_HOME: /usr/lib/jvm/java-11-openjdk-amd64
```

### Configure Node.js
```text
Name: NodeJS-18
Installation: Install automatically from nodejs.org
Version: 18.17.0
```

### Configure Docker
```text
Name: Docker
Installation: Install automatically from docker.com
Docker version: latest
```

## 🚀 First Pipeline Creation

### Step 1: Create Multibranch Pipeline
1. **Click**: `New Item`
2. **Name**: `microservice-admin-app`
3. **Type**: `Multibranch Pipeline`
4. **Click**: `OK`

### Step 2: Configure Branch Sources
**GitHub Source:**
```text
Repository HTTPS URL: https://github.com/shivamsingh163248/Microservice-admin-apps.git
Credentials: github-credentials
Behaviors:
  - Discover branches
  - Discover pull requests from origin
  - Clean before checkout
```

**Build Configuration:**
```text
Mode: by Jenkinsfile
Script Path: jenkins/pipelines/Jenkinsfile-DockerHub
```

### Step 3: Scan Repository
1. **Click**: `Scan Repository Now`
2. **Verify**: Branches are detected
3. **Check**: Build triggers automatically

## 🧪 Testing and Verification

### Step 1: Verify Plugin Installation
```bash
# Check installed plugins
curl -s -k http://admin:password@localhost:8080/pluginManager/api/json?depth=1 | \
  jq '.plugins[] | select(.enabled == true) | .shortName'
```

### Step 2: Test Git Integration
```bash
# Test Git connectivity
git ls-remote https://github.com/shivamsingh163248/Microservice-admin-apps.git
```

### Step 3: Test Docker Integration
```bash
# Test Docker in Jenkins
docker exec jenkins docker --version
docker exec jenkins docker images
```

### Step 4: Verify Credentials
1. **Navigate**: `Manage Jenkins` → `Manage Credentials`
2. **Check**: All credentials are properly configured
3. **Test**: Create a simple pipeline to test each credential

## ✅ Post-Installation Checklist

### Security Configuration
- [ ] Change default admin password
- [ ] Enable CSRF protection
- [ ] Configure authorization strategy
- [ ] Disable unused plugins
- [ ] Enable security realm

### Performance Optimization
- [ ] Configure Java heap size (`-Xmx4g`)
- [ ] Set up log rotation
- [ ] Configure workspace cleanup
- [ ] Enable build discarding

### Backup Strategy
- [ ] Configure Jenkins home backup
- [ ] Document credential backup process
- [ ] Test restore procedure
- [ ] Set up automated backups

### Monitoring Setup
- [ ] Configure system monitoring
- [ ] Set up log aggregation
- [ ] Enable health checks
- [ ] Configure alerting

## 🔧 Troubleshooting Common Issues

### Issue 1: Jenkins Won't Start
```bash
# Check Java version
java -version

# Check port availability
sudo netstat -tlnp | grep 8080

# Check Jenkins logs
sudo journalctl -u jenkins -f
```

### Issue 2: Plugin Installation Fails
```bash
# Update plugin center
curl -X POST http://admin:password@localhost:8080/updateCenter/byId/default/postBack

# Manual plugin installation
wget https://updates.jenkins.io/download/plugins/[plugin-name]/[version]/[plugin-name].hpi
sudo cp [plugin-name].hpi /var/lib/jenkins/plugins/
sudo systemctl restart jenkins
```

### Issue 3: Git Authentication Issues
```bash
# Test Git credentials
git config --global credential.helper store
git clone https://username:token@github.com/user/repo.git
```

### Issue 4: Docker Permission Issues
```bash
# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# For Docker container
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

## 📚 Next Steps

1. **Read**: [`JENKINS-ARCHITECTURE.md`](JENKINS-ARCHITECTURE.md) for advanced architecture patterns
2. **Configure**: Follow [`JENKINS-CONFIGURATION.md`](JENKINS-CONFIGURATION.md) for detailed plugin setup
3. **Implement**: Use [`JENKINS-STEP-BY-STEP.md`](JENKINS-STEP-BY-STEP.md) for complete walkthrough
4. **Advanced Features**: Explore [`JENKINS-ADVANCED.md`](JENKINS-ADVANCED.md) for enterprise features

## 🆘 Support Resources

- **Official Documentation**: https://www.jenkins.io/doc/
- **Plugin Index**: https://plugins.jenkins.io/
- **Community Forum**: https://community.jenkins.io/
- **GitHub Issues**: https://github.com/jenkinsci/jenkins/issues

## 💡 Quick Reference Commands

### Docker Commands
```bash
# Start Jenkins
docker start jenkins

# Stop Jenkins
docker stop jenkins

# View logs
docker logs -f jenkins

# Execute commands in container
docker exec -it jenkins bash
```

### Service Commands (Native Installation)
```bash
# Start/Stop/Restart Jenkins
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins

# Check status
sudo systemctl status jenkins

# View logs
sudo journalctl -u jenkins -f
```

### Backup Commands
```bash
# Backup Jenkins home
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/jenkins_home

# Restore Jenkins home
tar -xzf jenkins-backup-20231201.tar.gz -C /
```

---

**🏗️ Jenkins Setup Complete! Your CI/CD foundation is ready for microservice deployment automation!** 🚀