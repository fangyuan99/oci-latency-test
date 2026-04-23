# OCI Latency Test
### Lightweight scripts for testing latency to Oracle Cloud regional endpoints

[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#)
[![Script](https://img.shields.io/badge/script-sh%20%7C%20PowerShell-blue.svg)](#)
[![Python](https://img.shields.io/badge/python-3.11%2B-green.svg)](https://www.python.org/)
[![uv](https://img.shields.io/badge/managed%20by-uv-6A5ACD.svg)](https://github.com/astral-sh/uv)
[![Linux.do](https://img.shields.io/badge/linux.do-Forum-orange?logo=discourse&logoColor=white)](https://linux.do)

English | [中文](README_ZH.md)

## Overview

This project is used to test latency to Oracle Cloud regional endpoints. It pings built-in Oracle Cloud / OCI regional hosts, calculates average latency, sorts the results from low to high, and prints a readable table or exports a timestamped CSV file.

## Included Scripts

- `oci.sh` for Linux and macOS shells
- `oci.ps1` for Windows PowerShell
- `oci_py.py` as a Python implementation

The Python version uses only the standard library. You can run it with `uv` or directly with `python3`.

## Features

- Built-in Oracle Cloud regional test endpoints
- Concurrent probing with configurable parallelism
- Sorted output by average latency
- Optional CSV export with timestamp suffix
- Readable terminal table output

## Quick Start

### Linux / macOS

Run directly:

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.sh | sh
```

Export CSV:

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.sh | sh -s -- results.csv
```

Clone and run locally:

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
chmod +x oci.sh
./oci.sh
```

Export CSV after cloning:

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
chmod +x oci.sh
./oci.sh results.csv
```

### Windows PowerShell

Run directly:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.ps1)))
```

Export CSV:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.ps1))) .\results.csv
```

Clone and run locally:

```powershell
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
.\oci.ps1
```

Export CSV after cloning:

```powershell
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
.\oci.ps1 .\results.csv
```

### Python 3.11+ (Cross-Platform)

Run directly:

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci_py.py | python3 -
```

Export CSV:

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci_py.py | python3 - results.csv
```

Clone and run locally:

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
python3 oci_py.py
```

Export CSV after cloning:

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
python3 oci_py.py results.csv
```

Run with `uv` after cloning:

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
uv run python oci_py.py
```

## Environment Variables

Both shell scripts and the Python version support these environment variables:

- `COUNT`: ping count per endpoint, default `4`
- `MAX_JOBS`: max concurrent jobs, default `8`

Examples:

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.sh | env COUNT=6 MAX_JOBS=12 sh
```

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci_py.py | env COUNT=6 MAX_JOBS=12 python3 -
```

```powershell
$env:COUNT = 6
$env:MAX_JOBS = 12
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.ps1)))
```

## Output

Without an argument, the scripts print a sorted table like:

```text
region    subregion    city    hostname    avg_latency_ms    status
...
```

With an output filename, the project writes a timestamped CSV file such as:

```text
results_20260320_120000.csv
```

## Notes

- The one-line remote commands above require the repository contents to be pushed to the `main` branch first.
- `oci.sh` depends on the system `ping` command.
- `oci.ps1` uses PowerShell `Test-Connection`.
- `oci_py.py` requires Python `3.11+`.
- Failed probes are marked as `failed` and sorted to the end of the result list.

## Test Nodes

| Region | Subregion | City | Endpoint |
| --- | --- | --- | --- |
| Asia Pacific | Japan East | Tokyo | `objectstorage.ap-tokyo-1.oraclecloud.com` |
| Asia Pacific | Japan Central | Osaka | `objectstorage.ap-osaka-1.oraclecloud.com` |
| Asia Pacific | South Korea Central | Seoul | `objectstorage.ap-seoul-1.oraclecloud.com` |
| Asia Pacific | South Korea North | Chuncheon | `objectstorage.ap-chuncheon-1.oraclecloud.com` |
| Asia Pacific | Singapore | Singapore | `objectstorage.ap-singapore-1.oraclecloud.com` |
| Asia Pacific | Singapore West | Singapore | `objectstorage.ap-singapore-2.oraclecloud.com` |
| Asia Pacific | Australia East | Sydney | `objectstorage.ap-sydney-1.oraclecloud.com` |
| Asia Pacific | Australia Southeast | Melbourne | `objectstorage.ap-melbourne-1.oraclecloud.com` |
| Asia Pacific | India West | Mumbai | `objectstorage.ap-mumbai-1.oraclecloud.com` |
| Asia Pacific | India South | Hyderabad | `objectstorage.ap-hyderabad-1.oraclecloud.com` |
| Asia Pacific | Indonesia North | Batam | `objectstorage.ap-batam-1.oraclecloud.com` |
| Asia Pacific | Malaysia | Kulai | `objectstorage.ap-kulai-2.oraclecloud.com` |
| Asia Pacific | Israel Central | Jerusalem | `objectstorage.il-jerusalem-1.oraclecloud.com` |
| North America | US East | Ashburn | `objectstorage.us-ashburn-1.oraclecloud.com` |
| North America | US Midwest | Chicago | `objectstorage.us-chicago-1.oraclecloud.com` |
| North America | US West | Phoenix | `objectstorage.us-phoenix-1.oraclecloud.com` |
| North America | US West | San Jose | `objectstorage.us-sanjose-1.oraclecloud.com` |
| North America | Canada Southeast | Montreal | `objectstorage.ca-montreal-1.oraclecloud.com` |
| North America | Canada Southeast | Toronto | `objectstorage.ca-toronto-1.oraclecloud.com` |
| North America | Mexico Central | Queretaro | `objectstorage.mx-queretaro-1.oraclecloud.com` |
| North America | Mexico Northeast | Monterrey | `objectstorage.mx-monterrey-1.oraclecloud.com` |
| Europe | UK South | London | `objectstorage.uk-london-1.oraclecloud.com` |
| Europe | UK West | Newport | `objectstorage.uk-cardiff-1.oraclecloud.com` |
| Europe | Germany Central | Frankfurt | `objectstorage.eu-frankfurt-1.oraclecloud.com` |
| Europe | Switzerland North | Zurich | `objectstorage.eu-zurich-1.oraclecloud.com` |
| Europe | Sweden Central | Stockholm | `objectstorage.eu-stockholm-1.oraclecloud.com` |
| Europe | Netherlands Northwest | Amsterdam | `objectstorage.eu-amsterdam-1.oraclecloud.com` |
| Europe | France Central | Paris | `objectstorage.eu-paris-1.oraclecloud.com` |
| Europe | France South | Marseille | `objectstorage.eu-marseille-1.oraclecloud.com` |
| Europe | Spain Central | Madrid | `objectstorage.eu-madrid-1.oraclecloud.com` |
| Europe | Spain Central | Madrid 3 | `objectstorage.eu-madrid-3.oraclecloud.com` |
| Europe | Italy Northwest | Milan | `objectstorage.eu-milan-1.oraclecloud.com` |
| Europe | Italy North | Turin | `objectstorage.eu-turin-1.oraclecloud.com` |
| Middle East | UAE East | Dubai | `objectstorage.me-dubai-1.oraclecloud.com` |
| Middle East | UAE Central | Abu Dhabi | `objectstorage.me-abudhabi-1.oraclecloud.com` |
| Middle East | Saudi Arabia West | Jeddah | `objectstorage.me-jeddah-1.oraclecloud.com` |
| Middle East | Saudi Arabia Central | Riyadh | `objectstorage.me-riyadh-1.oraclecloud.com` |
| South America | Brazil East | Sao Paulo | `objectstorage.sa-saopaulo-1.oraclecloud.com` |
| South America | Brazil South | Vinhedo | `objectstorage.sa-vinhedo-1.oraclecloud.com` |
| South America | Chile Central | Santiago | `objectstorage.sa-santiago-1.oraclecloud.com` |
| South America | Chile West | Valparaiso | `objectstorage.sa-valparaiso-1.oraclecloud.com` |
| South America | Colombia Central | Bogota | `objectstorage.sa-bogota-1.oraclecloud.com` |
| Africa | South Africa Central | Johannesburg | `objectstorage.af-johannesburg-1.oraclecloud.com` |
| Africa | Morocco West | Casablanca | `objectstorage.af-casablanca-1.oraclecloud.com` |

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
