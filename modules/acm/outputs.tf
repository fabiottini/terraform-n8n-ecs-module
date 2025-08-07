output "certificate_arns" {
  description = "The ARNs of the validated ACM certificates for all domains."
  value = {
    for domain, cert in aws_acm_certificate_validation.cert_validations :
    domain => cert.certificate_arn
  }
}

output "acm_validation_options" {
  value = {
    for domain, cert in aws_acm_certificate.certificates :
    domain => cert.domain_validation_options
  }
}