resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "konecta-erp-${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "konecta-erp-igw-${var.environment}"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "konecta-erp-public-${var.environment}-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "konecta-erp-public-${var.environment}-2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "konecta-erp-private-${var.environment}-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = var.availability_zones[1]
  
  tags = {
    Name = "konecta-erp-private-${var.environment}-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "konecta-erp-public-rt-${var.environment}"
  }
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  tags = {
    Name = "konecta-erp-nat-eip-${var.environment}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_1.id
  tags = {
    Name = "konecta-erp-nat-gateway-${var.environment}"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
  }
  tags = {
    Name = "konecta-erp-private-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# # Bastion Host Security Group
# resource "aws_security_group" "bastion" {
#   name_prefix = "konecta-erp-bastion-${var.environment}-"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "SSH access to bastion host"
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "All outbound traffic"
#   }

#   tags = {
#     Name = "konecta-erp-bastion-sg-${var.environment}"
#   }
# }

# # Bastion Host Instance
# resource "aws_instance" "bastion" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = "t2.micro"
#   key_name               = var.bastion_host_key_name
#   subnet_id              = aws_subnet.public_1.id
#   vpc_security_group_ids = [aws_security_group.bastion.id]
  
#   associate_public_ip_address = true

#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     yum update -y
#     yum install -y kubectl
#     aws eks update-kubeconfig --region ${data.aws_region.current.name} --name konecta-erp-${var.environment}
#   EOF
#   )

#   tags = {
#     Name = "konecta-erp-bastion-${var.environment}"
#   }
# }

# # Data sources for bastion host
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

data "aws_region" "current" {}