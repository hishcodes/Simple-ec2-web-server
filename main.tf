# Create a vpc
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "demo-vpc"
  }
}

# Create a public subnet inside the vpc at AZ us-east-1a 
resource "aws_subnet" "pub_sub_1" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    name = "public-subnet-1"
  }
}

# Create internet gateway for the vpc
resource "aws_internet_gateway" "demo_internet_gateway" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

# Create a public route table for the vpc
resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

# Add a route in the route table which directs 0.0.0.0/0 traffic to internet gateway
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.demo_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo_internet_gateway.id
}

# Associate the route table to the subnet
resource "aws_route_table_association" "demo_public_assoc" {
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.demo_public_rt.id

}

# Create a security group for the vpc
resource "aws_security_group" "demo_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.demo_vpc.id

# Allow only port 80 inbound
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Allow all traffic for outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an ec2 instance with user data
resource "aws_instance" "demo" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.instance_ami.id
  user_data              = file("user-data.tpl")
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  subnet_id              = aws_subnet.pub_sub_1.id
}

# Output the public ip of instance in the terminal
output "ec2_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.demo.public_ip
}

# Create and define the elastic ip is for use in vpc
resource "aws_eip" "elastic_ip"{
    instance = aws_instance.demo.id
    domain = "vpc"
}

# Associate the elastic ip with the ec2 instance
resource "aws_eip_association" "eip_assoc"{
    instance_id = aws_instance.demo.id
    allocation_id = aws_eip.elastic_ip.id
}

# Output the elastic ip in the terminal
output "ec2_eip" {
  description = "The Elastic IP of the EC2 instance"
  value       = aws_eip.elastic_ip.public_ip
}