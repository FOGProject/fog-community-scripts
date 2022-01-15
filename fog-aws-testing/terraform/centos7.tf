resource "aws_instance" "centos7" {
  count                       = var.make_instances
  ami                         = data.aws_ami.centos7.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.allow-bastion[0].id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
  iam_instance_profile        = aws_iam_instance_profile.provisioning.name
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    tags = {
      Name    = "${var.project}-centos7"
      Project = var.project
      OS      = "centos7"
    }
  }
  tags = {
    Name    = "${var.project}-centos7"
    Project = var.project
    OS      = "centos7"
  }
  lifecycle {
    ignore_changes = [
      associate_public_ip_address, ami, root_block_device[0].volume_type,
    ]
  }

  user_data = <<END_OF_USERDATA
#!/bin/bash
output_log_name="centos7_provision_output.log"
output_log_absolute_path="/root/$${output_log_name}"
yum -y update >> $${output_log_absolute_path} 2>&1

# This bit here ensures we have python3, pip3, and the aws-cli.
# This is so the outcome of instance provisioning can be monitored easily via s3.
yum -y install python3 >> $${output_log_absolute_path} 2>&1
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $${output_log_absolute_path} 2>&1
python3 get-pip.py >> $${output_log_absolute_path} 2>&1
pip3 install awscli >> $${output_log_absolute_path} 2>&1
aws s3 rm s3://${aws_s3_bucket.provisioning.id}/$${output_log_name} >> $${output_log_absolute_path} 2>&1

setenforce 0 >> $${output_log_absolute_path} 2>&1
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config >> $${output_log_absolute_path} 2>&1
echo '' | sudo tee --append /etc/ssh/sshd_config >> $${output_log_absolute_path} 2>&1
echo 'PermitRootLogin prohibit-password' | tee --append /etc/ssh/sshd_config >> $${output_log_absolute_path} 2>&1
mkdir -p /root/.ssh >> $${output_log_absolute_path} 2>&1
cp /home/centos/.ssh/authorized_keys /root/.ssh/authorized_keys >> $${output_log_absolute_path} 2>&1
sed -i '/SELINUX=enforcing/d' /etc/selinux/config >> $${output_log_absolute_path} 2>&1
# echo 'SELINUX=permissive' | tee --append /etc/selinux/config >> $${output_log_absolute_path} 2>&1
mkdir -p /root/git >> $${output_log_absolute_path} 2>&1
yum -y install git >> $${output_log_absolute_path} 2>&1
git clone ${var.fog-project-repo} /root/git/fogproject >> $${output_log_absolute_path} 2>&1
(sleep 15 && sudo reboot)& >> $${output_log_absolute_path} 2>&1
aws s3 cp $${output_log_absolute_path} s3://${aws_s3_bucket.provisioning.id}/$${output_log_name}
END_OF_USERDATA
}

resource "aws_route53_record" "centos7-dns-record" {
  count   = var.make_instances
  zone_id = aws_route53_zone.private-zone.zone_id
  name    = "centos7.fogtesting.cloud"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_instance.centos7[0].private_dns]
}

