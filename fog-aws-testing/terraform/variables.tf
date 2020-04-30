# Backends cannot use interpolation.
terraform {
  backend "s3" {
    bucket = "us-east-1-remote-state.theworkmans.us"
    key    = "fogtesting.rs"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "fogtesting"
}

variable "fog-community-scripts-repo" {
  type    = string
#  default = "https://github.com/FOGProject/fog-community-scripts.git"
  default = "https://github.com/wayneworkman/fog-community-scripts.git" # For my testing.
}

variable "fog-project-repo" {
  type    = string
  default = "https://github.com/FOGProject/fogproject.git"
}

variable "zone_id" {
  type    = string
  default = "ZXXW1GUP5E4A0"
}

variable "zone_name" {
  type    = string
  default = "theworkmans.us"
}

# Manual lookup of AMIs from official provider websites.
# debian9 https://wiki.debian.org/Cloud/AmazonEC2Image/Stretch
# debian10 https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
# centos https://wiki.centos.org/Cloud/AWS
# rhel https://access.redhat.com/articles/3135121
# fedora https://alt.fedoraproject.org/cloud/
# arch https://www.uplinklabs.net/projects/arch-linux-on-ec2/
# ubuntu https://cloud-images.ubuntu.com/locator/ec2/

# Usernames: https://alestic.com/2014/01/ec2-ssh-username/

data "aws_ami" "debian9" {
  most_recent = true
  owners      = ["379101102735"]
  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-*"]
  }
}

data "aws_ami" "debian10" {
  most_recent = true
  owners      = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }
}

data "aws_ami" "centos7" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS 1801_01-*-ami-*"]
  }
}

data "aws_ami" "rhel7" {
  most_recent = true
  owners      = ["309956199498"]
  filter {
    name   = "name"
    values = ["RHEL-7.*_HVM_GA-*-x86_64-2-Hourly2-GP2"]
  }
}

data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["309956199498"]
  filter {
    name   = "name"
    values = ["309956199498/RHEL-8.*_HVM-*-x86_64-0-Hourly*-GP2"]
  }
}

data "aws_ami" "fedora32" {
  most_recent = true
  owners      = ["125523088429"]
  filter {
    name   = "name"
    values = ["Fedora-Cloud-Base-32-*.x86_64-hvm-us-east-1-standard-*"]
  }
}


#data "aws_ami" "arch" {
#  most_recent = true
#  owners      = ["093273469852"]
#  filter {
#    name   = "name"
#    values = ["arch-linux-lts-hvm-*.x86_64-ebs"]
#  }
#}

data "aws_ami" "ubuntu18" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

