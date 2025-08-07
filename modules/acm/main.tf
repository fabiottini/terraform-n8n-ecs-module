resource "aws_acm_certificate" "certificates" {
  for_each          = toset(var.domains)
  domain_name       = each.key
  validation_method = "DNS"

  tags = merge(
    var.common_tags,
    {
      Name = "${each.key}"
    }
  )
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for domain, cert in aws_acm_certificate.certificates : domain => tolist(cert.domain_validation_options)[0]
  }

  zone_id = var.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 300

  provider = aws.route53

}

resource "aws_acm_certificate_validation" "cert_validations" {
  for_each = aws_acm_certificate.certificates

  certificate_arn         = each.value.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]

}
