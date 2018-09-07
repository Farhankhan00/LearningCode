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

resource "aws_key_pair" "Farhan" {
  key_name = "deployer-Farhan"

  ## REVISIT
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbFmBUZofPhyF3KYxFmk2rAaNzhgujgznQUMxW5wViKu3yxzYbly6jV/2akUW44uZ9oeSh1jP7y7/mErhhkboeEkF1OEtfq9gQcWx8RUc/OqbMLSU9X7cVrqykl8W9FbT3dzvk0m0JCmyeOTx1rpN48fsvMWg0I6fJ11q9ZvwoIlCPIpJVzYRDJoxNUbwX80VmlkluY04fdqDz3nJgnzf3Gcz60FJHEpUOJn1pQxKfiDy5lqUMRZ8/+nQe1VBwUkEAtfps5m9qdybvbbW2BAaxX/rqZNS6rCGV1h+wTgbE5X1SUAZVh57J5lAwczy/gFXhZW/hlxQkJkOuLNjbOMLH12dt4rNcrvF+haghJcRgwkbC14JohPJQUw7vIL+dDQ8Ph8+GRdDQngviY0V9OHXlZl7L3MJ75vUdWFHS49CaD+NklYcAJF86sRjJH5t0vzCmYUCiEPKweo7i/s9xUzItwReVr/6fnNcIVXb+3sEdGX6LhR94tiyWz5yfBYzvK4JNo0aZ2t/BXtgyvFShjnBdNo6S3DvUPYqy66RWPcmIsyB1CzcxV7C4coiqdGwePI3Jq4eO2i2G1WsMoKq8xMm6UOjLQ+VL1roNsAw00SASRIJTz4NEBTmg+Kdxf1Ja9YPPpfWlz/+cEuxLOsVFyw5Y1h/v8HWLtBBiYQdlygoucw=="
}

resource "aws_security_group" "webservers" {
  name        = "webservers"
  description = "Allow all inbound traffic"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    ## REVISIT
    cidr_blocks = ["104.158.158.24/32"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    self      = true

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
    Name = "allow_ssh"
  }
}

resource "aws_launch_configuration" "webserver" {
  name_prefix   = "webserver_"
  image_id      = "${data.aws_ami.webserver.id}"
  instance_type = "t2.micro"

  security_groups = [
    "${aws_security_group.webservers.id}",
  ]

  key_name = "${aws_key_pair.Farhan.key_name}"

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
  max_size         = 2
  min_size         = 1
  desired_capacity = 2

  availability_zones = [
    "us-east-1b",
    "us-east-1c",
  ]

  load_balancers = [
    "${aws_elb.webservers.name}",
  ]

  force_delete         = true
  launch_configuration = "${aws_launch_configuration.webserver.name}"

  tag {
    key                 = "Name"
    value               = "webserver"
    propagate_at_launch = true
  }
}

resource "aws_elb" "webservers" {
  name               = "webservers"
  availability_zones = ["us-east-1b", "us-east-1c"]

  security_groups = [
    "${aws_security_group.webservers.id}",
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 20
  }

  tags {
    Name = "webservers"
  }
}
