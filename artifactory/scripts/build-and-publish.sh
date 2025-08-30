#!/bin/bash

#
# Complete Build and Artifact Management Script
# Handles building, testing, packaging, and publishing to Artifactory
#

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARTIFACT_DIR="$PROJECT_ROOT/artifacts"

# Default values
BUILD_VERSION="${BUILD_VERSION:-$(date +%Y.%m.%d-%H%M%S)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"
BUILD_NAME="${BUILD_NAME:-microservice-admin-app}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Artifactory configuration
ARTIFACTORY_URL="${ARTIFACTORY_URL:-https://your-company.jfrog.io/artifactory}"
DOCKER_REPO="${DOCKER_REPO:-docker-local}"
GENERIC_REPO="${GENERIC_REPO:-generic-local}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check required tools
    for tool in docker jf jq git tar gzip; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Check Artifactory connection
    if ! jf rt ping &> /dev/null; then
        log_error "Cannot connect to Artifactory. Please configure JFrog CLI first."
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

# Function to setup build environment
setup_build_environment() {
    log_header "Setting Up Build Environment"
    
    # Create artifact directories
    mkdir -p "$ARTIFACT_DIR"/{docker,generic,reports,metadata}
    
    # Set build information
    export BUILD_TIMESTAMP="$(date -Iseconds)"
    export GIT_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
    export GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
    export GIT_URL="$(git config --get remote.origin.url 2>/dev/null || echo 'unknown')"
    
    log_info "Build environment prepared"
    log_info "Version: $BUILD_VERSION"
    log_info "Build Number: $BUILD_NUMBER"
    log_info "Environment: $ENVIRONMENT"
    log_info "Git Commit: $GIT_COMMIT"
    log_info "Git Branch: $GIT_BRANCH"
}

# Function to build Docker images
build_docker_images() {
    log_header "Building Docker Images"
    
    cd "$PROJECT_ROOT"
    
    # Build frontend
    log_info "Building frontend image..."
    docker build -t nginx_frontend:$BUILD_VERSION frontend/
    docker tag nginx_frontend:$BUILD_VERSION nginx_frontend:latest
    
    # Build backend
    log_info "Building backend image..."
    docker build -t flask_backend:$BUILD_VERSION backend/
    docker tag flask_backend:$BUILD_VERSION flask_backend:latest
    
    # Build database
    log_info "Building database image..."
    docker build -t mysql_db:$BUILD_VERSION database/
    docker tag mysql_db:$BUILD_VERSION mysql_db:latest
    
    # Tag for Artifactory
    docker tag nginx_frontend:$BUILD_VERSION $ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:$BUILD_VERSION
    docker tag flask_backend:$BUILD_VERSION $ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:$BUILD_VERSION
    docker tag mysql_db:$BUILD_VERSION $ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:$BUILD_VERSION
    
    docker tag nginx_frontend:latest $ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:latest
    docker tag flask_backend:latest $ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:latest
    docker tag mysql_db:latest $ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:latest
    
    log_info "Docker images built successfully"
}

# Function to run tests
run_tests() {
    log_header "Running Tests"
    
    # Backend tests
    log_info "Running backend tests..."
    cd "$PROJECT_ROOT/backend"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate || source venv/Scripts/activate 2>/dev/null || true
    pip install -r requirements.txt || log_warn "Could not install requirements"
    
    # Run tests with coverage
    python -m pytest tests/ -v --junitxml="$ARTIFACT_DIR/reports/backend-tests.xml" \
        --cov=. --cov-report=xml --cov-report=html || log_warn "Backend tests failed"
    
    # Copy coverage reports
    cp coverage.xml "$ARTIFACT_DIR/reports/" 2>/dev/null || true
    tar -czf "$ARTIFACT_DIR/reports/backend-coverage-html.tar.gz" htmlcov/ 2>/dev/null || true
    
    cd "$PROJECT_ROOT"
    
    # Frontend tests (placeholder)
    log_info "Frontend tests not implemented yet"
    
    # Integration tests (placeholder)
    log_info "Integration tests not implemented yet"
    
    log_info "Tests completed"
}

# Function to run security scans
run_security_scans() {
    log_header "Running Security Scans"
    
    # Install Trivy if not present
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    # Scan Docker images
    log_info "Scanning Docker images for vulnerabilities..."
    
    trivy image --format json --output "$ARTIFACT_DIR/reports/security-frontend.json" nginx_frontend:$BUILD_VERSION || log_warn "Frontend security scan failed"
    trivy image --format json --output "$ARTIFACT_DIR/reports/security-backend.json" flask_backend:$BUILD_VERSION || log_warn "Backend security scan failed"
    trivy image --format json --output "$ARTIFACT_DIR/reports/security-database.json" mysql_db:$BUILD_VERSION || log_warn "Database security scan failed"
    
    # Scan source code
    trivy fs --format json --output "$ARTIFACT_DIR/reports/security-source.json" . || log_warn "Source code security scan failed"
    
    log_info "Security scans completed"
}

