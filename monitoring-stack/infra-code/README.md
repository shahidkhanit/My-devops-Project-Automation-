# Infrastructure Code - Multi-Cloud Monitoring Setup

## 🌟 Overview
Complete multi-cloud infrastructure automation for monitoring stack with Kubernetes clusters across AWS, Azure, and GCP. Supports automated deployment via GitHub Actions and GitOps with ArgoCD.

## 🏗️ Architecture

### Monitoring Stack Components
- **Grafana**: Dashboards and visualization
- **Mimir**: Long-term metrics storage
- **Loki**: Log aggregation and storage
- **Tempo**: Distributed tracing
- **Alertmanager**: Alert routing and notifications

### Infrastructure Components
- **Kubernetes Clusters**: 2 clusters per cloud (devops + application)
- **Storage**: Cloud-native storage for monitoring data
- **Networking**: VPC/VNet setup with proper security
- **IAM/RBAC**: Service accounts and permissions

## 📁 Directory Structure
```
infra-code/
├── aws/
│   ├── kubernetes/
│   │   └── main.tf           # EKS clusters (devops + application)
│   ├── networking/
│   │   └── vpc.tf            # VPC with public/private subnets
│   ├── monitoring/
│   │   └── mimir.tf          # S3 buckets + IAM for Mimir
│   ├── storage/              # Additional storage resources
│   └── variables.tf          # AWS region and environment vars
├── azure/
│   ├── kubernetes/
│   │   └── main.tf           # AKS clusters (devops + application)
│   ├── storage/
│   │   └── storage.tf        # Storage accounts for monitoring
│   ├── monitoring/           # Azure monitoring resources
│   ├── networking/           # VNet setup
│   └── variables.tf          # Azure location and environment vars
├── gcp/
│   ├── kubernetes/
│   │   └── main.tf           # GKE clusters (devops + application)
│   ├── storage/
│   │   └── storage.tf        # GCS buckets with lifecycle policies
│   ├── monitoring/           # GCP monitoring resources
│   ├── networking/           # VPC setup
│   └── variables.tf          # GCP project and region vars
├── scripts/
│   └── terraform-apply.sh    # Automated deployment script
└── README.md                 # This file
```

## ☁️ Cloud Provider Details

### AWS Infrastructure
- **EKS Clusters**: 
  - devops-cluster (3x t3.medium nodes)
  - application-cluster (5x t3.large nodes)
- **Storage**: S3 buckets for Mimir metrics
- **Networking**: VPC with 3 AZs, public/private subnets
- **IAM**: OIDC integration for workload identity

### Azure Infrastructure
- **AKS Clusters**:
  - aks-devops-cluster (3x Standard_D2_v2 nodes)
  - aks-application-cluster (5x Standard_D4_v2 nodes)
- **Storage**: Storage accounts for Mimir/Loki/Tempo
- **Networking**: VNet with proper subnet configuration
- **Identity**: System-assigned managed identities

### GCP Infrastructure
- **GKE Clusters**:
  - devops-cluster (3x e2-medium nodes)
  - application-cluster (5x e2-standard-2 nodes)
- **Storage**: GCS buckets with lifecycle policies
- **Networking**: VPC with regional subnets
- **Identity**: Workload Identity integration

## 🚀 Deployment Methods

### 1. Automated Deployment (Recommended)
Infrastructure automatically deploys via GitHub Actions when changes are pushed to `infra-code/` directory.

**Workflow Triggers:**
- Push to `main` branch with changes in `infra-code/`
- Pull request with infrastructure changes

**Path Detection:**
- Only deploys changed cloud providers
- Separate jobs for AWS/Azure/GCP
- Parallel execution for faster deployment

### 2. Manual Deployment
```bash
# Make script executable
chmod +x infra-code/scripts/terraform-apply.sh

# Deploy specific cloud and component
./infra-code/scripts/terraform-apply.sh aws kubernetes
./infra-code/scripts/terraform-apply.sh azure storage
./infra-code/scripts/terraform-apply.sh gcp all

# Deploy all components for a cloud
./infra-code/scripts/terraform-apply.sh aws all
./infra-code/scripts/terraform-apply.sh azure all
./infra-code/scripts/terraform-apply.sh gcp all
```

### 3. Component-Specific Deployment
```bash
# Deploy only Kubernetes clusters
./infra-code/scripts/terraform-apply.sh aws kubernetes
./infra-code/scripts/terraform-apply.sh azure kubernetes
./infra-code/scripts/terraform-apply.sh gcp kubernetes

# Deploy only storage components
./infra-code/scripts/terraform-apply.sh aws storage
./infra-code/scripts/terraform-apply.sh azure storage
./infra-code/scripts/terraform-apply.sh gcp storage

# Deploy networking only
./infra-code/scripts/terraform-apply.sh aws networking
```

