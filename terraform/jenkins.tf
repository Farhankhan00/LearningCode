data "aws_ami" "jenkins" {
  most_recent = true

  filter {
    name   = "name"
    values = ["jenkins_*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"] # Canonical
}