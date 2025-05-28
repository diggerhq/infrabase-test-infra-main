###############################################################################
# NOTE: This example is intentionally insecure. It is valid Terraform that
# will apply successfully, but it violates multiple AWS security best-practices.
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

#######################################
# Public S3 bucket (no block settings)
#######################################
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "public_assets" {
  bucket = "my-public-bucket-${random_id.suffix.hex}"
  acl    = "public-read"                 # ❌ public ACL

  tags = {
    Environment = "demo"
  }
}

resource "aws_s3_bucket_public_access_block" "disabled" {
  bucket                  = aws_s3_bucket.public_assets.id
  block_public_acls       = false         # ❌ do not block public ACLs
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#######################################
# IAM user with wildcard permissions
#######################################
resource "aws_iam_user" "ci" {
  name = "ci-user"
}

resource "aws_iam_access_key" "ci" {
  user = aws_iam_user.ci.name
}

resource "aws_iam_user_policy" "full_access" {
  name = "ci-all-access"
  user = aws_iam_user.ci.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"          # ❌ wide-open actions
      Resource = "*"          # ❌ wide-open resources
    }]
  })
}

#######################################
# Security group open to the world
#######################################
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "open_all" {
  name        = "open-all-sg"
  description = "Allows all inbound traffic from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"        # ❌ any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#######################################
# Public, unencrypted RDS instance
#######################################
resource "aws_db_instance" "public_db" {
  identifier             = "public-db-demo"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  username               = "admin"
  password               = "P@ssw0rd123"       # ❌ hard-coded plaintext secret
  publicly_accessible    = true                # ❌ internet-facing DB
  vpc_security_group_ids = [aws_security_group.open_all.id]

  skip_final_snapshot    = true                # ❌ no backup before deletion
  apply_immediately      = true
}
