resource "aws_security_group" "container_sg" {
  name        = "container_sg"
  description = "Security group for Fargate containers"
  vpc_id      = aws_vpc.my_vpc.id
  tags = {
    Name = "container_sg"
  }


  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "nishad-cluster"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Effect    = "Allow"
      Sid       = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/nishad_task"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "nishad-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "nishad-container"
    image     = "975050240431.dkr.ecr.us-east-1.amazonaws.com/nishad-repo:8fdef37"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "nishad-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    subnets          = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.container_sg.id]
  }

  load_balancer {
    container_port   = 5000
    container_name   = "nishad-container"
    target_group_arn = aws_lb_target_group.ecs_nishad_service.arn
  }

}
