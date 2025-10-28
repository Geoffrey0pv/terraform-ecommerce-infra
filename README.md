# E-commerce Infrastructure on Google Kubernetes Engine

## Overview

This repository contains Terraform configurations for deploying a production-ready e-commerce infrastructure on Google Kubernetes Engine (GKE). The infrastructure is optimized for cost-efficiency while maintaining scalability and high availability.

---

## Architecture Diagram

```mermaid
graph TB
    subgraph "Google Cloud Platform - Project: ecommerce-backend-1760307199"
        subgraph "Region: us-central1"
            subgraph "VPC Network: ecommerce-devops-vpc (10.20.0.0/20)"
                NAT[Cloud NAT Gateway<br/>Router: ecommerce-devops-vpc-nat-router]
                
                subgraph "GKE Cluster: ecommerce-devops-cluster"
                    subgraph "Node Pool: general-pool"
                        NODE1[Node 1<br/>Machine Type: e2-standard-2<br/>vCPU: 2 | RAM: 8 GB<br/>Disk: 30 GB SSD]
                        NODE2[Node 2<br/>Machine Type: e2-standard-2<br/>vCPU: 2 | RAM: 8 GB<br/>Disk: 30 GB SSD]
                        NODE3[Node 3<br/>Machine Type: e2-standard-2<br/>vCPU: 2 | RAM: 8 GB<br/>Disk: 30 GB SSD]
                        NODE4[Node 4<br/>Machine Type: e2-standard-2<br/>vCPU: 2 | RAM: 8 GB<br/>Disk: 30 GB SSD]
                    end
                    
                    subgraph "Namespace: tools"
                        JENKINS[Jenkins CI/CD]
                    end
                    
                    subgraph "Namespace: staging"
                        STAGING_APPS[Application Workloads]
                    end
                    
                    subgraph "Namespace: production"
                        PROD_APPS[Application Workloads]
                    end
                end
            end
        end
    end
    
    INTERNET((Internet)) -->|Ingress Traffic| NAT
    NAT --> NODE1
    NAT --> NODE2
    NAT --> NODE3
    NAT --> NODE4
    NODE1 -.Egress Traffic.-> NAT
    NODE2 -.Egress Traffic.-> NAT
    NODE3 -.Egress Traffic.-> NAT
    NODE4 -.Egress Traffic.-> NAT
```

---

## Infrastructure Components

### Google Cloud Project
- **Project ID**: ecommerce-backend-1760307199
- **Region**: us-central1
- **Kubernetes Version**: 1.33.4-gke.1245000

### Networking

#### VPC Network
- **Name**: ecommerce-devops-vpc
- **Subnet CIDR**: 10.20.0.0/20 (4,096 IPs)
- **Pod IP Range**: 10.21.0.0/16 (65,536 IPs)
- **Service IP Range**: 10.22.0.0/20 (4,096 IPs)

#### Cloud NAT
- **Name**: ecommerce-devops-vpc-nat-gateway
- **Router**: ecommerce-devops-vpc-nat-router
- **Purpose**: Provides internet access for private cluster nodes

### GKE Cluster

#### Cluster Configuration
- **Name**: ecommerce-devops-cluster
- **Type**: Regional
- **Region**: us-central1
- **Network**: ecommerce-devops-vpc
- **Release Channel**: REGULAR

#### Node Pool: general-pool
- **Node Count**: 4 nodes
- **Machine Type**: e2-standard-2
- **vCPU per Node**: 2 cores
- **Memory per Node**: 8 GB
- **Boot Disk**: 30 GB SSD per node
- **Total Cluster Resources**:
  - vCPU: 8 cores
  - Memory: 32 GB
  - Storage: 120 GB

#### Node Configuration
- **Image Type**: COS_CONTAINERD
- **Auto-repair**: Enabled
- **Auto-upgrade**: Enabled
- **Service Account**: Custom Terraform service account

### Namespaces

#### 1. tools
- **Purpose**: CI/CD and DevOps tooling
- **Managed by**: Terraform

#### 2. staging
- **Purpose**: Development and testing environment
- **Managed by**: Terraform

#### 3. production
- **Purpose**: Production workloads
- **Managed by**: Terraform

---

## Resource Specifications

### Compute Resources

