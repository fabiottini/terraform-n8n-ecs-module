resource "aws_lb" "webhook" {
  name                       = "${var.project_name}-webhook-alb"
  internal                   = var.alb_webhook_internal
  load_balancer_type         = "application"
  subnets                    = var.alb_webhook_internal ? var.private_subnet_ids : var.public_subnet_ids
  security_groups            = [aws_security_group.alb_webhook.id]
  enable_deletion_protection = false
  tags = merge(var.common_tags, {
    jira_issue = "TOP-4",
    Name       = "${var.project_name}-webhook-alb"
  })
}

resource "aws_security_group" "alb_webhook" {
  name        = "${var.project_name}-webhook-alb"
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
  tags = merge(var.common_tags, {
    jira_issue = "TOP-4",
    Name       = "${var.project_name}-webhook-alb"
  })
}

resource "aws_lb_target_group" "n8n_webhook" {
  name        = "${var.project_name}-webhook-tg"
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
  tags = merge(var.common_tags, {
    jira_issue = "TOP-4",
    Name       = "${var.project_name}-webhook-tg"
  })
}

resource "aws_lb_listener" "https_webhook" {
  load_balancer_arn = aws_lb.webhook.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn_webhook
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n_webhook.arn
  }

  tags = merge(var.common_tags, {
    jira_issue = "TOP-4",
    Name       = "${var.project_name}-https-webhook-listener"
  })
}

resource "aws_lb_listener" "http_webhook" {
  load_balancer_arn = aws_lb.webhook.arn
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
  tags = merge(var.common_tags, {
    jira_issue = "TOP-4",
    Name       = "${var.project_name}-http-webhook-listener"
  })
}

resource "aws_lb_listener_rule" "blocks_static_paths_webhook" {
  listener_arn = aws_lb_listener.https_webhook.arn
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