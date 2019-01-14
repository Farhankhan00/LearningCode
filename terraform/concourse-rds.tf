resource "aws_ssm_parameter" "concourse-password" {
  name      = "concourse-password"
  type      = "SecureString"
  value     = "${random_string.password.result}"
  overwrite = true
}

resource "random_string" "password" {
  length  = 25
  special = false
}

resource "aws_db_instance" "concourse" {
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "10.4"
  instance_class         = "db.t2.micro"
  identifier             = "concourse"
  name                   = "concourse"
  username               = "concourse"
  password               = "${aws_ssm_parameter.concourse-password.value}"
  parameter_group_name   = "${aws_db_parameter_group.concourse.name}"
  db_subnet_group_name   = "${aws_db_subnet_group.concourse.name}"
  vpc_security_group_ids = ["${aws_security_group.concourse-rds.id}"]
  publicly_accessible    = true
  skip_final_snapshot    = true
}

resource "aws_db_parameter_group" "concourse" {
  name   = "rds-pg"
  family = "postgres10"
}

resource "aws_db_subnet_group" "concourse" {
  name = "concoursedb_subnet_group"

  subnet_ids = [
    "${aws_subnet.database-a.id}",
    "${aws_subnet.database-b.id}",
    "${aws_subnet.database-c.id}",
  ]

  tags {
    Name = "concoursedb_subnet_group"
  }
}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

resource "aws_security_group" "concourse-rds" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "concourse-rds"

  tags {
    Name = "concourse-rds"
  }

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    cidr_blocks = [
      "104.158.158.8/32",
    ]
  }

  ingress {
    from_port = 5432
    to_port   = 5432
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

resource "aws_route53_record" "rds" {
  zone_id = "${aws_route53_zone.farhan.zone_id}"
  name    = "rds.farhan.specialpotato.net"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.concourse.address}"]
}