| Component | Type | Count | vCPU | Memory | Disk |
|-----------|------|-------|------|--------|------|
| GKE Nodes | e2-standard-2 | 4 | 2 cores | 8 GB | 30 GB SSD |
| **Total** | - | **4** | **8 cores** | **32 GB** | **120 GB** |

### Network Resources

| Component | CIDR/Range | Available IPs |
|-----------|------------|---------------|
| VPC Subnet | 10.20.0.0/20 | 4,096 |
| Pod CIDR | 10.21.0.0/16 | 65,536 |
| Service CIDR | 10.22.0.0/20 | 4,096 |

### Quotas

| Resource | Used | Limit | Available |
|----------|------|-------|-----------|
| IN_USE_ADDRESSES (us-central1) | 4 | 8 | 4 (50%) |
| CPUS (us-central1) | 8 | Variable | - |
| DISKS_TOTAL_GB (us-central1) | 120 | Variable | - |

---

## Cost Estimate

### Monthly Infrastructure Costs

| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|--------------|
| e2-standard-2 nodes | 4 | ~$37.50 | ~$150.00 |
| Cloud NAT Gateway | 1 | ~$15.00 | ~$15.00 |
| Persistent Disks (SSD) | 120 GB | $0.17/GB | ~$20.00 |
| Network Egress | Variable | $0.12/GB | ~$5-10.00 |
| **Total** | - | - | **~$190/month** |

Note: Costs may vary based on actual usage and Google Cloud pricing changes.

---

## Terraform Configuration

### Directory Structure

```
.
├── main.tf                      # Main Terraform configuration
├── provider.tf                  # GCP provider configuration
├── variables.tf                 # Variable definitions
├── output.tf                    # Output definitions
├── terraform.tfvars.backup      # Variable values
├── terraform-sa-key.json        # Service account credentials
│
├── modules/
│   ├── cluster/                 # GKE cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   │
│   ├── node_pools/              # Node pools module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   │
│   ├── networking/              # VPC and networking module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   │
│   └── namespaces/              # Kubernetes namespaces module
│       ├── main.tf
│       ├── variables.tf
│       └── output.tf
│
└── scripts/
    ├── apply_terraform.sh       # Apply infrastructure
    ├── destroy_terraform.sh     # Destroy infrastructure
    ├── pause-all.sh             # Scale down to 0 nodes
    ├── resume-all.sh            # Scale up to 4 nodes
    └── check-status.sh          # Check infrastructure status
```

---

## Deployment Guide

### Prerequisites

1. **Google Cloud SDK** installed and configured
   ```bash
   gcloud --version
   ```

2. **Terraform** installed (version >= 1.0)
   ```bash
   terraform --version
   ```

3. **kubectl** installed
   ```bash
   kubectl version --client
   ```

4. **Service Account Key** with required permissions:
   - Kubernetes Engine Admin
   - Compute Admin
   - Service Account User

### Step 1: Configure Service Account

1. Create or use existing service account key (`terraform-sa-key.json`)
2. Place the key in the project root directory
3. Ensure the service account has the required IAM roles

### Step 2: Configure Variables

Edit `terraform.tfvars.backup` with your configuration:

```hcl
project_id = "ecommerce-backend-1760307199"
region     = "us-central1"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers (Google Cloud, Kubernetes)
- Initialize the backend
- Prepare modules

### Step 4: Review Infrastructure Plan

```bash
terraform plan -var-file="terraform.tfvars.backup"
```

Review the planned changes:
- GKE cluster creation
- VPC network and subnets
- Node pool with 4 nodes
- NAT gateway
- Kubernetes namespaces

### Step 5: Deploy Infrastructure

```bash
terraform apply -var-file="terraform.tfvars.backup"
```

Or use the provided script:

```bash
./scripts/apply_terraform.sh
```

Deployment takes approximately 5-10 minutes.

### Step 6: Verify Deployment

```bash
# Configure kubectl
gcloud container clusters get-credentials ecommerce-devops-cluster --region=us-central1

# Check nodes
kubectl get nodes

