locals {
    common_name = "${var.project_name}-${var.environment}"
    az-names = slice(data.aws_availability_zones.available.names, 0,2 )
}

locals {
  common_tags = {
    Project = var.project_name
    Environment = var.environment
    terraform = true
  }
}

 