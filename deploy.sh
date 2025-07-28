#!/bin/bash

# Deployment Script for Microservices
# Usage: ./deploy.sh [version] [environment]

set -e

# Default values
VERSION=${1:-"latest"}
ENVIRONMENT=${2:-"production"}
GHCR_OWNER="shivamsingh163248"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists ansible; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if ! command_exists docker; then
        print_warning "Docker not found locally. Make sure it's installed on target servers."
    fi
    
    if [ ! -f "ansible/inventory.ini" ]; then
        print_error "Inventory file not found. Please configure ansible/inventory.ini"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Test connectivity
test_connectivity() {
    print_status "Testing connectivity to servers..."
    
    if ansible -i ansible/inventory.ini webservers -m ping > /dev/null 2>&1; then
        print_success "All servers are reachable"
    else
        print_error "Some servers are not reachable. Check your inventory and SSH configuration."
        exit 1
    fi
}

# Deploy application
deploy_application() {
    print_status "Starting deployment..."
    print_status "Version: $VERSION"
    print_status "Environment: $ENVIRONMENT"
    print_status "GHCR Owner: $GHCR_OWNER"
    
    cd ansible
    
    ansible-playbook -i inventory.ini deploy.yml \
        --extra-vars "image_version=$VERSION" \
        --extra-vars "ghcr_owner=$GHCR_OWNER" \
        --extra-vars "environment=$ENVIRONMENT" \
        -v
    
    if [ $? -eq 0 ]; then
        print_success "Deployment completed successfully!"
    else
        print_error "Deployment failed!"
        exit 1
    fi
}

# Show deployment info
show_deployment_info() {
    print_status "Deployment Information:"
    echo "----------------------------------------"
    echo "Version Deployed: $VERSION"
    echo "Environment: $ENVIRONMENT"
    echo "GHCR Owner: $GHCR_OWNER"
    echo "----------------------------------------"
    
    # Get server IPs from inventory
    SERVERS=$(ansible -i ansible/inventory.ini webservers --list-hosts | grep -v "hosts" | xargs)
    
    for SERVER in $SERVERS; do
        echo "Server: $SERVER"
        echo "  Frontend: http://$SERVER:8080"
        echo "  Backend API: http://$SERVER:5000"
        echo "  Health Check: http://$SERVER:5000/health"
    done
}

# Main execution
main() {
    echo "=========================================="
    echo "  Microservices Deployment Script"
    echo "=========================================="
    
    check_prerequisites
    test_connectivity
    deploy_application
    show_deployment_info
    
    print_success "All done! 🚀"
}

# Help function
show_help() {
    echo "Usage: $0 [version] [environment]"
    echo ""
    echo "Arguments:"
    echo "  version     Docker image version (default: latest)"
    echo "  environment Deployment environment (default: production)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy latest version to production"
    echo "  $0 v1.0.123          # Deploy specific version"
    echo "  $0 latest staging    # Deploy to staging environment"
    echo ""
    echo "Requirements:"
    echo "  - Ansible installed"
    echo "  - SSH access to target servers"
    echo "  - Configured ansible/inventory.ini"
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main
