terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

# Data source configuration
# Note: This datasource is created by Docker Compose and imported into Terraform
resource "grafana_data_source" "loki" {
  type       = "loki"
  name       = "Loki"
  url        = var.loki_url
  is_default = true

  json_data_encoded = jsonencode({})

  lifecycle {
    # Prevent Terraform from trying to recreate this if it exists
    prevent_destroy = false
  }
}

# Compliance Evidence Dashboard
# Managed inline with HCL for dynamic Terraform references and full IaC capabilities
resource "grafana_dashboard" "compliance_evidence" {
  overwrite = true

  config_json = jsonencode({
    title   = "Compliance Evidence Dashboard"
    uid     = "compliance-evidence"
    tags    = ["compliance", "evidence", "policy"]
    timezone = "browser"
    schemaVersion = 39
    version = 0
    refresh = ""
    editable = true
    fiscalYearStartMonth = 0
    graphTooltip = 0
    liveNow = false

    annotations = {
      list = [
        {
          builtIn = 1
          datasource = {
            type = "grafana"
            uid  = "-- Grafana --"
          }
          enable    = true
          hide      = true
          iconColor = "rgba(0, 211, 255, 1)"
          name      = "Annotations & Alerts"
          type      = "dashboard"
        }
      ]
    }

    time = {
      from = "now-6h"
      to   = "now"
    }

    timepicker = {}
    templating = {
      list = []
    }

    panels = [
      # Panel 1: Total Evidence Records
      {
        id = 1
        title = "Total Evidence Records"
        type = "stat"
        gridPos = {
          h = 8
          w = 6
          x = 0
          y = 0
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        pluginVersion = "11.6.0"
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode = "code"
          expr       = "sum(count_over_time({service_name=~\".+\"} [$__range]))"
          queryType  = "range"
          refId      = "A"
        }]
        options = {
          colorMode    = "value"
          graphMode    = "area"
          justifyMode  = "auto"
          orientation  = "auto"
          textMode     = "auto"
          reduceOptions = {
            values = false
            calcs  = ["lastNotNull"]
            fields = ""
          }
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            mappings = []
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                }
              ]
            }
          }
          overrides = []
        }
      },
      # Panel 2: Policy Evaluation Results (Pie Chart)
      {
        id = 2
        title = "Policy Evaluation Results"
        type = "piechart"
        gridPos = {
          h = 8
          w = 9
          x = 6
          y = 0
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        pluginVersion = "11.6.0"
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode   = "code"
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} [$__range]))"
          legendFormat = "{{policy_evaluation_result}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          "displayLabels": [
            "percent"
          ],
          legend = {
            displayMode = "table"
            placement   = "right"
            showLegend  = true
            values      = ["value"]
          }
          pieType = "pie"
          tooltip = {
            mode = "single"
            sort = "none"
          }
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              hideFrom = {
                tooltip = false
                viz     = false
                legend  = false
              }
            }
            mappings = []
          }
          overrides = [
            {
              matcher = {
                id      = "byName"
                options = "Passed"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "green"
                    mode       = "fixed"
                  }
                }
              ]
            },
            {
              matcher = {
                id      = "byName"
                options = "Failed"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "red"
                    mode       = "fixed"
                  }
                }
              ]
            }
          ]
        }
      },
      # Panel 3: Evaluation Results Summary (Table)
      {
        id = 3
        title = "Evaluation Results Summary"
        type = "table"
        gridPos = {
          h = 8
          w = 9
          x = 15
          y = 0
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        pluginVersion = "11.6.0"
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode   = "code"
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} [$__range]))"
          legendFormat = "{{policy_evaluation_result}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          showHeader = true
          cellHeight = "sm"
          footer = {
            show      = false
            reducer   = ["sum"]
            countRows = false
            fields    = ""
          }
          sortBy = [
            {
              displayName = "Count"
              desc        = true
            }
          ]
        }
        transformations = [
          {
            id = "organize"
            options = {
              excludeByName = {
                Time = true
              }
              indexByName = {}
              renameByName = {
                policy_evaluation_result = "Result"
                Value                    = "Count"
              }
            }
          }
        ]
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            mappings = [
              {
                type = "value"
                options = {
                  Passed = {
                    color = "green"
                    index = 0
                  }
                  Failed = {
                    color = "red"
                    index = 1
                  }
                  "Not Run" = {
                    color = "blue"
                    index = 2
                  }
                  "Needs Review" = {
                    color = "yellow"
                    index = 3
                  }
                  "Not Applicable" = {
                    color = "text"
                    index = 4
                  }
                  Unknown = {
                    color = "orange"
                    index = 5
                  }
                }
              }
            ]
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "text"
                  value = null
                }
              ]
            }
          }
          overrides = []
        }
      },
      # Panel 4: Policy Evaluation Over Time (Time Series)
      {
        id = 4
        title = "Policy Evaluation Over Time"
        type = "timeseries"
        gridPos = {
          h = 8
          w = 24
          x = 0
          y = 8
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode   = "code"
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} [$__interval]))"
          legendFormat = "{{policy_evaluation_result}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          legend = {
            calcs       = []
            displayMode = "list"
            placement   = "bottom"
            showLegend  = true
          }
          tooltip = {
            mode = "multi"
            sort = "none"
          }
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              axisCenteredZero = false
              axisColorMode    = "text"
              axisLabel        = ""
              axisPlacement    = "auto"
              barAlignment     = 0
              drawStyle        = "bars"
              fillOpacity      = 80
              gradientMode     = "none"
              hideFrom = {
                tooltip = false
                viz     = false
                legend  = false
              }
              lineInterpolation = "linear"
              lineWidth         = 1
              pointSize         = 5
              scaleDistribution = {
                type = "linear"
              }
              showPoints = "auto"
              spanNulls  = false
              stacking = {
                group = "A"
                mode  = "normal"
              }
              thresholdsStyle = {
                mode = "off"
              }
            }
            mappings = []
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                }
              ]
            }
          }
          overrides = [
            {
              matcher = {
                id      = "byName"
                options = "Passed"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "green"
                    mode       = "fixed"
                  }
                }
              ]
            },
            {
              matcher = {
                id      = "byName"
                options = "Failed"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "red"
                    mode       = "fixed"
                  }
                }
              ]
            },
            {
              matcher = {
                id      = "byName"
                options = "Unknown"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "orange"
                    mode       = "fixed"
                  }
                }
              ]
            }
          ]
        }
      },
      # Panel 5: Evidence by Policy Engine (Donut Chart)
      {
        id = 5
        title = "Evidence by Policy Engine"
        type = "piechart"
        gridPos = {
          h = 8
          w = 12
          x = 0
          y = 16
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        pluginVersion = "11.6.0"
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode   = "code"
          expr         = "sum by (policy_engine_name) (count_over_time({service_name=~\".+\"} [$__range]))"
          legendFormat = "{{policy_engine_name}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          legend = {
            displayMode = "table"
            placement   = "right"
            showLegend  = true
            values      = ["value"]
          }
          pieType = "donut"
          tooltip = {
            mode = "single"
            sort = "none"
          }
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              hideFrom = {
                tooltip = false
                viz     = false
                legend  = false
              }
            }
            mappings = []
          }
          overrides = []
        }
      },
      # Panel 6: Evidence by Policy Rule (Donut Chart)
      {
        id = 6
        title = "Evidence by Policy Rule"
        type = "piechart"
        gridPos = {
          h = 8
          w = 12
          x = 12
          y = 16
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        pluginVersion = "11.6.0"
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode   = "code"
          expr         = "sum by (policy_rule_id) (count_over_time({service_name=~\".+\"} [$__range]))"
          legendFormat = "{{policy_rule_id}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          legend = {
            displayMode = "table"
            placement   = "right"
            showLegend  = true
            values      = ["value"]
          }
          pieType = "donut"
          tooltip = {
            mode = "single"
            sort = "none"
          }
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              hideFrom = {
                tooltip = false
                viz     = false
                legend  = false
              }
            }
            mappings = []
          }
          overrides = []
        }
      },
      # Panel 7: Evidence Logs (Raw)
      {
        id = 7
        title = "Evidence Logs (Raw)"
        type = "logs"
        gridPos = {
          h = 12
          w = 24
          x = 0
          y = 34
        }
        datasource = {
          type = "loki"
          uid  = grafana_data_source.loki.uid
        }
        targets = [{
          datasource = {
            type = "loki"
            uid  = grafana_data_source.loki.uid
          }
          editorMode = "code"
          expr       = "{service_name=~\".+\"}"
          queryType  = "range"
          refId      = "A"
        }]
        options = {
          dedupStrategy       = "none"
          enableLogDetails    = true
          prettifyLogMessage  = true
          showCommonLabels    = false
          showLabels          = false
          showTime            = true
          sortOrder           = "Descending"
          wrapLogMessage      = false
        }
      }
    ]
  })
}

