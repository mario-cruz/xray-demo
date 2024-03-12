#create a security group for RDS Database Instance
resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  ingress {
    description = "ingress rds"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "egress rds"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create a RDS Database Instance
resource "aws_db_instance" "myinstance" {
  #checkov:skip=CKV_AWS_118
  #checkov:skip=CKV_AWS_161
  #checkov:skip=CKV_AWS_353
  engine                 = "mysql"
  identifier             = "myrdsinstance"
  allocated_storage      = 20
  engine_version         = "8.0.36"
  instance_class         = "db.t3.micro"
  username               = "rdsuser"
  password               = "myrdspassword"
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
  skip_final_snapshot    = true
  publicly_accessible    = true
}