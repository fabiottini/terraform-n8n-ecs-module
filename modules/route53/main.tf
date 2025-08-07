data "aws_route53_zone" "main" {
  zone_id = var.zone_id

  provider = aws.route53
}

resource "aws_route53_record" "cname" {
  for_each = toset(var.cname_domain_name)
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = each.value
  type     = "CNAME"
  ttl      = 300
  records  = [var.cname_value]

  provider = aws.route53
}