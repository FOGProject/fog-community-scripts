

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.debian9.id}"
  instance_type = "t3.nano"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg-ssh.id}"]
  associate_public_ip_address = true
  key_name = "${aws_key_pair.ssh-key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"

  root_block_device {
    volume_type = "standard"
    volume_size = 8
    delete_on_termination = true
  }

  connection {
    host = "${aws_instance.bastion.public_ip}"
    type     = "ssh"
    user     = "admin"
    private_key = "${file("${var.private_key_path}")}"
  }

  provisioner "file" {
    source      = "${var.private_key_path}"
    destination = "/home/admin/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install awscli python-pip git s3cmd",
      "sudo pip install boto3",
      "sudo apt-get -y dist-upgrade",
      "chmod 400 /home/admin/.ssh/id_rsa",
      "echo '${var.waynes-key}' >> /home/admin/.ssh/authorized_keys",
      "echo '${data.template_file.ssh-config.rendered}' > /home/admin/.ssh/config",
      "mkdir -p ~/.aws",
      "echo '${data.template_file.aws-config.rendered}' > ~/.aws/config",
      "chmod 600 ~/.aws/config",
      "sudo sed -i.bak 's/set mouse=a/\"set mouse=a/' /usr/share/vim/vim80/defaults.vim",
      "git clone ${var.fog-community-scripts-repo} /home/admin/fog-community-scripts",
      "(crontab -l; echo '0 12 * * * /home/admin/fog-community-scripts/fog-aws-testing/scripts/test_all.py') | crontab - >/dev/null 2>&1",
      "(sleep 10 && reboot)&"
    ]
  }

  tags = {
    Name = "${var.project}-bastion"
    Project = "${var.project}"
  }
}

resource "aws_iam_instance_profile" "profile" {
  name = "bastion_profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role_policy" "policy" {
  name = "bastion_policy"
  role = "${aws_iam_role.role.id}"

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
            ]
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
            "Resource": "*"
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
            "Resource": "*"
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
                "${aws_instance.arch.arn}",
                "${aws_instance.centos7.arn}",
                "${aws_instance.rhel7.arn}",
                "${aws_instance.fedora30.arn}",
                "${aws_instance.debian10.arn}",
                "${aws_instance.ubuntu18_04.arn}",
                "arn:aws:ec2:*::snapshot/*",
                "arn:aws:ec2:*:*:volume/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "role" {
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
  zone_id = "${var.zone_id}"
  name    = "fogbastion.${var.zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.bastion.public_dns}"]
}



resource "aws_security_group" "allow-bastion" {
  name        = "from-bastion"
  description = "Allow all communications from bastion"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-allow-bastion"
    Project = "${var.project}"
  }
}

