terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Create a VPC for isolation
resource "aws_vpc" "bhojan_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "bhojan-vpc"
  }
}

# 2. Subnets configuration
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.bhojan_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "bhojan-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.bhojan_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "bhojan-public-2"
  }
}

# Internet Gateway to grant VPC internet access
resource "aws_internet_gateway" "bhojan_igw" {
  vpc_id = aws_vpc.bhojan_vpc.id

  tags = {
    Name = "bhojan-igw"
  }
}

# Route Table for public subnets routing
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.bhojan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bhojan_igw.id
  }

  tags = {
    Name = "bhojan-public-rt"
  }
}

# Route Table associations
resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Subnet Group for RDS Database
resource "aws_db_subnet_group" "db_subnets" {
  name       = "bhojan-db-subnet-group"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "bhojan-db-subnet-group"
  }
}

# 3. Security Groups
resource "aws_security_group" "db_sg" {
  name        = "bhojan-db-security-group"
  description = "Allows traffic to PostgreSQL database"
  vpc_id      = aws_vpc.bhojan_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict to application security group only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. PostgreSQL Database Instance (RDS)
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" # Free tier eligible
  db_name                = "bhojan_db"
  username               = "bhojan_admin"
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = true

  tags = {
    Name = "bhojan-postgres-db"
  }

  depends_on = [
    aws_internet_gateway.bhojan_igw,
    aws_route_table_association.pub_1,
    aws_route_table_association.pub_2
  ]
}

# 5. Redis Cache Instance (ElastiCache)
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "bhojan-redis-subnet-group"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "bhojan-redis-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
}
