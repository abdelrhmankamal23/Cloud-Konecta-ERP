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
    "zone_1" = "us-east-1a"
    "zone_2" = "us-east-1b"
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

// VPC endpoints disabled; NAT is assumed and provides egress

variable "enable_vpc_peering" {
  description = "Enable creation of a VPC peering connection to a secondary VPC"
  type        = bool
  default     = false
}

variable "peer_vpc_id" {
  description = "Peer VPC ID in the secondary region/account"
  type        = string
  default     = ""
}

variable "peer_cidr_block" {
  description = "Peer VPC CIDR block for routing"
  type        = string
  default     = ""
}

variable "peer_region" {
  description = "AWS region of the peer VPC (required for cross-region peering)"
  type        = string
  default     = ""
}

# variable "enable_nat_gateway" {
#   description = "Enable NAT Gateway for private subnets"
#   type        = bool
#   default     = false
# }

# variable "bastion_host_key_name" {
#   description = "Name of the EC2 Key Pair to use for bastion host"
#   type        = string
# }
