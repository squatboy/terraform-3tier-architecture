// locals.tf

locals {
  project_name = "webapp-project"
  environment  = "prod" // Example: could be "dev", "staging", "prod"
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
  vpc_cidr = "10.0.0.0/16"

  // Subnet CIDRs based on the diagram (2 AZs)
  // Ensure var.availability_zones has 2 elements corresponding to these.
  public_subnet_cidrs = [
    "10.0.1.0/24", // Corresponds to var.availability_zones[0]
    "10.0.10.0/24" // Corresponds to var.availability_zones[1]
  ]
  private_app_subnet_cidrs = [
    "10.0.2.0/24", // Corresponds to var.availability_zones[0]
    "10.0.11.0/24" // Corresponds to var.availability_zones[1]
  ]
  private_db_subnet_cidrs = [
    "10.0.3.0/24", // Corresponds to var.availability_zones[0]
    "10.0.12.0/24" // Corresponds to var.availability_zones[1]
  ]
}

// Use a random string for unique naming where needed, e.g., S3 buckets for ALB logs (not shown but good practice)
resource "random_id" "suffix" {
  byte_length = 4
}
