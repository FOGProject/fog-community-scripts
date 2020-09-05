
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
    cidr_blocks = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "13.114.40.48/32",
    "52.192.72.89/32",
    "52.69.186.44/32",
    "15.164.81.167/32",
    "52.78.231.108/32",
    "13.234.176.102/32",
    "13.234.210.38/32",
    "13.229.188.59/32",
    "13.250.177.223/32",
    "52.74.223.119/32",
    "13.236.229.21/32",
    "13.237.44.5/32",
    "52.64.108.95/32",
    "18.228.52.138/32",
    "18.228.67.229/32",
    "18.231.5.6/32",
    "18.181.13.223/32",
    "54.238.117.237/32",
    "54.168.17.15/32",
    "3.34.26.58/32",
    "13.125.114.27/32",
    "3.7.2.84/32",
    "3.6.106.81/32",
    "18.140.96.234/32",
    "18.141.90.153/32",
    "18.138.202.180/32",
    "52.63.152.235/32",
    "3.105.147.174/32",
    "3.106.158.203/32",
    "54.233.131.104/32",
    "18.231.104.233/32",
    "18.228.167.86/32"
  ]
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



