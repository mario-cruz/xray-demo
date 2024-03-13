environment  = "dev"
aws_profile  = "app_deployment_dev"
network_cidr = "10.32.0.0/24"
additional-tags = {
  "application" : "xray-poc",
  "env" : "development"
}
images_bucket = "images-from-api-bucket-demo-mac"
