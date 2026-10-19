output "log_group_name" {
  value       = aws_cloudwatch_log_group.proxy.name
  description = "Pass to the proxy hosts as INGRESS_LOG_GROUP — docker-compose.prod-proxy.yml's awslogs driver writes here, one stream per PROXY_ID."
}

output "sns_topic_arn" {
  value       = var.monitoring_enabled ? aws_sns_topic.alerts[0].arn : null
  description = "Null when monitoring is disabled. Reuse for any further alarms in this region rather than creating a second topic."
}

output "alarm_names" {
  value = var.monitoring_enabled && var.create_default_alarms ? [
    aws_cloudwatch_metric_alarm.unconverged[0].alarm_name,
    aws_cloudwatch_metric_alarm.stale[0].alarm_name,
    aws_cloudwatch_metric_alarm.heartbeat_missing[0].alarm_name,
  ] : []
  description = "For `aws cloudwatch describe-alarms --alarm-names` during a rollout."
}
