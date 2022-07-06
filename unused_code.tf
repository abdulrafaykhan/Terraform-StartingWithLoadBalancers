/*
# Attaching the WebServer01 with our Target Group
resource "aws_lb_target_group_attachment" "external-lb-attach01" {
  target_group_arn = aws_lb_target_group.external_elb.arn
  target_id        = aws_instance.webserver1.id
  port             = 80

  depends_on = [
    aws_instance.webserver1,
  ]

}

# Attaching the WebServer02 with our Target Group
resource "aws_lb_target_group_attachment" "external-lb-attach02" {
  target_group_arn = aws_lb_target_group.external_elb.arn
  target_id        = aws_instance.webserver2.id
  port             = 80

  depends_on = [
    aws_instance.webserver2,
  ]

}
*/

/* ## CREATING THE WEB SERVER INSTANCES
# Web Server 01
resource "aws_instance" "webserver1" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a" # Mentioning since we want to achieve uptime even if a whole AZ goes down
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-01.id
  user_data              = file("/home/rafay/Downloads/terraform-practice/StartingWithLoadBalancers/install-apache.sh")

  tags = {
    Name = "Web-Server-1a"
  }
}
# Web Server 02
resource "aws_instance" "webserver2" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b" # Mentioning since we want to achieve uptime even if a whole AZ goes down
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-02.id
  user_data              = file("/home/rafay/Downloads/terraform-practice/StartingWithLoadBalancers/install-apache.sh")

  tags = {
    Name = "Web-Server-1b"
  }
}
## Web Server Instances Block Completed
 */