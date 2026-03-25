variable "project_name" {
  description = "Prefix used for resource names/tags."
  type        = string
  default     = "tf-c2-infra"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name for SSH."
  type        = string
}

variable "ami_id" {
  description = "Optional AMI override. Leave empty to use latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "instance_type_a" {
  description = "EC2 size for the VPC A instance."
  type        = string
  default     = "t3.micro"
}

variable "instance_type_b" {
  description = "EC2 size for each VPC B instance."
  type        = string
  default     = "t3.micro"
}

variable "vpc_a_cidr" {
  description = "CIDR for VPC A."
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc_b_cidr" {
  description = "CIDR for VPC B."
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_a_cidr" {
  description = "Public subnet CIDR for VPC A."
  type        = string
  default     = "10.10.1.0/24"
}

variable "subnet_b1_cidr" {
  description = "Public subnet 1 CIDR for VPC B."
  type        = string
  default     = "10.20.1.0/24"
}

variable "subnet_b2_cidr" {
  description = "Public subnet 2 CIDR for VPC B."
  type        = string
  default     = "10.20.2.0/24"
}

variable "instance_a_private_ip" {
  description = "Static private IP for VPC A instance ENI."
  type        = string
  default     = "10.10.1.10"
}

variable "instance_b1_private_ip" {
  description = "Static private IP for VPC B instance 1 ENI."
  type        = string
  default     = "10.20.1.10"
}

variable "instance_b2_private_ip" {
  description = "Static private IP for VPC B instance 2 ENI."
  type        = string
  default     = "10.20.2.10"
}
