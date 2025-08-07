resource "aws_lb" "this" {
  name                       = "${var.project_name}-alb"
  internal                   = var.alb_master_internal
  load_balancer_type         = "application"
  subnets                    = var.alb_master_internal ? var.private_subnet_ids : var.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = false
  tags                       = merge(var.common_tags, { Name = "${var.project_name}-alb" })
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "Security group for the ALB ${var.project_name}"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-alb" })
}

resource "aws_lb_target_group" "n8n_master" {
  name        = "${var.project_name}-master-tg"
  port        = 5678
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-499"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-master-tg" })
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n_master.arn
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-https-listener" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-http-listener" })
}

resource "aws_lb_listener_rule" "blocks_static_paths" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["/metrics"]
    }
  }
}