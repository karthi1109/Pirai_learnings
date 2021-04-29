provider "aws" {
    region = "ap-southeast-1"
    version = "2.17.0"
    access_key = "accesskey"
    secret_key = "secretkey"
}

resource "aws_instance" "terra1" {
    ami = "ami-03ca998611da0fe12"
    instance_type = "t2.micro"
    tags = {
      "Name" = "terra1"
    }

}
  
  # insert the 10 required variables here
