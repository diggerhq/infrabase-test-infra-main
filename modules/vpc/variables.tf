variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
