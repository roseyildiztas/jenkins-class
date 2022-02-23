terraform {
  backend "s3" {
    bucket = "pushbutton-sema"
    key    = "us/app/pushbutton/vpc"
    region = "us-east-1"
  }
}