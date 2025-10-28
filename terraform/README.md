# Konecta ERP - Terraform Infrastructure

## Project Overview

This Terraform project deploys a **multi-environment EKS-based infrastructure** for the Konecta ERP application using **workspace-driven architecture**.

## Core Components

### 1. **Project Structure**
```
terraform/
├── main.tf              # Core infrastructure logic
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── backend.tf          # State management
├── dev.tfvars          # Development configuration
├── prod.tfvars         # Production configuration
└── modules/            # Reusable infrastructure modules
    ├── vpc/            # Virtual Private Cloud
    ├── eks/            # Kubernetes cluster
    ├── rds/            # PostgreSQL database
    ├── s3/             # Object storage
    ├── cloudfront/     # CDN distribution
    └── secrets/        # Secrets management
```

### 2. **Workspace-Driven Architecture**

The project uses **Terraform workspaces** to manage multiple environments:

```hcl
# Workspace logic in main.tf
locals {
  environment = terraform.workspace           # "dev" or "prod"
  is_prod     = terraform.workspace == "prod" # Boolean flag
  name_prefix = "konecta-${local.environment}" # Resource naming
}

# Conditional resource deployment
module "rds" {
  count = local.is_prod ? 1 : 0  # Only deploy in prod
  # ... configuration
}
```

### 3. **Environment Separation Strategy**

| Component | Dev Workspace | Prod Workspace |
|-----------|---------------|----------------|
| **Region** | eu-west-1 | us-east-1 |
| **VPC** | ✅ Basic setup | ✅ Full setup |
| **EKS** | ✅ 1 t3.small node | ✅ 2+ t3.medium nodes |
| **RDS** | ❌ Use in-cluster DB | ✅ Managed PostgreSQL |
| **CloudFront** | ❌ Direct ALB access | ✅ CDN distribution |
| **Secrets** | ❌ K8s secrets | ✅ AWS Secrets Manager |

### 4. **Module Architecture**

Each module is **self-contained** and **reusable**:

```hcl
# Example: VPC module
module "vpc" {
  source = "./modules/vpc"
  
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
}
```

### 5. **State Management**

- **Backend**: S3 with workspace-specific state files
- **State Path**: `<workspace_key_prefix>/<workspace_name>/<key>`
- **Example**: `konecta-erp/dev/terraform.tfstate` or `konecta-erp/prod/terraform.tfstate`
- **Isolation**: Complete separation between environments

#### Backend Configuration

The backend configuration uses partial configuration to support dynamic workspace keys:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "konecta-terraform-state"
    region = "eu-west-1"
    encrypt = true
    use_lockfile = true
    # key is specified during initialization
  }
}
```

**Key Structure Template**: `<workspace_key_prefix>/<workspace_name>/<key>`

```
<workspace_key_prefix>/<workspace_name>/<key>
```

- `workspace_key_prefix`: Project identifier (e.g., "konecta-erp")
- `workspace_name`: Environment name ("dev", "prod", "staging")
- `key`: State file name ("terraform.tfstate")

**Examples**:
- `konecta-erp/dev/terraform.tfstate`
- `konecta-erp/prod/terraform.tfstate`
- `my-project/staging/terraform.tfstate`

**Initialization per workspace**:
```bash
# Development
terraform init -backend-config="key=konecta-erp/dev/terraform.tfstate"

# Production
terraform init -backend-config="key=konecta-erp/prod/terraform.tfstate"

# Staging (if needed)
terraform init -backend-config="key=konecta-erp/staging/terraform.tfstate"
```

### 6. **Configuration Management**

**Variables Priority** (highest to lowest):
1. Command line: `-var-file="dev.tfvars"`
2. Environment variables: `TF_VAR_*`
3. Default values in `variables.tf`

## Quick Start with Workspaces

### 1. Initialize Terraform with Workspace-Specific Backend
```bash
cd terraform/

# Initialize for development
terraform init -backend-config="key=konecta-erp/dev/terraform.tfstate"
terraform workspace new dev

# Re-initialize for production (when switching)
terraform init -reconfigure -backend-config="key=konecta-erp/prod/terraform.tfstate"
terraform workspace new prod
```

### 2. Using the Automated Script
```bash
# Use the provided script for easier management
./init.bat dev   # Initializes and switches to dev
./init.bat prod  # Initializes and switches to prod
```

### 3. Deploy to Development (Minimal EKS)
```bash
# Switch to dev workspace
terraform workspace select dev

