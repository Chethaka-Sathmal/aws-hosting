# MySQL in the private data subnets. Multi-AZ keeps a synchronous standby in
# the second AZ and fails over automatically.

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db"
  subnet_ids = aws_subnet.data[*].id
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name}-mysql"
  engine         = "mysql"
  engine_version = "8.4"
  instance_class = var.db_instance_class
  multi_az       = true

  db_name  = "conduit"
  username = "conduit_admin"

  # RDS generates the password and stores it in Secrets Manager
  manage_master_user_password = true

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period   = 7
  deletion_protection       = true
  final_snapshot_identifier = "${local.name}-mysql-final"
}
