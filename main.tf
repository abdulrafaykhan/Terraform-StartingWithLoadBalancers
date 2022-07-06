terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
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
  vpc_id                  = aws_vpc.vpc-one.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Web-1a"
  }
}

resource "aws_subnet" "web-subnet-02" {
  vpc_id                  = aws_vpc.vpc-one.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Web-1b"
  }

}
# Create the DB Private Subnet
resource "aws_subnet" "db-subnet-01" {
  vpc_id                  = aws_vpc.vpc-one.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "DB-1a"
  }
}

resource "aws_subnet" "db-subnet-02" {
  vpc_id                  = aws_vpc.vpc-one.id
  cidr_block              = "10.0.22.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "DB-1b"
  }

}

# Creating the Internet Gateway for the Public Subnets to connect to the Internet
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.vpc-one.id

  tags = {
    Name = "Internet Gateway for the Public Subnets"
  }
}


# Creating the Web Layer Route Table
# This for telling the traffic for the internet to be routed properly
resource "aws_route_table" "Main-RT" {
  vpc_id = aws_vpc.vpc-one.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-igw.id
  }

  tags = {
    Name = "WebRT"
  }
}

# Associating the subnets with the route table
resource "aws_route_table_association" "web-1a-rt" {
  subnet_id      = aws_subnet.web-subnet-01.id
  route_table_id = aws_route_table.Main-RT.id
}

resource "aws_route_table_association" "web-1b-rt" {
  subnet_id      = aws_subnet.web-subnet-02.id
  route_table_id = aws_route_table.Main-RT.id
}

## NETWORK CONFIG BLOCK FINISHED


## CREATING THE AUTOSCALING GROUP

# Creating the autoscaling configuration
resource "aws_launch_configuration" "TestASGConf" {
  name_prefix = "TestASGConf-"
  image_id = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
  user_data = file("/home/rafay/Downloads/terraform-practice/StartingWithLoadBalancers/install-apache.sh")
  security_groups = [aws_security_group.webserver-sg.id]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Creating the AutoScaling Group
resource "aws_autoscaling_group" "TestASG" {
  min_size = 3
  max_size = 5
  desired_capacity = 4
  launch_configuration = aws_launch_configuration.TestASGConf.name
  vpc_zone_identifier = [aws_subnet.web-subnet-01.id, aws_subnet.web-subnet-02.id]
  
}

## CREATING THE SECURITY GROUPS

# Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "Web-SG"
  description = "Allow HTTP Inbound Traffic"
  vpc_id      = aws_vpc.vpc-one.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}

# Web Server Security Group
resource "aws_security_group" "webserver-sg" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.vpc-one.id

  ingress {
    description     = "Allow traffic from Web Layer / Servers"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "WebServer-SG"
  }

}

# DB Server Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow Inbound Traffic from only the Application Layer"
  vpc_id      = aws_vpc.vpc-one.id

  ingress {
    description     = "Allow Inbound Traffic from Only The App Layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-sg.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}


## SECURITY GROUPS BLOCK CLOSED

## CREATING THE APPLICATION LOAD BALANCER

# Defining the Application Load Balancer
resource "aws_lb" "external_lb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.web-subnet-01.id, aws_subnet.web-subnet-02.id]
  access_logs {
    enabled = true
    bucket = "my-elb-tf-test-bucket"

  }
}

# Definiting the Load Balancer Target Group
resource "aws_lb_target_group" "external_elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-one.id

}

# Defining the AutoScaling Attachment with ELB
resource "aws_autoscaling_attachment" "external_elb_ASG" {

  autoscaling_group_name = aws_autoscaling_group.TestASG.id
  alb_target_group_arn = aws_lb_target_group.external_elb.arn

}


# Defining the ALB Listener
resource "aws_lb_listener" "external_lb_listener" {
  load_balancer_arn = aws_lb.external_lb.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_elb.arn
  }
}

## APPLICATION LOAD BALANCER BLOCK CLOSED


## CREATING THE RDS INSTANCE
resource "aws_db_instance" "dbserver-default" {

  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.dbserver-default-group.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  name                   = "MyDB"
  username               = var.username
  password               = var.password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]

}

resource "aws_db_subnet_group" "dbserver-default-group" {
  name       = "main"
  subnet_ids = [aws_subnet.db-subnet-01.id, aws_subnet.db-subnet-02.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}

## ADDING S3 Bucket for ALB Logs

resource "aws_s3_bucket" "alb_Accesslogsbucket" {
  bucket = "awslogselbaccess"
  
}

resource "aws_s3_bucket_acl" "AccessLogs_ACL" {

  bucket = "awslogselbaccess"
  acl = "private"
  
}


# Configuring the relevant permissions
resource "aws_s3_bucket" "elb_logs" {
  bucket = "my-elb-tf-test-bucket"
  acl    = "private"

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::my-elb-tf-test-bucket/AWSLogs/*",
      "Principal": {
        "AWS": [
          "127311923021"
        ]
      }
    }
  ]
}
POLICY
}

## S3 Bucket for ALB Logs CLOSED