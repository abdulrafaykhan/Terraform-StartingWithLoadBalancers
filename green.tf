/* GREEN ENV CONFIG 

## CREATING THE AUTOSCALING GROUP

# Creating the autoscaling configuration
resource "aws_launch_configuration" "greenASGConf" {
  name_prefix = "GreenASGConf-"
  image_id = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
  user_data = file("/home/rafay/Downloads/terraform-practice/StartingWithLoadBalancers/install-apache.sh")
  security_groups = [aws_security_group.webserver-sg.id]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Creating the AutoScaling Group
resource "aws_autoscaling_group" "greenASG" {
  min_size = 3
  max_size = 5
  desired_capacity = 4
  launch_configuration = aws_launch_configuration.greenASGConf.name
  vpc_zone_identifier = [aws_subnet.web-subnet-01.id, aws_subnet.web-subnet-02.id]
  
}

#Defining the LoadBalancer Target Group for Green

resource "aws_lb_target_group" "green_elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-one.id

}


# Defining the AutoScaling Attachment with ELB
resource "aws_autoscaling_attachment" "green_elb_ASG" {

  autoscaling_group_name = aws_autoscaling_group.greenASG.id
  alb_target_group_arn = aws_lb_target_group.green_elb.arn 

}

# Defining the ALB Listener
resource "aws_lb_listener" "green_lb_listener" {
  load_balancer_arn = aws_lb.external_lb.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green_elb.arn
  }
}

*/
