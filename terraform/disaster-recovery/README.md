# disaster-recovery explanation

During us-east-1 Failure:

```
us-east-1: FAILS ❌
eu-west-1: DR system still running ✅
├── CloudWatch alarms detect failure ✅
├── Lambda triggers from eu-west-1 ✅
├── Downloads DR config from S3 (in eu-west-1) ✅
├── Promotes RDS replica in eu-west-1 ✅
└── Deploys full infrastructure in eu-west-1 ✅
```

---

```
resource "aws_ecr_replication_configuration" "dr_replication" 
```

Sync all images from the primary region to the backup region (eu-west-1) which helps in fast recovery as no need to rebuild images during disaster as they'll be always presentas they're automatically copied so no manual intervention needed and ready for immediate deployment when disaster strikes.

---

```
resource "aws_s3_bucket" "dr_configs" 
```

This is Lambda's "emergency instruction manual storage" - it holds everything needed to rebuild your infrastructure in the DR region during a disaster

---

```
data "archive_file" "lambda_zip"
```

The `archive_file` data source automatically packages Lambda function code into a ZIP file that AWS Lambda can deploy and execute and `${path.module}` automatically resolves to the current Terraform directory

---

```
resource "aws_iam_role_policy" "lambda_dr"
```

IAM role policy defines what the Lambda function can do once it assumes the role. It has two main permission groups:

- (Basic Lambda needs): Allows Lambda to write logs so we can debug and monitor it
- Disaster Recovery Operations: 
  - the abiltiy to convert the RDS replica to primary, and change database settings after promotion
  - full EKS control (deploy apps)
  - let EKS use existing IAM roles, create new IAM roles for EKS cluster/Fargate, attach AWS policies to created roles
  - browse S3 bucket contents and download Terraform configs from S3

---

```
resource "aws_lambda_function" "dr_failover"
```

Lambda function that will rebuild the entire system in the secondary region (eu-west-1) when the primary region fails.

---

```
resource "aws_lambda_permission" "allow_cloudwatch"
```
It give the allowance to any CloudWatch alarm in the primary region (us-east-1) can call the lambda function in the secondary region 

---

```
resource "aws_cloudwatch_metric_alarm" "rds_primary_failure"
```
Create alarm in eu-west-1 that monitors us-east-1 resources and monitors RDS CloudWatch metric counting active database connections
