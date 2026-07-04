variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Target Hosting Region"
}

variable "database_password" {
  type        = string
  sensitive   = true
  description = "Password for PostgreSQL Database user admin"
  default     = "BhojanOSPassword123!"
}
