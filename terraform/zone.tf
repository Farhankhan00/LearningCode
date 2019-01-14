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
  subject_alternative_names = [
    "*.farhan.specialpotato.net"
  ]
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
  name     = "farhan.specialpotato.net"
  type     = "NS"
  zone_id  = "Z2YCIU8L9RIBGT"

  records = [
    "${aws_route53_zone.farhan.name_servers.0}",
    "${aws_route53_zone.farhan.name_servers.1}",
    "${aws_route53_zone.farhan.name_servers.2}",
    "${aws_route53_zone.farhan.name_servers.3}",
  ]

  ttl = 60
}

resource "aws_acm_certificate_validation" "farhan" {
  certificate_arn         = "${aws_acm_certificate.farhan.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

data "aws_ssm_parameter" "sp-ak" {
  name = "specialpotato-r53-access-key"
}

data "aws_ssm_parameter" "sp-secret" {
  name = "specialpotato-r53-secret"
}

provider "aws" {
  alias      = "SP"
  access_key = "${data.aws_ssm_parameter.sp-ak.value}"
  secret_key = "${data.aws_ssm_parameter.sp-secret.value}"
  region     = "us-east-1"
}