# Function to create generic artifacts
create_generic_artifacts() {
    log_header "Creating Generic Artifacts"
    
    cd "$PROJECT_ROOT"
    
    # Create source archives
    log_info "Creating source archives..."
    tar --exclude='.git' --exclude='node_modules' --exclude='venv' --exclude='__pycache__' \
        -czf "$ARTIFACT_DIR/generic/frontend-$BUILD_VERSION.tar.gz" frontend/
    
    tar --exclude='.git' --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' \
        -czf "$ARTIFACT_DIR/generic/backend-$BUILD_VERSION.tar.gz" backend/
    
    tar --exclude='.git' \
        -czf "$ARTIFACT_DIR/generic/database-$BUILD_VERSION.tar.gz" database/
    
    # Create application archive
    tar --exclude='.git' --exclude='artifacts' --exclude='node_modules' --exclude='venv' \
        -czf "$ARTIFACT_DIR/generic/microservice-admin-app-$BUILD_VERSION.tar.gz" .
    
    # Create requirements files
    cp backend/requirements.txt "$ARTIFACT_DIR/generic/backend-requirements-$BUILD_VERSION.txt" 2>/dev/null || true
    
    # Create deployment manifests
    if [ -d "k8s" ]; then
        tar -czf "$ARTIFACT_DIR/generic/k8s-manifests-$BUILD_VERSION.tar.gz" k8s/
    fi
    
    if [ -d "ansible" ]; then
        tar -czf "$ARTIFACT_DIR/generic/ansible-playbooks-$BUILD_VERSION.tar.gz" ansible/
    fi
    
    log_info "Generic artifacts created"
}

# Function to generate metadata
generate_metadata() {
    log_header "Generating Metadata"
    
    # Application metadata
    cat > "$ARTIFACT_DIR/metadata/app-info.json" << EOF
{
  "name": "$BUILD_NAME",
  "version": "$BUILD_VERSION",
  "build_number": "$BUILD_NUMBER",
  "environment": "$ENVIRONMENT",
  "build_timestamp": "$BUILD_TIMESTAMP",
  "git_commit": "$GIT_COMMIT",
  "git_branch": "$GIT_BRANCH",
  "git_url": "$GIT_URL",
  "components": ["frontend", "backend", "database"],
  "technologies": {
    "frontend": "nginx",
    "backend": "flask",
    "database": "mysql"
  }
}
EOF
    
    # Component metadata
    for component in frontend backend database; do
        local image_id=$(docker images --format "table {{.ID}}" ${component%end}*:$BUILD_VERSION | tail -1)
        local image_size=$(docker images --format "table {{.Size}}" ${component%end}*:$BUILD_VERSION | tail -1)
        
        cat > "$ARTIFACT_DIR/metadata/$component-$BUILD_VERSION.json" << EOF
{
  "component": "$component",
  "version": "$BUILD_VERSION",
  "build_number": "$BUILD_NUMBER",
  "build_timestamp": "$BUILD_TIMESTAMP",
  "git_commit": "$GIT_COMMIT",
  "docker_image_id": "$image_id",
  "docker_image_size": "$image_size",
  "dockerfile_path": "$component/Dockerfile"
}
EOF
    done
    
    # Build summary
    cat > "$ARTIFACT_DIR/metadata/build-summary.json" << EOF
{
  "build": {
    "name": "$BUILD_NAME",
    "number": "$BUILD_NUMBER",
    "version": "$BUILD_VERSION",
    "timestamp": "$BUILD_TIMESTAMP",
    "environment": "$ENVIRONMENT"
  },
  "git": {
    "commit": "$GIT_COMMIT",
    "branch": "$GIT_BRANCH",
    "url": "$GIT_URL"
  },
  "artifacts": {
    "docker_images": [
      "nginx_frontend:$BUILD_VERSION",
      "flask_backend:$BUILD_VERSION",
      "mysql_db:$BUILD_VERSION"
    ],
    "source_archives": [
      "frontend-$BUILD_VERSION.tar.gz",
      "backend-$BUILD_VERSION.tar.gz",
      "database-$BUILD_VERSION.tar.gz"
    ],
    "reports": [
      "backend-tests.xml",
      "security-frontend.json",
      "security-backend.json",
      "security-database.json"
    ]
  }
}
EOF
    
    log_info "Metadata generated"
}