# Deploy with dev-specific variables
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### 4. Deploy to Production (Full Setup)
```bash
# Switch to prod workspace
terraform workspace select prod

# Deploy with prod-specific variables
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## Alternative: Using Default terraform.tfvars

You can also rename the appropriate file to `terraform.tfvars` and run without `-var-file`:

```bash
# For dev
cp dev.tfvars terraform.tfvars
terraform workspace select dev
terraform apply

# For prod
cp prod.tfvars terraform.tfvars
terraform workspace select prod
terraform apply
```

## What Each Workspace Deploys

### Development Workspace (`dev`)
**Minimal EKS Setup - Cost Optimized**
- ✅ **VPC** with public/private subnets
- ✅ **EKS cluster** (1 t3.small node)
- ✅ **S3 bucket** for frontend hosting
- ❌ **No RDS** (use in-cluster PostgreSQL or external DB)
- ❌ **No CloudFront** (direct ALB access)
- ❌ **No Secrets Manager** (use Kubernetes secrets)

### Production Workspace (`prod`)
**Full Production Setup**
- ✅ **VPC** with public/private subnets
- ✅ **EKS cluster** with auto-scaling
- ✅ **RDS PostgreSQL** database
- ✅ **CloudFront CDN**
- ✅ **Application Load Balancer**
- ✅ **Secrets Manager**
- ✅ **Auto-scaling** capabilities

## How Workspace Logic Works

The infrastructure is controlled by the current workspace using **conditional expressions**:

### Conditional Expression Syntax
```hcl
condition ? value_if_true : value_if_false
```

### Implementation
```hcl
locals {
  environment = terraform.workspace    # Gets current workspace name
  is_prod     = terraform.workspace == "prod"  # Boolean condition
}

# Always deployed
module "vpc" { ... }
module "eks" { ... }
module "s3" { ... }

# Conditional deployment using ternary operator
module "rds" { 
  count = local.is_prod ? 1 : 0  # Deploy if prod, skip if dev
}
module "cloudfront" { 
  count = local.is_prod ? 1 : 0  # Deploy if prod, skip if dev
}

# Conditional values
instance_type = terraform.workspace == "prod" ? "t3.medium" : "t3.small"
node_count    = terraform.workspace == "prod" ? 3 : 1
```

## Customization

Edit `variables.tf` and `terraform.tfvars` to customize:
- AWS region
- Instance types
- Database settings
- Key pair names
- Node counts

## Workspace Management

```bash
# List workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Switch workspace
terraform workspace select <workspace-name>
```

## Technical Details

### Resource Naming Convention
```hcl
# All resources follow this pattern:
"konecta-${environment}-${resource-type}"

# Examples:
# konecta-dev-vpc
# konecta-prod-eks-cluster
# konecta-dev-frontend-bucket
```

### Tagging Strategy
```hcl
local.common_tags = {
  Environment = local.environment    # "dev" or "prod"
  Project     = "Konecta-ERP"
  ManagedBy   = "Terraform"
  Workspace   = terraform.workspace
}
```

### Security Considerations

- **Network**: Private subnets for EKS nodes and RDS
- **Access**: Bastion host for secure SSH access
- **Secrets**: AWS Secrets Manager for production
- **IAM**: Least privilege principle for EKS service accounts

### Cost Optimization

**Development Environment:**
- Single AZ deployment where possible
- t3.small instances
- No NAT Gateway redundancy
- No RDS (use in-cluster PostgreSQL)

**Production Environment:**
- Multi-AZ for high availability
- Auto-scaling enabled
- RDS with backup retention
- CloudFront for global distribution

## Best Practices

### 1. **Always use workspaces**
```bash
# Never deploy to default workspace
terraform workspace select dev  # or prod
```

### 2. **Use environment-specific .tfvars**
```bash
# Always specify the correct tfvars file
terraform apply -var-file="dev.tfvars"
```

### 3. **Verify before applying**
```bash
# Always run plan first
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### 4. **State file backup**
```bash
# State is automatically backed up in S3
# Each workspace has separate state file
```

## Troubleshooting

### Common Issues

1. **Wrong workspace**: Check with `terraform workspace show`
2. **Missing .tfvars**: Ensure you're using the correct file
3. **AWS credentials**: Verify AWS CLI configuration
4. **Resource limits**: Check AWS service quotas

### Useful Commands

```bash
# Check current workspace
terraform workspace show

# Validate configuration
terraform validate

# Format code
terraform fmt

# Show current state
terraform show

# List resources
terraform state list
```

## Environment Separation & Workflow

### Development vs Production Separation

#### **Complete Isolation Strategy**

