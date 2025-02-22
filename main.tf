provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Updated availability zone
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"  # Updated availability zone
  map_public_ip_on_launch = true
}

resource "aws_security_group" "microservice_sg_1" {
  name        = "microservice_sg_1"
  description = "Allow traffic for microservice 1"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "microservice_sg_2" {
  name        = "microservice_sg_2"
  description = "Allow traffic for microservice 2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_ecs_cluster" "microservice_cluster" {
  name = "microservice-cluster"
}

resource "aws_ecs_task_definition" "microservice_1_task" {
  family                   = "microservice-1-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "microservice-1-container"
    image     = "first:1.0"
    cpu       = 256
    memory    = 512
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
  }])
}

resource "aws_ecs_task_definition" "microservice_2_task" {
  family                   = "microservice-2-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "microservice-2-container"
    image     = "first:1.0"
    cpu       = 256
    memory    = 512
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
  }])
}

resource "aws_ecs_service" "microservice_1_service" {
  name            = "microservice-1-service"
  cluster         = aws_ecs_cluster.microservice_cluster.id
  task_definition = aws_ecs_task_definition.microservice_1_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_1.id]
    security_groups = [aws_security_group.microservice_sg_1.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "microservice_2_service" {
  name            = "microservice-2-service"
  cluster         = aws_ecs_cluster.microservice_cluster.id
  task_definition = aws_ecs_task_definition.microservice_2_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_2.id]
    security_groups = [aws_security_group.microservice_sg_2.id]
    assign_public_ip = true
  }
}
