# ALB ECS outputs
output "load_balancer_ip" {
  value = aws_lb.alb.dns_name
}
# MYSQL RDS
output "db_instance_endpoint" {
  value       = aws_db_instance.myinstance.endpoint
}
# Lambda
output "lambda_endpoint" {
  value       = aws_lambda_function_url.image_api_scraper_url.function_url
}