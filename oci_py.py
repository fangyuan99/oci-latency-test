#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import os
import re
import subprocess
import sys
import unicodedata
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ENDPOINTS = [
    ("亚太地区", "日本东部", "东京", "objectstorage.ap-tokyo-1.oraclecloud.com"),
    ("亚太地区", "日本中部", "大阪", "objectstorage.ap-osaka-1.oraclecloud.com"),
    ("亚太地区", "韩国中部", "首尔", "objectstorage.ap-seoul-1.oraclecloud.com"),
    ("亚太地区", "韩国北部", "春川", "objectstorage.ap-chuncheon-1.oraclecloud.com"),
    ("亚太地区", "新加坡", "新加坡", "objectstorage.ap-singapore-1.oraclecloud.com"),
    ("亚太地区", "新加坡西部", "新加坡", "objectstorage.ap-singapore-2.oraclecloud.com"),
    ("亚太地区", "澳大利亚东部", "悉尼", "objectstorage.ap-sydney-1.oraclecloud.com"),
    ("亚太地区", "澳大利亚东南部", "墨尔本", "objectstorage.ap-melbourne-1.oraclecloud.com"),
    ("亚太地区", "印度西部", "孟买", "objectstorage.ap-mumbai-1.oraclecloud.com"),
    ("亚太地区", "印度南部", "海得拉巴", "objectstorage.ap-hyderabad-1.oraclecloud.com"),
    ("亚太地区", "印度尼西亚北部", "巴淡岛", "objectstorage.ap-batam-1.oraclecloud.com"),
    ("亚太地区", "马来西亚", "古来", "objectstorage.ap-kulai-2.oraclecloud.com"),
    ("亚太地区", "以色列中部", "耶路撒冷", "objectstorage.il-jerusalem-1.oraclecloud.com"),
    ("北美地区", "美国东部", "阿什本", "objectstorage.us-ashburn-1.oraclecloud.com"),
    ("北美地区", "美国中西部", "芝加哥", "objectstorage.us-chicago-1.oraclecloud.com"),
    ("北美地区", "美国西部", "凤凰城", "objectstorage.us-phoenix-1.oraclecloud.com"),
    ("北美地区", "美国西部", "圣何塞", "objectstorage.us-sanjose-1.oraclecloud.com"),
    ("北美地区", "加拿大东南部", "蒙特利尔", "objectstorage.ca-montreal-1.oraclecloud.com"),
    ("北美地区", "加拿大东南部", "多伦多", "objectstorage.ca-toronto-1.oraclecloud.com"),
    ("北美地区", "墨西哥中部", "克雷塔罗", "objectstorage.mx-queretaro-1.oraclecloud.com"),
    ("北美地区", "墨西哥东北部", "蒙特雷", "objectstorage.mx-monterrey-1.oraclecloud.com"),
    ("欧洲地区", "英国南部", "伦敦", "objectstorage.uk-london-1.oraclecloud.com"),
    ("欧洲地区", "英国西部", "纽波特", "objectstorage.uk-cardiff-1.oraclecloud.com"),
    ("欧洲地区", "德国中部", "法兰克福", "objectstorage.eu-frankfurt-1.oraclecloud.com"),
    ("欧洲地区", "瑞士北部", "苏黎世", "objectstorage.eu-zurich-1.oraclecloud.com"),
    ("欧洲地区", "瑞典中部", "斯德哥尔摩", "objectstorage.eu-stockholm-1.oraclecloud.com"),
    ("欧洲地区", "荷兰西北部", "阿姆斯特丹", "objectstorage.eu-amsterdam-1.oraclecloud.com"),
    ("欧洲地区", "法国中部", "巴黎", "objectstorage.eu-paris-1.oraclecloud.com"),
    ("欧洲地区", "法国南部", "马赛", "objectstorage.eu-marseille-1.oraclecloud.com"),
    ("欧洲地区", "西班牙中部", "马德里", "objectstorage.eu-madrid-1.oraclecloud.com"),
    ("欧洲地区", "西班牙中部", "马德里3", "objectstorage.eu-madrid-3.oraclecloud.com"),
    ("欧洲地区", "意大利西北部", "米兰", "objectstorage.eu-milan-1.oraclecloud.com"),
    ("欧洲地区", "意大利北部", "都灵", "objectstorage.eu-turin-1.oraclecloud.com"),
    ("中东地区", "阿联酋东部", "迪拜", "objectstorage.me-dubai-1.oraclecloud.com"),
    ("中东地区", "阿联酋中部", "阿布扎比", "objectstorage.me-abudhabi-1.oraclecloud.com"),
    ("中东地区", "沙特阿拉伯西部", "吉达", "objectstorage.me-jeddah-1.oraclecloud.com"),
    ("中东地区", "沙特阿拉伯中部", "利雅得", "objectstorage.me-riyadh-1.oraclecloud.com"),
    ("南美地区", "巴西东部", "圣保罗", "objectstorage.sa-saopaulo-1.oraclecloud.com"),
    ("南美地区", "巴西南部", "文郝多", "objectstorage.sa-vinhedo-1.oraclecloud.com"),
    ("南美地区", "智利中部", "圣地亚哥", "objectstorage.sa-santiago-1.oraclecloud.com"),
    ("南美地区", "智利西部", "瓦尔帕莱索", "objectstorage.sa-valparaiso-1.oraclecloud.com"),
    ("南美地区", "哥伦比亚中部", "波哥大", "objectstorage.sa-bogota-1.oraclecloud.com"),
    ("非洲地区", "南非中部", "约翰内斯堡", "objectstorage.af-johannesburg-1.oraclecloud.com"),
    ("非洲地区", "摩洛哥西部", "卡萨布兰卡", "objectstorage.af-casablanca-1.oraclecloud.com"),
]

