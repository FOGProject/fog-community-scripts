# Backends cannot use interpolation.
terraform {
  backend "s3" {
    bucket = "us-east-1-remote-state.theworkmans.us"
    key    = "fogtesting.rs"
    region = "us-east-1"
  }
}

provider "aws" {
    region = "${var.region}"
}

variable "region" {
    type = "string"
    default = "us-east-1"
}

variable "project" {
    type = "string"
    default = "fogtesting"
}


variable "fog-community-scripts-repo" {
    type = "string"
    default = "https://github.com/FOGProject/fog-community-scripts.git"
}

variable "fog-project-repo" {
    type = "string"
    default = "https://github.com/FOGProject/fogproject.git"
}

# Usernames: https://alestic.com/2014/01/ec2-ssh-username/

variable "amis" {
  type    = "map"
  default = {
    "debian9" = "ami-0f9e7e8867f55fd8e" # https://wiki.debian.org/Cloud/AmazonEC2Image/Stretch
    "centos7" = "ami-4bf3d731" # https://wiki.centos.org/Cloud/AWS
    "rhel7" = "ami-c998b6b2" # https://access.redhat.com/articles/3135091
    "fedora29" = "ami-0ca275747dcc62c18" # https://alt.fedoraproject.org/cloud/
    "arch" = "ami-099a97582fc329220" # https://www.uplinklabs.net/projects/arch-linux-on-ec2/
    "ubuntu18_04" = "ami-07025b83b4379007e" # https://cloud-images.ubuntu.com/locator/ec2/
  }
}

variable "zone_id" {
    type = "string"
    default = "ZXXW1GUP5E4A0"
} 

variable "zone_name" {
    type = "string"
    default = "theworkmans.us"
} 


