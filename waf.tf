resource "aws_wafv2_web_acl" "waf" {
  name        = "${var.project}-waf"
  description = "WAF for CloudFront"
  scope       = "CLOUDFRONT" # CloudFront 배포에 연결하려면 반드시 CLOUDFRONT

  default_action {
    allow {}
  }

  # Web ACL 전체에 대한 모니터링/메트릭 설정
  visibility_config {
    sampled_requests_enabled   = true # 요청 샘플링 활성화
    cloudwatch_metrics_enabled = true # CW 지표 활성화
    metric_name                = "${var.project}-waf"
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {} # 규칙 위반 시 “허용” 또는 “차단” 대신 기본동작 유지
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    # 각 룰별 모니터링/메트릭 설정
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
    }
  }

  tags = {
    Project = var.project
  }
}

# CloudFront 배포에 WAF 연결
resource "aws_wafv2_web_acl_association" "cf" {
  resource_arn = aws_cloudfront_distribution.cf.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}