# Folder for organizing compliance alert rules
resource "grafana_folder" "compliance_alerts" {
  title = "Compliance Alerts"
}

# Slack contact point for alert notifications
resource "grafana_contact_point" "slack_compliance" {
  name = "Slack - Compliance Team"

  slack {
    url                      = var.slack_webhook_url
    disable_resolve_message  = true

    text = <<-EOT
:fire: *ALERT FIRING - Policy Evaluation Failures*

*Summary:* {{ .CommonAnnotations.summary }}
*Description:* {{ .CommonAnnotations.description }}

*Dashboard:* {{ .CommonAnnotations.dashboard_url }}
{{ range .Alerts -}}
{{ if .Values.B }}
*Failed Count:* {{ .Values.B }}
{{ end -}}
{{ end -}}

*Query to view failed logs in Grafana:*
{service_name=~".+"} | json | policy_evaluation_result="Failed"
    EOT

    title       = "ComplyBeacon Alert"
    username    = "ComplyBeacon"
    icon_emoji  = ":warning:"
  }
}

# Notification policy for routing alerts to Slack
resource "grafana_notification_policy" "compliance_alerts" {
  group_by      = ["alertname"]
  contact_point = grafana_contact_point.slack_compliance.name

  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"

  policy {
    matcher {
      label = "team"
      match = "="
      value = "compliance"
    }
    contact_point   = grafana_contact_point.slack_compliance.name
    group_by        = ["alertname"]
    group_wait      = "30s"
    group_interval  = "5m"
    repeat_interval = "4h"
  }
}

