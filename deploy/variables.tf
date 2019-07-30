variable "aws_region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block of main VPC"
}

variable "public_subnet_1_cidr" {
  default     = "10.0.11.0/24"
  description = "CIDR block of public subnet 1"
}

variable "public_subnet_2_cidr" {
  default     = "10.0.12.0/24"
  description = "CIDR block of public subnet 2"
}

variable "private_subnet_1_cidr" {
  default     = "10.0.21.0/24"
  description = "CIDR block of private subnet 1"
}

variable "private_subnet_2_cidr" {
  default     = "10.0.22.0/24"
  description = "CIDR block of private subnet 2"
}

variable "nat_private_ip" {
  default     = "10.0.0.5"
  description = "Private IP of the NAT gateway"
}
