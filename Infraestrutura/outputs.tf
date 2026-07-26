output "website_url" {
  value = aws_s3_bucket.royal_solo_bucket.website_endpoint
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.royal_solo_distribution.domain_name
}