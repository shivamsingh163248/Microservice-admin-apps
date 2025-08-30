# 🏛️ Artifactory Integration for Microservice Admin App

This directory contains comprehensive **JFrog Artifactory integration** for complete artifact lifecycle management, including Docker images, source archives, test reports, build metadata, and deployment artifacts.

## 📁 Directory Structure

```
artifactory/
├── config/
│   ├── repositories.yaml          # Artifactory repository configuration
│   ├── jfrog-cli.yaml            # JFrog CLI configuration template
│   ├── upload-spec.json          # Artifact upload specifications
│   ├── download-spec.json        # Artifact download specifications
│   ├── cleanup-spec.json         # Cleanup policies and specifications
│   └── search-spec.json          # Search patterns and queries
├── scripts/
│   ├── artifactory-utils.sh      # Comprehensive utility scripts
│   └── build-and-publish.sh      # Complete build and publish automation
├── templates/
│   └── build-info.json           # Build information template
├── jenkins/
│   └── Jenkinsfile-Artifactory   # Jenkins pipeline for Artifactory integration
└── README.md                     # This file
```

## 🎯 Overview

### **Complete Artifact Management System**

This Artifactory integration provides:

- **🐳 Docker Registry**: Complete Docker image lifecycle management
- **📦 Generic Repository**: Source code, build artifacts, and reports
- **🏷️ Build Information**: Comprehensive build metadata and traceability
- **🔒 Security Integration**: Xray security scanning and compliance
- **♻️ Lifecycle Management**: Automated cleanup and retention policies
- **📊 Reporting**: Detailed build and deployment reports

## 🚀 Quick Start

### **1. Prerequisites**

Install required tools:

```bash
# Install JFrog CLI
curl -fL https://getcli.jfrog.io | sh
sudo mv jfrog /usr/local/bin/jf

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install additional tools
sudo apt-get update
sudo apt-get install -y jq curl git tar gzip
```

### **2. Configure Artifactory Access**

```bash
# Configure JFrog CLI
./artifactory/scripts/artifactory-utils.sh configure \
    https://your-company.jfrog.io/artifactory \
    your-username \
    your-password

# Test connection
./artifactory/scripts/artifactory-utils.sh check-prerequisites
```

### **3. Build and Publish Artifacts**

```bash
# Complete build and publish process
./artifactory/scripts/build-and-publish.sh

# Or use the utility script
./artifactory/scripts/artifactory-utils.sh build-publish v1.2.3 12345
```

## 🏛️ Repository Structure

### **Docker Repositories**

#### **docker-local**
- **Purpose**: Local Docker images for the microservice app
- **Path Pattern**: `docker-local/<image-name>:<version>`
- **Examples**:
  - `docker-local/nginx_frontend:v1.2.3`
  - `docker-local/flask_backend:v1.2.3`
  - `docker-local/mysql_db:v1.2.3`

#### **docker-remote**
- **Purpose**: Proxy for Docker Hub
- **URL**: `https://registry-1.docker.io/`
- **Usage**: Caching external Docker images

#### **docker-virtual**
- **Purpose**: Aggregated view of local and remote Docker repositories
- **Default Deployment**: `docker-local`

### **Generic Repositories**

#### **generic-local**
- **Purpose**: Application artifacts, source code, reports
- **Path Pattern**: `generic-local/microservice-admin-app/<version>/`
- **Content Types**:
  - Source archives (`.tar.gz`)
  - Test reports (`.xml`, `.json`, `.html`)
  - Build metadata (`.json`)
  - Deployment manifests
  - Requirements files

#### **release-local**
- **Purpose**: Promoted release artifacts
- **Usage**: Production-ready artifacts only
- **Retention**: Long-term (365 days)

### **Package Repositories**

#### **npm-local/npm-remote/npm-virtual**
- **Purpose**: NPM packages for frontend dependencies
- **Future Use**: Frontend build optimization

#### **pypi-local/pypi-remote/pypi-virtual**
- **Purpose**: Python packages for backend dependencies
- **Usage**: Private package management

## 📋 Artifact Types and Specifications

### **Upload Specifications**

The system automatically uploads various artifact types:

#### **Docker Images**
```json
{
  "pattern": "artifacts/docker/nginx_frontend:*",
  "target": "docker-local/nginx_frontend/",
  "props": "component=frontend;type=docker;tier=web"
}
```

#### **Source Archives**
```json
{
  "pattern": "artifacts/generic/frontend-*.tar.gz",
  "target": "generic-local/microservice-admin-app/{1}/",
  "props": "component=frontend;type=source;format=tar.gz"
}
```