| Separation Layer | Development | Production | Purpose |
|------------------|-------------|------------|---------|
| **AWS Region** | eu-west-1 | us-east-1 | Geographic isolation |
| **Workspace** | `dev` | `prod` | Terraform state separation |
| **State File** | `konecta-erp/dev/terraform.tfstate` | `konecta-erp/prod/terraform.tfstate` | Complete state isolation |
| **Resource Names** | `konecta-dev-*` | `konecta-prod-*` | Clear resource identification |
| **Configuration** | `dev.tfvars` | `prod.tfvars` | Environment-specific settings |

#### **Infrastructure Differences**

```hcl
# Development (Cost-Optimized)
- Region: eu-west-1
- EKS: 1 t3.small node
- Database: In-cluster PostgreSQL
- CDN: None (direct ALB)
- Secrets: Kubernetes secrets
- Cost: ~$50-100/month

# Production (High-Availability)
- Region: us-east-1  
- EKS: 2+ t3.medium nodes with auto-scaling
- Database: RDS PostgreSQL with backups
- CDN: CloudFront distribution
- Secrets: AWS Secrets Manager
- Cost: ~$200-500/month
```

### Development Workflow

#### **1. Feature Development Cycle**

```bash
# Step 1: Develop infrastructure changes
git checkout -b feature/new-infrastructure

# Step 2: Test in development
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Step 3: Validate application deployment
kubectl get nodes
kubectl apply -f k8s-manifests/

# Step 4: Test application functionality
curl http://<alb-dns-name>/health
```

#### **2. Production Deployment Process**

```bash
# Step 1: Code review and merge
git push origin feature/new-infrastructure
# Create PR → Review → Merge to main

# Step 2: Deploy to production
git checkout main
git pull origin main

# Step 3: Production deployment
terraform workspace select prod
terraform plan -var-file="prod.tfvars"  # Review changes
terraform apply -var-file="prod.tfvars"

# Step 4: Verify production deployment
kubectl get nodes --context=prod
kubectl apply -f k8s-manifests/ --context=prod
```

#### **3. Rollback Strategy**

```bash
# Emergency rollback
terraform workspace select prod
terraform plan -destroy -var-file="prod.tfvars"
terraform destroy -target=module.new_feature -var-file="prod.tfvars"

# Or revert to previous state
git revert <commit-hash>
terraform apply -var-file="prod.tfvars"
```

### Safety Mechanisms

#### **1. Workspace Validation**
```bash
# Always verify workspace before deployment
echo "Current workspace: $(terraform workspace show)"
if [ "$(terraform workspace show)" != "prod" ]; then
  echo "⚠️  Not in production workspace!"
fi
```

#### **2. State File Protection**
```hcl
# S3 backend with versioning
terraform {
  backend "s3" {
    bucket         = "konecta-terraform-state"
    key            = "${terraform.workspace}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    versioning     = true
    dynamodb_table = "terraform-locks"  # Prevents concurrent runs
  }
}
```

#### **3. Resource Tagging for Identification**
```hcl
# All resources tagged with environment
local.common_tags = {
  Environment = local.environment     # "dev" or "prod"
  Workspace   = terraform.workspace   # Workspace name
  Project     = "Konecta-ERP"
  ManagedBy   = "Terraform"
}
```

### Best Practices for Team Workflow

#### **1. Development First Rule**
- ✅ **Always test in dev first**
- ✅ **Never deploy directly to prod**
- ✅ **Use feature branches for infrastructure changes**

#### **2. Production Deployment Checklist**
- [ ] Changes tested in dev environment
- [ ] Code reviewed and approved
- [ ] Backup plan documented
- [ ] Monitoring alerts configured
- [ ] Team notified of deployment window

#### **3. Emergency Procedures**
```bash
# Production incident response
1. Assess impact: kubectl get pods --context=prod
2. Quick fix: kubectl rollout restart deployment/app --context=prod
3. Infrastructure fix: terraform apply -var-file="prod.tfvars"
4. Full rollback: terraform destroy -target=module.problematic_resource
```

### Monitoring & Observability

#### **Environment Health Checks**
```bash
# Development environment
terraform workspace select dev
terraform output alb_dns_name
curl http://$(terraform output -raw alb_dns_name)/health

# Production environment  
terraform workspace select prod
terraform output alb_dns_name
curl http://$(terraform output -raw alb_dns_name)/health
```

### Terraform variable precedence (lowest → highest):

1- Default inside variable block  
2- Environment variable (TF_VAR_name)  
3- terraform.tfvars / .auto.tfvars  
4- CLI -var flag  