#!/bin/bash

# Google Cloud Service Account Creation Script
# This script creates a service account with the necessary permissions for Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="ecommerce-backend-1760307199"
SA_NAME="terraform-sa"
SA_DISPLAY_NAME="Terraform Service Account"
KEY_FILE="terraform-sa-key.json"
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install gcloud first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Please authenticate with Google Cloud: gcloud auth login"
        exit 1
    fi
    
    # Check if project exists and is accessible
    if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
        print_error "Cannot access project '$PROJECT_ID'. Please check project ID and permissions."
        exit 1
    fi
    
    # Set the project
    gcloud config set project "$PROJECT_ID"
    
    print_success "Prerequisites check passed"
}

# Function to enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    local apis=(
        "iam.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "container.googleapis.com"
        "compute.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        print_status "Enabling $api..."
        gcloud services enable "$api" --project="$PROJECT_ID"
    done
    
    print_success "All required APIs have been enabled"
}

# Function to create service account
create_service_account() {
    print_status "Creating service account '$SA_NAME'..."
    
    # Check if service account already exists
    if gcloud iam service-accounts describe "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" &> /dev/null; then
        print_warning "Service account '$SA_NAME' already exists. Skipping creation."
    else
        gcloud iam service-accounts create "$SA_NAME" \
            --display-name="$SA_DISPLAY_NAME" \
            --description="Service account for Terraform infrastructure management" \
            --project="$PROJECT_ID"
        
        print_success "Service account '$SA_NAME' created successfully"
    fi
}

# Function to assign IAM roles
assign_roles() {
    print_status "Assigning IAM roles to service account..."
    
    local sa_email="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    local roles=(
        "roles/compute.admin"
        "roles/container.admin"
        "roles/iam.serviceAccountAdmin"
        "roles/iam.serviceAccountUser"
        "roles/resourcemanager.projectIamAdmin"
        "roles/storage.admin"
        "roles/serviceusage.serviceUsageAdmin"
    )
    
    for role in "${roles[@]}"; do
        print_status "Assigning role: $role"
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$sa_email" \
            --role="$role" \
            --quiet
    done
    
    print_success "All IAM roles have been assigned"
}

# Function to create and download service account key
create_key() {
    print_status "Creating service account key..."
    
    local sa_email="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    local key_path="$TERRAFORM_DIR/$KEY_FILE"
    
    # Remove existing key file if it exists
    if [[ -f "$key_path" ]]; then
        print_warning "Existing key file found. Backing up..."
        mv "$key_path" "${key_path}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create new key
    gcloud iam service-accounts keys create "$key_path" \
        --iam-account="$sa_email" \
        --project="$PROJECT_ID"
    
    # Set appropriate permissions on the key file
    chmod 600 "$key_path"
    
    print_success "Service account key created: $key_path"
    print_warning "Keep this key file secure and do not commit it to version control!"
}

# Function to verify service account setup
verify_setup() {
    print_status "Verifying service account setup..."
    
    local sa_email="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Check if service account exists
    if gcloud iam service-accounts describe "$sa_email" &> /dev/null; then
        print_success "Service account exists and is accessible"
    else
        print_error "Service account verification failed"
        return 1
    fi
    
    # Check if key file exists and is valid JSON
    local key_path="$TERRAFORM_DIR/$KEY_FILE"
    if [[ -f "$key_path" ]] && python3 -m json.tool "$key_path" &> /dev/null; then
        print_success "Service account key file is valid"
    else
        print_error "Service account key file is missing or invalid"
        return 1
    fi
    
    print_success "Service account setup verification completed"
}

# Function to show next steps
show_next_steps() {
    print_success "Service account setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. The service account key has been saved to: $TERRAFORM_DIR/$KEY_FILE"
    echo "2. You can now run Terraform operations using this service account"
    echo "3. Use the apply_terraform.sh script to deploy infrastructure:"
    echo "   ./scripts/apply_terraform.sh devops"
    echo "4. Or manually set the environment variable:"
    echo "   export GOOGLE_APPLICATION_CREDENTIALS=$TERRAFORM_DIR/$KEY_FILE"
    echo ""
    print_warning "Security reminders:"
    echo "- Never commit the service account key to version control"
    echo "- Store the key file securely"
    echo "- Consider using workload identity in production environments"
    echo "- Regularly rotate service account keys"
}

# Main execution
main() {
    print_status "Starting Google Cloud Service Account setup for Terraform"
    print_status "Project ID: $PROJECT_ID"
    print_status "Service Account: $SA_NAME"
    echo ""
    
    check_prerequisites
    enable_apis
    create_service_account
    assign_roles
    create_key
    verify_setup
    show_next_steps
}

# Run main function
main "$@"