provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}


resource "aws_acm_certificate" "results_cert" {
  domain_name = "${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}"
#  subject_alternative_names = ["stats.fogproject.org"]
  validation_method = "DNS"
  provider = aws.virginia
}


resource "aws_route53_record" "results_cert" {
  for_each = {
    for dvo in aws_acm_certificate.results_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.terraform_remote_state.base.outputs.zone_id
}

resource "aws_acm_certificate_validation" "results_cert" {
  depends_on = [aws_route53_record.results_cert]
  certificate_arn = aws_acm_certificate.results_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.results_cert : record.fqdn]
  provider = aws.virginia
}


# NOTE: Bucket name must have exact same name as the dns recored, like example.com or box.example.com
resource "aws_s3_bucket" "results_bucket" {
  bucket = "${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  lifecycle_rule {
    id      = "lifecycle"
    enabled = true
    tags = {
      "rule"      = "lifecycle"
      "autoclean" = "true"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 365
    }
  }
  tags = {
    Name = "${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}"
    Project = var.project
  }
  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Id":"PolicyForCloudFrontPrivateContent",
    "Statement":[
        {
            "Sid":"1",
            "Effect":"Allow",
            "Principal":{
                "AWS":"${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
            },
            "Action":"s3:GetObject",
            "Resource":"arn:aws:s3:::${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}/*"
        }
    ]
}
POLICY
}


# NOTE: the higher-level zone_id is the owned zone_id. The alias zone_ID is the s3 bucket's zone_id.
resource "aws_route53_record" "results_record" {
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name = "${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}"
  type = "A"
  alias {
    name = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [aws_acm_certificate_validation.results_cert]
  origin {
    domain_name = aws_s3_bucket.results_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

#  aliases = ["${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}","stats.fogproject.org"]
  aliases = ["${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 600
    max_ttl                = 900
  }

  price_class = "PriceClass_100"

  tags = {
    Name = "${var.results_name}.${data.terraform_remote_state.base.outputs.zone_name}"
    Project = var.project
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.results_cert.arn
    ssl_support_method = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


