/*
 * remote state
 */
terraform {
  backend "s3" {
    bucket = "remote-states"
    key    = "steam/vpc.state"
  }
}

/* defining provider */
provider "aws" {
  region = "${var.aws_region}"
}

/* creating vpc */
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags       = {
    Name = "${var.NetworkName}"
    Environment = "${var.Environment}"
  }
  enable_dns_hostnames = "true"
}

/* defining subnets */
resource "aws_subnet" "a" {
  vpc_id                   = "${aws_vpc.vpc.id}"
  cidr_block               = "${var.subnet_a_cidr}"
  availability_zone        = "${var.az_a}"
  map_public_ip_on_launch  = "true"
}

resource "aws_subnet" "b" {
  vpc_id                   = "${aws_vpc.vpc.id}"
  cidr_block               = "${var.subnet_b_cidr}"
  availability_zone        = "${var.az_b}"
  map_public_ip_on_launch  = "true"
}

resource "aws_subnet" "c" {
  vpc_id                   = "${aws_vpc.vpc.id}"
  cidr_block               = "${var.subnet_c_cidr}"
  availability_zone        = "${var.az_c}"
  map_public_ip_on_launch  = "true"
}


/* internet gateway */
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = {
    Name = "${var.NetworkName}-gw"
    Environment = "${var.Environment}"
  }
}

/* default router*/
resource "aws_route" "default" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

