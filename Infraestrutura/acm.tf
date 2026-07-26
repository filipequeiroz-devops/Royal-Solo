resource "aws_acm_certificate" "royal_solo_cert" {
  provider          = aws.us_east_1
  domain_name       = "royal-solo.filipe-deabreu.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

}

# Cria os registros CNAME no Route53 automaticamente para provar a posse
resource "aws_route53_record" "royal_solo_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.royal_solo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.meu_dominio.zone_id
}

# Este bloco diz para o Terraform aguardar a AWS confirmar a validação do DNS 
# antes de dar o deploy como "concluído".
resource "aws_acm_certificate_validation" "royal_solo_cert_validation_wait" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.royal_solo_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.royal_solo_cert_validation : record.fqdn]
}