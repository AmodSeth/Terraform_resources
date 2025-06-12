data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "public-subnet-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Type        = "Public"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name        = "private-subnet-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Type        = "Private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "igw-${var.environment}"
    Environment = var.environment
  }
}
#
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]
  
  tags = {
    Name        = "eip-nat-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name        = "nat-gateway-${var.environment}"
    Environment = var.environment
  }
}
# Public Route Table

# Public route table (routes to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "public-rt-${var.environment}"
    Environment = var.environment
  }
}

# Private route table (routes to NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name        = "private-rt-${var.environment}"
    Environment = var.environment
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
# creating security group
resource "aws_security_group" "public_sg" {
  name        = "public-sg-${var.environment}"
  description = "Security group for public EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "public-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg-${var.environment}"
  description = "Security group for private EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]  # Only from public SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "private-sg-${var.environment}"
    Environment = var.environment
  }
}
# EC2 instance in public subnet
resource "aws_instance" "public" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.public_sg.id,aws_security_group.private_sg.id]
  subnet_id              = aws_subnet.public[0].id

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "public-ec2-${var.environment}"
    Environment = var.environment
    Type        = "Public"
  }
}

# EC2 instance in private subnet
resource "aws_instance" "private" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id              = aws_subnet.private[0].id

  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "private-ec2-${var.environment}"
    Environment = var.environment
    Type        = "Private"
  }
}