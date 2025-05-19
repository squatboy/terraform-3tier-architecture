// data.tf

// Data source to get available AZs in the current region.
// Useful if you want to dynamically pick AZs instead of hardcoding in var.availability_zones
// For this setup, we assume var.availability_zones is explicitly provided and ordered.
data "aws_availability_zones" "available" {
  state = "available"
}

// Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"] // AWS-owned AMIs

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// Data source for Route 53 Hosted Zone
// (Moved from route53.tf as it's a data source)
data "aws_route53_zone" "selected" {
  name         = var.domain_name // e.g., "example.com." (note the trailing dot for FQDN)
  private_zone = false           // Public hosted zone
}
