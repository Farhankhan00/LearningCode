#VPC - virtual private cloud (Isolated network in AWS)
resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"

  tags {
    Name = "main"
  }
}

#its the users vpc link to the public internet!
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "main"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "main"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "frontend-a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.0.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true

  tags {
    Name = "frontend-a"
  }
}

resource "aws_subnet" "frontend-b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.1.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = true

  tags {
    Name = "frontend-b"
  }
}

resource "aws_subnet" "frontend-c" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.2.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"
  map_public_ip_on_launch = true

  tags {
    Name = "frontend-c"
  }
}

resource "aws_subnet" "application-a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.3.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true

  tags {
    Name = "application-a"
  }
}

resource "aws_subnet" "application-b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.4.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = true

  tags {
    Name = "application-b"
  }
}

resource "aws_subnet" "application-c" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.5.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"
  map_public_ip_on_launch = true

  tags {
    Name = "application-c"
  }
}

resource "aws_subnet" "database-a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.6.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true

  tags {
    Name = "database-a"
  }
}

resource "aws_subnet" "database-b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.7.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = true

  tags {
    Name = "database-b"
  }
}

resource "aws_subnet" "database-c" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "172.16.8.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"
  map_public_ip_on_launch = true

  tags {
    Name = "database-c"
  }
}

resource "aws_route_table_association" "frontend-a" {
  subnet_id      = "${aws_subnet.frontend-a.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "frontend-b" {
  subnet_id      = "${aws_subnet.frontend-b.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "frontend-c" {
  subnet_id      = "${aws_subnet.frontend-c.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "application-a" {
  subnet_id      = "${aws_subnet.application-a.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "application-b" {
  subnet_id      = "${aws_subnet.application-b.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "application-c" {
  subnet_id      = "${aws_subnet.application-c.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "database-a" {
  subnet_id      = "${aws_subnet.database-a.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "database-b" {
  subnet_id      = "${aws_subnet.database-b.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "database-c" {
  subnet_id      = "${aws_subnet.database-c.id}"
  route_table_id = "${aws_route_table.r.id}"
}
