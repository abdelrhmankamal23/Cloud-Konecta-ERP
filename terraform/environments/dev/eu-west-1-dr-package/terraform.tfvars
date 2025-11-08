aws_region           = "eu-west-1"
environment          = "dr-active"
vpc_cidr             = "10.1.0.0/16"  # Different CIDR for DR region
availability_zones   = {
    "zone_1" = "eu-west-1a"
    "zone_2" = "eu-west-1b"
  }
enable_nat_gateway   = true
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
deletion_protection  = false
storage_encrypted    = true
db_engine           = "postgres"
bastion_host_key_name = "aws-key-pair"

team_admin_arns = [
  "arn:aws:iam::712416034227:user/Abdelrhman_khaled",
  "arn:aws:iam::712416034227:user/mohamed_ashraf",
  "arn:aws:iam::712416034227:user/malak_wagdy"
]

# RDS alarm actions for CloudWatch
rds_alarm_actions = []

# ssl_certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"