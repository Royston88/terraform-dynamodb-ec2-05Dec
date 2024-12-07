terraform {
  backend "s3" {
    bucket = "sctp-ce8-tfstate"
    key    = "royston-dynamodb-ec2-tfstate"
    region = "ap-southeast-1"
  }
}
