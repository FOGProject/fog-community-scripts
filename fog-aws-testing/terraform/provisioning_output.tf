resource "aws_s3_bucket" "provisioning" {
  bucket = "provisioning-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  acl = "private"
}

resource "aws_iam_instance_profile" "provisioning" {
  name = "${var.project}-provisioning"
  role = aws_iam_role.provisioning.name
}

resource "aws_iam_role_policy" "provisioning" {
  name = "${var.project}-provisioning"
  role = aws_iam_role.provisioning.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "output",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${aws_s3_bucket.provisioning.arn}",
                "${aws_s3_bucket.provisioning.arn}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "provisioning" {
  name = "${var.project}-provisioning"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}