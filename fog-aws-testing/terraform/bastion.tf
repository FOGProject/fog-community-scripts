resource "aws_instance" "bastion" {
  count                       = var.make_instances
  ami                         = data.aws_ami.debian10.id
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.sg-ssh.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  iam_instance_profile        = aws_iam_instance_profile.profile[0].name

  root_block_device {
    volume_type           = "standard"
    volume_size           = 8
    delete_on_termination = true
  }

  connection {
    host        = aws_instance.bastion[0].public_ip
    type        = "ssh"
    user        = "admin"
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = var.private_key_path
    destination = "/home/admin/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    #on_failure = continue
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install awscli groff python-pip git vim",
      "sudo pip install boto3",
      "sudo apt-get -y dist-upgrade",
      "chmod 400 /home/admin/.ssh/id_rsa",
      "echo '${data.template_file.ssh-config.rendered}' > /home/admin/.ssh/config",
      "mkdir -p ~/.aws",
      "echo '${data.template_file.aws-config.rendered}' > ~/.aws/config",
      "chmod 600 ~/.aws/config",
      "sudo sed -i.bak 's/set mouse=a/\"set mouse=a/' /usr/share/vim/vim81/defaults.vim",
      "git clone ${var.fog-community-scripts-repo} /home/admin/fog-community-scripts",
      "(crontab -l; echo '0 12 * * * /home/admin/fog-community-scripts/fog-aws-testing/scripts/test_all.py') | crontab - >/dev/null 2>&1",
      "(sleep 10 && reboot)&",
    ]
  }

  tags = {
    Name    = "${var.project}-bastion"
    Project = var.project
  }
}

resource "aws_iam_instance_profile" "profile" {
  count = var.make_instances
  name = "bastion_profile"
  role = aws_iam_role.role[0].name
}

resource "aws_iam_role_policy" "policy" {
  count = var.make_instances
  name = "bastion_policy"
  role = aws_iam_role.role[0].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "s3Perms",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:ListBucket",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "${aws_s3_bucket.fogtesting.arn}",
                "${aws_s3_bucket.fogtesting.arn}/*"
            ],
            "Condition": {"IpAddress": {"aws:SourceIp": "${aws_instance.bastion[0].public_ip}/32"}}
        },
        {
            "Sid": "ec2ReadPerms",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeSnapshots",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeSnapshotAttribute",
                "ec2:DescribeVolumeAttribute",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeVolumesModifications",
                "ec2:DescribeTags"
            ],
            "Resource": "*",
            "Condition": {"IpAddress": {"aws:SourceIp": "${aws_instance.bastion[0].public_ip}/32"}}
        },
        {
            "Sid": "ec2SpecialPerms",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifyInstanceAttribute",
                "ec2:CreateVolume",
                "ec2:DeleteVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {"IpAddress": {"aws:SourceIp": "${aws_instance.bastion[0].public_ip}/32"}}
        },
        {
            "Sid": "ec2ModifyPerms",
            "Effect": "Allow",
            "Action": [
                "ec2:DetachVolume",
                "ec2:AttachVolume",
                "ec2:StartInstances",
                "ec2:CreateTags",
                "ec2:RunInstances",
                "ec2:StopInstances"
            ],
            "Resource": [
                "${aws_instance.centos7[0].arn}",
                "${aws_instance.centos8[0].arn}",
                "${aws_instance.rhel7[0].arn}",
                "${aws_instance.rhel8[0].arn}",
                "${aws_instance.fedora32[0].arn}",
                "${aws_instance.fedora33[0].arn}",
                "${aws_instance.debian10[0].arn}",
                "${aws_instance.ubuntu16_04[0].arn}",
                "${aws_instance.ubuntu18_04[0].arn}",
                "${aws_instance.ubuntu20_04[0].arn}",
                "arn:aws:ec2:*::snapshot/*",
                "arn:aws:ec2:*:*:volume/*"
            ],
            "Condition": {"IpAddress": {"aws:SourceIp": "${aws_instance.bastion[0].public_ip}/32"}}
        }
    ]
}
EOF

}

resource "aws_iam_role" "role" {
  count = var.make_instances
  name = "bastion_role"
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
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_route53_record" "bastion-dns-record" {
  count   = var.make_instances
  zone_id = var.zone_id
  name    = "fogbastion.${var.zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.bastion[0].public_dns]
}

resource "aws_security_group" "allow-bastion" {
  count       = var.make_instances
  name        = "from-bastion"
  description = "Allow all communications from bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_instance.bastion[0].private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-allow-bastion"
    Project = var.project
  }
}

