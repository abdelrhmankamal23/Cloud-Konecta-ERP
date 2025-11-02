# Konecta ERP - Terraform Infrastructure

## Project Overview

This Terraform project deploys a **multi-region, multi-environment EKS-based infrastructure** for the Konecta ERP application with disaster recovery capabilities and comprehensive monitoring.

## Architecture Overview

The infrastructure follows a **multi-region deployment pattern** with:
- **Primary Region**: us-east-1 (Full production infrastructure)
- **DR Region**: us-west-1 (Read replica and disaster recovery)
- **Environment Separation**: Development and production workspaces
- **Microservices Support**: 8 containerized services with ECR repositories

## Project Structure

```
terraform/
├── environments/                    # Environment-specific configurations
│   └── dev/
│       ├── us-east-1/              # Primary region (full stack)
│       │   ├── main.tf             # Main infrastructure orchestration
│       │   ├── variables.tf        # Environment variables
│       │   ├── outputs.tf          # Infrastructure outputs
│       │   ├── backend.tf          # S3 state backend configuration
│       │   └── terraform.tfvars    # Environment-specific values
│       └── us-west-1/              # DR region (read replica only)
│           ├── main.tf             # DR infrastructure
│           ├── variables.tf        # DR variables
│           ├── backend.tf          # DR state backend
│           └── terraform.tfvars    # DR-specific values
├── modules/                        # Reusable infrastructure modules
│   ├── vpc/                        # Virtual Private Cloud module
│   ├── eks/                        # Kubernetes cluster module
│   ├── rds/                        # PostgreSQL database module
│   ├── ecr/                        # Container registry module
│   ├── secrets/                    # Secrets management module
│   └── cloudWatch/                 # Monitoring and alerting module
├── shared/                         # Shared variables and configurations
│   └── variables.tf                # Global variable definitions
└── README.md                       # This documentation
```

## Infrastructure Components

### 1. VPC Module (`modules/vpc/`)

**Purpose**: Creates the foundational network infrastructure with public/private subnets, NAT gateways, and optional VPC peering.

**Resources Created**:
- `aws_vpc.main` - Main VPC with DNS support
- `aws_internet_gateway.main` - Internet gateway for public access
- `aws_subnet.public_1/2` - Public subnets (10.0.1.0/24, 10.0.2.0/24)
- `aws_subnet.private_1/2` - Private subnets (10.0.11.0/24, 10.0.12.0/24)
- `aws_nat_gateway.main` - NAT gateway for private subnet internet access
- `aws_eip.nat` - Elastic IP for NAT gateway
- `aws_route_table.public/private` - Route tables for traffic routing
- `aws_vpc_peering_connection.to_peer` - Optional cross-region VPC peering

**Key Features**:
- Multi-AZ deployment across 2 availability zones
- Kubernetes-ready subnet tagging for ELB integration
- Conditional NAT gateway deployment
- Cross-region VPC peering support for DR scenarios

### 2. EKS Module (`modules/eks/`)

**Purpose**: Deploys a production-ready Kubernetes cluster using AWS Fargate for serverless container execution.

**Resources Created**:
- `aws_eks_cluster.main` - EKS cluster (v1.32) with comprehensive logging
- `aws_eks_fargate_profile.main` - Fargate profile for serverless pods
- `aws_iam_role.cluster` - EKS cluster service role
- `aws_iam_role.fargate` - Fargate pod execution role
- `aws_iam_openid_connect_provider.cluster` - OIDC provider for IRSA
- `aws_eks_access_entry.team_admins` - Team admin access entries
- `aws_eks_access_policy_association.team_admins_policy` - Admin policy associations

**Key Features**:
- **Serverless Architecture**: 100% Fargate-based (no EC2 nodes)
- **Enhanced Security**: Private/public endpoint access with RBAC
- **Comprehensive Logging**: All cluster log types enabled
- **Team Access Management**: Configurable admin access via ARNs
- **IRSA Ready**: OpenID Connect provider for service account roles

### 3. RDS Module (`modules/rds/`)

**Purpose**: Manages PostgreSQL databases with cross-region read replicas for disaster recovery.

**Resources Created**:
- `aws_db_instance.postgres` - Primary PostgreSQL instance (v15.8)
- `aws_db_instance.replica` - Cross-region read replica (DR)
- `aws_db_subnet_group.main` - Database subnet group
- `aws_security_group.rds` - Database security group
- `aws_kms_key.dr` - KMS key for replica encryption
- `aws_iam_role.rds_enhanced_monitoring` - Enhanced monitoring role
- `random_password.db_password` - Secure password generation

**Key Features**:
- **Multi-Region DR**: Automated cross-region read replica
- **Enhanced Security**: Encryption at rest, VPC isolation, IAM authentication
- **Performance Monitoring**: Enhanced monitoring and Performance Insights
- **Automated Backups**: 7-day retention with point-in-time recovery
- **EKS Integration**: Security group rules for cluster access

### 4. ECR Module (`modules/ecr/`)

**Purpose**: Container registry for all microservices with lifecycle management and security scanning.

