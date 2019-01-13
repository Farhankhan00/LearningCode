resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow all ssh traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    ## REVISIT
    cidr_blocks = ["104.158.158.8/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ssh"
  }
}
