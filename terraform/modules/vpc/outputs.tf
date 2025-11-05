output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}
output "vpc_peering_connection_id" {
  description = "VPC peering connection ID (if created)"
  value       = try(aws_vpc_peering_connection.to_peer[0].id, null)
}

# output "bastion_public_ip" {
#   description = "Public IP address of the bastion host"
#   value       = aws_instance.bastion.public_ip
# }

# output "bastion_private_ip" {
#   description = "Private IP address of the bastion host"
#   value       = aws_instance.bastion.private_ip
# }

# output "bastion_security_group_id" {
#   description = "Security group ID of the bastion host"
#   value       = aws_security_group.bastion.id
# }
