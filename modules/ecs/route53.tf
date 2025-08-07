module "route53_master" {
  source            = "../route53"
  zone_id           = var.zone_id
  cname_value       = aws_lb.this.dns_name
  cname_domain_name = [var.domain_master] #, var.domain_webhook]
  region            = var.aws_region
  common_tags       = var.common_tags
  project_name      = var.project_name

  providers = {
    aws.route53 = aws.route53
  }
}

module "route53_webhook" {
  source            = "../route53"
  zone_id           = var.zone_id
  cname_value       = aws_lb.webhook.dns_name
  cname_domain_name = [var.domain_webhook]
  region            = var.aws_region
  common_tags       = var.common_tags
  project_name      = var.project_name

  providers = {
    aws.route53 = aws.route53
  }
}
