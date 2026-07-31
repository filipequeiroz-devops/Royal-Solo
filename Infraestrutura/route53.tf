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

# 1. Criação do Log Group do CloudWatch (Obrigatório ser em us-east-1)
resource "aws_cloudwatch_log_group" "route53_query_logs" {
  provider          = aws.us_east_1 # Assegure que o provider está apontado para us-east-1
  name              = "/aws/route53/${data.aws_route53_zone.meu_dominio.name}"
  retention_in_days = 30 # Tempo de retenção dos logs para controlar custos
}

# 2. Permissão para o Route 53 publicar logs no CloudWatch
data "aws_iam_policy_document" "route53_query_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:us-east-1:*:log-group:/aws/route53/*"]

    principals {
      type        = "Service"
      identifiers = ["route53.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
  provider        = aws.us_east_1
  policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
  policy_name     = "route53-query-logging-policy"
}

# 3. Ativação do Query Logging na sua Hosted Zone
resource "aws_route53_query_log" "main" {
  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
  zone_id                  = data.aws_route53_zone.meu_dominio.zone_id
}