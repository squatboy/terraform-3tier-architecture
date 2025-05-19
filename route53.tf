// route53.tf

//------------------------------------------------------------------------------
// Route 53 DNS Record for the Application
//------------------------------------------------------------------------------
resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id       // From data.tf
  name    = "app.${data.aws_route53_zone.selected.name}" // e.g., app.example.com.
  type    = "A"                                          // A record for IPv4

  alias {
    name                   = aws_lb.main.dns_name // DNS name of the ALB
    zone_id                = aws_lb.main.zone_id  // Hosted zone ID of the ALB
    evaluate_target_health = true                 // Route traffic based on ALB health
  }
}
