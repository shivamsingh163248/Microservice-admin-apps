#!/bin/bash

#
# Jenkins Utility Scripts for Microservice Admin App
# Provides common operations and maintenance tasks
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
DOCKER_HUB_REPO="shivamsingh163248"
GHCR_REGISTRY="ghcr.io"
GHCR_OWNER="shivamsingh163248"

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

# Function to check if required tools are installed
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if ! command -v ansible &> /dev/null; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        print_status "All required tools are installed"
        return 0
    else
        print_error "Missing tools: ${missing_tools[*]}"
        print_warning "Please install missing tools before proceeding"
        return 1
    fi
}

# Function to build all Docker images
build_images() {
    local version=${1:-"latest"}
    print_header "Building Docker Images (Version: $version)"
    
    # Build frontend
    print_status "Building frontend image..."
    docker build -t nginx_frontend:$version frontend/
    
    # Build backend
    print_status "Building backend image..."
    docker build -t flask_backend:$version backend/
    
    # Build database
    print_status "Building database image..."
    docker build -t mysql_db:$version database/
    
    print_status "All images built successfully!"
}

# Function to push images to Docker Hub
push_to_dockerhub() {
    local version=${1:-"latest"}
    print_header "Pushing Images to Docker Hub (Version: $version)"
    
    # Tag and push frontend
    docker tag nginx_frontend:$version $DOCKER_HUB_REPO/nginx_frontend:$version
    docker push $DOCKER_HUB_REPO/nginx_frontend:$version
    
    # Tag and push backend
    docker tag flask_backend:$version $DOCKER_HUB_REPO/flask_backend:$version
    docker push $DOCKER_HUB_REPO/flask_backend:$version
    
    # Tag and push database
    docker tag mysql_db:$version $DOCKER_HUB_REPO/mysql_db:$version
    docker push $DOCKER_HUB_REPO/mysql_db:$version
    
    print_status "All images pushed to Docker Hub successfully!"
}

# Function to push images to GitHub Container Registry
push_to_ghcr() {
    local version=${1:-"latest"}
    print_header "Pushing Images to GitHub Container Registry (Version: $version)"
    
    # Login to GHCR (assumes GITHUB_TOKEN is set)
    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "GITHUB_TOKEN environment variable is not set"
        return 1
    fi
    
    echo $GITHUB_TOKEN | docker login $GHCR_REGISTRY -u $GHCR_OWNER --password-stdin
    
    # Tag and push frontend
    docker tag nginx_frontend:$version $GHCR_REGISTRY/$GHCR_OWNER/nginx_frontend:$version
    docker push $GHCR_REGISTRY/$GHCR_OWNER/nginx_frontend:$version
    
    # Tag and push backend
    docker tag flask_backend:$version $GHCR_REGISTRY/$GHCR_OWNER/flask_backend:$version
    docker push $GHCR_REGISTRY/$GHCR_OWNER/flask_backend:$version
    
    # Tag and push database
    docker tag mysql_db:$version $GHCR_REGISTRY/$GHCR_OWNER/mysql_db:$version
    docker push $GHCR_REGISTRY/$GHCR_OWNER/mysql_db:$version
    
    print_status "All images pushed to GHCR successfully!"
}

# Function to start local development environment
start_local_env() {
    print_header "Starting Local Development Environment"
    
    print_status "Starting services with docker-compose..."
    docker-compose up -d
    
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_status "Development environment started successfully!"
        print_status "Frontend: http://localhost:8081"
        print_status "Backend API: http://localhost:5001"
        print_status "Database: localhost:3306"
    else
        print_error "Failed to start development environment"
        docker-compose logs
    fi
}

# Function to stop local development environment
stop_local_env() {
    print_header "Stopping Local Development Environment"
    
    docker-compose down
    print_status "Development environment stopped"
}

# Function to clean up Docker resources
cleanup_docker() {
    print_header "Cleaning Up Docker Resources"
    
    print_status "Removing stopped containers..."
    docker container prune -f
    
    print_status "Removing unused images..."
    docker image prune -f
    
    print_status "Removing unused volumes..."
    docker volume prune -f
    
    print_status "Removing unused networks..."
    docker network prune -f
    
    print_status "Docker cleanup completed"
}

# Function to run tests
run_tests() {
    print_header "Running Tests"
    
    # Backend tests
    print_status "Running backend tests..."
    cd backend
    python -m pytest tests/ -v || print_warning "Backend tests failed or not found"
    cd ..
    
    # Frontend tests (if any)
    print_status "Frontend tests not implemented yet"
    
    print_status "Test execution completed"
}

# Function to deploy to staging
deploy_staging() {
    local version=${1:-"latest"}
    print_header "Deploying to Staging Environment (Version: $version)"
    
    print_status "Running Ansible deployment..."
    cd ansible
    ansible-playbook -i inventory.ini deploy.yml \
        --extra-vars "environment=staging image_version=$version"
    cd ..
    
    print_status "Staging deployment completed"
}

# Function to deploy to production
deploy_production() {
    local version=${1:-"latest"}
    print_header "Deploying to Production Environment (Version: $version)"
    
    print_warning "This will deploy to PRODUCTION environment!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Running Ansible deployment..."
        cd ansible
        ansible-playbook -i inventory.ini deploy-production.yml \
            --extra-vars "environment=production image_version=$version"
        cd ..
        
        print_status "Production deployment completed"
    else
        print_warning "Production deployment cancelled"
    fi
}

