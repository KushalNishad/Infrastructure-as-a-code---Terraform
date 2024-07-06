# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "nishad-vpc"
  }
}

# Public Subnet 1 with Default Route to Internet Gateway
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "nishad-public-subnet-1"
  }
}

# Public Subnet 2 with Default Route to Internet Gateway
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "nishad-public-subnet-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "nishad-private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "nishad-private-subnet-2"
  }
}

# Create Internet Gateway for Public Subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "nishad-internet-gateway"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT-EIP"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public1.id
  tags = {
    Name = "nishad-nat-gateway"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "nishad-public-route-table"
  }
}

# Association of Public Route Table with Public Subnets
resource "aws_route_table_association" "public1-route-association" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2-route-association" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnets 
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "nishad-private-route-table"
  }
}

# Association of Private Route Table with Private Subnets
resource "aws_route_table_association" "private1-route-association" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2-route-association" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
