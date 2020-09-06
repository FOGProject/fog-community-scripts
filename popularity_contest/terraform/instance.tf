
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
    Name = var.name
    Project = var.name
  }
  lifecycle {
    ignore_changes = [
        ami,
    ]
  }
}


resource "aws_eip" "eip" {
  vpc = true
  instance = aws_instance.instance.id
  associate_with_private_ip = aws_instance.instance.private_ip
  tags = {
    Name = var.name
    Project = var.name
  }
}

data "http" "github_meta" {
  # This is to get GitHub's git public cidr list for use with security group to restrict outbound ssh.
  url = "https://api.github.com/meta"
  request_headers = {
    Accept = "application/json"
  }
}



resource "aws_security_group" "sg" {
  name = var.name
  description = var.name
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
    cidr_blocks = [var.my_public_ip_cidr]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [var.my_public_ip_cidr]
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
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = lookup(jsondecode(data.http.github_meta.body), "git")
  }
  tags = {
    Name = var.name
    Project = var.name
  }
}


resource "aws_route53_record" "record" {
  zone_id = data.terraform_remote_state.base.outputs.zone_id
  name    = "${var.name}.${data.terraform_remote_state.base.outputs.zone_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}


resource "aws_iam_instance_profile" "profile" {
  name = var.name
  role = aws_iam_role.role.name
}


resource "aws_iam_role_policy" "policy" {
  name = var.name
  role = aws_iam_role.role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "a",
            "Effect": "Deny",
            "Action": [
                "*"
            ],
            "Resource": [
                "*"
            ],
            "Condition": {"IpAddress": {"aws:SourceIp": "${aws_eip.eip.public_ip}/32"}}
        }
    ]
}
EOF
}

resource "aws_iam_role" "role" {
  name = var.name
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



