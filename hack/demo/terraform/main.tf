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
# Note: These datasources are created by Docker Compose and imported into Terraform
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

# Local variables
locals {
  loki_ds_uid = grafana_data_source.loki.uid
}

# Compliance Evidence Dashboard
# Managed inline with HCL for dynamic Terraform references and full IaC capabilities
resource "grafana_dashboard" "compliance_evidence" {
  overwrite = true

  config_json = jsonencode({
    title                = "Compliance Evidence Dashboard"
    uid                  = "compliance-evidence"
    tags                 = ["compliance", "evidence", "policy"]
    timezone             = "browser"
    schemaVersion        = 39
    version              = 0
    refresh              = ""
    editable             = true
    fiscalYearStartMonth = 0
    graphTooltip         = 0
    liveNow              = false

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
        id    = 1
        title = "Total Evidence Records"
        type  = "stat"
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
          # Count enriched evidence logs (have policy_evaluation_result from truthbeam - signaltometrics logs don't have this)
          expr       = "sum(count_over_time({service_name=~\".+\"} | json | policy_evaluation_result=~\".+\" [$__range]))"
          queryType  = "range"
          refId      = "A"
        }]
        options = {
          colorMode   = "value"
          graphMode   = "area"
          justifyMode = "auto"
          orientation = "auto"
          textMode    = "auto"
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
        id    = 2
        title = "Policy Evaluation Results"
        type  = "piechart"
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
          # Query enriched evidence logs (have policy_evaluation_result from truthbeam - signaltometrics logs don't have this)
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} | json | policy_evaluation_result=~\".+\" [$__range]))"
          legendFormat = "{{policy_evaluation_result}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          "displayLabels" : [
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
        id    = 3
        title = "Evaluation Results Summary"
        type  = "table"
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
          # Query enriched evidence logs (have policy_evaluation_result from truthbeam - signaltometrics logs don't have this)
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} | json | policy_evaluation_result=~\".+\" [$__range]))"
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
        id    = 4
        title = "Policy Evaluation Over Time"
        type  = "timeseries"
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
          # Query enriched evidence logs (have policy_evaluation_result from truthbeam - signaltometrics logs don't have this)
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} | json | policy_evaluation_result=~\".+\" [$__interval]))"
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
        id    = 5
        title = "Evidence by Policy Engine"
        type  = "piechart"
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
          # Query enriched evidence logs (have policy_engine_name from truthbeam - signaltometrics logs don't have policy_evaluation_result)
          expr         = "sum by (policy_engine_name) (count_over_time({service_name=~\".+\"} | json | policy_engine_name=~\".+\" and policy_evaluation_result=~\".+\" [$__range]))"
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
        id    = 6
        title = "Evidence by Policy Rule"
        type  = "piechart"
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
          # Query enriched evidence logs (have policy_rule_id from truthbeam - signaltometrics logs don't have policy_evaluation_result)
          expr         = "sum by (policy_rule_id) (count_over_time({service_name=~\".+\"} | json | policy_rule_id=~\".+\" and policy_evaluation_result=~\".+\" [$__range]))"
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
        id    = 7
        title = "Evidence Logs (Raw)"
        type  = "logs"
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
          dedupStrategy      = "none"
          enableLogDetails   = true
          prettifyLogMessage = true
          showCommonLabels   = false
          showLabels         = false
          showTime           = true
          sortOrder          = "Descending"
          wrapLogMessage     = false
        }
      },
      # Panel 8: Evidence Count by Control (Real-time)
      {
        id    = 8
        title = "Evidence Count by Control (Real-time)"
        type  = "timeseries"
        gridPos = {
          h = 8
          w = 12
          x = 0
          y = 46
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
          # Query enriched logs: real-time evidence rate per control (uses compliance_control_id from truthbeam when available, otherwise policy_rule_id)
          expr         = "sum by (compliance_control_id, policy_rule_id) (rate({service_name=~\".+\"} | json | policy_evaluation_result=~\".+\" and policy_rule_id=~\".+\" [$__interval]))"
          legendFormat = "{{compliance_control_id}} ({{policy_rule_id}})"
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
              axisCenteredZero  = false
              axisColorMode     = "text"
              axisLabel         = "Evidence/sec"
              axisPlacement     = "auto"
              drawStyle         = "line"
              fillOpacity       = 20
              gradientMode      = "none"
              lineInterpolation = "smooth"
              lineWidth         = 3
              pointSize         = 10
              scaleDistribution = {
                type = "linear"
              }
              showPoints = "always"
              spanNulls  = false
            }
            unit = "ops/sec"
          }
          overrides = []
        }
      },
      # Panel 9: Total Evidence Count by Control
      {
        id    = 9
        title = "Total Evidence Count by Control"
        type  = "stat"
        gridPos = {
          h = 8
          w = 12
          x = 12
          y = 46
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
          # Query enriched logs: total evidence count per control (uses policy_rule_id)
          expr         = "sum by (policy_rule_id) (count_over_time({service_name=~\".+\"} | json | policy_rule_id=~\".+\" [$__range]))"
          legendFormat = "{{policy_rule_id}}"
          queryType    = "range"
          refId        = "A"
        }]
        options = {
          colorMode   = "value"
          graphMode   = "area"
          justifyMode = "auto"
          orientation = "auto"
          textMode    = "auto"
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
            unit = "short"
          }
          overrides = []
        }
      },
      # Panel 19: Control Health - Evidence by Result (Pie Chart)
      {
        id    = 19
        title = "Control Health: Evidence by Result (Pie Chart)"
        type  = "piechart"
        gridPos = {
          h = 8
          w = 12
          x = 12
          y = 94
        }
        datasource = {
          type = "loki"
          uid  = local.loki_ds_uid
        }
        targets = [{
          datasource = {
            type = "loki"
            uid  = local.loki_ds_uid
          }
          expr         = "sum by (policy_evaluation_result) (count_over_time({service_name=~\".+\"} | json | policy_evaluation_result=~\".+\" [$__range]))"
          legendFormat = "{{policy_evaluation_result}}"
          refId        = "A"
        }]
        options = {
          legend = {
            calcs       = []
            displayMode = "table"
            placement   = "right"
            showLegend  = true
            values      = ["value", "percent"]
          }
          tooltip = {
            mode = "single"
            sort = "none"
          }
          pieType = "pie"
          reduceOptions = {
            values = false
            calcs  = ["lastNotNull"]
            fields = ""
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
            unit = "short"
          }
          overrides = [
            {
              matcher = {
                id      = "byRegexp"
                options = ".*Passed.*"
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
                id      = "byRegexp"
                options = ".*Failed.*"
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
                id      = "byRegexp"
                options = ".*Not Run.*"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "gray"
                    mode       = "fixed"
                  }
                }
              ]
            },
            {
              matcher = {
                id      = "byRegexp"
                options = ".*Needs Review.*"
              }
              properties = [
                {
                  id = "color"
                  value = {
                    fixedColor = "yellow"
                    mode       = "fixed"
                  }
                }
              ]
            }
          ]
        }
      },
      # Panel 21: Control IDs by Rule (Lightweight)
      {
        id    = 21
        title = "Control Health: Assessment Requirements and Evidence Count per Control ID"
        type  = "table"
        gridPos = {
          h = 8
          w = 24
          x = 0
          y = 110
        }
        datasource = {
          type = "loki"
          uid  = local.loki_ds_uid
        }
        targets = [{
          datasource = {
            type = "loki"
            uid  = local.loki_ds_uid
          }
          expr    = "sum by (compliance_control_id, policy_rule_id, policy_config_include) (count_over_time({service_name=~\".+\"} | json | policy_config_include=~\".+\" [$__range]))"
          format  = "table"
          instant = true
          refId   = "A"
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
              displayName = "Evidence Count"
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
                compliance_control_id = true
              }
              indexByName = {}
              renameByName = {
                policy_rule_id        = "Control ID"
                policy_config_include = "Assessment Requirement"
                Value                 = "Evidence Count"
                "Value #A"            = "Evidence Count"
              }
            }
          }
        ]
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
                  color = "text"
                  value = null
                }
              ]
            }
            unit = "short"
          }
          overrides = []
        }
      }
    ]
  })
}
