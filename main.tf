provider "aws" {
    region = "eu-west-3"
}

variable "vpc_cidr_block" {}
variable "env_prefix" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "public_key_location" {}
variable "script_location" {}
variable "ec2_names" {
    default = ["server", "client"]
}

resource "aws_vpc" "myapp_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.myapp_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet"
    }
}

resource "aws_internet_gateway" "myapp_igw" {
    vpc_id = aws_vpc.myapp_vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "capstone-rtb" {
    default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp_igw.id
    }
    tags = {
        Name = "${var.env_prefix}-rtb"
    }
}

resource "aws_default_security_group" "cap_sg" {
    vpc_id = aws_vpc.myapp_vpc.id

    # ssh
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # grafana
    ingress {
        from_port = 3020
        to_port = 3020 
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # application
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

resource "aws_key_pair" "ssh-ec2-key" {
    key_name = "ec2-key"
    public_key = file(var.public_key_location)
}

# resource "aws_instance" "server" {
#     ami = data.aws_ami.latest-amazon-linux-image.id
#     instance_type = "t2.micro"  
#     subnet_id = aws_subnet.public_subnet.id
#     vpc_security_group_ids = [aws_default_security_group.cap_sg.id]
#     availability_zone = var.avail_zone
#     associate_public_ip_address = true
#     key_name = aws_key_pair.ssh-ec2-key.key_name
#     user_data = file(var.script_location)

#     tags = {
#         Name = "${var.env_prefix}-server"
#     }
# }

resource "aws_instance" "ec2vm" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = "t2.micro"  
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_default_security_group.cap_sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-ec2-key.key_name
    user_data = file(var.script_location)
    count = 2
    tags = {
        Name = "${var.env_prefix}-${var.ec2_names[count.index]}"
    }
}

output "ec2_server_public_ip" {
    value = aws_instance.ec2vm[0].public_ip
}

output "ec2_client_public_ip" {
    value = aws_instance.ec2vm[1].public_ip
}