# Function to show application status
show_status() {
    print_header "Application Status"
    
    # Local environment
    print_status "Local Environment:"
    docker-compose ps
    
    # Kubernetes (if available)
    if command -v kubectl &> /dev/null; then
        print_status "Kubernetes Environments:"
        
        for ns in dev-$APP_NAME staging-$APP_NAME production-$APP_NAME; do
            if kubectl get namespace $ns &> /dev/null; then
                echo -e "${BLUE}Namespace: $ns${NC}"
                kubectl get pods -n $ns
                echo ""
            fi
        done
    fi
}

# Function to show logs
show_logs() {
    local service=${1:-"all"}
    local environment=${2:-"local"}
    
    print_header "Showing Logs for $service in $environment"
    
    case $environment in
        "local")
            if [[ $service == "all" ]]; then
                docker-compose logs -f
            else
                docker-compose logs -f $service
            fi
            ;;
        "k8s-dev"|"k8s-staging"|"k8s-production")
            local ns="${environment#k8s-}-$APP_NAME"
            if [[ $service == "all" ]]; then
                kubectl logs -f -l app=$APP_NAME -n $ns
            else
                kubectl logs -f -l app=$service -n $ns
            fi
            ;;
        *)
            print_error "Unknown environment: $environment"
            ;;
    esac
}

# Function to backup database
backup_database() {
    local environment=${1:-"local"}
    local backup_file="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    print_header "Creating Database Backup"
    
    case $environment in
        "local")
            docker-compose exec mysql mysqldump -u adminuser -padminpass adminapp > $backup_file
            ;;
        "k8s-dev"|"k8s-staging"|"k8s-production")
            local ns="${environment#k8s-}-$APP_NAME"
            kubectl exec -n $ns -it deployment/mysql-database -- \
                mysqldump -u adminuser -padminpass adminapp > $backup_file
            ;;
        *)
            print_error "Unknown environment: $environment"
            return 1
            ;;
    esac
    
    print_status "Database backup created: $backup_file"
}

# Function to restore database
restore_database() {
    local backup_file=$1
    local environment=${2:-"local"}
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_header "Restoring Database from $backup_file"
    
    print_warning "This will overwrite the current database!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        case $environment in
            "local")
                docker-compose exec -T mysql mysql -u adminuser -padminpass adminapp < $backup_file
                ;;
            "k8s-dev"|"k8s-staging"|"k8s-production")
                local ns="${environment#k8s-}-$APP_NAME"
                kubectl exec -n $ns -i deployment/mysql-database -- \
                    mysql -u adminuser -padminpass adminapp < $backup_file
                ;;
            *)
                print_error "Unknown environment: $environment"
                return 1
                ;;
        esac
        
        print_status "Database restored successfully"
    else
        print_warning "Database restore cancelled"
    fi
}

# Function to generate version number
generate_version() {
    local version_type=${1:-"patch"}
    
    # Get current version from git tags
    local current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    current_version=${current_version#v}  # Remove 'v' prefix
    
    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    local major=${VERSION_PARTS[0]:-0}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}
    
    case $version_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            print_error "Invalid version type: $version_type (use: major, minor, patch)"
            return 1
            ;;
    esac
    
    local new_version="v$major.$minor.$patch"
    echo $new_version
}

# Function to create release
create_release() {
    local version_type=${1:-"patch"}
    
    print_header "Creating Release"
    
    # Generate new version
    local new_version=$(generate_version $version_type)
    print_status "New version: $new_version"
    
    # Build and tag images
    build_images ${new_version#v}
    
    # Create git tag
    git tag $new_version
    git push origin $new_version
    
    print_status "Release $new_version created successfully!"
}

# Main function to show usage
show_usage() {
    echo -e "${PURPLE}Jenkins Utility Scripts for Microservice Admin App${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  check-prerequisites           - Check if required tools are installed"
    echo "  build [version]              - Build all Docker images"
    echo "  push-dockerhub [version]     - Push images to Docker Hub"
    echo "  push-ghcr [version]          - Push images to GitHub Container Registry"
    echo "  start-local                  - Start local development environment"
    echo "  stop-local                   - Stop local development environment"
    echo "  cleanup-docker               - Clean up Docker resources"
    echo "  run-tests                    - Run application tests"
    echo "  deploy-staging [version]     - Deploy to staging environment"
    echo "  deploy-production [version]  - Deploy to production environment"
    echo "  status                       - Show application status"
    echo "  logs [service] [env]         - Show logs (service: all|frontend|backend|mysql, env: local|k8s-dev|k8s-staging|k8s-production)"
    echo "  backup-db [environment]      - Create database backup"
    echo "  restore-db <file> [env]      - Restore database from backup"
    echo "  generate-version [type]      - Generate new version (type: major|minor|patch)"
    echo "  create-release [type]        - Create new release with version bump"
    echo ""
    echo "Examples:"
    echo "  $0 build v1.2.3"
    echo "  $0 start-local"
    echo "  $0 deploy-staging v1.2.3"
    echo "  $0 logs backend k8s-staging"
    echo "  $0 backup-db local"
    echo "  $0 create-release minor"
}

# Main script logic
main() {
    case "${1:-}" in
        "check-prerequisites")
            check_prerequisites
            ;;
        "build")
            build_images "$2"
            ;;
        "push-dockerhub")
            push_to_dockerhub "$2"
            ;;
        "push-ghcr")
            push_to_ghcr "$2"
            ;;
        "start-local")
            start_local_env
            ;;
        "stop-local")
            stop_local_env
            ;;
        "cleanup-docker")
            cleanup_docker
            ;;
        "run-tests")
            run_tests
            ;;
        "deploy-staging")
            deploy_staging "$2"
            ;;
        "deploy-production")
            deploy_production "$2"
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        "backup-db")
            backup_database "$2"
            ;;
        "restore-db")
            restore_database "$2" "$3"
            ;;
        "generate-version")
            generate_version "$2"
            ;;
        "create-release")
            create_release "$2"
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
