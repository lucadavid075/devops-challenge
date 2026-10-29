locals {
  app_dockerfile = "${path.module}/../../intern-task-app/Dockerfile"
  app_source     = "${path.module}/../../intern-task-app/app/app.py"

  # Read the configured default from the actual Dockerfile so the EC2
  # bootstrap, firewall, security group, and output cannot drift from it.
  app_port       = tonumber(regex("(?m)^ENV PORT=([0-9]+)", file(local.app_dockerfile))[0])
}

resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "intern-task-app-vpc"
  }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "intern-task-app-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "intern-task-app-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

  tags = {
    Name = "intern-task-app-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app" {
  name_prefix = "intern-task-app-"
  description = "SSH from the supplied CIDR and HTTP on the app port only"
  vpc_id      = aws_vpc.app.id

  ingress {
    description = "SSH from the configured administrator CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "Intern task app"
    from_port   = local.app_port
    to_port     = local.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Bootstrap needs apt (HTTP/HTTPS) and Docker Hub (HTTPS); no other
  # outbound ports are required. The two ingress rules above are the only
  # inbound access granted by this security group.
  egress {
    description = "HTTP Ubuntu package mirrors"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS package and Docker image downloads"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "intern-task-app"
  }
}

resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_port       = local.app_port
    ssh_cidr       = var.ssh_cidr
    dockerfile_b64 = filebase64(local.app_dockerfile)
    app_py_b64     = filebase64(local.app_source)
  })

  # Explicitly opt out of replacement: cloud-init consumes user_data only
  # at first boot, so later changes need a deliberate rollout to take effect.
  user_data_replace_on_change = false

  tags = {
    Name = "intern-task-app"
  }

  # Ensure the public route exists before cloud-init tries to download packages.
  depends_on = [aws_route_table_association.public]
}