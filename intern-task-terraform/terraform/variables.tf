variable "aws_region" {
  description = "AWS region for the VPC and instance."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS x86_64 AMI in us-east-1; override it when using another region."
  type        = string
  default     = "ami-0e86e20dae9224db8"
}

variable "instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr" {
  description = "Your IPv4 CIDR allowed to SSH to the instance, for example 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && var.ssh_cidr != "0.0.0.0/0"
    error_message = "ssh_cidr must be a valid, specific IPv4 CIDR; do not open SSH to 0.0.0.0/0."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the app VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR for the public subnet that hosts the app instance."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR."
  }
}