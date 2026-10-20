variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "conduit"
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Site domain served by CloudFront (e.g. conduit.example.com)."
  type        = string
}

variable "hosted_zone_name" {
  description = "Route 53 public hosted zone containing domain_name (e.g. example.com)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the ECS container instances."
  type        = string
  default     = "t3.small"
}

variable "image_tag" {
  description = "Backend image tag in ECR (usually the git commit SHA)."
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Number of backend tasks to run."
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}
