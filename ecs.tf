################################################################################
# Task Role
################################################################################
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "xray_pol_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
}
resource "aws_iam_role_policy_attachment" "dynamo_pol_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy" "create_log_group_pol" {
  name = "create-log-group-pol"
  role = aws_iam_role.ecs_task_role.id
  #checkov:skip=CKV_AWS_290
  #checkov:skip=CKV_AWS_355
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


################################################################################
# SG
################################################################################
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.vpc_app.id
  description = "ALB SG"
  #checkov:skip=CKV_AWS_260
  ingress {
    description = "ingress 80"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ALB egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "task01" {
  name        = "task01-sg"
  vpc_id      = aws_vpc.vpc_app.id
  description = "task01 SG"

  ingress {
    description     = "ingress MYSQL"
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "RDS egress"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# Load Balancer
################################################################################

resource "aws_lb" "alb" {
  name            = "ecs-alb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.alb.id]
  #checkov:skip=CKV_AWS_150
  #checkov:skip=CKV_AWS_131
  #checkov:skip=CKV_AWS_91
  #checkov:skip=CKV2_AWS_28
  #checkov:skip=CKV_AWS_104
  enable_deletion_protection = false
  drop_invalid_header_fields = false
}

resource "aws_lb_listener" "listener" {
  #checkov:skip=CKV_AWS_2
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg" {
  #checkov:skip=CKV_AWS_261
  name        = "app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_app.id
  target_type = "ip"
}

################################################################################
# ECS Cluster
################################################################################

resource "aws_ecs_cluster" "app_cluster" {
  #checkov:skip=CKV_AWS_65
  name = "app-ecs-cluster"
}

resource "aws_ecs_service" "my_service" {
  name            = "app-ecs-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.task01.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.task01.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.id
    container_name   = "nodejs-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_ecs_task_definition" "task01" {
  #checkov:skip=CKV_AWS_249
  #checkov:skip=CKV_AWS_336
  family                   = "demo-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

  container_definitions = <<TASK_DEFINITION
  [
    {
      "name": "nodejs-app",
      "image": "docker.io/mariocrux/aws-nodejs-demo:latest@sha256:d7c0340cf91f9d2cdf6442c672acdb0ffd9ed9ac89ab2b8edbe742f4cf7256c1",
      "cpu": 512,
      "memory": 1024,
      "essential": true,
      "environment": [
        {
          "name": "DEFAULT_AWS_REGION", 
          "value": "${data.aws_region.current.name}"
        },
        {
          "name": "DB_HOST", 
          "value": "${aws_db_instance.myinstance.address}"
        },
        {
          "name": "DB_NAME", 
          "value": "myrdsinstance"
        },
        {
          "name": "DB_USER", 
          "value": "rdsuser"
        },
        {
          "name": "DB_PASS", 
          "value": "myrdspassword"
        },
        {
          "name": "DB_TABLE", 
          "value": "Persons"
        }
      ],
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "nodejs-app",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      }
    },
    {
      "name": "xray-daemon",
      "image": "amazon/aws-xray-daemon",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 2000,
          "hostPort": 2000,
          "Protocol": "udp"
        }
      ]
    }
  ]
  TASK_DEFINITION
  depends_on            = [aws_db_instance.myinstance]
}
