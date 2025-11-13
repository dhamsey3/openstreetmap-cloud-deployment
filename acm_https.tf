# ACM Certificate for HTTPS (requires domain validation)
# Note: You need to manually validate the domain ownership via DNS or email
variable "domain_name" {
  description = "Domain name for the application (e.g., osm.example.com)"
  type        = string
  default     = ""  # Set this in terraform.tfvars if you have a domain
}

resource "aws_acm_certificate" "main" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "openstreetmap-cert"
  }
}

# HTTPS listener for ALB (only created if domain_name is set)
resource "aws_lb_listener" "https" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  depends_on = [aws_acm_certificate.main]
}

# Update security group to allow HTTPS
resource "aws_security_group_rule" "alb_https_ingress" {
  count             = var.domain_name != "" ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Optional: Redirect HTTP to HTTPS
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  count        = var.domain_name != "" ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
