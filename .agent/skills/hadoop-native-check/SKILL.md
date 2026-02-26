---
name: hadoop-native-check
description: Verify Hadoop native libraries are installed and discoverable.
disable-model-invocation: true
---

# Hadoop Native Library Check

## Steps
1. Confirm environment:
   - `echo $HADOOP_HOME`
   - `echo $LD_LIBRARY_PATH`
2. Verify native libs exist:
   - `ls -la /opt/hadoop/lib/native`
3. Run Hadoop native check:
   - `/opt/hadoop/bin/hadoop checknative -a`

## Success Criteria
- `libhadoop.so` and related libs are present under `/opt/hadoop/lib/native`.
- `hadoop checknative -a` reports native libs as available.
