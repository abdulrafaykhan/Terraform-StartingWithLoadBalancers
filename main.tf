terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

# Configuring the AWS Provider

provider "aws" {
  region = "us-east-1"
}

## VPC & Subnet Block ##
resource "aws_vpc" "vpc-one" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Testing VPC"
  }
}

# Create the Web Public Subnet
# Creating 02 Web Subnets since it is required by the Load Balancer
# Creating 02 DB Subnets since we need 02 seperate instances of the application
# We will still needs an IGW and NAT Gateway
resource "aws_subnet" "web-subnet-01" {
    vpc_id = aws_vpc.vpc-one.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags {
        Name = "Web-1a"
    }
}

resource "aws_subnet" "web-subnet-02" {
    vpc_id = aws_vpc.vpc-one.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true

    tags {
        Name = "Web-1b"
    }
  
}
# Create the DB Private Subnet
resource "aws_subnet" "db-subnet-01" {
    vpc_id = aws_vpc.vpc-one.id
    cidr_block = "10.0.21.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false

    tags {
        Name = "DB-1a"
    }
}

resource "aws_subnet" "db-subnet-02" {
    vpc_id = aws_vpc.vpc-one.id
    cidr_block = "10.0.22.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = false

    tags {
        Name = "DB-1b"
    }

}

# Creating the Internet Gateway for the Public Subnets to connect to the Internet
resource "aws_internet_gateway" "test-igw" {
    vpc_id = aws_vpc.vpc-one.id

    tags {
        Name = "Internet Gateway for the Public Subnets"
    }
}


# Creating the Web Layer Route Table
# This for telling the traffic for the internet to be routed properly
resource "aws_route_table_association" "Main-RT" {
    vpc_id = aws_vpc.vpc-one.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.test-igw.id
    }

    tags {
        Name = "WebRT"
    }
}

# Associating the subnets with the route table
resource "aws_route_table_association" "web-1a-rt" {
    subnet_id = aws_subnet.web-subnet-01.id
    route_table_id = aws_route_table_association.Main-RT.id
}

resource "aws_route_table_association" "web-1b-rt" {
    subnet_id = aws_subnet.web-subnet-02.id
    route_table_id = aws_route_table_association.Main-RT.id
}

## NETWORK CONFIG BLOCK FINISHED


