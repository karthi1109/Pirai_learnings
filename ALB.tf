provider "aws" {
    
    region = "ap-southeast-1"
    access_key = ""
    secret_key = ""
}

resource "aws_vpc" "g1_vpc" {
    cidr_block = "10.92.30.0/27"
    instance_tenancy = "default"

    
    tags = {
      "Name" = "g1_vpc"
    }
}

resource "aws_internet_gateway" "g1_ig"{
    vpc_id = "aws_vpc.g1_vpc.id"

    tags = {
      "Name" = "g1_ig"
    }

}
resource "aws_route_table" "g1_rtb" {
  vpc_id = aws_vpc.g1_vpc.id

  route {
    cidr_block = "10.92.30.0/27"
    gateway_id = aws_internet_gateway.g1_ig.id
  }

  
  tags = {
    Name = "g1_rtb"
  }
}
resource "aws_subnet" "g1_subnet_pub1" {
  vpc_id     = aws_vpc.g1_vpc.id
  cidr_block = "10.92.30.0/28"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "g1_subnet_pub1"
  
  }
}
resource "aws_subnet" "g1_subnet_pub2" {
  vpc_id     = aws_vpc.g1_vpc.id
  cidr_block = "10.92.30.16/29"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "doc_subnet_pub2"
  
  }
}
resource "aws_route_table_association" "g1_pub1" {
  subnet_id      = aws_subnet.g1_subnet_pub1.id 
  
  route_table_id = aws_route_table.g1_rtb.id 
}
resource "aws_route_table_association" "g1_pub2" {
  subnet_id      = aws_subnet.g1_subnet_pub2.id 
  
  route_table_id = aws_route_table.g1_rtb.id 
}

resource "aws_security_group" "g1_sg" {
  name        = "g1_sg"
  description = "Allow ssh,http,https inbound traffic"
  vpc_id      = aws_vpc.g1_vpc.id 

  ingress {
    description      = "SSH ACCESS TO DEVELOPERS"
    from_port        = 22
    to_port          = 22
    protocol         = "SSH"
    cidr_blocks      = [aws_vpc.g1_vpc.cidr_block]
  }

  ingress {
    description      = "access to internet"
    from_port        = 443
    to_port          = 443
    protocol         = "https"
    cidr_blocks      = [aws_vpc.g1_vpc.cidr_block]
   
  }
  ingress {
    description      = "access to internet"
    from_port        = 80
    to_port          = 80
    protocol         = "http"
    cidr_blocks      = [aws_vpc.g1_vpc.cidr_block]
   
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "g1_sg"
  }
}
resource "aws_instance" "g1_ec2" {
    ami = "ami-03ca998611da0fe12"
    instance_type = "t2.micro"
    availability_zone = "ap-southeast-1a "
    key_name = "Karthi-learning.pem"
    subnet_id = "g1_subnet_pub1"
    tags = {
      "Name" = "g1_ec2"

    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo hello am running in aws server with alb > /var/www/html/index.html'
                EOF

}
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "g1-alb"

  load_balancer_type = "application"

  vpc_id             = "aws_vpc.g1_vpc.id"
  subnets            = ["g1_subnet_pub1", "g1_subnet_pub2"]
  security_groups    = ["g1_sg"]

  access_logs = {
    bucket = "my-alb-logs"
  }

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [
        {
          target_id = "aws_instance.g1_ec2.id"
          port = 80
        }
        
      ]
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
