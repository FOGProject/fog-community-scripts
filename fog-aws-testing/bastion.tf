

resource "aws_instance" "bastion" {
  ami           = "${var.amis["debian9"]}"
  instance_type = "t2.nano"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg-ssh.id}"]
  associate_public_ip_address = true
  key_name = "${aws_key_pair.ssh-key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"

  connection {
    type     = "ssh"
    user     = "admin"
    private_key = "${file("/root/.ssh/fogtesting_private")}"
  }

  provisioner "file" {
    source      = "/root/.ssh/fogtesting_private"
    destination = "/home/admin/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install awscli python-pip git",
      "sudo pip install boto3",
      "sudo apt-get -y dist-upgrade",
      "chmod 400 /home/admin/.ssh/id_rsa",
      "echo '${var.waynes-key}' >> /home/admin/.ssh/authorized_keys",
      "echo '${data.template_file.ssh-config.rendered}' > /home/admin/.ssh/config",
      "mkdir -p ~/.aws",
      "echo '${data.template_file.aws-config.rendered}' > ~/.aws/config",
      "chmod 600 ~/.aws/config",
      "sudo sed -i.bak 's/set mouse=a/\"set mouse=a/' /usr/share/vim/vim80/defaults.vim",
      "git clone https://github.com/wayneworkman/fog-community-scripts.git /home/admin/fog-community-scripts",
    ]
  }

  tags {
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
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
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


