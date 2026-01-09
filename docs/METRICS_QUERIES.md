# Control Health Metrics Queries

This document provides LogQL queries for viewing control health metrics in Grafana Explore or dashboard panels.

## Basic Evidence Queries

### Total Evidence Count
```logql
# Total evidence records in time range
sum(count_over_time({service_name=~".+"} [$__range]))
```

### Evidence Count by Control ID
```logql
# Count evidence per control
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
)
```

### Evidence Rate by Control ID (Real-time)
```logql
# Evidence rate per control (evidence/sec)
sum by (compliance_control_id) (
  rate({service_name=~".+"} | json | compliance_control_id=~".+" [$__interval])
)
```

## Evidence by Result Type

### Evidence Count by Result
```logql
# Count evidence by evaluation result (Passed/Failed/etc)
sum by (policy_evaluation_result) (
  count_over_time({service_name=~".+"} | json | policy_evaluation_result=~".+" [$__range])
)
```

### Evidence Count by Control and Result
```logql
# Evidence count grouped by control and result
sum by (compliance_control_id, policy_evaluation_result) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and policy_evaluation_result=~".+" [$__range])
)
```

### Pass Rate by Control ID
```logql
# Calculate pass rate percentage per control
(
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and policy_evaluation_result="Passed" [$__range])
  ) 
  / 
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
  )
) * 100
```

### Failure Count by Control ID
```logql
# Count failures per control
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and policy_evaluation_result="Failed" [$__range])
)
```

## Evidence by Compliance Status

### Evidence Count by Compliance Status
```logql
# Count evidence by compliance status
sum by (compliance_status) (
  count_over_time({service_name=~".+"} | json | compliance_status=~".+" [$__range])
)
```

### Evidence Count by Control and Status
```logql
# Evidence grouped by control and compliance status
sum by (compliance_control_id, compliance_status) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and compliance_status=~".+" [$__range])
)
```

### Compliance Rate by Control ID
```logql
# Calculate compliance rate (Compliant / Total) per control
(
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and compliance_status="Compliant" [$__range])
  )
  /
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
  )
) * 100
```

## Time-Series Queries

### Evidence Over Time by Control
```logql
# Evidence count over time, grouped by control
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__interval])
)
```

### Evidence Rate Over Time by Control
```logql
# Evidence rate over time per control
sum by (compliance_control_id) (
  rate({service_name=~".+"} | json | compliance_control_id=~".+" [$__interval])
)
```

### Result Distribution Over Time
```logql
# Evaluation results over time
sum by (policy_evaluation_result) (
  rate({service_name=~".+"} | json | policy_evaluation_result=~".+" [$__interval])
)
```

### Compliance Status Over Time
```logql
# Compliance status distribution over time
sum by (compliance_status) (
  rate({service_name=~".+"} | json | compliance_status=~".+" [$__interval])
)
```

## SignalToMetrics Queries

If metrics are being exported successfully, you can query them using the `__name__` label:

### Total Evaluations Metric
```logql
# Query signaltometrics metric: compliance.control.evaluations
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | __name__="compliance.control.evaluations" [$__range])
)
```

### Evaluation Result Metric
```logql
# Query signaltometrics metric: compliance.control.evaluation.result
sum by (compliance_control_id, result) (
  count_over_time({service_name=~".+"} | json | __name__="compliance.control.evaluation.result" [$__range])
)
```

### Compliance Status Metric
```logql
# Query signaltometrics metric: compliance.control.status
sum by (compliance_control_id, status) (
  count_over_time({service_name=~".+"} | json | __name__="compliance.control.status" [$__range])
)
```

### Evaluation Rate from Metrics
```logql
# Evaluation rate from signaltometrics metrics
sum by (compliance_control_id) (
  rate({service_name=~".+"} | json | __name__="compliance.control.evaluations" [$__interval])
)
```

## Advanced Queries

### Top Controls by Evidence Count
```logql
# Top 10 controls by evidence count
topk(10, 
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
  )
)
```

### Controls with Failures
```logql
# Controls that have failures
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and policy_evaluation_result="Failed" [$__range])
) > 0
```

### Non-Compliant Controls
```logql
# Controls with non-compliant status
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and compliance_status="Non-Compliant" [$__range])
) > 0
```

### Evidence by Policy Engine
```logql
# Evidence count by policy engine
sum by (policy_engine_name) (
  count_over_time({service_name=~".+"} | json | policy_engine_name=~".+" [$__range])
)
```

### Evidence by Control Category
```logql
# Evidence count by control category
sum by (compliance_control_category) (
  count_over_time({service_name=~".+"} | json | compliance_control_category=~".+" [$__range])
)
```

### Health Score by Control
```logql
# Calculate health score: (Passed / Total) * 100 per control
(
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" and policy_evaluation_result="Passed" [$__range])
  )
  /
  sum by (compliance_control_id) (
    count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
  )
) * 100
```

## Filtering Queries

### Specific Control ID
```logql
# Evidence for a specific control
count_over_time({service_name=~".+"} | json | compliance_control_id="OSPS-QA-05.01" [$__range])
```

### Multiple Control IDs
```logql
# Evidence for multiple controls
count_over_time({service_name=~".+"} | json | compliance_control_id=~"OSPS-QA-05.01|OSPS-QA-06.02" [$__range])
```

### Failed Evaluations Only
```logql
# Only failed evaluations
{service_name=~".+"} | json | policy_evaluation_result="Failed"
```

### Non-Compliant Only
```logql
# Only non-compliant evidence
{service_name=~".+"} | json | compliance_status="Non-Compliant"
```

## Summary Queries

### Complete Control Health Summary
```logql
# Comprehensive summary: control, result, status, count
sum by (compliance_control_id, policy_evaluation_result, compliance_status) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
)
```

### Control Health Table
```logql
# Table view: control, total, passed, failed, compliant, non-compliant
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json | compliance_control_id=~".+" [$__range])
)
```

## Troubleshooting Queries

### Check if Enrichment is Working
```logql
# See if compliance_control_id exists
{service_name=~".+"} | json | compliance_control_id=~".+"
```

### Check Available Labels
```logql
# See all available labels
{service_name=~".+"} | json
```

### Check for Metrics
```logql
# Check if signaltometrics metrics exist
{service_name=~".+"} | json | __name__=~"compliance.control.*"
```

### Check Enrichment Status
```logql
# Check enrichment status
sum by (compliance_enrichment_status) (
  count_over_time({service_name=~".+"} | json | compliance_enrichment_status=~".+" [$__range])
)
```

## Using in Grafana

### In Explore
1. Go to http://localhost:3000/explore
2. Select **Loki** as data source
3. Paste any query above
4. Set time range (e.g., Last 5 minutes)
5. Click "Run query"

### In Dashboard Panels
1. Edit a panel
2. Add a query
3. Select **Loki** data source
4. Switch to "Code" mode
5. Paste query
6. Adjust visualization type (Time series, Table, Stat, etc.)

## Query Variables

Grafana provides these variables you can use:
- `$__range` - Selected time range (e.g., `5m`, `1h`)
- `$__interval` - Calculated interval for time series (e.g., `1m`)
- `$__from` - Start time (Unix timestamp)
- `$__to` - End time (Unix timestamp)

Example with variables:
```logql
sum by (compliance_control_id) (
  rate({service_name=~".+"} | json | compliance_control_id=~".+" [$__interval])
)
```
