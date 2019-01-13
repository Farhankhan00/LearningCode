resource "aws_security_group" "concourse-master" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "concourse-master"

  tags {
    Name = "concourse-master"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}