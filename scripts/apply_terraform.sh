#!/bin/bash

# Terraform Apply Script for Multi-Environment Infrastructure
# Usage: ./apply_terraform.sh [environment] [auto-approve]
# Example: ./apply_terraform.sh devops auto-approve

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
    echo "  devops     - Deploy DevOps infrastructure"
    echo "  staging    - Deploy Staging infrastructure"
    echo "  prod       - Deploy Production infrastructure"
    echo ""
    echo "Options:"
    echo "  auto-approve  - Skip interactive approval"
    echo ""
    echo "Examples:"
    echo "  $0 devops"
    echo "  $0 staging auto-approve"
    echo "  $0 prod"
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
        print_error "Please run the create_sa.sh script first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to set up terraform workspace
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
    
    # Select or create workspace
    if terraform workspace list | grep -q "$env"; then
        print_status "Selecting existing workspace: $env"
        terraform workspace select "$env"
    else
        print_status "Creating new workspace: $env"
        terraform workspace new "$env"
    fi
    
    print_success "Terraform setup completed for $env environment"
}

# Function to run terraform plan
run_terraform_plan() {
    local env=$1
    local tfvars_file="$TERRAFORM_DIR/environments/$env/terraform.tfvars"
    
    print_status "Running Terraform plan for $env environment..."
    terraform plan -var-file="$tfvars_file" -out="$env.tfplan"
    
    if [[ $? -eq 0 ]]; then
        print_success "Terraform plan completed successfully"
        return 0
    else
        print_error "Terraform plan failed"
        return 1
    fi
}

# Function to run terraform apply
run_terraform_apply() {
    local env=$1
    local auto_approve=$2
    
    print_status "Applying Terraform plan for $env environment..."
    
    if [[ "$auto_approve" == "auto-approve" ]]; then
        terraform apply -auto-approve "$env.tfplan"
    else
        terraform apply "$env.tfplan"
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "Terraform apply completed successfully"
        print_success "Infrastructure for $env environment has been deployed"
        
        # Clean up plan file
        rm -f "$env.tfplan"
        
        # Show outputs
        print_status "Infrastructure outputs:"
        terraform output
        
        return 0
    else
        print_error "Terraform apply failed"
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
    
    print_status "Starting Terraform deployment for $ENVIRONMENT environment"
    
    # Run checks and deployment
    check_prerequisites
    setup_terraform "$ENVIRONMENT"
    
    if run_terraform_plan "$ENVIRONMENT"; then
        if run_terraform_apply "$ENVIRONMENT" "$AUTO_APPROVE"; then
            print_success "Deployment completed successfully!"
            print_status "You can now access your GKE cluster using:"
            print_status "gcloud container clusters get-credentials ecommerce-$ENVIRONMENT-cluster --region us-central1"
        else
            print_error "Deployment failed during apply phase"
            exit 1
        fi
    else
        print_error "Deployment failed during planning phase"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"