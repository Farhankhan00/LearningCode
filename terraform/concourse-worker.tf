resource "aws_security_group" "concourse-worker" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "concourse-worker"

  tags {
    Name = "concourse-worker"
  }

  ingress {
    from_port = 7777
    to_port   = 7777
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.concourse-master.id}",
    ]
  }

  ingress {
    from_port = 7788
    to_port   = 7788
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.concourse-master.id}",
    ]
  }

  ingress {
    from_port = 7799
    to_port   = 7799
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.concourse-master.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "concourse-worker" {
  name = "concourse-worker"

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
      "Sid": "allowec2tobecomeconcourseworker"
    }
  ]
}
EOF

  tags = {
    Name = "concourse-worker"
  }
}

resource "aws_iam_instance_profile" "concourse-worker" {
  name = "concourse-worker"
  role = "${aws_iam_role.concourse-worker.name}"
}

resource "aws_iam_role_policy_attachment" "concourse-worker" {
  role       = "${aws_iam_role.concourse-worker.name}"
  policy_arn = "${aws_iam_policy.concourse-worker.arn}"
}

resource "aws_iam_policy" "concourse-worker" {
  name        = "concourse-worker"
  path        = "/"
  description = "concourse worker nodes"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
        ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "aws_ami" "concourse-worker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["concourse_worker_*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

data "template_file" "worker-user-data" {
  template = "${file("concourse-worker-userdata.tpl")}"

  vars = {
    GIT_REPO   = "git@github.com:Farhankhan00/LearningCode.git"
    GIT_BRANCH = "master"
    REGION     = "${data.aws_region.current.name}"
  }
}

resource "aws_launch_configuration" "concourse-worker" {
  name_prefix          = "concourse-worker_"
  image_id             = "${data.aws_ami.concourse-worker.id}"
  instance_type        = "t3.small"
  iam_instance_profile = "${aws_iam_instance_profile.concourse-worker.name}"
  user_data            = "${data.template_file.worker-user-data.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  security_groups = [
    "${aws_security_group.concourse-worker.id}",
    "${aws_security_group.ssh.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "concourse-worker" {
  name                 = "concourse-worker"
  max_size             = 2
  min_size             = 0
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.concourse-worker.name}"

  vpc_zone_identifier = [
    "${aws_subnet.frontend-a.id}",
    "${aws_subnet.frontend-b.id}",
    "${aws_subnet.frontend-c.id}",
  ]

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      "max_size",
      "min_size",
    ]
  }

  tag {
    key                 = "Name"
    value               = "concourse-worker"
    propagate_at_launch = true
  }
}
