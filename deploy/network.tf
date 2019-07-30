data "aws_security_group" "default" {
    name   = "default"
    vpc_id = module.vpc.vpc_id
}

module "vpc" {
    source = "../../"

    name = "osscarto-dev"

    cidr = "10.0.0.0/16"

    azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = [  "10.0.1.0/24",   "10.0.2.0/24",   "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    assign_generated_ipv6_cidr_block = true

    enable_nat_gateway = true
    single_nat_gateway = true

    public_subnet_tags = {
        Name = "overridden-name-public"
    }

    tags = {
        Owner       = "terraform"
        Environment = "dev"
    }

    vpc_tags = {
        Name        = "osscarto-dev"
        Terraform   = true
    }
}
