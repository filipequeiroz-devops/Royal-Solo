# -------------------------------------------------------------------------
# 0. CLOUDFRONT FUNCTION (Reescrita de URL)
# Reescreve rotas sem extensão (ex: /contato) para buscar arquivos .html (ex: /contato.html)
# -------------------------------------------------------------------------
resource "aws_cloudfront_function" "rewrite_uri" {
  name    = "rewrite-html-extension"
  runtime = "cloudfront-js-2.0"
  comment = "Reescreve URLs sem extensao para .html no S3"
  publish = true
  code    = <<EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Se a URI nao contem ponto (nao e um arquivo como .png/.css) e nao termina em /
    if (!uri.includes('.') && !uri.endsWith('/')) {
        request.uri += '.html';
    } 
    // Se a URI termina com barra (ex: /contato/), remove a barra e adiciona .html
    else if (uri.endsWith('/') && uri !== '/') {
        request.uri = uri.slice(0, -1) + '.html';
    }

    return request;
}
EOF


}

# -------------------------------------------------------------------------
# 1. ORIGIN ACCESS CONTROL (OAC)
# Este bloco cria a identidade de segurança do CloudFront. 
# Ele substitui o antigo OAI e é a forma moderna de acessar o S3 de forma privada.
# -------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "royal_solo_oac" {
  name                              = "OAC-royal_solo"
  description                       = "Controle de acesso do CloudFront para o bucket S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -------------------------------------------------------------------------
# 2. DISTRIBUIÇÃO CLOUDFRONT
# -------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "royal_solo_distribution" {

  origin {
    # Aponta para a URL regional do bucket S3
    domain_name = aws_s3_bucket.royal_solo_bucket.bucket_regional_domain_name
    origin_id   = "S3-royal-solo-bucket"

    # Vinculando o OAC criado
    origin_access_control_id = aws_cloudfront_origin_access_control.royal_solo_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for Daily Personal Performance website"
  default_root_object = "index.html"

  aliases = ["royal-solo.filipe-deabreu.com"]

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html" # S3 privado com OAC costuma retornar 403 em vez de 404
    error_caching_min_ttl = 10
  }

  default_cache_behavior {
    target_origin_id = "S3-royal-solo-bucket"

    # Força qualquer requisição HTTP a ser redirecionada para HTTPS
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      # Sem cache por ser site estático, e também para evitar que o CloudFront crie uma cache para cada combinação de cookies (o que pode explodir o custo)
      cookies {
        forward = "none"
      }


    }

    # ---------------------------------------------------------------------
    # Associação da CloudFront Function para remover a necessidade do .html na URL
    # ---------------------------------------------------------------------
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_uri.arn
    }
  }

  # Limita os servidores para baratear o custo (EUA, Canadá e Europa)
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.royal_solo_cert_validation_wait.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021" # Mesma política de segurança mostrada no seu print
  }
}