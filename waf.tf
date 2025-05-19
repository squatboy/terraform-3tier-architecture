// waf.tf

//------------------------------------------------------------------------------
// AWS WAFv2 Web ACL
//------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "main" {
  name        = "${local.project_name}-waf-acl"
  scope       = "REGIONAL" // For ALB. Use "CLOUDFRONT" for CloudFront distributions.
  description = "WAF ACL for ${local.project_name} ALB"

  default_action {
    allow {} // Default action if no rules match (can be block {} for a more restrictive default)
  }

  // Rule 1: AWS Managed Core Rule Set (Common baseline protection)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1 // Lower numbers are evaluated first

    override_action {
      none {} // Use the action defined within the managed rule group
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
        // excluded_rule { // Example: If you need to exclude a specific rule from the group
        //   name = "SizeRestrictions_BODY"
        // }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.project_name}WAFCommonRules"
      sampled_requests_enabled   = true // Log sampled requests for analysis
    }
  }

  // Rule 2: Rate-based rule to mitigate DDoS or brute-force attacks
  rule {
    name     = "RateLimit500PerIP"
    priority = 2

    action {
      block {} // Block requests if rate exceeds limit
      // Or use count {} to monitor before blocking:
      // count {}
    }

    statement {
      rate_based_statement {
        limit              = 500  // Max requests per 5-minute period per IP address
        aggregate_key_type = "IP" // Aggregate by source IP
        // scope_down_statement { // Optional: Apply rate limiting only to specific parts of requests
        //   byte_match_statement {
        //     search_string = "/login"
        //     field_to_match { uri_path {} }
        //     text_transformation { type = "NONE" priority = 0 }
        //     positional_constraint = "CONTAINS"
        //   }
        // }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.project_name}WAFRateLimit"
      sampled_requests_enabled   = true
    }
  }

  // Add more rules as needed (e.g., SQL injection, IP reputation lists)

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.project_name}WAFDefaultAction"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-waf-acl"
  })
}

//------------------------------------------------------------------------------
// Associate WAF with ALB
//------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = aws_lb.main.arn            // ARN of the Application Load Balancer
  web_acl_arn  = aws_wafv2_web_acl.main.arn // ARN of the Web ACL
}
