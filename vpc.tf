resource "aws_vpc" "vpc" {
  cidr_block = "${module.global_variables.is_staging ? "10.10.0.0/16" : "10.0.0.0/16"}"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
  tags = {
    Name = "vpc-${module.global_variables.env}"
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_subnet" "public_2a" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2a"
  cidr_block = "${module.global_variables.is_staging ? "10.10.0.0/24" : "10.0.0.0/24"}"
  tags {
    Name = "${module.global_variables.env}-public-2a"
  }
}

resource "aws_subnet" "public_2c" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2c"
  cidr_block = "${module.global_variables.is_staging ? "10.10.1.0/24" : "10.0.1.0/24"}"
  tags {
    Name = "${module.global_variables.env}-public-2c"
  }
}

resource "aws_subnet" "private_2a" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2a"
  cidr_block = "${module.global_variables.is_staging ? "10.10.10.0/24" : "10.0.10.0/24"}"
  tags {
    Name = "${module.global_variables.env}-private-2a"
  }
}

resource "aws_subnet" "private_2c" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2c"
  cidr_block = "${module.global_variables.is_staging ? "10.10.11.0/24" : "10.0.11.0/24"}"
  tags {
    Name = "${module.global_variables.env}-private-2c"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_default_route_table" "public" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
  tags {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "private"
  }
}

resource "aws_route_table_association" "public_2a" {
	subnet_id = "${aws_subnet.public_2a.id}"
	route_table_id = "${aws_vpc.vpc.default_route_table_id}"
}

resource "aws_route_table_association" "public_2c" {
	subnet_id = "${aws_subnet.public_2c.id}"
	route_table_id = "${aws_vpc.vpc.default_route_table_id}"
}

resource "aws_route_table_association" "private_2a" {
	subnet_id = "${aws_subnet.private_2a.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "private_2c" {
	subnet_id = "${aws_subnet.private_2c.id}"
	route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route" "public" {
	route_table_id = "${aws_vpc.vpc.main_route_table_id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public_2a.id}"
}

resource "aws_route" "private" {
  route_table_id = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}"
}

resource "aws_network_acl" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = [
    "${aws_subnet.public_2a.id}",
    "${aws_subnet.public_2c.id}",
  ]
  tags {
    Name = "public"
  }
}

resource "aws_network_acl" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}",
  ]
  tags {
    Name = "private"
  }
}

resource "aws_network_acl_rule" "public_ingress_80" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number = 1
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "218.232.41.2/32"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "public_egress_80" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number = 1
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "public_ingress_443" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number = 2
  rule_action = "allow"
  egress = false
  protocol = "tcp"
  cidr_block = "218.232.41.2/32"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "public_egress_443" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number = 2
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_rule" "private_ingress_vpc" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number = 1
  rule_action = "allow"
  egress = false
  protocol = -1
  cidr_block = "${aws_vpc.vpc.cidr_block}"
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "private_egress_vpc" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number = 1
  rule_action = "allow"
  egress = true
  protocol = -1
  cidr_block = "${aws_vpc.vpc.cidr_block}"
  from_port = 0
  to_port = 0
}

resource "aws_network_acl_rule" "private_egress_80" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number = 2
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

resource "aws_network_acl_rule" "private_egress_443" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number = 3
  rule_action = "allow"
  egress = true
  protocol = "tcp"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}
