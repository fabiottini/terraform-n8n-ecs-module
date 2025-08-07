# # Task definition for debug
# resource "aws_ecs_task_definition" "debug" {
#   family                   = "debug-amazonlinux2"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = 512
#   memory                   = 1024
#   execution_role_arn       = aws_iam_role.ecs_task_execution.arn
#   task_role_arn            = aws_iam_role.ecs_task_execution.arn
#   container_definitions    = jsonencode([
#     {
#       name      = "debug-amazonlinux2"
#       image     = "public.ecr.aws/amazonlinux/amazonlinux:2"
#       command   = ["tail", "-f", "/dev/null"]
#       essential = true
#       environment = concat(
#         local.environment, 
#         [  { name = "N8N_WORKER_MODE", value = "master" } ]
#       )
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = "/ecs/debug-amazonlinux2"
#           awslogs-region        = "${var.aws_region}"
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
#   ])
#   depends_on = [aws_cloudwatch_log_group.debug]
#   tags = var.common_tags
# }

# resource "aws_ecs_service" "debug" {
#   name            = "debug-amazonlinux2"
#   cluster         = aws_ecs_cluster.this.id
#   task_definition = aws_ecs_task_definition.debug.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#   enable_execute_command = true
#   network_configuration {
#     subnets          = var.subnet_ids
#     security_groups  = [aws_security_group.ecs_tasks.id]
#     assign_public_ip = false
#   }
#   depends_on = [aws_ecs_task_definition.debug]
#   tags = var.common_tags
# }

# resource "aws_cloudwatch_log_group" "debug" {
#   name              = "/ecs/debug-amazonlinux2"
#   retention_in_days = 7
#   tags = var.common_tags
# }