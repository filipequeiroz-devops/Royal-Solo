resource "aws_route53_record" "royal_solo_cname" {
  zone_id = data.aws_route53_zone.meu_dominio.zone_id
  name    = "royal-solo"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.royal_solo_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.royal_solo_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
