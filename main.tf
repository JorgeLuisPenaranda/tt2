terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  cloud {
    organization = "test01org"

    workspaces {
      name = "Dev"
    }
  }
}

provider "aws" {
    region = "us-west-2"  
}

resource "random_pet" "sg" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "jpenaranda"
  vpc_security_group_ids = [ aws_security_group.tt2sg.id ]

  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y apache2
              chmod 777 /var/www/html
              systemctl restart apache2
              EOF

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_security_group" "tt2sg" {
  name        = "${random_pet.sg.id}-sg"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
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
    Name = "allow_tls"
  }
}

output "publicaddr" {
    value = "${aws_instance.web.public_dns}"  
}
