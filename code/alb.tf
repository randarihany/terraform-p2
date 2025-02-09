//Application load balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  //ALB will be deploed in  2 subnets
  subnets = aws_subnet.tf_public_subnet[*].id
  
  depends_on = [aws_internet_gateway.igw_vpc]
}

//Target Group for ALB
resource "aws_lb_target_group" "alb_ec2_tg" {
  name     = "alb-ec2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id     = aws_vpc.main_vpc.id
  
  tags = {
      name = "alb_ec2_tg"
  }
}


resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_ec2_tg.arn
  }
  
  tags = {
      name = "alb_listener"
  }
}