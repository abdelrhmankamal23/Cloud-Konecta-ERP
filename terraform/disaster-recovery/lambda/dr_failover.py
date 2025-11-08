import boto3
import json
import os
import subprocess
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    DR Failover Lambda Function
    1. Promote RDS replica
    2. Run terraform apply in DR region
    3. Deploy applications
    """
    
    try:
        dr_region = os.environ['DR_REGION']
        rds_replica_id = os.environ['RDS_REPLICA_ID']
        eks_cluster_name = os.environ['EKS_CLUSTER_NAME']
        app_namespace = os.environ['APP_NAMESPACE']
        app_service_name = os.environ['APP_SERVICE_NAME']
        
        logger.info("Starting DR failover process...")
        
        # Step 1: Promote RDS Read Replica
        promote_rds_replica(dr_region, rds_replica_id)
        
        # Step 2: Run Terraform Apply in DR Region
        run_terraform_apply(dr_region)
        
        # Step 3: Deploy Applications
        deploy_applications(dr_region, eks_cluster_name, app_namespace, app_service_name)
        
        logger.info("DR failover completed successfully")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'DR failover completed successfully',
                'region': dr_region,
                'rds_promoted': rds_replica_id,
                'eks_cluster': eks_cluster_name
            })
        }
        
    except Exception as error:
        logger.error("DR failover failed:" + str(error) )
        raise error

def promote_rds_replica(region, replica_id):
    """Promote RDS read replica to primary"""
    logger.info(f"Promoting RDS replica {replica_id} in {region}")
    
    rds_client = boto3.client('rds', region_name=region)
    
    try:
        response = rds_client.promote_read_replica(
            DBInstanceIdentifier=replica_id
        )
        logger.info(f"RDS replica promotion initiated: {response['DBInstance']['DBInstanceStatus']}")
        
        # Wait for promotion to complete
        waiter = rds_client.get_waiter('db_instance_available')
        waiter.wait(
            DBInstanceIdentifier=replica_id,
            WaiterConfig={'Delay': 30, 'MaxAttempts': 40}
        )
        logger.info("RDS replica promoted successfully")
        
    except Exception as e:
        logger.error(f"Failed to promote RDS replica: {str(e)}")
        raise e

def run_terraform_apply(region):
    """Download DR config from S3 and run Terraform apply"""
    logger.info(f"Running Terraform apply in {region}")
    
    try:
        # Download DR configuration from S3
        s3_client = boto3.client('s3', region_name=region)
        
        logger.info("Downloading DR configuration from S3")
        s3_client.download_file(
            'konecta-erp-dr-configs',
            'eu-west-1-dr.zip',
            '/tmp/eu-west-1-dr.zip'
        )
        
        # Extract configuration
        subprocess.run(['unzip', '-o', '/tmp/eu-west-1-dr.zip', '-d', '/tmp/terraform/'], check=True, timeout=60)
        
        # Set environment variables
        env = os.environ.copy()
        env['AWS_DEFAULT_REGION'] = region
        env['TF_VAR_environment'] = 'dr-active'
        
        # Run terraform init
        logger.info("Initializing Terraform")
        init_result = subprocess.run(
            ['terraform', 'init'],
            cwd='/tmp/terraform',
            env=env,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if init_result.returncode != 0:
            raise Exception(f"Terraform init failed: {init_result.stderr}")
        
        # Run terraform apply
        logger.info("Applying Terraform configuration")
        apply_result = subprocess.run(
            ['terraform', 'apply', '-auto-approve'],
            cwd='/tmp/terraform',
            env=env,
            capture_output=True,
            text=True,
            timeout=1800
        )
        
        if apply_result.returncode != 0:
            raise Exception(f"Terraform apply failed: {apply_result.stderr}")
            
        logger.info("Terraform apply completed successfully")
        
    except Exception as e:
        logger.error(f"Terraform execution failed: {str(e)}")
        raise e

def deploy_applications(region, cluster_name, namespace, service_name):
    """Deploy applications to EKS cluster"""
    logger.info(f"Deploying applications to EKS cluster {cluster_name}")
    
    try:
        eks_client = boto3.client('eks', region_name=region)
        
        # Get cluster endpoint and certificate
        cluster_info = eks_client.describe_cluster(name=cluster_name)
        endpoint = cluster_info['cluster']['endpoint']
        
        # Configure kubectl
        subprocess.run([
            'aws', 'eks', 'update-kubeconfig',
            '--region', region,
            '--name', cluster_name
        ], check=True, timeout=60)
        
        # Apply Kubernetes manifests
        kubectl_commands = [
            f'kubectl create namespace {namespace} --dry-run=client -o yaml | kubectl apply -f -',
            f'kubectl apply -f /tmp/k8s-manifests/ -n {namespace}',
            f'kubectl rollout restart deployment/{service_name} -n {namespace}'
        ]
        
        for cmd in kubectl_commands:
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                logger.warning(f"Command failed: {cmd}, Error: {result.stderr}")
            else:
                logger.info(f"Command succeeded: {cmd}")
        
        logger.info("Application deployment completed")
        
    except Exception as e:
        logger.error(f"Application deployment failed: {str(e)}")
        raise e