## 🔄 GitOps Integration

### ArgoCD Applications
Infrastructure changes automatically trigger ArgoCD sync:

- **aws-infra.yaml**: Manages AWS infrastructure deployment
- **azure-infra.yaml**: Manages Azure infrastructure deployment
- **gcp-infra.yaml**: Manages GCP infrastructure deployment

### Sync Process
1. Infrastructure code changes pushed to repository
2. GitHub Actions deploys infrastructure via Terraform
3. ArgoCD detects infrastructure updates
4. Monitoring stack automatically syncs to new clusters
5. Monitoring becomes available on new infrastructure

## 🔐 Required Secrets & Configuration

### GitHub Secrets
```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key

# Azure Credentials (Service Principal JSON)
AZURE_CREDENTIALS={
  "clientId": "your_client_id",
  "clientSecret": "your_client_secret",
  "subscriptionId": "your_subscription_id",
  "tenantId": "your_tenant_id"
}

# GCP Credentials (Service Account JSON)
GCP_SA_KEY={
  "type": "service_account",
  "project_id": "your_project_id",
  "private_key_id": "your_key_id",
  "private_key": "your_private_key",
  "client_email": "your_service_account_email",
  "client_id": "your_client_id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}

# Monitoring Stack
MIMIR_PASSWORD=your_mimir_password
```

### Terraform Variables
```bash
# AWS
export TF_VAR_region="us-west-2"
export TF_VAR_environment="production"

# Azure
export TF_VAR_location="East US"
export TF_VAR_environment="production"

# GCP
export TF_VAR_project_id="your-gcp-project"
export TF_VAR_region="us-central1"
export TF_VAR_environment="production"
```

## 🛠️ Customization

### Cluster Sizing
Modify node counts and instance types in respective `main.tf` files:

```hcl
# AWS EKS
eks_managed_node_groups = {
  devops_nodes = {
    min_size     = 2
    max_size     = 5
    desired_size = 3
    instance_types = ["t3.medium"]
  }
}

# Azure AKS
default_node_pool {
  name       = "devops"
  node_count = 3
  vm_size    = "Standard_D2_v2"
}

# GCP GKE
node_config {
  machine_type = "e2-medium"
}
```

### Storage Configuration
Adjust storage settings in `storage.tf` files:

```hcl
# Lifecycle policies
lifecycle_rule {
  condition {
    age = 90  # Days to retain metrics
  }
  action {
    type = "Delete"
  }
}
```

### Network Configuration
Modify CIDR blocks and subnets in networking files:

```hcl
# AWS VPC
cidr = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
```

## 🔍 Monitoring & Troubleshooting

### Deployment Status
Check GitHub Actions for deployment status:
- Go to repository → Actions tab
- View "Deploy Infrastructure" workflow
- Check individual cloud provider jobs

### Terraform State
Terraform state is managed locally. For production, consider:
- AWS S3 backend for state storage
- Azure Storage backend
- GCP Cloud Storage backend

### Common Issues

1. **Authentication Failures**
   - Verify cloud provider credentials in GitHub secrets
   - Check service account permissions

2. **Resource Limits**
   - Verify quota limits in cloud providers
   - Check regional availability of instance types

3. **Network Conflicts**
   - Ensure CIDR blocks don't overlap
   - Check existing VPC/VNet configurations

### Cleanup
```bash
# Destroy infrastructure
cd infra-code/aws && terraform destroy
cd infra-code/azure && terraform destroy
cd infra-code/gcp && terraform destroy
```

## 📊 Cost Optimization

### Resource Recommendations
- Use spot instances for non-production workloads
- Implement cluster autoscaling
- Set up storage lifecycle policies
- Monitor resource utilization

### Cost Monitoring
- Enable cloud provider cost monitoring
- Set up billing alerts
- Regular resource cleanup

## 🔄 Maintenance

### Regular Tasks
- Update Terraform provider versions
- Review and update instance types
- Monitor cluster health
- Update Kubernetes versions

### Backup Strategy
- Terraform state backup
- Cluster configuration backup
- Monitoring data retention policies

## 📞 Support

For issues and questions:
1. Check GitHub Actions logs
2. Review Terraform plan output
3. Verify cloud provider console
4. Check ArgoCD application status