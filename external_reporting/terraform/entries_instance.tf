
resource "aws_instance" "instance" {
  ami = data.aws_ami.debian10.id
  instance_type = var.instance_type
  subnet_id = data.terraform_remote_state.base.outputs.public_subnet_c
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.profile.name
  key_name = "waynes"
  root_block_device {
    volume_type = "standard"
    volume_size = 20
    delete_on_termination = true
    encrypted = true
  }
  tags = {
    Name = var.entries_name
    Project = var.project
    keep-instance-running = "true"
    Snapshot = "true"
  }
  lifecycle {
    ignore_changes = [
        ami, user_data
    ]
  }
  user_data = <<END_OF_USERDATA
#!/bin/bash
apt-get update
apt-get -y dist-upgrade
apt-get -y install git
git clone https://github.com/wayneworkman/fog-community-scripts.git
cd fog-community-scripts/external_reporting/external_reporting
# install server software.
bash setup.sh
# Replace s3 arn in settings file.
sed -i 's/S3_BUCKET_NAME_HERE/${aws_s3_bucket.results_bucket.id}/' /opt/external_reporting/settings.json
# Setup HTTPS using certbot silently.
apt-get -y install certbot python-certbot-apache
certbot --no-eff-email --redirect --agree-tos -w /var/www/html -d ${var.entries_name}.${data.terraform_remote_state.base.outputs.zone_name} -m ${var.letsencrypt_email}
# Cleanup stuff we don't need anymore.
apt-get -y autoclean
apt-get -y autoremove
# Schedule a reboot in 10 seconds after this script as exited.
(sleep 10 && sudo reboot)&
END_OF_USERDATA
}


resource "aws_eip" "eip" {
  vpc = true
  instance = aws_instance.instance.id
  associate_with_private_ip = aws_instance.instance.private_ip
  tags = {
    Name = var.entries_name
    Project = var.project
  }
}


resource "aws_security_group" "sg" {
  name = var.entries_name
  description = var.entries_name
  vpc_id = data.terraform_remote_state.base.outputs.vpc_id
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${lookup(jsondecode(data.http.public_ip.body), "ip")}/32"]
  }
  egress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = [data.terraform_remote_state.base.outputs.vpc_cidr]
  }
  egress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = [data.terraform_remote_state.base.outputs.vpc_cidr]
  }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["169.254.169.123/32"]
  }
  tags = {
    Name = var.entries_name
    Project = var.project
  }
}


resource "aws_route53_record" "entries_record" {
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "${var.entries_name}.${data.terraform_remote_state.base.outputs.zone_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}


resource "aws_iam_instance_profile" "profile" {
  name = var.entries_name
  role = aws_iam_role.role.name
}


resource "aws_iam_role_policy" "policy" {
  name = var.entries_name
  role = aws_iam_role.role.id
  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Sid":"a",
            "Effect":"Allow",
            "Action":[
                "s3:Get*",
                "s3:PutAnalyticsConfiguration",
                "s3:DeleteAccessPoint",
                "s3:ReplicateObject",
                "s3:DeleteBucketWebsite",
                "s3:PutLifecycleConfiguration",
                "s3:DeleteObject",
                "s3:PutReplicationConfiguration",
                "s3:PutObjectLegalHold",
                "s3:PutBucketCORS",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutBucketNotification",
                "s3:DescribeJob",
                "s3:PutBucketLogging",
                "s3:PutBucketObjectLockConfiguration",
                "s3:CreateAccessPoint",
                "s3:PutAccelerateConfiguration",
                "s3:DeleteObjectVersion",
                "s3:ListBucketVersions",
                "s3:RestoreObject",
                "s3:ListBucket",
                "s3:PutEncryptionConfiguration",
                "s3:AbortMultipartUpload",
                "s3:UpdateJobPriority",
                "s3:DeleteBucket",
                "s3:PutBucketVersioning",
                "s3:ListBucketMultipartUploads",
                "s3:PutMetricsConfiguration",
                "s3:UpdateJobStatus",
                "s3:PutInventoryConfiguration",
                "s3:PutBucketWebsite",
                "s3:PutBucketRequestPayment",
                "s3:PutObjectRetention",
                "s3:ReplicateDelete"
            ],
            "Resource":[
                "${aws_s3_bucket.results_bucket.arn}",
                "${aws_s3_bucket.results_bucket.arn}/*"
            ],
            "Condition":{
                "IpAddress":{
                    "aws:SourceIp":"${aws_eip.eip.public_ip}/32"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role" "role" {
  name = var.entries_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}



