resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization"],
            ["AWS/S3", "NumberOfObjects"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "System Metrics"
        }
      }
    ]
  })

  tags = var.tags
}
