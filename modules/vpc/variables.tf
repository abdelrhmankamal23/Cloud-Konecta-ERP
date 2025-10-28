variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Map of availability zones"
  type        = map(string)
  default = {
    zone-1 = "us-east-1a"
    zone-2 = "us-east-1b"
    }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "bastion_host_key_name" {
  description = "Name of the EC2 Key Pair to use for bastion host"
  type        = string
}
