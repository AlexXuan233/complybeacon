# How to Populate Metrics on Grafana Dashboard

## Problem: Dashboard Shows "No Data"

If your Grafana dashboard panels show "No Data", follow these steps:

## Step 1: Verify Logs Are in Loki

1. Open Grafana (http://localhost:3000)
2. Go to **Explore** (compass icon on left)
3. Select **Loki** as data source
4. Run this query:
   ```logql
   {service_name=~".+"}
   ```
5. You should see log entries. If not, send test evidence:
   ```bash
   bash hack/sampledata/send-all-evidence.sh
   ```

## Step 2: Check Attribute Names

The enriched attributes from truthbeam use **dots** (e.g., `compliance.control.id`), but Loki might convert them to **underscores** (`compliance_control_id`).

1. In Grafana Explore, run:
   ```logql
   {service_name=~".+"} | json
   ```
2. Click on a log entry to expand it
3. Look for these fields:
   - `compliance_control_id` OR `compliance.control.id`
   - `policy_evaluation_result` OR `policy.evaluation.result`
   - `compliance_status` OR `compliance.status`

## Step 3: Update Queries Based on Actual Format

### If attributes use UNDERSCORES (compliance_control_id):

The current queries should work. If not, try:
```logql
sum by (compliance_control_id) (count_over_time({service_name=~".+"} | json [$__range]))
```

### If attributes use DOTS (compliance.control.id):

Update queries to escape dots:
```logql
sum by (compliance\\.control\\.id) (count_over_time({service_name=~".+"} | json [$__range]))
```

### If attributes are in resource attributes (not JSON body):

Try querying without JSON parsing:
```logql
sum by (compliance_control_id) (count_over_time({service_name=~".+", compliance_control_id=~".+"} [$__range]))
```

## Step 4: Apply Terraform Changes

After verifying the attribute format:

```bash
cd hack/demo/terraform
terraform apply
```

This updates the dashboard panels with the correct queries.

## Step 5: Verify Enrichment is Working

Check collector logs to ensure truthbeam is enriching:
```bash
podman-compose logs collector | grep -i "truthbeam\|enrichment\|compliance"
```

You should see:
- No errors about missing attributes
- Enrichment status = "success"
- Compliance attributes being added

## Step 6: Send Test Evidence

If logs exist but aren't enriched:
```bash
bash hack/sampledata/send-all-evidence.sh
```

Wait a few seconds, then check Grafana dashboard again.

## Common Issues

### Issue 1: Attributes Not in JSON Body

**Symptom**: `| json | compliance_control_id=~".+"` returns nothing

**Solution**: Attributes might be in resource attributes. Try:
```logql
{service_name=~".+"} | json | line_format "{{.compliance_control_id}}"
```

### Issue 2: Attribute Names Don't Match

**Symptom**: Queries return empty but logs exist

**Solution**: Check actual attribute names in Grafana Explore, then update queries accordingly.

### Issue 3: No Enrichment

**Symptom**: Logs exist but no compliance attributes

**Solution**: 
1. Check Compass API is running: `podman-compose ps compass`
2. Check collector logs for truthbeam errors
3. Verify policy.rule.id is being extracted correctly

## Quick Test Query

Run this in Grafana Explore to test:
```logql
sum by (compliance_control_id) (
  count_over_time({service_name=~".+"} | json [$__range])
)
```

If this returns data, the dashboard queries should work. If not, check the attribute names and update queries accordingly.
