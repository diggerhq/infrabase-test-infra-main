terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "git::https://github.com/diggerhq/common-modules//s3"

  bucket_name = "${var.project_name}-${var.environment}-storage"
  environment = var.environment
  tags        = local.common_tags
}




module "cloudwatch" {
  source = "git::https://github.com/diggerhq/common-modules//cloudwatch"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "vpc" {
  source = "git::https://github.com/diggerhq/common-modules//vpc"

  project_name = var.project_name
  environment  = var.environment
  cidr_block   = var.vpc_cidr
  tags         = local.common_tags
}

module "ec2" {
  source = "git::https://github.com/diggerhq/common-modules//ec2"

  instance_count    = var.instance_count
  instance_type     = var.instance_type
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.vpc.default_security_group_id
  tags              = local.common_tags
}

module "rds" {
  source = "git::https://github.com/diggerhq/common-modules//rds"

  db_name     = "${var.project_name}${var.environment}db"
  environment = var.environment
  subnet_ids  = module.vpc.private_subnet_ids
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}
