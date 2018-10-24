resource "aws_lb" "webservers" {
  name               = "webserver"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.elb.id}"]

  subnets = [
    "${aws_subnet.frontend-a.id}",
    "${aws_subnet.frontend-b.id}",
    "${aws_subnet.frontend-c.id}",
  ]

  enable_deletion_protection = false

  tags {
    Name = "webservers"
  }
}

resource "aws_lb_target_group" "webserver" {
  name     = "webserver"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
  health_check = {
    interval = 15
    path = "/"
    port = "traffic-port"
    protocol = "http"
    timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200-299"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.webservers.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate.farhan.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.webserver.arn}"
  }
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = "${aws_lb_listener.http.arn}"

  action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "host-header"
    values = ["*.farhan.tastycidr.net"]
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.webservers.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.webserver.arn}"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.farhan.zone_id}"
  name    = "www.farhan.tastycidr.net"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.webservers.dns_name}"]
}

resource "aws_route53_record" "apex" {
  zone_id = "${aws_route53_zone.farhan.zone_id}"
  name    = "farhan.tastycidr.net"
  type    = "A"

  alias {
    name                   = "${aws_lb.webservers.dns_name}"
    zone_id                = "${aws_lb.webservers.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group" "elb" {
  name        = "elb"
  description = "security group for application elb"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    ## REVISIT
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    ## REVISIT
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "webservers"
  }
}
