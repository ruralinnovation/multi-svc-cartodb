resource "aws_vpc" "main" {
    cidr_block              = "10.0.0.0/16"
    enable_dns_support      = true
    enable_dns_hostnames    = true
    tags                    = { Name = "osscarto-vpc" }
}

resource "aws_subnet" "public_1" {
    vpc_id              = "${aws_vpc.main.id}"
    cidr_block          = "10.0.11.0/16"
    availability_zone   = "us-east-1a"
    tags                = { Name = "osscarto-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
    vpc_id              = "${aws_vpc.main.id}"
    cidr_block          = "10.0.12.0/16"
    availability_zone   = "us-east-1b"
    tags                = { Name = "osscarto-public-subnet-2"}
}

resource "aws_subnet" "private_1" {
    vpc_id              = "${aws_vpc.main.id}"
    cidr_block          = "10.0.21.0/16"
    availability_zone   = "us-east-1a"
    tags                = { Name = "osscarto-private-subnet-1"}
}

resource "aws_subnet" "private_2" {
    vpc_id              = "${aws_vpc.main.id}"
    cidr_block          = "10.0.22.0/16"
    availability_zone   = "us-east-1b"
    tags                = { Name = "osscarto-private-subnet-2"}
}

resource "aws_route_table" "public" {
    vpc_id  = "${aws_vpc.main.id}"
    tags    = { Name = "osscarto-public-route-table"}

    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = "${aws_internet_gateway.main.id}"
    }
}

resource "aws_route_table" "private" {
    vpc_id  = "${aws_vpc.main.id}"
    tags    = { Name = "osscarto-private-route-table"}

    route {
        cidr_block      = "0.0.0.0/0"
        nat_gateway_id  = "${aws_nat_gateway.main.id}"
    }
}

resource "aws_route_table_association" "public_1" {
    subnet_id       = "${aws_subnet.public_1.id}"
    route_table_id  = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_2" {
    subnet_id       = "${aws_subnet.public_2.id}"
    route_table_id  = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private_1" {
    subnet_id       = "${aws_subnet.private_1.id}"
    route_table_id  = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private_2" {
    subnet_id       = "${aws_subnet.private_2.id}"
    route_table_id  = "${aws_route_table.private.id}"
}

resource "aws_eip" "nat" {
    vpc                         = true
    associate_with_private_ip   = "10.0.0.5"
    tags                        = { Name = "osscarto-nat-gw"}
}

resource "aws_internet_gateway" "main" {
    vpc_id  = "${aws_vpc.main.id}"
    tags    = { Name = "osscarto-igw" }
}

resource "aws_nat_gateway" "main" {
    allocation_id   = "${aws_eip.nat.id}"
    subnet_id       = "${aws_subnet.public_1.id}"
    depends_on      = [ 
        "aws_internet_gateway.main",
        "aws_eip.nat"
    ]
    tags            = { Name = "osscarto-nat-gw" }
}

resource "aws_security_group" "private_egress" {
    name        = "osscarto-private-sub-egress"
    description = "Allow all outbound traffic from the private subnets"
    vpc_id      = "${aws_vpc.main.id}"

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = [ "0.0.0.0/0" ]
    }
}
