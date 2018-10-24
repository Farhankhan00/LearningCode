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

  ## USE YOUR NEW KEY
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbFmBUZofPhyF3KYxFmk2rAaNzhgujgznQUMxW5wViKu3yxzYbly6jV/2akUW44uZ9oeSh1jP7y7/mErhhkboeEkF1OEtfq9gQcWx8RUc/OqbMLSU9X7cVrqykl8W9FbT3dzvk0m0JCmyeOTx1rpN48fsvMWg0I6fJ11q9ZvwoIlCPIpJVzYRDJoxNUbwX80VmlkluY04fdqDz3nJgnzf3Gcz60FJHEpUOJn1pQxKfiDy5lqUMRZ8/+nQe1VBwUkEAtfps5m9qdybvbbW2BAaxX/rqZNS6rCGV1h+wTgbE5X1SUAZVh57J5lAwczy/gFXhZW/hlxQkJkOuLNjbOMLH12dt4rNcrvF+haghJcRgwkbC14JohPJQUw7vIL+dDQ8Ph8+GRdDQngviY0V9OHXlZl7L3MJ75vUdWFHS49CaD+NklYcAJF86sRjJH5t0vzCmYUCiEPKweo7i/s9xUzItwReVr/6fnNcIVXb+3sEdGX6LhR94tiyWz5yfBYzvK4JNo0aZ2t/BXtgyvFShjnBdNo6S3DvUPYqy66RWPcmIsyB1CzcxV7C4coiqdGwePI3Jq4eO2i2G1WsMoKq8xMm6UOjLQ+VL1roNsAw00SASRIJTz4NEBTmg+Kdxf1Ja9YPPpfWlz/+cEuxLOsVFyw5Y1h/v8HWLtBBiYQdlygoucw=="
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