#### **Test Reports**
```json
{
  "pattern": "artifacts/reports/*.xml",
  "target": "generic-local/microservice-admin-app/${BUILD_NUMBER}/reports/",
  "props": "type=test-report;format=xml"
}
```

#### **Security Reports**
```json
{
  "pattern": "artifacts/reports/*.json",
  "target": "generic-local/microservice-admin-app/${BUILD_NUMBER}/reports/",
  "props": "type=security-report;format=json"
}
```

### **Download Specifications**

#### **Latest Artifacts**
```json
{
  "pattern": "generic-local/microservice-admin-app/*",
  "target": "downloads/",
  "sortBy": ["created"],
  "sortOrder": "desc",
  "limit": 10
}
```

#### **Component-Specific Downloads**
```json
{
  "aql": {
    "items.find": {
      "repo": "generic-local",
      "path": {"$match": "microservice-admin-app/*"},
      "name": {"$match": "*.tar.gz"}
    }
  },
  "target": "downloads/source/"
}
```

## 🛠️ Utility Scripts

### **artifactory-utils.sh**

Comprehensive utility script with 15+ commands:

```bash
# Basic operations
./artifactory-utils.sh check-prerequisites
./artifactory-utils.sh configure <url> <user> <pass>

# Build and publish
./artifactory-utils.sh build-publish v1.2.3 12345

# Artifact management
./artifactory-utils.sh download v1.2.3 ./downloads
./artifactory-utils.sh search "*.tar.gz" generic-local
./artifactory-utils.sh promote microservice-admin-app 12345

# Maintenance
./artifactory-utils.sh cleanup 30 generic-local
./artifactory-utils.sh backup ./backup
./artifactory-utils.sh storage-usage

# Information
./artifactory-utils.sh artifact-info generic-local/path/to/artifact
./artifactory-utils.sh list-builds microservice-admin-app 10
```

### **build-and-publish.sh**

Complete build automation script:

```bash
# Full build process
./build-and-publish.sh

# Individual steps
./build-and-publish.sh check      # Prerequisites only
./build-and-publish.sh build      # Build Docker images
./build-and-publish.sh test       # Run tests
./build-and-publish.sh scan       # Security scans
./build-and-publish.sh artifacts  # Create generic artifacts
./build-and-publish.sh publish    # Publish to Artifactory
```

## 🏗️ Build Information

### **Comprehensive Build Metadata**

Each build generates detailed metadata including:

#### **Build Properties**
- Build name, number, and version
- Git commit, branch, and URL
- Build timestamp and duration
- Jenkins job information
- Environment details

#### **Component Information**
```json
{
  "component": "frontend",
  "version": "v1.2.3",
  "build_number": "12345",
  "technology": "nginx",
  "docker_image_id": "sha256:abc123...",
  "dockerfile_path": "frontend/Dockerfile"
}
```

#### **Artifact Tracking**
- Docker image details (ID, size, architecture)
- Source archive checksums (SHA1, SHA256, MD5)
- Test results and coverage reports
- Security scan results
- Deployment manifests

### **Build Info Template**

The system uses a comprehensive build info template that includes:

- **VCS Information**: Git commit, branch, URL
- **Build Agent**: Jenkins version and configuration
- **Modules**: Frontend, backend, database components
- **Artifacts**: Docker images, source archives, reports
- **Dependencies**: Python packages, NPM modules
- **Issues**: JIRA/GitHub issue tracking
- **Promotion**: Release promotion history

## 🔒 Security and Compliance

### **Xray Integration**

#### **Security Scanning**
- Automated vulnerability scanning for Docker images
- Source code security analysis
- Dependency vulnerability tracking
- License compliance checking

#### **Security Policies**
```bash
# Enable Xray scanning
jf xr scan --build-name=microservice-admin-app --build-number=12345

# Get scan results
jf xr build-scan microservice-admin-app 12345 --format=json
```

### **Access Control**

#### **Repository Permissions**
- **Read**: All authenticated users
- **Deploy**: CI/CD systems only
- **Admin**: DevOps team only
- **Delete**: Restricted to cleanup automation

#### **API Security**
- API key authentication
- Access token management
- Service account isolation
- Audit logging enabled

## ♻️ Lifecycle Management

### **Retention Policies**

#### **Docker Images**
- **Local Images**: 30 days since last download
- **Latest Tags**: Never deleted
- **Release Images**: 365 days retention

#### **Generic Artifacts**
- **Development**: 60 days retention
- **Reports**: 90 days retention
- **Release Artifacts**: Permanent retention

#### **Build Information**
- **Build Records**: 100 builds maximum
- **Build Artifacts**: Linked to retention policies
- **Metadata**: Permanent retention

