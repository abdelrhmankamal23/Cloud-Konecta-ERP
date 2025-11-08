# DR Failover Lambda Function

## What this Lambda Function Does

When primary region (us-east-1) fails, this Lambda function automatically:

1. **Promotes the backup database (RDS)** to become the main database
2. **Builds new infrastructure** in the backup region (eu-west-1)  

 { **Deploys the applications** to the new infrastructure }

## The Trigger

**CloudWatch Alarms** watch your infrastructure and trigger this function when:

- Database stops working
- The loadbalancer controller has no response

### The handler function

 It first gathers all the necessary information (like region names and database IDs) from environment variables, then executes the three critical steps in order: promotes your backup database to become the primary, builds new infrastructure in the backup region using packaged Terraform, and deploys the applications to the new infrastructure . If everything succeeds, it returns a success message with details about what was accomplished. If anything goes wrong at any step, it logs the error to CloudWatch for debugging and throws the error back to whoever called it,ensuring they know the disaster recovery failed


















## Function Breakdown

**Steps**:
1. Gets environment variables (region names, database IDs, etc.)
2. Calls the RDS promotion function
3. Calls the infrastructure building function  
4. Calls the application deployment function
5. Returns success/failure message

### `promote_rds_replica(region, replica_id)` - Database Promotion

Promotes the replica rds to be primary

**Steps**:
1. Connects to AWS RDS service in the backup region
2. Tells AWS: "Make this backup database the main one"
3. Waits for the promotion to complete (can take 5-10 minutes)
4. Confirms the database is ready to use

**Why this works**: Your backup database already has all your data (it's been copying from the main database).

### `run_terraform_apply(region)` - Infrastructure Builder
**What it does**: Downloads building plans and constructs new infrastructure.

**Simple explanation**: Like a construction crew that downloads blueprints and builds a new office.

**Steps**:
1. **Downloads blueprints**: Gets Terraform configuration files from S3 bucket
2. **Extracts files**: Unzips the configuration files to `/tmp/terraform/`
3. **Prepares environment**: Sets up variables for the backup region
4. **Initializes Terraform**: Prepares the building tools
5. **Builds infrastructure**: Runs `terraform apply` to create:
   - Virtual Private Cloud (your private network)
   - EKS cluster (where applications run)
   - Load balancers (traffic directors)
   - Security groups (firewalls)

**What gets built**: Complete copy of your primary region infrastructure.

### `deploy_applications(region, cluster_name, namespace, service_name)` - App Deployment
**What it does**: Installs and starts your applications on the new infrastructure.

**Simple explanation**: Like moving your employees and equipment to the new backup office.

**Steps**:
1. **Connects to Kubernetes**: Gets access to the new EKS cluster
2. **Configures kubectl**: Sets up the tool to manage applications
3. **Creates namespace**: Makes a dedicated space for your apps
4. **Deploys applications**: Installs your apps using Kubernetes manifests
5. **Restarts services**: Makes sure everything is running fresh

## File Structure After Download

When the function runs, it creates this structure in Lambda's temporary storage:

```
/tmp/
├── eu-west-1-dr.zip          (downloaded zip file)
└── terraform/                (extracted files)
    ├── main.tf               (infrastructure definition)
    ├── variables.tf          (configuration options)
    ├── terraform.tfvars      (actual values)
    └── backend.tf            (state storage config)
```

## Environment Variables Used

The function needs these settings (automatically provided by Terraform):

- `DR_REGION`: Where to build backup infrastructure (eu-west-1)
- `PRIMARY_REGION`: Your main region (us-east-1)
- `RDS_REPLICA_ID`: Name of your backup database
- `EKS_CLUSTER_NAME`: Name for the new Kubernetes cluster
- `APP_NAMESPACE`: Where to put your applications
- `APP_SERVICE_NAME`: Name of your main application service

## What Happens During a Real Disaster

1. **Alarm triggers** (database or load balancer fails)
2. **Lambda starts** (gets the emergency call)
3. **Database promotion** (5-10 minutes)
4. **Infrastructure building** (10-15 minutes)
5. **Application deployment** (5-10 minutes)
6. **Total time**: ~20-35 minutes to full recovery

## Success Response

When everything works, you get:
```json
{
  "statusCode": 200,
  "body": {
    "message": "DR failover completed successfully",
    "region": "eu-west-1",
    "rds_promoted": "konecta-erp-dev-replica",
    "eks_cluster": "konecta-erp-dev-dr"
  }
}
```

## Testing

To test without a real disaster:

```bash
aws lambda invoke \
  --function-name konecta-erp-dr-failover \
  --payload '{"test": true}' \
  response.json
```