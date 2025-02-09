//Security group for ALB(internet --> ALB)
resource "aws_security_group" "alb_sg" {
 name = "alb-sg"
 description = "Security group for Application Load Balancer"
 vpc_id     = aws_vpc.main_vpc.id
 
 ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
      name = "alb-sg"
  }
}


//Security group for EC2(internet --> EC2)
resource "aws_security_group" "ec2_sg" {
 name = "ec2-sg"
 description = "Security group for Apache EC2"
 vpc_id     = aws_vpc.main_vpc.id
 
 //traffic only from ALB
 ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups      = [aws_security_group.alb_sg.id]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  tags = {
      name = "ec2-sg"
  }
}