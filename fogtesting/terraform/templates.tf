data "template_file" "ssh-config" {
  template = "${file("ssh-config.tpl")}"
}


data "template_file" "aws-config" {
  template = "${file("aws-config.tpl")}"
  vars {
    region = "${var.region}"
  }
}

