data "aws_ami" "base_ami" {
  most_recent        = true
  name_regex         = "tio_base_centos7-*"
  owners             = ["702267635140"]
}