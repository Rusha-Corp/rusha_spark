#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path


JAR_VERSION = re.compile(
    r"(?P<artifact>.+)-(?P<version>\d+(?:\.\d+)+(?:[-+][A-Za-z0-9._+-]+)?)$"
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spark-jars", type=Path, default=Path("/opt/spark/jars"))
    parser.add_argument("--expected-hadoop", required=True)
    parser.add_argument("--expected-aws-sdk-v2", required=True)
    parser.add_argument("--expected-netty", required=True)
    parser.add_argument("--expected-derby", required=True)
    args = parser.parse_args()

    grouped: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for jar in args.spark_jars.glob("*.jar"):
        match = JAR_VERSION.fullmatch(jar.stem)
        if match is None:
            continue
        artifact = match.group("artifact")
        if artifact.startswith(("hadoop-", "aws-java-sdk-")) or artifact in {
            "bundle",
            "derby",
            "derbyshared",
            "derbytools",
        }:
            grouped[artifact].append((match.group("version"), jar.name))

    errors = []
    for artifact, entries in sorted(grouped.items()):
        if len(entries) > 1:
            errors.append(
                f"{artifact} appears more than once: {', '.join(name for _, name in entries)}"
            )

    required_hadoop = ("hadoop-client-api", "hadoop-client-runtime", "hadoop-aws")
    for artifact in required_hadoop:
        entries = grouped.get(artifact, [])
        if len(entries) != 1:
            errors.append(f"expected exactly one {artifact} jar, found {len(entries)}")
        elif entries[0][0] != args.expected_hadoop:
            errors.append(
                f"{entries[0][1]} does not match Hadoop {args.expected_hadoop}"
            )

    for artifact, entries in grouped.items():
        if artifact.startswith("hadoop-") and any(
            version != args.expected_hadoop for version, _ in entries
        ):
            errors.append(
                f"{artifact} jars must match Hadoop {args.expected_hadoop}: "
                + ", ".join(name for _, name in entries)
            )

    v1_sdk = [
        (artifact, version)
        for artifact, entries in grouped.items()
        if artifact.startswith("aws-java-sdk-")
        for version, _ in entries
    ]
    v1_versions = {version for _, version in v1_sdk}
    if len(v1_versions) > 1:
        errors.append(
            f"AWS SDK v1 artifacts have conflicting versions: {sorted(v1_versions)}"
        )
    if "aws-java-sdk-bundle" in grouped and len(v1_sdk) > 1:
        errors.append(
            "AWS SDK v1 bundle is present alongside individual AWS SDK v1 jars"
        )

    sdk_v2_bundle = grouped.get("bundle", [])
    if len(sdk_v2_bundle) != 1:
        errors.append(
            f"expected exactly one Hadoop AWS SDK v2 bundle, found {len(sdk_v2_bundle)}"
        )
    elif sdk_v2_bundle[0][0] != args.expected_aws_sdk_v2:
        errors.append(
            f"{sdk_v2_bundle[0][1]} does not match Hadoop AWS SDK v2 "
            f"{args.expected_aws_sdk_v2}"
        )

    for artifact in ("derby", "derbyshared", "derbytools"):
        entries = grouped.get(artifact, [])
        if len(entries) != 1:
            errors.append(f"expected exactly one {artifact} jar, found {len(entries)}")
        elif entries[0][0] != args.expected_derby:
            errors.append(f"{entries[0][1]} does not match Derby {args.expected_derby}")

    netty_handler_jars = list(
        args.spark_jars.glob(f"netty-handler-{args.expected_netty}.jar")
    )
    if len(netty_handler_jars) != 1:
        errors.append(
            f"expected exactly one Netty handler jar for {args.expected_netty}, "
            f"found {len(netty_handler_jars)}"
        )

    unexpected_netty = [
        jar.name
        for jar in args.spark_jars.glob("netty-*.jar")
        if not jar.name.startswith("netty-tcnative-")
        and f"-{args.expected_netty}" not in jar.stem
    ]
    if unexpected_netty:
        errors.append(
            f"Netty modules must use {args.expected_netty}: "
            + ", ".join(sorted(unexpected_netty))
        )

    if errors:
        print("Runtime jar validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"Validated Hadoop {args.expected_hadoop}, AWS SDK v2 {args.expected_aws_sdk_v2}, "
        f"Netty {args.expected_netty}, Derby {args.expected_derby}, "
        "and no duplicate Hadoop/AWS SDK jars."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
