resource "aws_security_group" "alb_sg" {
  name        = "alb-sg "
  description = "Allow inbound traffic to load balancer"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    description = "Allow SSH access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound access to Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# output "public_subnets" {
#   value = aws_subnet.public1.id + aws_subnet.public2.id
# }

resource "aws_lb" "ecs-alb" {
  name               = "nishad-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "ecs_nishad_service" {
  name     = "nishad-ecs-target-group"
  port     = 5000
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "nishad_listener" {
  load_balancer_arn = aws_lb.ecs-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_nishad_service.arn
  }
}
