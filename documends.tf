provider "aws" {
    
    region = "ap-southeast-1"    #change to desired region
    access_key = ""
    secret_key = ""
}

resource "aws_vpc" "doc_vpc" {
    cidr_block = "10.92.30.0/27"              # Give cidr block according to required ip's
    instance_tenancy = "default"

    
    tags = {
      "Name" = "doc_vpc"
    }
}
resource "aws_internet_gateway" "doc_ig"{
    vpc_id = "aws_vpc.doc_vpc.id"

    tags = {
      "Name" = "doc_ig"
    }

}

resource "aws_route_table" "doc_rtb" {
  vpc_id = aws_vpc.doc_vpc.id

  route {
    cidr_block = "10.92.30.0/27"
    gateway_id = aws_internet_gateway.doc_ig.id
  }

  
  tags = {
    Name = "doc_rtb"
  }
}

resource "aws_subnet" "doc_dev_subnet" {
  vpc_id     = aws_vpc.doc_vpc.id
  cidr_block = "10.92.30.0/28"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "doc_dev_subnet"
  
  }
}

# resource "aws_subnet" "doc_testing_subnet" {
#   vpc_id     = aws_vpc.doc_vpc.id
#   cidr_block = "10.92.30.16/29"
#   availability_zone = "ap-southeast-1a"

#   tags = {
#     Name = "doc_testing_subnet"
  
#   }
# }

resource "aws_route_table_association" "rtb_pub" {
  subnet_id      = aws_subnet.doc_dev_subnet.id 
  
  route_table_id = aws_route_table.doc_rtb.id 
}
# resource "aws_route_table_association" "rtb_pri" {
#   subnet_id      = aws_subnet.doc_testing_subnet.id 
  
#   route_table_id = aws_route_table.doc_rtb.id 
# }



resource "aws_security_group" "doc_dev_sg" {
  name        = "doc_sg"
  description = "Allow ssh,http inbound traffic"
  vpc_id      = aws_vpc.doc_vpc.id 

  ingress {
    description      = "SSH ACCESS TO DEVELOPERS"
    from_port        = 22
    to_port          = 22
    protocol         = "SSH"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "access to internet"
    from_port        = 443
    to_port          = 443
    protocol         = "https"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  ingress {
    description      = "access to internet"
    from_port        = 80
    to_port          = 80
    protocol         = "http"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  ingress {
    description      = "access to internet"
    from_port        = 8084
    to_port          = 8084
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  ingress {
    description      = "ports"
    from_port        = 32768
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
   
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "doc_sg"
  }
}
# resource "aws_network_acl" "doc_dev_nacl" {
#   vpc_id = aws_vpc.doc_vpc.id

#   egress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 101
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 8085
#     to_port    = 8085
#   }
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 104
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   tags = {
#     Name = "doc_dev_nacl"
#   }
# }

resource "aws_instance" "doc_ec2" {
    ami = "ami-03ca998611da0fe12"
    instance_type = "t2.micro"
    availability_zone = "ap-southeast-1a "
    key_name = "Karthi-learning.pem"
    subnet_id = "aws_subnet.doc_dev_subnet.id"
    tags = {
      "Name" = "doc_dev"

    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install apt-transport-https ca-certificates curl software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
                sudo apt update
                sudo apt-cache policy docker-ce
                sudo apt install docker-ce -y
                curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

                EOF

}
  

resource "aws_iam_role_policy" "start_stop_policy" {
  name = "start_stop_policy"
  role = aws_iam_role.start_stop_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Start*",
        "ec2:Stop*"
      ],
      "Resource": "*"
    }
  ]
})
}

resource "aws_iam_role" "start_stop_role" {
  name = "start_stop_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

data "archive_file" "startec2" {
  type        = "zip"
  source_file = "start.py"
  output_path = "outputs/start.zip"
}

data "archive_file" "stopec2" {
  type        = "zip"
  source_file = "stop.py"
  output_path = "outputs/stop.zip"
}
resource "aws_lambda_function" "start_ec2" {
  filename      = "startec2.zip"
  function_name = "start_ec2"
  role          = aws_iam_role.start_stop_role.arn
  handler       = "start.start"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # cercsource_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.8"


}

resource "aws_lambda_function" "stop_ec2" {
  filename      = "stopec2.zip"
  function_name = "stop_ec2"
  role          = aws_iam_role.start_stop_role.arn
  handler       = "stop.stop"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.8"

  
}
# resource "aws_cloudwatch_event_rule" "stop_instance" {
#   name                = "Stop_instance"
#   description         = "Stop instances night"
#   schedule_expression = "cron(30 16 ? * MON-FRI *)"
# }

# resource "aws_cloudwatch_event_target" "stop_instance" {
#   target_id = "Stop_instance"
#   arn       = aws_cloudwatch_event_target.stop_instance.arn
#   input     = aws_lambda_function.stop_instance
#   rule      = aws_cloudwatch_event_rule.stop_instance.name
#   role_arn  = aws_iam_role.start_stop_role.arn

#   run_command_targets {
#     key    = "tag:stop"
#     values = ["night"]
#   }
# }
# resource "aws_cloudwatch_event_rule" "start_instance" {
#   name                = "Start_instance"
#   description         = "Start instances Morning"
#   schedule_expression = "cron(30 4 ? * MON-FRI *)"
# }

# resource "aws_cloudwatch_event_target" "start_instance" {
#   target_id = "Start_instance"
#   arn       = aws_cloudwatch_event_target.start_instance.arn
#   input     = aws_lambda_function.Start_instance
#   rule      = aws_cloudwatch_event_rule.start_instance.name
#   role_arn  = aws_iam_role.start_stop_role.arn

#   run_command_targets {
#     key    = "tag:start"
#     values = ["morning"]
#   }
# }
