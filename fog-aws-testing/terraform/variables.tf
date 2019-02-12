# Backends cannot use interpolation.
terraform {
  backend "s3" {
    bucket = "remote-state.theworkmans.us"
    key    = "fogtesting.rs"
    region = "us-east-2"
  }
}

provider "aws" {
    region = "${var.region}"
}

variable "region" {
    type = "string"
    default = "us-east-2"
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
    "debian9" = "ami-08e2234d40f32eb5c" # https://wiki.debian.org/Cloud/AmazonEC2Image/Stretch
    "centos7" = "ami-e1496384" # https://wiki.centos.org/Cloud/AWS
    "rhel7" = "ami-cfdafaaa" # https://access.redhat.com/articles/3135091
    "fedora29" = "ami-0f7e779f5a384f9fc" # https://alt.fedoraproject.org/cloud/
    "arch" = "ami-039027559d31b8c6b" # https://www.uplinklabs.net/projects/arch-linux-on-ec2/
    "ubuntu18_04" = "ami-02e1499f8253f416f" # https://cloud-images.ubuntu.com/locator/ec2/
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


