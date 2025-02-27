resource "aws_lb" "app_lb" {
  name               = "flask-api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.api_sg.id]
  subnets            = [
    aws_subnet.public1.id,  # ✅ Terraform-managed subnets
    aws_subnet.public2.id
  ]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "flask_api_tg" {
  name        = "flask-api-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  # ✅ Add Health Check
  health_check {
    path                = "/health"  # ✅ Ensure your Flask app responds here
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_target_group_attachment" "api_instances" {
  target_group_arn = aws_lb_target_group.flask_api_tg.arn
  target_id        = aws_instance.api_server.id
  port             = 5000
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_api_tg.arn
  }
}