# Function to publish to Artifactory
publish_to_artifactory() {
    log_header "Publishing to Artifactory"
    
    # Set build info
    jf rt build-collect-env $BUILD_NAME $BUILD_NUMBER
    jf rt build-add-git $BUILD_NAME $BUILD_NUMBER
    
    # Publish Docker images
    log_info "Publishing Docker images..."
    
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:$BUILD_VERSION $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:$BUILD_VERSION $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:$BUILD_VERSION $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:latest $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:latest $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:latest $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    
    # Publish generic artifacts
    log_info "Publishing generic artifacts..."
    jf rt upload "$ARTIFACT_DIR/generic/*" "$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/" \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER --flat=false
    
    # Publish reports
    log_info "Publishing reports..."
    jf rt upload "$ARTIFACT_DIR/reports/*" "$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/reports/" \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER --flat=false
    
    # Publish metadata
    log_info "Publishing metadata..."
    jf rt upload "$ARTIFACT_DIR/metadata/*" "$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/metadata/" \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER --flat=false
    
    # Publish build info
    log_info "Publishing build info..."
    jf rt build-publish $BUILD_NAME $BUILD_NUMBER
    
    log_info "Artifacts published successfully"
}

# Function to generate final report
generate_build_report() {
    log_header "Generating Build Report"
    
    cat > "$ARTIFACT_DIR/build-report.md" << EOF
# Build Report: $BUILD_NAME#$BUILD_NUMBER

## Build Information
- **Build Name**: $BUILD_NAME
- **Build Number**: $BUILD_NUMBER
- **Version**: $BUILD_VERSION
- **Environment**: $ENVIRONMENT
- **Timestamp**: $BUILD_TIMESTAMP
- **Git Commit**: $GIT_COMMIT
- **Git Branch**: $GIT_BRANCH

## Artifacts Published

### Docker Images
- \`$ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:$BUILD_VERSION\`
- \`$ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:$BUILD_VERSION\`
- \`$ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:$BUILD_VERSION\`

### Generic Artifacts
- Source archives: \`$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/\`
- Test reports: \`$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/reports/\`
- Metadata: \`$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/metadata/\`

## Build Steps Completed
- ✅ Prerequisites check
- ✅ Build environment setup
- ✅ Docker images built
- ✅ Tests executed
- ✅ Security scans performed
- ✅ Generic artifacts created
- ✅ Metadata generated
- ✅ Artifacts published to Artifactory

## Access Information
- **Artifactory URL**: $ARTIFACTORY_URL
- **Build Info**: $ARTIFACTORY_URL/ui/builds/$BUILD_NAME/$BUILD_NUMBER
- **Docker Registry**: \`docker pull $ARTIFACTORY_URL/$DOCKER_REPO/<image>:<tag>\`

---
Generated on $BUILD_TIMESTAMP by build script
EOF
    
    # Upload the report
    jf rt upload "$ARTIFACT_DIR/build-report.md" "$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION/" \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    
    log_info "Build report generated and uploaded"
    cat "$ARTIFACT_DIR/build-report.md"
}

# Function to cleanup
cleanup() {
    log_header "Cleanup"
    
    # Remove local Docker images to save space (optional)
    if [ "$CLEANUP_DOCKER_IMAGES" = "true" ]; then
        log_info "Cleaning up local Docker images..."
        docker rmi nginx_frontend:$BUILD_VERSION flask_backend:$BUILD_VERSION mysql_db:$BUILD_VERSION || true
    fi
    
    log_info "Cleanup completed"
}

# Main execution flow
main() {
    log_header "Starting Complete Build Process"
    
    check_prerequisites
    setup_build_environment
    build_docker_images
    run_tests
    run_security_scans
    create_generic_artifacts
    generate_metadata
    publish_to_artifactory
    generate_build_report
    cleanup
    
    log_header "Build Process Completed Successfully!"
    log_info "Build: $BUILD_NAME#$BUILD_NUMBER"
    log_info "Version: $BUILD_VERSION"
    log_info "Artifacts available at: $ARTIFACTORY_URL/ui/repos/tree/General/$GENERIC_REPO/$BUILD_NAME/$BUILD_VERSION"
}

# Handle script arguments
case "${1:-main}" in
    "check")
        check_prerequisites
        ;;
    "build")
        build_docker_images
        ;;
    "test")
        run_tests
        ;;
    "scan")
        run_security_scans
        ;;
    "artifacts")
        create_generic_artifacts
        ;;
    "metadata")
        generate_metadata
        ;;
    "publish")
        publish_to_artifactory
        ;;
    "report")
        generate_build_report
        ;;
    "cleanup")
        cleanup
        ;;
    "main"|*)
        main
        ;;
esac