### **Cleanup Automation**

#### **Automated Cleanup**
```json
{
  "aql": {
    "items.find": {
      "repo": "generic-local",
      "path": {"$match": "microservice-admin-app/*"},
      "created": {"$before": "30d"}
    }
  }
}
```

#### **Manual Cleanup**
```bash
# Clean artifacts older than 30 days
./artifactory-utils.sh cleanup 30 generic-local

# Clean Docker images (keep last 5 versions)
./artifactory-utils.sh cleanup-docker nginx_frontend 5
```

## 📊 Monitoring and Reporting

### **Storage Monitoring**

```bash
# Check storage usage
./artifactory-utils.sh storage-usage

# Repository-specific usage
curl -X GET "$ARTIFACTORY_URL/api/storageinfo" \
    -H "Authorization: Bearer $API_KEY" | jq '.repositoriesSummaryList'
```

### **Build Reporting**

#### **Build Summary Report**
```bash
# Generate build report
./artifactory-utils.sh build-report microservice-admin-app 12345
```

#### **Artifact Inventory**
```bash
# List all artifacts for a version
./artifactory-utils.sh search "v1.2.3" generic-local

# Get artifact details
./artifactory-utils.sh artifact-info generic-local/microservice-admin-app/v1.2.3/frontend-v1.2.3.tar.gz
```

## 🚀 Jenkins Integration

### **Jenkinsfile-Artifactory**

Comprehensive Jenkins pipeline with:

#### **Build Stages**
1. **Preparation**: Environment setup and configuration
2. **Build**: Parallel Docker image builds
3. **Test**: Unit tests, integration tests, security scans
4. **Publish**: Upload all artifacts to Artifactory
5. **Build Info**: Create and publish build metadata
6. **Security**: Xray security scanning
7. **Promotion**: Promote to release repository
8. **Cleanup**: Remove old artifacts
9. **Reporting**: Generate comprehensive reports

#### **Parameters**
- `IMAGE_VERSION`: Docker image version
- `ENVIRONMENT`: Target environment
- `ARTIFACT_STRATEGY`: Publishing strategy
- `PROMOTE_TO_RELEASE`: Promotion flag
- `SECURITY_SCAN`: Security scanning toggle
- `CLEANUP_OLD_ARTIFACTS`: Cleanup automation
- `RETENTION_DAYS`: Retention period

#### **Credentials Required**
- `artifactory-credentials`: Username/Password
- `artifactory-api-key`: API key for automation
- Docker registry authentication

## 🔧 Configuration

### **Environment Variables**

```bash
# Artifactory configuration
export ARTIFACTORY_URL="https://your-company.jfrog.io/artifactory"
export ARTIFACTORY_USERNAME="your-username"
export ARTIFACTORY_PASSWORD="your-password"
export ARTIFACTORY_API_KEY="your-api-key"

# Repository configuration
export DOCKER_REPO="docker-local"
export GENERIC_REPO="generic-local"
export RELEASE_REPO="release-local"

# Build configuration
export BUILD_NAME="microservice-admin-app"
export BUILD_NUMBER="${BUILD_NUMBER}"
export BUILD_VERSION="v1.0.${BUILD_NUMBER}"
```

### **JFrog CLI Configuration**

```yaml
# jfrog-cli.yaml
servers:
  - serverId: "artifactory-server"
    artifactoryUrl: "${ARTIFACTORY_URL}"
    username: "${ARTIFACTORY_USERNAME}"
    password: "${ARTIFACTORY_PASSWORD}"

defaults:
  serverId: "artifactory-server"

buildSettings:
  buildName: "microservice-admin-app"
  buildNumber: "${BUILD_NUMBER}"
```

## 📚 Usage Examples

### **Complete Build and Publish**

```bash
# Set environment variables
export BUILD_VERSION="v1.2.3"
export BUILD_NUMBER="12345"
export ENVIRONMENT="staging"

# Run complete build process
./artifactory/scripts/build-and-publish.sh
```

### **Download Specific Version**

```bash
# Download specific version
./artifactory/scripts/artifactory-utils.sh download v1.2.3 ./downloads

# Download latest
./artifactory/scripts/artifactory-utils.sh download latest ./downloads
```

### **Promote to Release**

```bash
# Promote build to release repository
./artifactory/scripts/artifactory-utils.sh promote microservice-admin-app 12345 release-local
```

### **Backup and Restore**

```bash
# Create backup
./artifactory/scripts/artifactory-utils.sh backup ./backup-$(date +%Y%m%d)

# Restore from backup
./artifactory/scripts/artifactory-utils.sh restore ./backup-20231215 generic-local
```