**Resources Created**:
- `aws_ecr_repository.services` - 8 repositories for microservices:
  - `auth-service` - Authentication and authorization
  - `hr-service` - Human resources management
  - `finance-service` - Financial operations
  - `operation-service` - Operational workflows
  - `gateway-service` - API gateway and routing
  - `discovery-server` - Service discovery (Eureka)
  - `config-server` - Configuration management
  - `reporting-service` - Business intelligence and reporting
- `aws_ecr_lifecycle_policy.services` - Lifecycle policies (keep last 10 images)
- `aws_iam_role_policy.ecr_access` - Fargate ECR access permissions

**Key Features**:
- **Vulnerability Scanning**: Automatic image scanning on push
- **Lifecycle Management**: Automated cleanup of old images
- **Encryption**: AES256 encryption for stored images
- **Fargate Integration**: Proper IAM permissions for pod image pulls

### 5. Secrets Module (`modules/secrets/`)

**Purpose**: Secure management of application secrets using AWS Secrets Manager with KMS encryption.

**Resources Created**:
- `aws_secretsmanager_secret.db_password` - Database credentials
- `aws_secretsmanager_secret.jwt_secret` - JWT signing secret
- `aws_secretsmanager_secret_version.*` - Secret values
- `aws_kms_key.secrets_key` - KMS key for secrets encryption
- `aws_kms_alias.secrets_key_alias` - KMS key alias

**Key Features**:
- **KMS Encryption**: All secrets encrypted with customer-managed keys
- **Zero Recovery Window**: Immediate secret deletion capability
- **JSON Structure**: Structured secret storage for complex credentials
- **Application Integration**: Ready for Kubernetes secret store CSI driver

### 6. CloudWatch Module (`modules/cloudWatch/`)

**Purpose**: Comprehensive monitoring, alerting, and observability for RDS and EKS resources.

**Resources Created**:
- `aws_cloudwatch_dashboard.rds` - RDS performance dashboard
- `aws_cloudwatch_dashboard.eks_dashboard` - EKS cluster dashboard
- `aws_cloudwatch_metric_alarm.rds_cpu_high` - RDS CPU utilization alarm
- `aws_cloudwatch_metric_alarm.rds_free_storage_low` - RDS storage alarm
- `aws_cloudwatch_metric_alarm.rds_db_connections_high` - RDS connection alarm
- `aws_cloudwatch_metric_alarm.eks_pod_cpu_high` - EKS pod CPU alarm
- `aws_cloudwatch_metric_alarm.eks_pod_memory_high` - EKS pod memory alarm

**Key Features**:
- **RDS Monitoring**: CPU, storage, connections, and latency metrics
- **EKS Monitoring**: Container Insights integration for pod metrics
- **Proactive Alerting**: Configurable SNS notifications
- **Visual Dashboards**: Real-time performance visualization

## Multi-Region Architecture

### Primary Region (us-east-1)
**Full Production Stack**:
- ✅ VPC with public/private subnets
- ✅ EKS cluster with Fargate profiles
- ✅ Primary PostgreSQL database
- ✅ ECR repositories for all services
- ✅ Secrets Manager with KMS encryption
- ✅ CloudWatch monitoring and alerting

### DR Region (us-west-1)
**Disaster Recovery Setup**:
- ✅ VPC infrastructure (isolated)
- ✅ Cross-region RDS read replica
- ✅ KMS key for replica encryption
- ❌ No EKS cluster (cost optimization)
- ❌ No ECR repositories (shared from primary)

### Cross-Region Communication
- **RDS Replication**: Automated cross-region read replica
- **State Management**: Separate S3 backends per region
- **VPC Peering**: Optional cross-region VPC connectivity
- **Failover Strategy**: Manual promotion of read replica to primary

## Deployment Environments

### Development Environment
**Cost-Optimized Configuration**:
- **Region**: us-east-1
- **RDS**: Primary database only (no replica)
- **EKS**: Fargate-based with minimal resources
- **Monitoring**: Basic CloudWatch metrics
- **Estimated Cost**: $150-250/month

### Production Environment
**High-Availability Configuration**:
- **Primary Region**: us-east-1 (full stack)
- **DR Region**: us-west-1 (read replica)
- **RDS**: Primary + cross-region replica
- **EKS**: Production-grade Fargate configuration
- **Monitoring**: Full CloudWatch suite with alerting
- **Estimated Cost**: $400-600/month

## Security Architecture

### Network Security
- **VPC Isolation**: Private subnets for all compute and database resources
- **Security Groups**: Least-privilege access rules
- **NAT Gateway**: Controlled internet access for private resources
- **EKS Security**: Cluster endpoint access controls

### Data Security
- **Encryption at Rest**: KMS encryption for RDS, Secrets Manager, and ECR
- **Encryption in Transit**: TLS for all service communications
- **IAM Integration**: RDS IAM authentication enabled
- **Secret Management**: AWS Secrets Manager with rotation capability

### Access Control
- **EKS RBAC**: Kubernetes role-based access control
- **IAM Roles**: Service-specific IAM roles with minimal permissions
- **Team Access**: Configurable admin access via IAM ARNs
- **IRSA**: IAM Roles for Service Accounts for pod-level permissions

