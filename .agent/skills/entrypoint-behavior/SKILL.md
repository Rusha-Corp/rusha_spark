---
name: entrypoint-behavior
description: Explain and test container startup behavior and entrypoint scripts.
disable-model-invocation: true
---

# Entrypoint Behavior

## Steps
1. Confirm image CMD/ENTRYPOINT:
   - `docker inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' <image>`
2. Verify scripts exist and are executable:
   - `ls -la /start_thrift_server.sh /start-spark.sh`
3. Test Spark master/worker script via `SPARK_WORKLOAD`:
   - `SPARK_WORKLOAD=master /start-spark.sh`

## Success Criteria
- CMD is `bash` (manual invocation required).
- Scripts are present and executable.
- Spark workload script runs without errors for `master` or `worker`.
