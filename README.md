# Konecta ERP Terraform Infrastructure

This directory contains Terraform configurations for deploying the Konecta ERP system infrastructure on AWS.

## Structure

```
terraform/
├── dev/                   
│   ├── main.tf            
│   ├── variables.tf       
│   ├── outputs.tf         
│   ├── terraform.tfvars   
│   └── .terraform.lock.hcl
└── modules/               
    ├── vpc/               
    ├── ecs/               
    ├── rds/               
    ├── s3/                
    ├── cloudfront/        
    └── secrets/           
```

## Environments

### Development (dev/)
- **Cost-optimized** for AWS Free Tier
- Used single EC2 instance (t2.micro) instead of ECS
- Used default VPC to avoid NAT Gateway costs
- Local PostgreSQL installation on EC2
- S3 static website hosting for frontend

### Terraform Modules
The modules directory contains reusable infrastructure components:

#### VPC Module (`modules/vpc/`)
- **Purpose**: Creates isolated network infrastructure
- **Role**: Provides secure networking foundation for all services
- **Components**: VPC, public/private subnets, internet gateway, NAT gateway, route tables
- **Usage**: Base networking layer that other modules depend on

#### ECS Module (`modules/ecs/`)

- **Purpose**: Container orchestration platform for microservices
- **Role**: Hosts and manages all backend services (auth, HR, finance, etc.)
- **Components**: ECS cluster, ECR repositories, Application Load Balancer, security groups
- **Usage**: Production-ready container deployment with auto-scaling

#### RDS Module (`modules/rds/`)

- **Purpose**: Managed PostgreSQL database service
- **Role**: Centralized data storage for all application services
- **Components**: RDS instance, subnet group, security group, automated backups
- **Usage**: Scalable, secure database with high availability options

#### S3 Module (`modules/s3/`)

- **Purpose**: Static website hosting for frontend application
- **Role**: Serves Angular frontend assets with high availability
- **Components**: S3 bucket, website configuration, public access policies
- **Usage**: Cost-effective frontend hosting with global accessibility

#### CloudFront Module (`modules/cloudfront/`)

- **Purpose**: Content Delivery Network (CDN) for global performance
- **Role**: Accelerates content delivery and provides SSL termination
- **Components**: CloudFront distribution, origin access control, caching behaviors
- **Usage**: Improves user experience with faster load times worldwide

#### Secrets Module (`modules/secrets/`)

- **Purpose**: Secure storage and management of sensitive data
- **Role**: Protects database passwords, JWT secrets, and API keys
- **Components**: AWS Secrets Manager, KMS encryption, secret rotation
- **Usage**: Enterprise-grade security for application credentials

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **EC2 Key Pair** (optional, for SSH access)

## Quick Start

1. **Navigate to dev environment:**
   ```bash
   cd infrastructure/terraform/dev
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review and modify variables:**
   ```bash
   # Edit terraform.tfvars
   aws_region = "us-east-1"
   environment = "dev"
   key_name = "your-key-pair-name"  # Optional
   ```

4. **Plan deployment:**
   ```bash
   terraform plan
   ```

5. **Deploy infrastructure:**
   ```bash
   terraform apply
   ```

## Security

- **Security Groups**: Configured for HTTP/HTTPS and application ports
- **S3 Bucket**: Public read access for static website hosting
- **EC2 Instance**: Optional SSH access with key pair
- **Database**: Local PostgreSQL with standard security