# Alert rule group for policy failure detection
resource "grafana_rule_group" "policy_failures" {
  name = "Policy Failure Detection"
  folder_uid = grafana_folder.compliance_alerts.uid
  # Convert alert_evaluation_interval from "1m" to seconds
  interval_seconds = tonumber(replace(replace(var.alert_evaluation_interval, "m", ""), "s", "")) * (can(regex("m$", var.alert_evaluation_interval)) ? 60 : 1)

  rule {
    name      = "Policy Evaluation Failures"
    condition = "C"
    for       = var.alert_for_duration

    # Query A: Count failed logs
    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = grafana_data_source.loki.uid
      model = jsonencode({
        editorMode = "code"
        expr       = "sum(count_over_time({service_name=~\".+\"} | json | policy_evaluation_result=\"Failed\" [5m]))"
        queryType  = "range"
        refId      = "A"
      })
    }

    # Query B: Reduce to single value
    data {
      ref_id = "B"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "A"
        reducer    = "last"
        type       = "reduce"
        refId      = "B"
      })
    }

    # Query C: Threshold - trigger if failures exceed threshold
    data {
      ref_id = "C"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [var.alert_failure_threshold - 1]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["B"]
            }
            type = "query"
          }
        ]
        datasource = {
          type = "grafana"
          uid  = "__expr__"
        }
        expression = "B"
        refId      = "C"
        type       = "threshold"
      })
    }

    annotations = {
      summary       = "Policy evaluation failures detected"
      description   = "One or more policy evaluations have failed. Check the Compliance Evidence Dashboard for details."
      dashboard_url = "${var.grafana_url}/d/compliance-evidence"
    }

    labels = {
      team     = "compliance"
      severity = "critical"
      service  = "complybeacon"
    }

    no_data_state  = "NoData"
    exec_err_state = "Alerting"
  }
}
