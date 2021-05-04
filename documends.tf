provider "aws" {
    
    region = "ap-southeast-1"
    access_key = ""
    secret_key = ""
}

resource "aws_vpc" "terra_vpc" {
    cidr_block = "10.92.30.0/27"
    instance_tenancy = "default"

    
    tags = {
      "Name" = "terra_vpc"
    }
}
resource "aws_internet_gateway" "terra_ig"{
    vpc_id = "aws_vpc.terra_vpc.id"

    tags = {
      "Name" = "terra_ig"
    }

}

resource "aws_route_table" "terra_rtb" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "10.92.30.0/27"
    gateway_id = aws_internet_gateway.terra_ig.id
  }

  
  tags = {
    Name = "terra_rtb"
  }
}

resource "aws_subnet" "terra_subnet_pub" {
  vpc_id     = aws_vpc.terra_vpc.id
  cidr_block = "10.92.30.0/28"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "terra_subnet_pub"
  
  }
}

resource "aws_subnet" "terra_subnet_pri" {
  vpc_id     = aws_vpc.terra_vpc.id
  cidr_block = "10.92.30.16/29"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "terra_subnet_pri"
  
  }
}

resource "aws_route_table_association" "rtb_pub" {
  subnet_id      = aws_subnet.terra_subnet_pub.id 
  
  route_table_id = aws_route_table.terra_rtb.id 
}
resource "aws_route_table_association" "rtb_pri" {
  subnet_id      = aws_subnet.terra_subnet_pri.id 
  
  route_table_id = aws_route_table.terra_rtb.id 
}



resource "aws_security_group" "terra_sg" {
  name        = "terra_sg"
  description = "Allow ssh,http inbound traffic"
  vpc_id      = aws_vpc.terra_vpc.id 

  ingress {
    description      = "SSH ACCESS TO DEVELOPERS"
    from_port        = 22
    to_port          = 22
    protocol         = "SSH"
    cidr_blocks      = [aws_vpc.terra_vpc.cidr_block]
  }

  ingress {
    description      = "access to internet"
    from_port        = 443
    to_port          = 443
    protocol         = "https"
    cidr_blocks      = [aws_vpc.terra_vpc.cidr_block]
   
  }
  ingress {
    description      = "access to internet"
    from_port        = 80
    to_port          = 80
    protocol         = "http"
    cidr_blocks      = [aws_vpc.terra_vpc.cidr_block]
   
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terra_sg"
  }
}


resource "aws_instance" "terra_ec2" {
    ami = "ami-03ca998611da0fe12"
    instance_type = "t2.micro"
    availability_zone = "ap-southeast-1a "
    key_name = "Karthi-learning.pem"
    tags = {
      "Name" = "terraec2"

    }

}
  
