#!/bin/bash

#
# Artifactory Management Scripts for Microservice Admin App
# Comprehensive artifact management and operations
#

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="microservice-admin-app"
ARTIFACTORY_URL="${ARTIFACTORY_URL:-https://your-company.jfrog.io/artifactory}"
DOCKER_REPO="docker-local"
GENERIC_REPO="generic-local"
RELEASE_REPO="release-local"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Artifactory Prerequisites"
    
    local missing_tools=()
    
    if ! command -v jf &> /dev/null; then
        missing_tools+=("jfrog-cli")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        print_status "All required tools are installed"
        
        # Test Artifactory connection
        if jf rt ping > /dev/null 2>&1; then
            print_status "Artifactory connection successful"
            return 0
        else
            print_warning "Artifactory connection failed - please configure JFrog CLI"
            return 1
        fi
    else
        print_error "Missing tools: ${missing_tools[*]}"
        print_warning "Please install missing tools before proceeding"
        return 1
    fi
}

# Function to configure JFrog CLI
configure_artifactory() {
    local server_url=${1:-$ARTIFACTORY_URL}
    local username=${2}
    local password=${3}
    
    print_header "Configuring JFrog CLI"
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        print_error "Usage: configure_artifactory <server_url> <username> <password>"
        return 1
    fi
    
    print_status "Configuring Artifactory server: $server_url"
    
    jf config add artifactory-server \
        --artifactory-url="$server_url" \
        --user="$username" \
        --password="$password" \
        --interactive=false
    
    # Test connection
    if jf rt ping --server-id=artifactory-server; then
        print_status "Artifactory configuration successful"
    else
        print_error "Artifactory configuration failed"
        return 1
    fi
}

# Function to build and publish artifacts
build_and_publish() {
    local version=${1:-"latest"}
    local build_number=${2:-$(date +%Y%m%d%H%M%S)}
    
    print_header "Building and Publishing Artifacts (Version: $version)"
    
    # Set build info
    export BUILD_NAME="$APP_NAME"
    export BUILD_NUMBER="$build_number"
    export BUILD_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create artifacts directory
    mkdir -p artifacts/{docker,generic,reports}
    
    # Build Docker images
    print_status "Building Docker images..."
    docker build -t nginx_frontend:$version frontend/
    docker build -t flask_backend:$version backend/
    docker build -t mysql_db:$version database/
    
    # Tag images for Artifactory
    docker tag nginx_frontend:$version $ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:$version
    docker tag flask_backend:$version $ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:$version
    docker tag mysql_db:$version $ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:$version
    
    # Create generic artifacts
    print_status "Creating generic artifacts..."
    tar -czf artifacts/generic/frontend-$version.tar.gz frontend/
    tar -czf artifacts/generic/backend-$version.tar.gz backend/
    tar -czf artifacts/generic/database-$version.tar.gz database/
    
    # Generate metadata
    generate_artifact_metadata $version $build_number
    
    # Publish Docker images
    print_status "Publishing Docker images to Artifactory..."
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/nginx_frontend:$version $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/flask_backend:$version $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    jf rt docker-push $ARTIFACTORY_URL/$DOCKER_REPO/mysql_db:$version $DOCKER_REPO \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER
    
    # Publish generic artifacts
    print_status "Publishing generic artifacts to Artifactory..."
    jf rt upload "artifacts/generic/*" "$GENERIC_REPO/$APP_NAME/$version/" \
        --build-name=$BUILD_NAME --build-number=$BUILD_NUMBER --flat=false
    
    # Collect build info and publish
    print_status "Publishing build info..."
    jf rt build-collect-env $BUILD_NAME $BUILD_NUMBER
    jf rt build-add-git $BUILD_NAME $BUILD_NUMBER
    jf rt build-publish $BUILD_NAME $BUILD_NUMBER
    
    print_status "Build and publish completed successfully!"
}

