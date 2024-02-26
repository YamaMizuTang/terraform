resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_block

  tags = {
    Name = "subnet-private"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr_block

  tags = {
    Name = "subnet-public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "rt-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "rt-private"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}




data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "public_ec2_security" {
  name = "public_ec2_security"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.public_ec2_security.id]

  tags = {
    Name = "ec2-public"
  }
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  key_name               = aws_key_pair.key.key_name
  vpc_security_group_ids = [aws_security_group.public_ec2_security.id]

  tags = {
    Name = "ec2-private"
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "my_key" {
  content  = tls_private_key.key.private_key_pem
  filename = "${aws_key_pair.key.key_name}.pem"
}

resource "aws_key_pair" "key" {
  key_name   = var.key_name
  public_key = tls_private_key.key.public_key_openssh
}

output "ec2_public_ip" {
  value = aws_instance.public.public_ip
}

output "public_ec2_ssh" {
  value = "ssh -i ${local_file.my_key.filename} ubuntu@${aws_instance.public.public_ip}"
}

output "private_ec2_ssh" {
  value = "ssh ubuntu@${aws_instance.private.private_ip} -oProxyCommand=\"ssh ubuntu@${aws_instance.public.public_ip} -i ${local_file.my_key.filename} -W %h:%p\" -i ${local_file.my_key.filename}"
}
