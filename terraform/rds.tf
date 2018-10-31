resource "aws_db_subnet_group" "default" {
  name = "ghostdb_subnet_group"

  subnet_ids = [
    "${aws_subnet.database-a.id}",
    "${aws_subnet.database-b.id}",
    "${aws_subnet.database-c.id}",
  ]

  tags {
    Name = "ghostdb_subnet_group"
  }
}

resource "aws_db_instance" "ghost" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "ghost"
  username             = "ghost"
  password             = "ghostpass"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"

  vpc_security_group_ids = [
    "${aws_security_group.ghost-rds.id}",
  ]
}

resource "aws_security_group" "ghost-rds" {
  vpc_id = "${aws_vpc.main.id}"
  name   = "ghost-rds"

  tags {
    Name = "ghost-rds"
  }

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.webservers.id}",
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
  records = ["${aws_db_instance.ghost.address}"]
}
