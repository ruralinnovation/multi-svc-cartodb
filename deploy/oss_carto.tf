terraform {
    backend "s3" {
        region  = "us-east-1"
        bucket  = "cori-carto-remote-tfstate"
        key     = "tfstate/oss_carto.tfstate"
    }
    required_providers {
        aws     = ">= 2.14.0"
    }
}

provider "aws" {
    region = "us-east-1"
}

#### VARIABLES ###############################################################

variable "region" {
    default     = "us-east-1"
    description = "AWS Region"
}

variable "vpc_cidr" {
    default     = "10.0.0.0/16"
    description = "VPC CIDR Block"
}

variable "public_subnet_1_cidr" { description = "Public Subnet 1 CIDR" }

variable "private_subnet_1_cidr" { description = "Private Subnet 1 CIDR"}

#### NETWORKING ##############################################################

resource "aws_vpc" "osc_vpc" {
    cidr_block              = "${var.vpc_cidr}"
    enable_dns_hostnames    = true
    tags                    = { Name = "OSC VPC" }
}

resource "aws_subnet" "osc_public_subnet_1" {
    vpc_id              = "${aws_vpc.osc_vpc.id}"
    cidr_block          = "${var.public_subnet_1_cidr}"
    availability_zone   = "us-east-1a"
    tags                = { Name = "OSC Public Subnet 1"}
}

resource "aws_subnet" "osc_private_subnet_1" {
    vpc_id              = "${aws_vpc.osc_vpc.id}"
    cidr_block          = "${var.private_subnet_1_cidr}"
    availability_zone   = "us-east-1a"
    tags                = { Name = "OSC Private Subnet 1"}
}

resource "aws_route_table" "osc_public_route_table" {
    vpc_id = "${aws_vpc.osc_vpc.id}"
    tags   = { Name = "OSC Public Route Table"}
}

resource "aws_route_table" "osc_private_route_table" {
    vpc_id = "${aws_vpc.osc_vpc.id}"
    tags   = { Name = "OSC Private Route Table"}
}

resource "aws_route_table_association" "osc_public_subnet_1_association" {
    route_table_id  = "${aws_route_table.osc_public_route_table.id}"
    subnet_id       = "${aws_subnet.osc_public_subnet_1.id}"
}

resource "aws_route_table_association" "osc_private_subnet_1_association" {
    route_table_id  = "${aws_route_table.osc_private_route_table.id}"
    subnet_id       = "${aws_route_table.osc_private_route_table.id}"   
}

resource "aws_eip" "osc_eip_for_nat_gw" {
    vpc                         = true
    associate_with_private_ip   = "10.0.0.5"
    tags                        = { Name = "OSC NAT GW EIP" }
}

resource "aws_nat_gateway" "osc_nat_gw" {
    allocation_id   = "${aws_eip.osc_eip_for_nat_gw.id}"
    subnet_id       = "${aws_subnet.osc_public_subnet_1.id}"
    depends_on      = ["aws_eip.osc_eip_for_nat_gw"]
    tags            = { Name = "OSC NAT GW" }
}

resource "aws_internet_gateway" "osc_igw" {
    vpc_id = "${aws_vpc.osc_vpc.id}"
    tags   = { Name = "OSC IGW" }
}

resource "aws_route" "osc_public_igw_route" {
    route_table_id          = "${aws_route_table.osc_public_route_table.id}"
    gateway_id              = "${aws_internet_gateway.osc_igw.id}"
    destination_cidr_block  = "0.0.0.0/0"
}
