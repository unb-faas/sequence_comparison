variable "instancetype" {
  type = string
}

variable "accesskey" {
  type = string
}

variable "secretkey" {
  type = string
}

provider "aws" {
  region     = "us-west-1"
  access_key = var.accesskey
  secret_key = var.secretkey
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true 
  enable_dns_hostnames = true 
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-subnet"
  }
}

resource "aws_network_interface" "main" {
  subnet_id   = aws_subnet.main_subnet.id
  private_ips = ["10.0.1.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_acl" "Public_NACL" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [ aws_subnet.main_subnet.id ]
  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
 
  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0 
    to_port    = 0
  }
  
  tags = {
    Name = "Public NACL"
  }
}
resource "aws_internet_gateway" "IGW_teste" {
 vpc_id = aws_vpc.main.id
 tags = {
        Name = "Internet gateway teste"
}
} 
resource "aws_route_table" "Public_RT" {
 vpc_id = aws_vpc.main.id
 tags = {
        Name = "Public Route table"
}
} 
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.Public_RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW_teste.id
}
resource "aws_route_table_association" "Public_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.Public_RT.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJTNheRcHkQfiXTN6DDtUGKxnfbmtLHGTZDmX9PJkFgZNXM4xxvPQd8mk0lZ4gXKwBVSdv5oAAf50f7YxePp5rL/17nAItQvvZw0KKYWFMhr448c2FGwVMDpkyEHBUEFuV9wMnndaNn4Hnq5EKbQ2LrpVXiPuaIeSSUrlLqvK4eCHUuq2ceD6Nn1NjB3zoJLqclJIk4cdGiZPywjSW2A2TJtDKc1WcgAw9pbHSfdHuR1LXB0mMfxiHGpV6+Sdbq6I65oK7jneLWwEZmAql83Wf9wXfc4gX+Z3ixw9TOj+qwaJAXv6kpxG7DoC6sqY7MSht17NNn9thZsF7fRmCIQ2+2xLrKv9RiaMhIBx1L2Oy44gpX0N+NlvjL+BwsG9WxzKKwu44gQfdjEH69bCNKGT+MHYhQLPdExpL748tjRg2u+VYsGNEn7jwvsjl+00uzM00mOAvJI1UdRPkrUbMuLZdQmff+oyv1cb6s/dpXuUp4vihtPVE7OegJgXY85fWHyE= leonardo@leonardo-Avell"
}

resource "aws_instance" "machine" {
  ami          = "ami-0ec6517f6edbf8044"
  instance_type = var.instancetype
  key_name      = aws_key_pair.deployer.key_name
  tags = {
    Name = "sequencecomparisson"
  }

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }

  #user_data = file("init-script.sh")
  user_data = <<-EOF
              #!/bin/bash
              yum install git python36 gcc python36-devel aws-cli -y
              python3.6 -m venv .venv
              source .venv/bin/activate
              pip-3.6 install fastapi psutil boto3
              pip-3.6 install uvicorn[standard]
              mkdir ~/.aws
              echo "[default]" > ~/.aws/credentials
              echo "aws_access_key_id = " ${var.accesskey} >> ~/.aws/credentials
              echo "aws_secret_access_key = ${var.secretkey}" >> ~/.aws/credentials
              mkdir -p /app
              cd /app
              git clone https://github.com/unb-faas/sequence_comparison.git
              cd /app/sequence_comparison/algorithms/hirschberg/Python/app/
              sed -i "s/\/localhost/\/${var.instancetype}/" main.py
              ./start.sh &
              #teste
            EOF 
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.allow_http.id
  network_interface_id = aws_instance.machine.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "sg_attachment_ssh" {
  security_group_id    = aws_security_group.allow_ssh.id
  network_interface_id = aws_instance.machine.primary_network_interface_id
}

output "instance_ips" {
  value = aws_instance.machine.*.public_ip
}

