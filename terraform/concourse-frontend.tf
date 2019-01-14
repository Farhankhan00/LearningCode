resource "aws_security_group" "concourse-master" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "concourse-master"

  tags {
    Name = "concourse-master"
  }

  ingress {
    from_port = 2222
    to_port   = 2222
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.concourse-master-lb.id}",
    ]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.concourse-master-lb.id}",
    ]
  }

  ingress {
    from_port = 1024
    to_port   = 65535
    protocol  = "tcp"
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "concourse-master-lb" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "concourse-master-lb"

  tags {
    Name = "concourse-master-lb"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["104.158.158.8/32"]
  }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   security_groups = [
  #     "${aws_security_group.concourse-master.id}"
  #   ]
  # }

  # ingress {
  #   from_port = 2222
  #   to_port   = 2222
  #   protocol  = "tcp"

  #   security_groups = [
  #     "${aws_security_group.concourse-master.id}",
  #   ]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "concourse-master" {
  name = "concourse-master"

  subnets = [
    "${aws_subnet.frontend-a.id}",
    "${aws_subnet.frontend-b.id}",
    "${aws_subnet.frontend-c.id}",
  ]

  security_groups = [
    "${aws_security_group.concourse-master-lb.id}",
  ]

  listener {
    instance_port     = 2222
    instance_protocol = "tcp"
    lb_port           = 2222
    lb_protocol       = "tcp"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_acm_certificate.farhan.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 14
    target              = "HTTP:8080/"
    interval            = 15
  }

  tags = {
    Name = "concourse-master"
  }
}

resource "aws_route53_record" "external" {
  zone_id = "${aws_route53_zone.farhan.zone_id}"
  name    = "concourse.farhan.specialpotato.net"
  type    = "A"
  alias {
    name                   = "${aws_elb.concourse-master.dns_name}"
    zone_id                = "${aws_elb.concourse-master.zone_id}"
    evaluate_target_health = true
  }
}