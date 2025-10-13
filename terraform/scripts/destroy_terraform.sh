#!/bin/bash

# Terraform Destroy Script for Multi-Environment Infrastructure
# Usage: ./destroy_terraform.sh [environment] [auto-approve]
# Example: ./destroy_terraform.sh devops auto-approve

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
AUTO_APPROVE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [environment] [auto-approve]"
    echo ""
    echo "Environments:"
    echo "  devops     - Destroy DevOps infrastructure"
    echo "  staging    - Destroy Staging infrastructure"
    echo "  prod       - Destroy Production infrastructure"
    echo ""
    echo "Options:"
    echo "  auto-approve  - Skip interactive approval"
    echo ""
    echo "Examples:"
    echo "  $0 devops"
    echo "  $0 staging auto-approve"
    echo "  $0 prod"
    echo ""
    echo "WARNING: This will PERMANENTLY DELETE all infrastructure in the specified environment!"
}

# Function to validate environment
validate_environment() {
    case $1 in
        devops|staging|prod)
            return 0
            ;;
        *)
            print_error "Invalid environment: $1"
            print_error "Valid environments: devops, staging, prod"
            return 1
            ;;
    esac
}

# Function to confirm destruction
confirm_destruction() {
    local env=$1
    local auto_approve=$2
    
    if [[ "$auto_approve" == "auto-approve" ]]; then
        print_warning "Auto-approve enabled. Skipping confirmation."
        return 0
    fi
    
    print_warning "You are about to DESTROY all infrastructure in the $env environment!"
    print_warning "This action is IRREVERSIBLE and will delete:"
    echo "  - GKE cluster and all workloads"
    echo "  - VPC network and subnets"
    echo "  - Service accounts"
    echo "  - Any persistent volumes and data"
    echo ""
    read -p "Are you absolutely sure you want to continue? (type 'yes' to confirm): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_status "Destruction cancelled by user."
        exit 0
    fi
    
    print_warning "Final confirmation required!"
    read -p "Type the environment name '$env' to proceed: " env_confirmation
    
    if [[ "$env_confirmation" != "$env" ]]; then
        print_error "Environment name mismatch. Destruction cancelled."
        exit 1
    fi
    
    print_status "Confirmation received. Proceeding with destruction..."
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install terraform first."
        exit 1
    fi
    
    # Check if gcloud is installed and authenticated
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install gcloud first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Please authenticate with Google Cloud: gcloud auth login"
        exit 1
    fi
    
    # Check if service account key exists
    if [[ ! -f "$TERRAFORM_DIR/terraform-sa-key.json" ]]; then
        print_error "Service account key not found: $TERRAFORM_DIR/terraform-sa-key.json"
        print_error "Cannot proceed without service account credentials."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to setup terraform workspace
setup_terraform() {
    local env=$1
    local tfvars_file="$TERRAFORM_DIR/environments/$env/terraform.tfvars"
    
    print_status "Setting up Terraform for $env environment..."
    
    # Change to terraform directory
    cd "$TERRAFORM_DIR"
    
    # Check if tfvars file exists
    if [[ ! -f "$tfvars_file" ]]; then
        print_error "Terraform variables file not found: $tfvars_file"
        exit 1
    fi
    
    # Set Google Application Credentials
    export GOOGLE_APPLICATION_CREDENTIALS="$TERRAFORM_DIR/terraform-sa-key.json"
    
    # Initialize terraform if needed
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing Terraform..."
        terraform init
    fi
    
    # Check if workspace exists
    if ! terraform workspace list | grep -q "$env"; then
        print_error "Workspace '$env' does not exist. Nothing to destroy."
        exit 1
    fi
    
    # Select workspace
    print_status "Selecting workspace: $env"
    terraform workspace select "$env"
    
    print_success "Terraform setup completed for $env environment"
}

# Function to run terraform destroy
run_terraform_destroy() {
    local env=$1
    local auto_approve=$2
    local tfvars_file="$TERRAFORM_DIR/environments/$env/terraform.tfvars"
    
    print_status "Running Terraform destroy for $env environment..."
    
    # First, show what will be destroyed
    print_status "Showing destruction plan..."
    terraform plan -destroy -var-file="$tfvars_file"
    
    echo ""
    print_warning "The above resources will be DESTROYED!"
    
    if [[ "$auto_approve" != "auto-approve" ]]; then
        read -p "Do you want to proceed with the destruction? (yes/no): " proceed
        if [[ "$proceed" != "yes" ]]; then
            print_status "Destruction cancelled by user."
            exit 0
        fi
    fi
    
    # Run destroy
    if [[ "$auto_approve" == "auto-approve" ]]; then
        terraform destroy -auto-approve -var-file="$tfvars_file"
    else
        terraform destroy -var-file="$tfvars_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "Terraform destroy completed successfully"
        print_success "Infrastructure for $env environment has been destroyed"
        
        # Delete the workspace
        terraform workspace select default
        terraform workspace delete "$env"
        
        return 0
    else
        print_error "Terraform destroy failed"
        print_error "Some resources may still exist. Please check the GCP console."
        return 1
    fi
}

# Main execution
main() {
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    ENVIRONMENT=$1
    AUTO_APPROVE=$2
    
    # Validate environment
    if ! validate_environment "$ENVIRONMENT"; then
        show_usage
        exit 1
    fi
    
    print_warning "Starting Terraform destruction for $ENVIRONMENT environment"
    
    # Confirm destruction
    confirm_destruction "$ENVIRONMENT" "$AUTO_APPROVE"
    
    # Run checks and destruction
    check_prerequisites
    setup_terraform "$ENVIRONMENT"
    
    if run_terraform_destroy "$ENVIRONMENT" "$AUTO_APPROVE"; then
        print_success "Destruction completed successfully!"
        print_status "All resources for $ENVIRONMENT environment have been removed."
    else
        print_error "Destruction failed"
        print_error "Please check the GCP console for any remaining resources."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"