# Manual EKS Deployment Guide

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed and running
- kubectl installed
- Helm installed
- Terraform installed

## Step 1: Deploy Infrastructure

### 1.1 Initialize Terraform
```bash
cd infrastructure/terraform
terraform init
```

### 1.2 Review Configuration
```bash
terraform plan
```

### 1.3 Deploy Infrastructure
```bash
terraform apply
```
**Expected Output**: VPC, EKS cluster, RDS database, ECR repositories, S3 bucket, secrets

### 1.4 Get Infrastructure Outputs
```bash
# Get ECR URI
ECR_URI=$(terraform output -raw ecr_repositories | jq -r '.["auth-service"]' | cut -d'/' -f1)

# Get RDS endpoint
DB_ENDPOINT=$(terraform output -raw db_endpoint)

# Get cluster name
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Get database password
DB_PASSWORD=$(terraform output -raw db_password)

echo "ECR URI: $ECR_URI"
echo "DB Endpoint: $DB_ENDPOINT"
echo "Cluster: $CLUSTER_NAME"
```

## Step 2: Configure kubectl

### 2.1 Update kubeconfig
```bash
aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME
```

### 2.2 Verify Connection
```bash
kubectl get nodes
```
**Expected Output**: List of EKS worker nodes

## Step 3: Install AWS Load Balancer Controller

### 3.1 Add Helm Repository
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

### 3.2 Install Controller
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 3.3 Verify Installation
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

## Step 4: Build and Push Docker Images

### 4.1 Login to ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI
```

### 4.2 Build Auth Service
```bash
cd backend/auth-service
docker build -t konecta-erp/auth-service .
docker tag konecta-erp/auth-service:latest $ECR_URI/konecta-erp/auth-service:latest
docker push $ECR_URI/konecta-erp/auth-service:latest
```

### 4.3 Build HR Service
```bash
cd ../hr-service
docker build -t konecta-erp/hr-service .
docker tag konecta-erp/hr-service:latest $ECR_URI/konecta-erp/hr-service:latest
docker push $ECR_URI/konecta-erp/hr-service:latest
```

### 4.4 Build Gateway Service
```bash
cd ../gateway-service
docker build -t konecta-erp/gateway-service .
docker tag konecta-erp/gateway-service:latest $ECR_URI/konecta-erp/gateway-service:latest
docker push $ECR_URI/konecta-erp/gateway-service:latest
```

### 4.5 Build Discovery Server
```bash
cd ../discovery-server
docker build -t konecta-erp/discovery-server .
docker tag konecta-erp/discovery-server:latest $ECR_URI/konecta-erp/discovery-server:latest
docker push $ECR_URI/konecta-erp/discovery-server:latest
```

### 4.6 Verify Images in ECR
```bash
aws ecr list-images --repository-name konecta-erp/auth-service --region us-east-1
```

## Step 5: Update Kubernetes Manifests

### 5.1 Update ECR URIs
```bash
cd ../../k8s
sed -i "s|<ECR_URI>|$ECR_URI|g" *.yaml
```

### 5.2 Update RDS Endpoint
```bash
sed -i "s|<RDS_ENDPOINT>|$DB_ENDPOINT|g" *.yaml
```

### 5.3 Verify Updates
```bash
grep -n "image:" auth-service.yaml
grep -n "DB_HOST" auth-service.yaml
```

## Step 6: Deploy to Kubernetes

### 6.1 Create Namespace
```bash
kubectl apply -f namespace.yaml
```

### 6.2 Create Database Secret
```bash
kubectl create secret generic db-secret \
  --from-literal=password=$DB_PASSWORD \
  -n konecta-erp
```

### 6.3 Deploy Discovery Server (First)
```bash
kubectl apply -f discovery-server.yaml
```

### 6.4 Wait for Discovery Server
```bash
kubectl wait --for=condition=ready pod -l app=discovery-server -n konecta-erp --timeout=300s
```

### 6.5 Deploy Services
```bash
kubectl apply -f auth-service.yaml
kubectl apply -f hr-service.yaml
kubectl apply -f gateway-service.yaml
```

### 6.6 Deploy Ingress
```bash
kubectl apply -f ingress.yaml
```

## Step 7: Verify Deployment

### 7.1 Check Pods
```bash
kubectl get pods -n konecta-erp
```
**Expected Output**: All pods in Running state

### 7.2 Check Services
```bash
kubectl get services -n konecta-erp
```

### 7.3 Check Ingress
```bash
kubectl get ingress -n konecta-erp
```

### 7.4 Get Application URL
```bash
ALB_URL=$(kubectl get ingress konecta-erp-ingress -n konecta-erp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_URL"
```

## Step 8: Test Application

### 8.1 Test Auth Service
```bash
curl http://$ALB_URL/auth/health
```

### 8.2 Test HR Service
```bash
curl http://$ALB_URL/hr/health
```

### 8.3 View Logs
```bash
kubectl logs -f deployment/auth-service -n konecta-erp
```

## Step 9: Monitor and Scale

### 9.1 Monitor Pods
```bash
kubectl top pods -n konecta-erp
```

### 9.2 Scale Services
```bash
kubectl scale deployment auth-service --replicas=3 -n konecta-erp
```

### 9.3 View Events
```bash
kubectl get events -n konecta-erp --sort-by='.lastTimestamp'
```

## Troubleshooting

### Common Issues

1. **Pods Stuck in Pending**
   ```bash
   kubectl describe pod <pod-name> -n konecta-erp
   ```

2. **Image Pull Errors**
   ```bash
   # Check ECR permissions
   aws ecr describe-repositories --region us-east-1
   ```

3. **Database Connection Issues**
   ```bash
   # Check secret
   kubectl get secret db-secret -n konecta-erp -o yaml
   ```

4. **Ingress Not Working**
   ```bash
   # Check ALB controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

## Cleanup

### Remove Kubernetes Resources
```bash
kubectl delete namespace konecta-erp
```

### Destroy Infrastructure
```bash
cd infrastructure/terraform
terraform destroy
```

## Next Steps

1. **Set up CI/CD pipeline** for automated deployments
2. **Configure monitoring** with CloudWatch and Prometheus
3. **Implement auto-scaling** with HPA and VPA
4. **Add SSL certificates** for HTTPS
5. **Set up backup strategies** for RDS and persistent volumes