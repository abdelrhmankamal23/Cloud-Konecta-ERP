aws_region           = "eu-west-1"
primary_region       = "us-east-1"
environment          = "dev"
vpc_cidr             = "10.1.0.0/16"  # Different CIDR for DR region
availability_zones   = {
    "zone-1" = "eu-west-1a"
    "zone-2" = "eu-west-1b"
  }
enable_nat_gateway   = true

# Replica settings
replica_instance_class      = "db.t3.micro"
replica_deletion_protection = false  # Set to true for production
storage_encrypted          = true
db_engine                 = "postgres"

team_admin_arns = [
  "arn:aws:iam::712416034227:user/mohamed_ashraf",
  "arn:aws:iam::712416034227:user/malak_wagdy"
]