## Microservices Architecture

The infrastructure supports 8 microservices with dedicated ECR repositories:

### Core Services
1. **auth-service** - JWT-based authentication and authorization
2. **gateway-service** - API gateway with routing and load balancing
3. **discovery-server** - Eureka-based service discovery
4. **config-server** - Centralized configuration management

### Business Services
5. **hr-service** - Human resources and employee management
6. **finance-service** - Financial transactions and accounting
7. **operation-service** - Operational workflows and processes
8. **reporting-service** - Business intelligence and analytics

### Service Communication
- **Service Discovery**: Eureka server for dynamic service registration
- **Configuration**: Centralized config server for environment-specific settings
- **API Gateway**: Single entry point with request routing and authentication
- **Database**: Shared PostgreSQL with service-specific schemas

## Quick Start Guide

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- kubectl installed for EKS management

### 1. Initialize Primary Region (us-east-1)
```bash
cd terraform/environments/dev/us-east-1/

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Configure kubectl for EKS
```bash
# Get cluster credentials
aws eks update-kubeconfig --region us-east-1 --name konecta-erp-dev

# Verify cluster access
kubectl get nodes
```

### 3. Deploy DR Region (us-west-1)
```bash
cd terraform/environments/dev/us-west-1/

# Initialize Terraform
terraform init

# Deploy DR infrastructure
terraform apply
```

### 4. Verify Deployment
```bash
# Check RDS endpoints
terraform output rds_endpoint

# Check ECR repositories
terraform output ecr_repositories

# Check EKS cluster
terraform output eks_cluster_endpoint
```

## Monitoring and Observability

### CloudWatch Dashboards
- **RDS Dashboard**: Database performance metrics
- **EKS Dashboard**: Container and pod metrics

### Alerting Thresholds
- **RDS CPU**: > 80% for 5 minutes
- **RDS Storage**: < 2GB free space
- **RDS Connections**: > 100 concurrent connections
- **EKS Pod CPU**: > 80% average utilization
- **EKS Pod Memory**: > 80% average utilization

### Log Management
- **EKS Logs**: All cluster log types enabled
- **RDS Logs**: PostgreSQL and upgrade logs exported
- **Application Logs**: Container logs via CloudWatch Container Insights

## Disaster Recovery Procedures

### Failover Process
1. **Assess Primary Region**: Determine scope of outage
2. **Promote Read Replica**: Convert us-west-1 replica to primary
3. **Update DNS**: Point application to DR region
4. **Deploy EKS**: Spin up EKS cluster in DR region if needed
5. **Restore Services**: Deploy applications to DR infrastructure

### Recovery Commands
```bash
# Promote read replica to primary
aws rds promote-read-replica --db-instance-identifier konecta-erp-dev-replica --region us-west-1

# Deploy EKS in DR region (if needed)
cd terraform/environments/dev/us-west-1/
terraform apply -target=module.eks

# Update application configuration
kubectl apply -f k8s-manifests/ --context=dr-cluster
```

## Cost Optimization

### Development Environment
- **Single Region**: us-east-1 only
- **No Read Replica**: Reduces RDS costs by 50%
- **Fargate Only**: No EC2 node costs
- **Basic Monitoring**: Essential metrics only

### Production Environment
- **Reserved Instances**: Consider RDS reserved instances for 40% savings
- **Fargate Spot**: Use Spot pricing for non-critical workloads
- **Storage Optimization**: Regular cleanup of ECR images and logs
- **Auto-Scaling**: Right-size resources based on demand

## Maintenance and Updates

### Regular Tasks
- **Terraform Updates**: Keep provider versions current
- **EKS Updates**: Regular cluster and node group updates
- **RDS Maintenance**: Apply patches during maintenance windows
- **Security Scans**: Regular ECR image vulnerability scans

### Backup Strategy
- **RDS Backups**: 7-day automated backups with point-in-time recovery
- **Terraform State**: S3 versioning and cross-region replication
- **Configuration**: Git-based version control for all IaC

---

### Common Commands

#### EKS Access

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name konecta-erp-dev

# Check IAM permissions
aws sts get-caller-identity
```

```bash
# Check Terraform state
terraform state list
terraform show

# Validate configuration
terraform validate
terraform fmt

# Check resource drift
terraform plan -detailed-exitcode

```

## Best Practices

### Infrastructure as Code
- ✅ **Version Control**: All Terraform code in Git
- ✅ **Module Reusability**: Shared modules across environments
- ✅ **State Management**: Remote state with locking on S3 itself Not DynamoDB table 


### Security
- ✅ **Least Privilege**: Minimal IAM permissions
- ✅ **Encryption**: KMS encryption for all sensitive data
- ✅ **Network Isolation**: Private subnets for all resources
- ✅ **Secret Management**: AWS Secrets Manager integration

### Operations
- ✅ **Monitoring**: Comprehensive CloudWatch integration
- ✅ **Alerting**: Proactive notification system
- ✅ **Backup Strategy**: Automated backups and disaster recovery
- ✅ **Cost Optimization**: Resource right-sizing and cleanup
