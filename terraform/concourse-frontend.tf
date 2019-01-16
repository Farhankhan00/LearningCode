resource "aws_security_group" "concourse-master" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "concourse-master"

  tags {
    Name = "concourse-master"
  }
}

resource "aws_security_group_rule" "master-lb-to-master-2222" {
  type = "ingress"
  from_port = 2222
  to_port = 2222
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.concourse-master-lb.id}"
  security_group_id = "${aws_security_group.concourse-master.id}"
}

resource "aws_security_group_rule" "master-lb-to-master-8080" {
  type = "ingress"
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.concourse-master-lb.id}"
  security_group_id = "${aws_security_group.concourse-master.id}"
}

resource "aws_security_group_rule" "master-to-master-ephemeral" {
  type = "ingress"
  from_port = 1024
  to_port = 65535
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.concourse-master.id}"
  security_group_id = "${aws_security_group.concourse-master.id}"
}

resource "aws_security_group_rule" "master-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.concourse-master.id}"
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

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [
      "${aws_security_group.concourse-worker.id}"
    ]
  }

  ingress {
    from_port = 2222
    to_port   = 2222
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.concourse-worker.id}",
    ]
  }

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
    instance_protocol = "tcp"/github-deploy-key-priv
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

resource "aws_elb" "concourse-master-internal" {
  name = "concourse-master-internal"
  internal = true

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
    Name = "concourse-master-internal"
  }
}

resource "aws_route53_record" "internal" {
  zone_id = "${aws_route53_zone.farhan.zone_id}"
  name    = "concourse-internal.farhan.specialpotato.net"
  type    = "A"
  alias {
    name                   = "${aws_elb.concourse-master-internal.dns_name}"
    zone_id                = "${aws_elb.concourse-master-internal.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_iam_role" "concourse-master" {
  name = "concourse-master"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "allowec2tobecomeconcoursemaster"
    }
  ]
}
EOF

  tags = {
      Name = "concourse-master"
  }
}

resource "aws_iam_instance_profile" "concourse-master" {
  name = "concourse-master"
  role = "${aws_iam_role.concourse-master.name}"
}
resource "aws_iam_role_policy_attachment" "concourse-master" {
  role       = "${aws_iam_role.concourse-master.name}"
  policy_arn = "${aws_iam_policy.concourse-master.arn}"
}

resource "aws_iam_policy" "concourse-master" {
  name        = "concourse-master"
  path        = "/"
  description = "concourse master nodes"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:Describe*"
        ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "template_file" "master-user-data" {
  template = "${file("concourse-master-userdata.tpl")}"
  vars = {
    GIT_REPO = "git@github.com:Farhankhan00/LearningCode.git"
    GIT_BRANCH = "concourse_workers"
  }
}

data "aws_ami" "concourse-master" {
  most_recent = true

  filter {
    name   = "name"
    values = ["concourse_master_*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"] 
}

resource "aws_launch_configuration" "concourse-master" {
  name_prefix        = "concourse-master_"
  image_id      = "${data.aws_ami.concourse-master.id}"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.concourse-master.name}"
  user_data = "${data.template_file.master-user-data.rendered}"
  security_groups = [
    "${aws_security_group.concourse-master.id}",
    "${aws_security_group.ssh.id}"
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "concourse-master" {
  name                      = "concourse-master"
  max_size                  = 2
  min_size                  = 0
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.concourse-master.name}"
  vpc_zone_identifier       = [
    "${aws_subnet.frontend-a.id}",
    "${aws_subnet.frontend-b.id}",
    "${aws_subnet.frontend-c.id}",
  ]
  
  load_balancers = [
    "${aws_elb.concourse-master.name}",
    "${aws_elb.concourse-master-internal.name}"
  ]  

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      "max_size", "min_size"
    ]
  }

  tag {
    key                 = "Name"
    value               = "concourse-master"
    propagate_at_launch = true
  }
}