# Function to generate artifact metadata
generate_artifact_metadata() {
    local version=$1
    local build_number=$2
    
    print_status "Generating artifact metadata..."
    
    # Frontend metadata
    cat > artifacts/generic/frontend-$version.json << EOF
{
  "component": "frontend",
  "version": "$version",
  "build_number": "$build_number",
  "build_timestamp": "$BUILD_TIMESTAMP",
  "technology": "nginx",
  "type": "web-server"
}
EOF
    
    # Backend metadata
    cat > artifacts/generic/backend-$version.json << EOF
{
  "component": "backend",
  "version": "$version",
  "build_number": "$build_number",
  "build_timestamp": "$BUILD_TIMESTAMP",
  "technology": "flask",
  "type": "api-server"
}
EOF
    
    # Database metadata
    cat > artifacts/generic/database-$version.json << EOF
{
  "component": "database",
  "version": "$version",
  "build_number": "$build_number",
  "build_timestamp": "$BUILD_TIMESTAMP",
  "technology": "mysql",
  "type": "database"
}
EOF
}

# Function to download artifacts
download_artifacts() {
    local version=${1:-"latest"}
    local target_dir=${2:-"downloads"}
    
    print_header "Downloading Artifacts (Version: $version)"
    
    mkdir -p $target_dir
    
    # Download specific version or latest
    if [ "$version" == "latest" ]; then
        print_status "Downloading latest artifacts..."
        jf rt download "$GENERIC_REPO/$APP_NAME/*" "$target_dir/" \
            --sort-by=created --sort-order=desc --limit=1 --flat=false
    else
        print_status "Downloading artifacts for version: $version"
        jf rt download "$GENERIC_REPO/$APP_NAME/$version/*" "$target_dir/" --flat=false
    fi
    
    print_status "Download completed to: $target_dir"
}

# Function to search artifacts
search_artifacts() {
    local pattern=${1:-"*"}
    local repo=${2:-$GENERIC_REPO}
    
    print_header "Searching Artifacts"
    
    print_status "Searching in repository: $repo"
    print_status "Pattern: $pattern"
    
    jf rt search "$repo/$APP_NAME/$pattern" --sort-by=created --sort-order=desc
}

# Function to promote artifacts to release
promote_to_release() {
    local build_name=${1:-$APP_NAME}
    local build_number=${2}
    local target_repo=${3:-$RELEASE_REPO}
    
    if [ -z "$build_number" ]; then
        print_error "Build number is required for promotion"
        return 1
    fi
    
    print_header "Promoting Build to Release"
    
    print_status "Promoting build: $build_name#$build_number"
    print_status "Target repository: $target_repo"
    
    jf rt build-promote $build_name $build_number $target_repo \
        --status=Released \
        --comment="Promoted to release repository" \
        --copy=true
    
    print_status "Promotion completed successfully!"
}

# Function to cleanup old artifacts
cleanup_artifacts() {
    local retention_days=${1:-30}
    local repo=${2:-$GENERIC_REPO}
    
    print_header "Cleaning Up Old Artifacts"
    
    print_status "Cleaning artifacts older than $retention_days days from $repo"
    
    # Create cleanup specification
    cat > cleanup-spec.json << EOF
{
  "files": [
    {
      "aql": {
        "items.find": {
          "repo": "$repo",
          "path": {"\\$match": "$APP_NAME/*"},
          "created": {"\\$before": "${retention_days}d"}
        }
      }
    }
  ]
}
EOF
    
    # Perform cleanup
    jf rt delete --spec=cleanup-spec.json --dry-run=false
    
    rm -f cleanup-spec.json
    print_status "Cleanup completed"
}

# Function to get artifact information
get_artifact_info() {
    local artifact_path=$1
    
    if [ -z "$artifact_path" ]; then
        print_error "Artifact path is required"
        return 1
    fi
    
    print_header "Artifact Information"
    
    # Get artifact properties
    jf rt curl -X GET "/api/storage/$artifact_path" | jq '.'
    
    # Get artifact properties
    print_status "Artifact Properties:"
    jf rt curl -X GET "/api/storage/$artifact_path?properties" | jq '.properties'
}