LATENCY_PATTERNS = (
    re.compile(r"round-trip min/avg/max/stddev = [^/]+/([^/]+)/"),
    re.compile(r"rtt min/avg/max/mdev = [^/]+/([^/]+)/"),
)


@dataclass(slots=True)
class Result:
    region: str
    subregion: str
    city: str
    hostname: str
    avg_latency_ms: str
    status: str
    sort_key: float


def parse_positive_int(raw: str, name: str) -> int:
    if not raw.isdigit() or raw == "0":
        raise ValueError(f"{name} must be a positive integer.")
    return int(raw)


def build_output_path(raw_path: str) -> Path:
    input_path = Path(raw_path)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    suffix = input_path.suffix
    if suffix.lower() == ".csv":
        return input_path.with_name(f"{input_path.stem}_{timestamp}.csv")
    return input_path.with_name(f"{input_path.name}_{timestamp}.csv")


def extract_avg_latency(output: str) -> str | None:
    for line in output.splitlines():
        for pattern in LATENCY_PATTERNS:
            match = pattern.search(line)
            if match:
                return match.group(1)
    return None


def ping_host(endpoint: tuple[str, str, str, str], count: int) -> Result:
    region, subregion, city, hostname = endpoint
    print(f"Pinging {hostname} ...", flush=True)

    completed = subprocess.run(
        ["ping", "-c", str(count), hostname],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    output = f"{completed.stdout}\n{completed.stderr}"
    avg_latency = extract_avg_latency(output)

    if completed.returncode == 0 and avg_latency is not None:
        return Result(
            region=region,
            subregion=subregion,
            city=city,
            hostname=hostname,
            avg_latency_ms=avg_latency,
            status="ok",
            sort_key=float(avg_latency),
        )

    return Result(
        region=region,
        subregion=subregion,
        city=city,
        hostname=hostname,
        avg_latency_ms="N/A",
        status="failed",
        sort_key=999999.0,
    )


def write_csv(results: list[Result], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["region", "subregion", "city", "hostname", "avg_latency_ms", "status"])
        for result in results:
            writer.writerow(
                [
                    result.region,
                    result.subregion,
                    result.city,
                    result.hostname,
                    result.avg_latency_ms,
                    result.status,
                ]
            )


def display_width(text: str) -> int:
    width = 0
    for char in text:
        if unicodedata.combining(char):
            continue
        width += 2 if unicodedata.east_asian_width(char) in {"F", "W"} else 1
    return width


def pad(text: str, width: int, align: str = "left") -> str:
    padding = max(width - display_width(text), 0)
    if align == "right":
        return (" " * padding) + text
    return text + (" " * padding)


def format_rows(results: list[Result]) -> str:
    rows = [
        ["region", "subregion", "city", "hostname", "avg_latency_ms", "status"],
        *[
            [
                result.region,
                result.subregion,
                result.city,
                result.hostname,
                result.avg_latency_ms,
                result.status,
            ]
            for result in results
        ],
    ]

    widths = [display_width(cell) for cell in rows[0]]
    for row in rows[1:]:
        for index, value in enumerate(row):
            widths[index] = max(widths[index], display_width(value))

    formatted_rows: list[str] = []
    for row in rows:
        formatted_rows.append(
            "  ".join(
                pad(value, widths[index], "right" if index == 4 else "left")
                for index, value in enumerate(row)
            )
        )
    return "\n".join(formatted_rows)


def print_results(results: list[Result]) -> None:
    print(format_rows(results))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Ping OCI Object Storage endpoints and sort by average latency."
    )
    parser.add_argument("output", nargs="?", help="Optional CSV output path prefix or filename.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        count = parse_positive_int(os.getenv("COUNT", "4"), "COUNT")
        max_jobs = parse_positive_int(os.getenv("MAX_JOBS", "8"), "MAX_JOBS")
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    results: list[Result] = []
    with ThreadPoolExecutor(max_workers=max_jobs) as executor:
        futures = [executor.submit(ping_host, endpoint, count) for endpoint in ENDPOINTS]
        for future in as_completed(futures):
            results.append(future.result())

    results.sort(key=lambda item: item.sort_key)

    if args.output:
        output_path = build_output_path(args.output)
        write_csv(results, output_path)
        print(f"CSV written to {output_path}")
    else:
        print_results(results)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
