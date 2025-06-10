variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  default     = "uat"
}
