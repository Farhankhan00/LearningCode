resource "aws_route53_zone" "farhan" {
  name          = "farhan.tastycidr.net."
  comment       = "farhan.tastycidr.net Route53 Zone"
  force_destroy = false

  tags {
    Terraform = "True"
    Name      = "farhan.tastycidr.net"
  }
}

resource "aws_acm_certificate" "farhan" {
  domain_name       = "farhan.tastycidr.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  depends_on = ["aws_acm_certificate.farhan"]
  name    = "${aws_acm_certificate.farhan.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.farhan.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.farhan.zone_id}"
  records = ["${aws_acm_certificate.farhan.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "farhan" {
  certificate_arn         = "${aws_acm_certificate.farhan.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