# Expected output:
# NAME                                              STATUS   ROLES    AGE
# gke-ecommerce-devops-general-pool-xxxxx-xxxx     Ready    <none>   5m
# gke-ecommerce-devops-general-pool-xxxxx-xxxx     Ready    <none>   5m
# gke-ecommerce-devops-general-pool-xxxxx-xxxx     Ready    <none>   5m
# gke-ecommerce-devops-general-pool-xxxxx-xxxx     Ready    <none>   5m

# Check namespaces
kubectl get namespaces

# Expected output:
# NAME              STATUS   AGE
# default           Active   5m
# kube-system       Active   5m
# kube-public       Active   5m
# tools             Active   5m
# staging           Active   5m
# production        Active   5m
```

### Step 7: View Outputs

```bash
terraform output
```

Expected outputs:
- Cluster name
- Cluster endpoint
- Cluster CA certificate
- Available namespaces

---

## Infrastructure Management

### Scaling Operations

#### Pause Infrastructure (Scale to 0 nodes)
```bash
./scripts/pause-all.sh
```
This reduces costs to approximately $45/month (only Load Balancers remain).

#### Resume Infrastructure (Scale to 4 nodes)
```bash
./scripts/resume-all.sh
```
This restores the cluster to full operational capacity.

#### Check Status
```bash
./scripts/check-status.sh
```
Shows current node count, pod status, and resource usage.

### Updating Infrastructure

```bash
# 1. Modify Terraform files as needed
# 2. Review changes
terraform plan -var-file="terraform.tfvars.backup"

# 3. Apply changes
terraform apply -var-file="terraform.tfvars.backup"
```

### Destroying Infrastructure

```bash
terraform destroy -var-file="terraform.tfvars.backup"
```

Or use the script:

```bash
./scripts/destroy_terraform.sh
```

Warning: This permanently deletes all infrastructure resources.

---

## Application Deployment

Application deployments are managed separately from infrastructure. See the `k8s-apps-v2` directory for:

- Kubernetes manifests for microservices
- Helm charts for platform components
- Deployment scripts and automation

Application deployment is intentionally decoupled from infrastructure provisioning to allow independent lifecycle management.

---

## Troubleshooting

### Common Issues

#### Issue: Quota Exceeded
```
Error: Error creating NodePool: googleapi: Error 403: Quota 'IN_USE_ADDRESSES' exceeded
```

**Solution**: 
- Check current quota usage: `gcloud compute project-info describe --project=ecommerce-backend-1760307199`
- Request quota increase in Google Cloud Console
- Or reduce node count in `variables.tf`

#### Issue: Authentication Failed
```
Error: google: could not find default credentials
```

**Solution**:
```bash
gcloud auth application-default login
```

#### Issue: kubectl Cannot Connect
```
Unable to connect to the server
```

**Solution**:
```bash
gcloud container clusters get-credentials ecommerce-devops-cluster --region=us-central1
```

### Useful Commands

```bash
# View cluster details
gcloud container clusters describe ecommerce-devops-cluster --region=us-central1

# View node pool details
gcloud container node-pools describe general-pool \
  --cluster=ecommerce-devops-cluster \
  --region=us-central1

# View current quota usage
gcloud compute project-info describe --project=ecommerce-backend-1760307199

# View Terraform state
terraform show

# List all resources
terraform state list
```

---

## Security Considerations

- Service account key (`terraform-sa-key.json`) is not version controlled (.gitignore)
- Node auto-upgrade enabled for security patches
- Private cluster endpoints (controlled by NAT gateway)
- Network policies should be implemented at application layer
- Secrets should be managed using Kubernetes Secrets or Google Secret Manager

---

## Maintenance

### Regular Tasks

- **Weekly**: Review resource usage and costs in GCP Console
- **Monthly**: Check for Terraform provider updates
- **Quarterly**: Review and optimize resource allocation
- **Annually**: Review security configurations and IAM policies

### Terraform State Management

- State is stored locally in `terraform.tfstate`
- Backup files are created automatically (`terraform.tfstate.backup`)
- Consider migrating to remote state (GCS bucket) for team environments

---

## Version Information

- Terraform: >= 1.0
- Google Provider: ~> 5.0
- Kubernetes Provider: ~> 2.20
- GKE Version: 1.33.4-gke.1245000

---

## Support and Documentation

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## License

This infrastructure code is proprietary and confidential.

---

Last Updated: October 2025
