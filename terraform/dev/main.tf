provider "aws" {
  region = "us-east-1"  # Change this to your preferred AWS region
}

# Create a VPC
resource "aws_vpc" "example_vpc" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
}

resource "aws_route_table" "example_route_table_a" {
  vpc_id = aws_vpc.example_vpc.id
}
resource "aws_route_table" "example_route_table_b" {
  vpc_id = aws_vpc.example_vpc.id
}


# Create subnets in different availability zones associated with the VPC
resource "aws_subnet" "example_subnet_a" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "example_subnet_b" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
}

resource "aws_route" "example_route_a" {
  route_table_id         = aws_route_table.example_route_table_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example_igw.id
}

resource "aws_route" "example_route_b" {
  route_table_id         = aws_route_table.example_route_table_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example_igw.id
}

# Create a Security Group associated with the VPC
resource "aws_security_group" "example_sg" {
  name        = "example-sg"
  description = "Security group for port 8081"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from any IP address. Adjust as needed.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a Launch Configuration associated with the VPC
resource "aws_launch_configuration" "example_lc" {
  name                 = "example-lc"
  image_id             = var.ami_id  # Specify your desired AMI ID
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.example_sg.id]
  key_name             = var.ssh_key

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker
              sudo service docker start
              sudo usermod -aG docker ec2-user
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Create an Auto Scaling Group specifying VPC subnets
resource "aws_autoscaling_group" "example_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  health_check_type    = "EC2"
  health_check_grace_period = 300

  launch_configuration = aws_launch_configuration.example_lc.id
  vpc_zone_identifier  = [aws_subnet.example_subnet_a.id, aws_subnet.example_subnet_b.id]
}

# Create an Application Load Balancer (ALB) associated with the VPC
resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example_sg.id]
  subnets            = [aws_subnet.example_subnet_a.id, aws_subnet.example_subnet_b.id]
}

# Create a Target Group associated with the VPC
resource "aws_lb_target_group" "example_target_group" {
  name     = "example-target-group"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.example_vpc.id
}

# Attach the Auto Scaling Group to the Target Group
resource "aws_autoscaling_attachment" "example_asg_attachment" {
  lb_target_group_arn  = aws_lb_target_group.example_target_group.arn
  autoscaling_group_name = aws_autoscaling_group.example_asg.name
}

# Output the Auto Scaling Group name, Security Group ID, Subnet IDs, Load Balancer DNS Name
output "asg_name" {
  value = aws_autoscaling_group.example_asg.name
}

output "sg_id" {
  value = aws_security_group.example_sg.id
}

output "subnet_ids" {
  value = [aws_subnet.example_subnet_a.id, aws_subnet.example_subnet_b.id]
}

output "lb_dns_name" {
  value = aws_lb.example_lb.dns_name
}
