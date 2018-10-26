resource "aws_route53_zone" "farhan" {
  name          = "farhan.specialpotato.net."
  comment       = "farhan.specialpotato.net Route53 Zone"
  force_destroy = false

  tags {
    Terraform = "True"
    Name      = "farhan.specialpotato.net"
  }
}

resource "aws_acm_certificate" "farhan" {
  domain_name       = "farhan.specialpotato.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  depends_on = ["aws_acm_certificate.farhan"]
  name       = "${aws_acm_certificate.farhan.domain_validation_options.0.resource_record_name}"
  type       = "${aws_acm_certificate.farhan.domain_validation_options.0.resource_record_type}"
  zone_id    = "${aws_route53_zone.farhan.zone_id}"
  records    = ["${aws_acm_certificate.farhan.domain_validation_options.0.resource_record_value}"]
  ttl        = 60
}

resource "aws_route53_record" "SPNS" {
  provider = "aws.SP"
  name       = "farhan.specialpotato.net"
  type       = "NS"
  zone_id    = "Z2YCIU8L9RIBGT"
  records    = [
    "${aws_route53_zone.farhan.name_servers.0}",
    "${aws_route53_zone.farhan.name_servers.1}",
    "${aws_route53_zone.farhan.name_servers.2}",
    "${aws_route53_zone.farhan.name_servers.3}"
  ]

  ttl        = 60
}

resource "aws_acm_certificate_validation" "farhan" {
  certificate_arn         = "${aws_acm_certificate.farhan.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

variable "SP_AK" {}
variable "SP_SK" {}
provider "aws" {
  alias      = "SP"
  access_key = "${var.SP_AK}"
  secret_key = "${var.SP_SK}"
  region     = "us-east-1"
}
