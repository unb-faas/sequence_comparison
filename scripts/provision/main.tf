variable "instancetype" {
  type = string
}

variable "accesskey" {
  type = string
}

variable "secretkey" {
  type = string
}

resource "random_string" "random" {
  length           = 16
  special          = false
  number           = false
  override_special = "/@£$"
}

provider "aws" {
  region     = "us-west-1"
  access_key = var.accesskey
  secret_key = var.secretkey
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  #vpc_id = aws_vpc.main.id

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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = random_string.random.result
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJTNheRcHkQfiXTN6DDtUGKxnfbmtLHGTZDmX9PJkFgZNXM4xxvPQd8mk0lZ4gXKwBVSdv5oAAf50f7YxePp5rL/17nAItQvvZw0KKYWFMhr448c2FGwVMDpkyEHBUEFuV9wMnndaNn4Hnq5EKbQ2LrpVXiPuaIeSSUrlLqvK4eCHUuq2ceD6Nn1NjB3zoJLqclJIk4cdGiZPywjSW2A2TJtDKc1WcgAw9pbHSfdHuR1LXB0mMfxiHGpV6+Sdbq6I65oK7jneLWwEZmAql83Wf9wXfc4gX+Z3ixw9TOj+qwaJAXv6kpxG7DoC6sqY7MSht17NNn9thZsF7fRmCIQ2+2xLrKv9RiaMhIBx1L2Oy44gpX0N+NlvjL+BwsG9WxzKKwu44gQfdjEH69bCNKGT+MHYhQLPdExpL748tjRg2u+VYsGNEn7jwvsjl+00uzM00mOAvJI1UdRPkrUbMuLZdQmff+oyv1cb6s/dpXuUp4vihtPVE7OegJgXY85fWHyE= leonardo@leonardo-Avell"
}

resource "aws_instance" "machine" {
  ami          = "ami-0ec6517f6edbf8044"
  instance_type = var.instancetype
  key_name      = aws_key_pair.deployer.key_name
  tags = {
    Name = "sequencecomparisson"
  }

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
              git clone https://github.com/unb-faas/sequence_comparison_app.git
              cd /app/sequence_comparison_app/algorithms/hirschberg/Python/app/
              sed -i "s/\/localhost/\/${var.instancetype}/" main.py
              ./start.sh &
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

