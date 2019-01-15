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

