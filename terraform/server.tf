data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

resource "aws_key_pair" "farhan" {
  key_name = "farhan"

  ## REVISIT
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDR5OofU6s5jMWkcdUKtti0fw6QaofD4bw0abgAleqZ9XujDwhqM3S6B19QvekNx2OhF7XrCNgYoUYcA2iOFx01NGt5pWTQot4SokTeXgffl+GN3gD8hdsU9ObDlKLzppSCyvLb/somMa3fbJ+jlECduVYEb2uVbhpS0PODjrcoPPKIGnPFEz++/9ZF5/TOM+rB9Y1c8sn0uPSV+zJVQ7pYaP7l5FF3vCGiNpXgwkVE7J20QaWgS44w5RQfxw/f4nGJDpcfIEersweojCP2XOQsxvEghqZql1o051KL22FvBJbad3022dLCAa1Gc329vSU9PHgPseAtLvb+eU2f7fE/Xp1AxBKzsQUBsdbDp/euEGM2OQDCnvcmlE41uGBrkKxsBrjlnTNOku1/jKOWKdnOX9uBxFRlubr3XlXDjNYAqYwUpejmCqfiYOcOdA6udFuTOR0w7t+9vO7kqmwb0hmZr6hMJfNvjPH4ahZq4M5QQMfZJI7n3SHb4YPiTzOrVblZoqXhwyOVMJkcscUoJ+BuUcykl6DsmZYdj+D2bOTlsH0cxsyfY8XJI7jl15I+H6SnJ8cnOjMDqAMjM3rnAsIdo5LuhzqoRmZ+jugDUuaeJIhi07AsCrlZbk5UYYZGoHx/+VAADnqVKoLO96Bpe1t4erzV2fajG8CPpa7bEAVuzw== fkhan@Fkhan"
}

resource "aws_security_group" "webservers" {
  name        = "webservers"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    ## REVISIT
    security_groups = [
      "${aws_security_group.elb.id}",
    ]
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

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow all ssh traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    ## REVISIT
    cidr_blocks = ["104.158.158.24/32"]
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

resource "aws_launch_configuration" "webserver" {
  name_prefix   = "webserver_"
  image_id      = "${data.aws_ami.webserver.id}"
  instance_type = "t2.micro"

  security_groups = [
    "${aws_security_group.webservers.id}",
    "${aws_security_group.ssh.id}",
  ]

  key_name = "${aws_key_pair.farhan.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "webserver" {
  most_recent = true

  filter {
    name   = "name"
    values = ["webserver_*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"] # Canonical
}

resource "aws_autoscaling_group" "webservers" {
  name             = "webservers"
  max_size         = 3
  min_size         = 1
  desired_capacity = 3

  vpc_zone_identifier = [
    "${aws_subnet.application-a.id}",
    "${aws_subnet.application-b.id}",
    "${aws_subnet.application-c.id}",
  ]

  target_group_arns = [
    "${aws_lb_target_group.webserver.arn}",
  ]

  force_delete         = true
  launch_configuration = "${aws_launch_configuration.webserver.name}"

  tag {
    key                 = "Name"
    value               = "webserver"
    propagate_at_launch = true
  }
}
