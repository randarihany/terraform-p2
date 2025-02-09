resource "aws_launch_template" "ec2" {
  name = "web-server"
  image_id = "ami-085ad6ae776d8f09c"
  instance_type = "t2.micro"
  
  network_interfaces {
    //deployed in private subnet
    associate_public_ip_address = false
    security_groups = [aws_security_group.ec2_sg.id]
  }
  user_data = filebase64("userdata.sh")
            

  tag_specifications {
    resource_type = "instance"
    
    tags =  {
    Name = "ec2-web-server"
  }
}
  
}

//Auto Scaling Group
resource "aws_autoscaling_group" "ec2_asg" {
  name = "web-server-asg"
  max_size = 3
  min_size = 2
  desired_capacity = 2
  target_group_arns = [aws_lb_target_group.alb_ec2_tg.arn]
  vpc_zone_identifier = aws_subnet.tf_private_subnet[*].id
  
  launch_template {
    id      = aws_launch_template.ec2.id
    version = "$Latest"
  }
  
  health_check_type = "EC2"
}

output "alb_dns_name"{
  value = aws_lb.app_lb.dns_name
}
