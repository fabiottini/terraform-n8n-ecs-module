output "zone_id" {
  description = "L'ID della zona Route53."
  value       = data.aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "I nameserver della zona Route53."
  value       = data.aws_route53_zone.main.name_servers
}

output "cname_domain_name" {
  description = "The CNAME domain name."
  value       = values(aws_route53_record.cname)[*].name
}