# Function to set artifact properties
set_artifact_properties() {
    local artifact_path=$1
    shift
    local properties=("$@")
    
    if [ -z "$artifact_path" ] || [ ${#properties[@]} -eq 0 ]; then
        print_error "Usage: set_artifact_properties <artifact_path> <property1=value1> [property2=value2] ..."
        return 1
    fi
    
    print_header "Setting Artifact Properties"
    
    for prop in "${properties[@]}"; do
        print_status "Setting property: $prop"
        jf rt set-props "$artifact_path" "$prop"
    done
    
    print_status "Properties set successfully"
}

# Function to create repository
create_repository() {
    local repo_name=$1
    local repo_type=${2:-"generic"}
    
    if [ -z "$repo_name" ]; then
        print_error "Repository name is required"
        return 1
    fi
    
    print_header "Creating Repository"
    
    print_status "Creating repository: $repo_name (type: $repo_type)"
    
    # Create repository configuration
    cat > repo-config.json << EOF
{
  "key": "$repo_name",
  "rclass": "local",
  "packageType": "$repo_type",
  "description": "Repository for $APP_NAME artifacts"
}
EOF
    
    # Create repository
    jf rt curl -X PUT "/api/repositories/$repo_name" \
        -H "Content-Type: application/json" \
        -d @repo-config.json
    
    rm -f repo-config.json
    print_status "Repository created successfully"
}

# Function to generate build report
generate_build_report() {
    local build_name=${1:-$APP_NAME}
    local build_number=${2}
    
    if [ -z "$build_number" ]; then
        print_error "Build number is required"
        return 1
    fi
    
    print_header "Generating Build Report"
    
    # Get build info
    jf rt curl -X GET "/api/build/$build_name/$build_number" > build-info.json
    
    # Generate report
    cat > build-report-$build_number.md << EOF
# Build Report: $build_name#$build_number

## Build Information
- **Build Name**: $build_name
- **Build Number**: $build_number
- **Timestamp**: $(date)

## Build Details
$(jq -r '.buildInfo | "- **Started**: \(.started)\n- **Principal**: \(.principal)\n- **URL**: \(.url)\n- **VCS Revision**: \(.vcsRevision)"' build-info.json)

## Modules
$(jq -r '.buildInfo.modules[] | "### \(.id)\n- **Type**: \(.type)\n- **Artifacts**: \(.artifacts | length)\n- **Dependencies**: \(.dependencies | length)\n"' build-info.json)

## Artifacts
$(jq -r '.buildInfo.modules[].artifacts[] | "- **\(.name)** (\(.type)) - \(.size) bytes"' build-info.json)

---
Generated on $(date) by Artifactory Management Script
EOF
    
    rm -f build-info.json
    print_status "Build report generated: build-report-$build_number.md"
}

# Function to backup artifacts
backup_artifacts() {
    local backup_path=${1:-"./backup"}
    local repo=${2:-$GENERIC_REPO}
    
    print_header "Backing Up Artifacts"
    
    mkdir -p $backup_path
    
    print_status "Backing up artifacts from $repo to $backup_path"
    
    # Download all artifacts
    jf rt download "$repo/$APP_NAME/*" "$backup_path/" \
        --include-dirs --flat=false
    
    # Create backup metadata
    cat > $backup_path/backup-metadata.json << EOF
{
  "backup_date": "$(date -Iseconds)",
  "repository": "$repo",
  "app_name": "$APP_NAME",
  "backup_path": "$backup_path",
  "created_by": "$(whoami)"
}
EOF
    
    print_status "Backup completed to: $backup_path"
}

# Function to restore artifacts
restore_artifacts() {
    local backup_path=${1}
    local target_repo=${2:-$GENERIC_REPO}
    
    if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
        print_error "Valid backup path is required"
        return 1
    fi
    
    print_header "Restoring Artifacts"
    
    print_warning "This will restore artifacts to $target_repo"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Restoring artifacts from $backup_path to $target_repo"
        
        # Upload artifacts
        jf rt upload "$backup_path/$APP_NAME/*" "$target_repo/$APP_NAME/" \
            --flat=false --include-dirs
        
        print_status "Restore completed successfully"
    else
        print_warning "Restore cancelled"
    fi
}

# Function to show storage usage
show_storage_usage() {
    print_header "Storage Usage Information"
    
    # Get storage info
    jf rt curl -X GET "/api/storageinfo" | jq '{
        "total_size": .binariesSummary.binariesSize,
        "total_count": .binariesSummary.binariesCount,
        "artifacts_size": .binariesSummary.artifactsSize,
        "artifacts_count": .binariesSummary.artifactsCount
    }'
    
    # Get repository sizes
    print_status "Repository sizes:"
    jf rt curl -X GET "/api/storageinfo" | jq -r '.repositoriesSummaryList[] | "\(.repoKey): \(.usedSpace)"'
}

# Function to list builds
list_builds() {
    local build_name=${1:-$APP_NAME}
    local limit=${2:-10}
    
    print_header "Recent Builds"
    
    print_status "Showing last $limit builds for $build_name"
    
    jf rt curl -X GET "/api/build/$build_name" | jq -r ".builds[:$limit][] | \"\(.uri) - \(.started)\""
}

# Main function to show usage
show_usage() {
    echo -e "${PURPLE}Artifactory Management Scripts for Microservice Admin App${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  check-prerequisites              - Check if required tools are installed"
    echo "  configure <url> <user> <pass>    - Configure JFrog CLI"
    echo "  build-publish [version] [build]  - Build and publish artifacts"
    echo "  download [version] [target_dir]  - Download artifacts"
    echo "  search [pattern] [repo]          - Search for artifacts"
    echo "  promote <build_name> <build_num> - Promote build to release"
    echo "  cleanup [retention_days] [repo]  - Clean up old artifacts"
    echo "  artifact-info <artifact_path>    - Get artifact information"
    echo "  set-props <path> <prop=val>...   - Set artifact properties"
    echo "  create-repo <name> [type]        - Create repository"
    echo "  build-report <build_name> <num>  - Generate build report"
    echo "  backup [backup_path] [repo]      - Backup artifacts"
    echo "  restore <backup_path> [repo]     - Restore artifacts"
    echo "  storage-usage                    - Show storage usage"
    echo "  list-builds [build_name] [limit] - List recent builds"
    echo ""
    echo "Examples:"
    echo "  $0 configure https://company.jfrog.io/artifactory admin password"
    echo "  $0 build-publish v1.2.3 12345"
    echo "  $0 download v1.2.3 ./downloads"
    echo "  $0 promote microservice-admin-app 12345"
    echo "  $0 cleanup 30 generic-local"
    echo "  $0 backup ./backup"
}

# Main script logic
main() {
    case "${1:-}" in
        "check-prerequisites")
            check_prerequisites
            ;;
        "configure")
            configure_artifactory "$2" "$3" "$4"
            ;;
        "build-publish")
            build_and_publish "$2" "$3"
            ;;
        "download")
            download_artifacts "$2" "$3"
            ;;
        "search")
            search_artifacts "$2" "$3"
            ;;
        "promote")
            promote_to_release "$2" "$3" "$4"
            ;;
        "cleanup")
            cleanup_artifacts "$2" "$3"
            ;;
        "artifact-info")
            get_artifact_info "$2"
            ;;
        "set-props")
            set_artifact_properties "$2" "${@:3}"
            ;;
        "create-repo")
            create_repository "$2" "$3"
            ;;
        "build-report")
            generate_build_report "$2" "$3"
            ;;
        "backup")
            backup_artifacts "$2" "$3"
            ;;
        "restore")
            restore_artifacts "$2" "$3"
            ;;
        "storage-usage")
            show_storage_usage
            ;;
        "list-builds")
            list_builds "$2" "$3"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
