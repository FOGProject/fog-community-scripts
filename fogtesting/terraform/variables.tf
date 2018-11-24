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

variable "amis" {
  type    = "map"
  default = {
    "debian9" = "ami-08e2234d40f32eb5c"
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


