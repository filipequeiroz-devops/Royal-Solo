resource "aws_s3_bucket" "royal_solo_bucket" {
  bucket = "royal-solo-bucket"

  tags = {
    Name        = "terraform-states-buckets"
    Environment = "prod"
  }
}

resource "aws_s3_bucket_public_access_block" "royal_solo_bucket" {
  bucket                  = aws_s3_bucket.royal_solo_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "royal_solo_bucket" {
  bucket = aws_s3_bucket.royal_solo_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.royal_solo_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "royal_solo_bucket" {
  bucket = aws_s3_bucket.royal_solo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "royal_solo_bucket" {
  bucket = aws_s3_bucket.royal_solo_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


resource "aws_s3_object" "arquivos_aplicacao" {
  for_each = fileset("${path.module}/../App", "**/*")
  bucket   = aws_s3_bucket.royal_solo_bucket.id
  key      = each.value
  source   = "${path.module}/../App/${each.value}"

  # Checa as mudanças no conteúdo do arquivo para atualizar o objeto no S3, em vez de apenas checar o timestamp
  etag = filemd5("${path.module}/../App/${each.value}")

  content_type = lookup(
    {
      "html" = "text/html",
      "css"  = "text/css",
      "js"   = "application/javascript",
      "png"  = "image/png",
      "jpg"  = "image/jpeg",
      "jpeg" = "image/jpeg",
      "svg"  = "image/svg+xml",
      "json" = "application/json"
    },
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "binary/octet-stream"
  )
}