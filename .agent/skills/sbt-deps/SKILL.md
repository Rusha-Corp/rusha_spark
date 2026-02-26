---
name: sbt-deps
description: Validate SBT dependencies, resolve artifacts, and ensure jars land in target/lib.
disable-model-invocation: true
---

# SBT Dependency Validation

## Steps
1. Run `sbt update` to resolve dependencies.
2. Run `sbt compile` (this triggers `copyDependencies`).
3. Verify jars were copied to `target/lib`:
   - `ls -la target/lib`

## Success Criteria
- `sbt update` and `sbt compile` succeed.
- `target/lib` contains the expected Spark/Delta/Iceberg/Nessie jars.
