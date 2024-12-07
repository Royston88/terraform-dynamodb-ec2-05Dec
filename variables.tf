variable "tablename" {
  type    = string
  default = "royston-bookinventory"
}


variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "ec2name" {
  type    = string
  default = "royston-dynamodb-reader"
}

variable "vpc_id" {
  type    = string
  default = "vpc-04cdd2b9251b86e69"
}

variable "name" {
  type    = string
  default = "royston"
}

variable "keypair" {
  type    = string
  default = "royston-ec2-keypair"
}