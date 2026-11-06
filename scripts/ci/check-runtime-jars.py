#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path


JAR_VERSION = re.compile(r"(?P<artifact>.+)-(?P<version>\d+(?:\.\d+)+(?:[-+][A-Za-z0-9._+-]+)?)$")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spark-jars", type=Path, default=Path("/opt/spark/jars"))
    parser.add_argument("--expected-hadoop", required=True)
    parser.add_argument("--expected-aws-sdk-v2", required=True)
    args = parser.parse_args()

    grouped: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for jar in args.spark_jars.glob("*.jar"):
        match = JAR_VERSION.fullmatch(jar.stem)
        if match is None:
            continue
        artifact = match.group("artifact")
        if artifact.startswith(("hadoop-", "aws-java-sdk-")) or artifact == "bundle":
            grouped[artifact].append((match.group("version"), jar.name))

    errors = []
    for artifact, entries in sorted(grouped.items()):
        if len(entries) > 1:
            errors.append(f"{artifact} appears more than once: {', '.join(name for _, name in entries)}")

    required_hadoop = ("hadoop-client-api", "hadoop-client-runtime", "hadoop-aws")
    for artifact in required_hadoop:
        entries = grouped.get(artifact, [])
        if len(entries) != 1:
            errors.append(f"expected exactly one {artifact} jar, found {len(entries)}")
        elif entries[0][0] != args.expected_hadoop:
            errors.append(f"{entries[0][1]} does not match Hadoop {args.expected_hadoop}")

    for artifact, entries in grouped.items():
        if artifact.startswith("hadoop-") and any(version != args.expected_hadoop for version, _ in entries):
            errors.append(
                f"{artifact} jars must match Hadoop {args.expected_hadoop}: "
                + ", ".join(name for _, name in entries)
            )

    v1_sdk = [(artifact, version) for artifact, entries in grouped.items() if artifact.startswith("aws-java-sdk-") for version, _ in entries]
    v1_versions = {version for _, version in v1_sdk}
    if len(v1_versions) > 1:
        errors.append(f"AWS SDK v1 artifacts have conflicting versions: {sorted(v1_versions)}")
    if "aws-java-sdk-bundle" in grouped and len(v1_sdk) > 1:
        errors.append("AWS SDK v1 bundle is present alongside individual AWS SDK v1 jars")

    sdk_v2_bundle = grouped.get("bundle", [])
    if len(sdk_v2_bundle) != 1:
        errors.append(f"expected exactly one Hadoop AWS SDK v2 bundle, found {len(sdk_v2_bundle)}")
    elif sdk_v2_bundle[0][0] != args.expected_aws_sdk_v2:
        errors.append(
            f"{sdk_v2_bundle[0][1]} does not match Hadoop AWS SDK v2 "
            f"{args.expected_aws_sdk_v2}"
        )

    if errors:
        print("Runtime jar validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"Validated Hadoop {args.expected_hadoop}, AWS SDK v2 {args.expected_aws_sdk_v2}, "
        "and no duplicate Hadoop/AWS SDK jars."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
