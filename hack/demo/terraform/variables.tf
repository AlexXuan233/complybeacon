variable "grafana_url" {
  description = "Grafana server URL"
  type        = string
  default     = "http://localhost:3000"
}

variable "grafana_auth" {
  description = "Grafana authentication (e.g., 'admin:admin' or use API key)"
  type        = string
  default     = "admin:admin"
  sensitive   = true
}

variable "loki_url" {
  description = "Loki server URL"
  type        = string
  default     = "http://loki:3100"
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for alert notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alert_evaluation_interval" {
  description = "How often to evaluate alert rules (e.g., '1m', '5m')"
  type        = string
  default     = "1m"
}

variable "alert_for_duration" {
  description = "Duration condition must be true before firing (e.g., '5m')"
  type        = string
  default     = "2m"
}

variable "alert_failure_threshold" {
  description = "Minimum number of failed policy evaluations to trigger alert"
  type        = number
  default     = 1
}
