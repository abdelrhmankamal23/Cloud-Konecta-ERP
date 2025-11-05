# Infrastructure Changes Summary

## Overview
The infrastructure has been simplified by removing S3/CloudFront modules and adding a dedicated ECR module for Docker image storage and EKS integration.

## Changes Made

### 1. **Removed S3 and CloudFront Modules**
- **Reason**: Frontend will now be hosted directly in the EKS cluster with the backend
- **Files Removed from main.tf**:
  - `module "s3"` - No longer needed
  - `module "cloudfront"` - No longer needed
  - `resource "random_id" "bucket_suffix"` - No longer needed

### 2. **Created New ECR Module** (`/modules/ecr/`)
**Purpose**: Secure Docker image storage for Kubernetes deployments

#### Files Created:
- `main.tf`: 
  - 8 ECR repositories for microservices:
    - auth-service
    - hr-service
    - finance-service
    - operation-service
    - gateway-service
    - discovery-server
    - config-server
    - reporting-service
  - IAM policy for EKS nodes to pull images from ECR
  - Lifecycle policies to keep only last 10 images
  - Image scanning enabled on push
  - AES256 encryption

- `variables.tf`:
  - `environment`: Environment name
  - `node_role_name`: EKS node IAM role name for permissions

- `outputs.tf`:
  - `ecr_repositories`: Map of repository URLs
  - `ecr_repository_arns`: Map of repository ARNs
  - `ecr_repository_names`: Map of repository names

### 3. **Updated EKS Module**
- **Removed**: `aws_ecr_repository` resources (moved to dedicated ECR module)
- **Added Output**: `node_role_name` to expose EKS node role for IAM permissions

### 4. **Updated Root Configuration**
**Files Modified**:
- `main.tf`: 
  - Removed S3, CloudFront, and random_id resources
  - Added `module "ecr"` with proper dependencies
  - Updated CloudWatch module call
  
- `outputs.tf`:
  - Removed `s3_bucket_name` and `cloudfront_domain` outputs
  - Added `ecr_repositories` output

## Security Configuration

### IAM Permissions for EKS-ECR Integration
The ECR module automatically grants the following permissions to EKS node role:
```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:DescribeRepositories",
    "ecr:DescribeImages",
    "ecr:ListImages"
  ],
  "Resource": "*"
}
```

### ECR Security Features
- ✅ Image scanning on push
- ✅ AES256 encryption at rest
- ✅ Lifecycle policy (keeps last 10 images)
- ✅ Private repositories (no public access)

## Architecture Flow

### Before (S3 + EKS):
```
User → CloudFront → S3 (Frontend)
               ↓
               ALB → EKS (Backend)
```

### After Option 1 (EKS Only - Current Implementation):
```
User → ALB → EKS (Frontend + Backend Pods)
                   ↓
              ECR (Docker Images)
```

### Alternative Option 2 (EKS + CloudFront):
```
User → CloudFront → ALB → EKS (Frontend + Backend Pods)
                                      ↓
                                 ECR (Docker Images)
```

## Cost Impact
- **Removed**: 
  - S3 storage costs (~$0.023/GB)
  - CloudFront costs (~$0.085/GB)
  - S3 request costs (~$0.0004/1000)
- **Added**:
  - ECR storage (~$0.10/GB/month)
  - ECR data transfer (~$0.02/GB)
  - Minimal cost increase as images are small

## Next Steps

### 1. Initialize Terraform
```bash
cd Cloud-Konecta-ERP/terraform
terraform init -reconfigure
```

### 2. Review Changes
```bash
terraform plan
```

### 3. Apply Changes (if satisfied)
```bash
terraform apply
```

### 4. Push Docker Images to ECR
After deployment, you'll receive ECR repository URLs. Use them to push your images:

```bash
# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push each image
docker tag your-image:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/konecta-erp/auth-service:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/konecta-erp/auth-service:latest
```

### 5. Deploy to EKS
Create Kubernetes manifests that reference ECR images:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  template:
    spec:
      containers:
      - name: auth-service
        image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/konecta-erp/auth-service:latest
        # ... rest of configuration
```

## Benefits of This Architecture

1. **Simplified Deployment**: All components in one place (EKS)
2. **Better Security**: ECR provides secure image storage with scanning
3. **Cost Efficient**: Lower costs by eliminating S3/CloudFront
4. **Easier Management**: All logs, metrics, and resources in one cluster
5. **Container-First**: Modern approach using containers for everything

## Migration Notes

If you have existing resources in S3:
1. Download content from S3 bucket
2. Create nginx/static-server deployment in EKS
3. Upload files to persistent volume
4. Point ALB to new service

The S3 bucket will be automatically destroyed when you apply these changes.
