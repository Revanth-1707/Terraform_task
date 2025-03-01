
resource "aws_vpc" "my" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}


resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my.id
  cidr_block              = "10.0.0.0/25"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "my_public_subnet"
  }
}


resource "aws_subnet" "my_private_subnet" {
  vpc_id                  = aws_vpc.my.id
  cidr_block              = "10.0.0.128/25"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "my_private_subnet"
  }
}


resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my.id
  tags = {
    Name = "my_sg"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

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


resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my.id
  tags = {
    Name = "my_internet_gateway"
  }
}


resource "aws_route_table" "my_public_rt" {
  vpc_id = aws_vpc.my.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }
  tags = {
    Name = "my_public_rt"
  }
}


resource "aws_route_table_association" "my_public_assoc" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_public_rt.id
}


resource "aws_eip" "my_nat_eip" {
  vpc = true
}


resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.my_nat_eip.id
  subnet_id     = aws_subnet.my_public_subnet.id
  depends_on    = [aws_internet_gateway.my_gateway]
  tags = {
    Name = "my_nat_gateway"
  }
}



resource "aws_route_table" "my_private_rt" {
  vpc_id = aws_vpc.my.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat.id
  }
  tags = {
    Name = "my_private_rt"
  }
}


resource "aws_route_table_association" "my_private_assoc" {
  subnet_id      = aws_subnet.my_private_subnet.id
  route_table_id = aws_route_table.my_private_rt.id
}



resource "aws_instance" "my_public" {
  ami                         = "ami-0f2ce9ce760bd7133"
  instance_type               = "t2.micro"
  key_name                    = "203devclass"
  subnet_id                   = aws_subnet.my_public_subnet.id
  security_groups             = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "my_public"
  }
  user_data = file("startup.sh")
}


resource "aws_instance" "my_private" {
  ami                         = "ami-0f2ce9ce760bd7133"
  instance_type               = "t2.micro"
  key_name                    = "203devclass"
  subnet_id                   = aws_subnet.my_private_subnet.id
  security_groups             = [aws_security_group.my_sg.id]
  associate_public_ip_address = false
  tags = {
    Name = "my_private"
  }
}