## 🐛 Troubleshooting

### **Common Issues**

#### **Connection Problems**
```bash
# Test Artifactory connection
jf rt ping

# Check configuration
jf config show

# Reconfigure
./artifactory/scripts/artifactory-utils.sh configure <url> <user> <pass>
```

#### **Authentication Failures**
```bash
# Check API key
curl -H "Authorization: Bearer $API_KEY" "$ARTIFACTORY_URL/api/system/ping"

# Update credentials
jf config add artifactory-server --artifactory-url=$ARTIFACTORY_URL --user=$USER --password=$PASS
```

#### **Upload Failures**
```bash
# Check repository permissions
jf rt curl -X GET "/api/repositories/generic-local"

# Test upload with small file
echo "test" | jf rt upload - generic-local/test.txt
```

#### **Docker Registry Issues**
```bash
# Login to Docker registry
echo $ARTIFACTORY_PASSWORD | docker login $ARTIFACTORY_URL/docker-local -u $ARTIFACTORY_USERNAME --password-stdin

# Test Docker push
docker tag hello-world $ARTIFACTORY_URL/docker-local/hello-world:test
docker push $ARTIFACTORY_URL/docker-local/hello-world:test
```

### **Debug Commands**

```bash
# Enable debug logging
export JFROG_CLI_LOG_LEVEL=DEBUG

# Check system information
jf rt curl -X GET "/api/system/info"

# Check repository health
jf rt curl -X GET "/api/repositories"

# Check build information
jf rt curl -X GET "/api/build/microservice-admin-app"
```

## 📈 Performance Optimization

### **Upload Optimization**

```bash
# Parallel uploads
jf rt upload "artifacts/*" "generic-local/" --threads=5

# Exclude unnecessary files
jf rt upload "artifacts/*" "generic-local/" --exclusions="*.tmp;*.log"

# Use checksums for deduplication
jf rt upload "artifacts/*" "generic-local/" --checksum-deploy
```

### **Download Optimization**

```bash
# Parallel downloads
jf rt download "generic-local/microservice-admin-app/*" --threads=3

# Resume interrupted downloads
jf rt download "generic-local/microservice-admin-app/*" --resume
```

### **Storage Optimization**

```bash
# Enable deduplication
# (Configured at repository level)

# Compress artifacts before upload
tar -czf source.tar.gz source/
jf rt upload source.tar.gz generic-local/

# Use sparse checkouts for large repositories
git clone --filter=blob:none <url>
```

## 🔮 Future Enhancements

### **Planned Features**

1. **Advanced Promotion Rules**
   - Automated promotion based on test results
   - Multi-stage promotion pipeline
   - Approval workflows

2. **Enhanced Security**
   - SAML/SSO integration
   - Advanced access policies
   - Security metrics dashboard

3. **Improved Automation**
   - Webhook integration
   - Event-driven cleanup
   - Automated dependency updates

4. **Better Monitoring**
   - Grafana dashboards
   - Alert management
   - Performance metrics

### **Integration Roadmap**

- **Kubernetes**: Helm chart repository
- **Terraform**: Module registry
- **IDE Integration**: VS Code extension
- **Compliance**: SBOM generation
- **ML/AI**: Predictive analytics for storage

## 📞 Support

### **Contact Information**

- **DevOps Team**: devops@company.com
- **Artifactory Admin**: artifactory-admin@company.com
- **Emergency**: +1-xxx-xxx-xxxx

### **Resources**

- **JFrog Documentation**: https://jfrog.com/help/
- **REST API**: https://jfrog.com/help/r/jfrog-rest-apis
- **CLI Documentation**: https://jfrog.com/help/r/jfrog-cli
- **Best Practices**: https://jfrog.com/help/r/jfrog-artifactory/best-practices

---

## 🎉 Quick Start Example

```bash
# 1. Configure Artifactory
./artifactory/scripts/artifactory-utils.sh configure \
    https://your-company.jfrog.io/artifactory admin password

# 2. Check prerequisites
./artifactory/scripts/artifactory-utils.sh check-prerequisites

# 3. Build and publish everything
export BUILD_VERSION="v1.0.1"
export BUILD_NUMBER="$(date +%Y%m%d%H%M%S)"
./artifactory/scripts/build-and-publish.sh

# 4. View artifacts in Artifactory UI
# Visit: https://your-company.jfrog.io/ui/repos/tree/General/generic-local/microservice-admin-app

# 5. Download and deploy
./artifactory/scripts/artifactory-utils.sh download v1.0.1 ./deployment
cd deployment && docker-compose up -d
```

**🏛️ Your Artifactory integration is now ready for enterprise-grade artifact management!**
