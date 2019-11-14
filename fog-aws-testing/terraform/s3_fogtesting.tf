# NOTE: Bucket name must have exact same name as the dns recored, like example.com or box.example.com
resource "aws_s3_bucket" "fogtesting" {
  bucket = "${var.project}.theworkmans.us"
  region = var.region
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
	"Sid":"PublicReadGetObject",
        "Effect":"Allow",
	  "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.project}.theworkmans.us/*"
      ]
    }
  ]
}
POLICY

}

# NOTE: the higher-level zone_id is the owned zone_id. The alias zone_ID is the s3 bucket's zone_id.
resource "aws_route53_record" "fogtesting-dns-record" {
  zone_id = "ZXXW1GUP5E4A0"
  name    = "${var.project}.theworkmans.us"
  type    = "A"
  alias {
    name                   = aws_s3_bucket.fogtesting.website_domain
    zone_id                = aws_s3_bucket.fogtesting.hosted_zone_id
    evaluate_target_health = false
  }
}

