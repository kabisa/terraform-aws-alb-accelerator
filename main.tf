resource "aws_security_group" "https" {
  vpc_id      = var.vpc_id
  name        = "HTTPS sg"
  description = "Allow HTTPS traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_security_group" "default" {
  vpc_id = var.vpc_id
  name   = "default"
}

resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [data.aws_security_group.default.id, aws_security_group.https.id]
}

resource "aws_alb_listener" "alb3_port443" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type = "redirect"
    redirect {
      host        = var.alb_dns_name
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "alb3_port80" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_globalaccelerator_accelerator" "this" {
  name            = var.accelerator_name
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "http" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_listener" "https" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "http_alb" {
  listener_arn = aws_globalaccelerator_listener.http.id

  endpoint_configuration {
    endpoint_id = aws_lb.this.arn
    client_ip_preservation_enabled = true
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "https_alb" {
  listener_arn = aws_globalaccelerator_listener.https.id

  endpoint_configuration {
    endpoint_id = aws_lb.this.arn
    client_ip_preservation_enabled = true
    weight      = 100
  }
}
