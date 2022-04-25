resource "aws_vpc" "vpc_wordpress" {
  enable_dns_hostnames = true
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_wordpress"
  }
}

resource "aws_internet_gateway" "project_igw" {
  vpc_id = "${aws_vpc.vpc_wordpress.id}"
}

resource "aws_eip" "eip_project" {
  vpc      = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc_wordpress.id}"
  availability_zone = "ap-southeast-2a"
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.vpc_wordpress.id}"
  availability_zone = "ap-southeast-2a"
  cidr_block = "10.0.10.0/24"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_project.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.project_igw]
}

resource "aws_route_table" "private_zoneA" {
  vpc_id = "${aws_vpc.vpc_wordpress.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }
}