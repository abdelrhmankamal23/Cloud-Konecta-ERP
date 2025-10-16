# Konecta ERP - Development Environment Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CloudFront CDN                          │
│                    (Frontend + API Routing)                     │
└────────────────┬────────────────────────────────┬───────────────┘
                 │                                │
        ┌────────▼────────┐              ┌────────▼────────┐
        │   S3 Bucket     │              │  Application    │
        │  (Angular SPA)  │              │  Load Balancer  │
        └─────────────────┘              └────────┬────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────────┐
                    │                             │                             │
            ┌───────▼────────┐          ┌────────▼────────┐          ┌────────▼────────┐
            │  ECS Fargate   │          │  ECS Fargate    │          │  ECS Fargate    │
            │ Gateway Service│          │ Discovery Server│          │ Config Server   │
            │    (8080)      │          │    (8761)       │          │    (8888)       │
            └───────┬────────┘          └─────────────────┘          └─────────────────┘
                    │
        ┌───────────┼───────────┬───────────────┬───────────────┐
        │           │           │               │               │
┌───────▼──────┐ ┌──▼──────┐ ┌─▼──────────┐ ┌──▼──────────┐ ┌──▼──────────┐
│ Auth Service │ │HR Service│ │Finance Svc │ │Operation Svc│ │Reporting Svc│
│   (8081)     │ │  (8082)  │ │   (8083)   │ │   (8085)    │ │   (5156)    │
└──────┬───────┘ └────┬─────┘ └─────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │              │              │               │               │
       └──────────────┴──────────────┴───────────────┴───────────────┘
                                     │
                            ┌────────▼────────┐
                            │  RDS PostgreSQL │
                            │   (db.t3.micro) │
                            │   Multi-Schema  │
                            └─────────────────┘
```

## Network Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (us-east-1a, us-east-1b)
│   ├── Application Load Balancer
│   ├── NAT Gateway
│   └── Internet Gateway
│
└── Private Subnets (us-east-1a, us-east-1b)
    ├── ECS Fargate Tasks
    │   ├── Gateway Service
    │   ├── Auth Service
    │   ├── HR Service
    │   ├── Finance Service
    │   ├── Operation Service
    │   ├── Discovery Server
    │   ├── Config Server
    │   └── Reporting Service
    │
    └── RDS PostgreSQL (Multi-AZ standby optional)
```

## Service Communication Flow

1. **User Request** → CloudFront
2. **Static Assets** → S3 Bucket
3. **API Calls** → ALB → Gateway Service
4. **Service Discovery** → Eureka Discovery Server
5. **Configuration** → Config Server
6. **Authentication** → Auth Service → JWT Token
7. **Business Logic** → HR/Finance/Operation Services
8. **Data Persistence** → RDS PostgreSQL

## Security Groups

- **ALB SG**: Allows 80/443 from internet
- **ECS Tasks SG**: Allows all ports from ALB SG
- **RDS SG**: Allows 5432 from ECS Tasks SG

## Database Schema

- auth-service DB
- hr-service DB
- finance-service DB
- operation-service DB
- reporting-service DB

## Container Registry (ECR)

- konecta-erp/auth-service
- konecta-erp/hr-service
- konecta-erp/finance-service
- konecta-erp/operation-service
- konecta-erp/gateway-service
- konecta-erp/discovery-server
- konecta-erp/config-server
- konecta-erp/reporting-service
