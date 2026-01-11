# Running `complytime-collector-components`

## Choose exporters

We currently have Amazon S3, Grafana Loki, and SignalToMetrics (leveraging Loki)

**Amazon S3:** If choosing to export to an S3 Bucket, follow the instructions in SyncEvidence2Hyperproof.md
**Grafana Loki:**

1. Run `podman-compose down` to ensure you have no containers running
2. Delete all files in the `self-signed-cert` directory other than **openssl.cnf**
3. Run `make build`
4. Run `make generate-self-signed-cert`
5. If exporting to Amazon S3, export your credentials as environment variables. Do **NOT** commit these credentials to GitHub. This is for local testing ONLY.
6. Run `podman-compose up --build`
7. After waiting a few seconds and watching the debug output `podman-compose ps`
8. In another shell run `cd hack/demo/terraform` and `terraform init`, `terraform plan`, and `terraform apply`
9. Send evidence to backends using `curl` 