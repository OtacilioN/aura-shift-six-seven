#!/usr/bin/env python3
"""Verify that an Android App Bundle contains one coherent AdMob mode."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree


TEST_REWARDED_ID = "ca-app-pub-3940256099942544/5224354917"
PRODUCTION_APP_ID = "ca-app-pub-1879801690271355~3301040623"
PRODUCTION_REWARDED_IDS = (
    "ca-app-pub-1879801690271355/8535542665",
    "ca-app-pub-1879801690271355/7922811916",
)


def encoded(value: str) -> bytes:
    return value.encode("utf-8")


def require(payload: bytes, value: str, location: str) -> None:
    if encoded(value) not in payload:
        raise ValueError(f"missing {value} in {location}")


def reject(payload: bytes, value: str, location: str) -> None:
    if encoded(value) in payload:
        raise ValueError(f"unexpected {value} in {location}")


def dump_manifest(bundle: Path, bundletool: Path) -> ElementTree.Element:
    if not bundletool.is_file():
        raise ValueError(f"bundletool not found: {bundletool}")
    result = subprocess.run(
        [
            "java",
            "-jar",
            str(bundletool),
            "dump",
            "manifest",
            f"--bundle={bundle}",
            "--module=base",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        raise ValueError(f"bundletool manifest dump failed: {message}")
    try:
        return ElementTree.fromstring(result.stdout)
    except ElementTree.ParseError as error:
        raise ValueError("bundletool returned an invalid manifest") from error


def verify_signature(bundle: Path) -> None:
    environment = dict(os.environ, LC_ALL="C", LANG="C")
    result = subprocess.run(
        ["jarsigner", "-verify", str(bundle)],
        check=False,
        capture_output=True,
        text=True,
        env=environment,
    )
    output = f"{result.stdout}\n{result.stderr}".lower()
    if result.returncode != 0 or "jar verified" not in output:
        raise ValueError("bundle signature verification failed")


def verify_manifest(
    root: ElementTree.Element,
    *,
    package: str,
    version_name: str,
    version_code: int,
) -> None:
    android = "{http://schemas.android.com/apk/res/android}"
    actual = {
        "package": root.attrib.get("package"),
        "versionName": root.attrib.get(f"{android}versionName"),
        "versionCode": root.attrib.get(f"{android}versionCode"),
    }
    expected = {
        "package": package,
        "versionName": version_name,
        "versionCode": str(version_code),
    }
    if actual != expected:
        raise ValueError(f"manifest identity mismatch: {actual} != {expected}")

    app_ids = [
        element.attrib.get(f"{android}value")
        for element in root.findall("./application/meta-data")
        if element.attrib.get(f"{android}name")
        == "com.google.android.gms.ads.APPLICATION_ID"
    ]
    if app_ids != [PRODUCTION_APP_ID]:
        raise ValueError(
            "AdMob manifest metadata must contain only the Aura Shift app ID: "
            f"{app_ids}"
        )


def verify(
    bundle: Path,
    mode: str,
    *,
    bundletool: Path,
    package: str,
    version_name: str,
    version_code: int,
) -> None:
    if not bundle.is_file():
        raise ValueError(f"bundle not found: {bundle}")

    root = dump_manifest(bundle, bundletool)
    verify_manifest(
        root,
        package=package,
        version_name=version_name,
        version_code=version_code,
    )
    verify_signature(bundle)

    with zipfile.ZipFile(bundle) as archive:
        runtime_names = sorted(
            name
            for name in archive.namelist()
            if name.startswith("base/lib/") and name.endswith("/libapp.so")
        )
        if not runtime_names:
            raise ValueError("bundle has no base/lib/*/libapp.so runtime")
        runtimes = b"".join(archive.read(name) for name in runtime_names)

    if mode == "test":
        require(runtimes, TEST_REWARDED_ID, "libapp.so")
        for unit_id in PRODUCTION_REWARDED_IDS:
            reject(runtimes, unit_id, "libapp.so")
    else:
        for unit_id in PRODUCTION_REWARDED_IDS:
            require(runtimes, unit_id, "libapp.so")
        reject(runtimes, TEST_REWARDED_ID, "libapp.so")

    print(
        f"AdMob bundle verification passed: mode={mode}, "
        f"abis={len(runtime_names)}, bundle={bundle}"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--mode", choices=("test", "production"), required=True)
    parser.add_argument("--bundletool", type=Path, required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--version-code", type=int, required=True)
    args = parser.parse_args()
    try:
        verify(
            args.bundle,
            args.mode,
            bundletool=args.bundletool,
            package=args.package,
            version_name=args.version_name,
            version_code=args.version_code,
        )
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"AdMob bundle verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
