# OCI Latency Test
### 一个用于测试到甲骨文各区域延迟的轻量脚本项目

[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#)
[![Script](https://img.shields.io/badge/script-sh%20%7C%20PowerShell-blue.svg)](#)
[![Python](https://img.shields.io/badge/python-3.11%2B-green.svg)](https://www.python.org/)
[![uv](https://img.shields.io/badge/managed%20by-uv-6A5ACD.svg)](https://github.com/astral-sh/uv)
[![Linux.do](https://img.shields.io/badge/linux.do-Forum-orange?logo=discourse&logoColor=white)](https://linux.do)

[English](README.md) | 中文

## 项目简介

本项目用于测试到甲骨文各区域的延迟。它会对内置的 Oracle Cloud / OCI 区域节点执行 ping，计算平均延迟，并按延迟从低到高排序输出。你可以直接在终端查看结果，也可以导出带时间戳的 CSV 文件。

## 包含内容

- `oci.sh`：Linux / macOS 版 Shell 脚本
- `oci.ps1`：Windows PowerShell 版脚本
- `oci_py.py`：Python 实现版本

Python 版本只使用标准库，可以直接用 `python3` 运行，也可以用 `uv` 运行。

## 功能特性

- 内置多个甲骨文区域测试节点
- 支持并发探测，可调最大并发数
- 按平均延迟排序输出结果
- 支持导出带时间戳的 CSV 文件
- 对中文终端表格展示做了可读性处理

## 快速开始

### Linux / macOS

直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.sh | sh
```

导出 CSV：

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.sh | sh -s -- results.csv
```

Clone 后本地运行：

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
chmod +x oci.sh
./oci.sh
```

Clone 后导出 CSV：

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
chmod +x oci.sh
./oci.sh results.csv
```

### Windows PowerShell

直接运行：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.ps1)))
```

导出 CSV：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci.ps1))) .\results.csv
```

Clone 后本地运行：

```powershell
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
.\oci.ps1
```

Clone 后导出 CSV：

```powershell
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
.\oci.ps1 .\results.csv
```

### Python 3.11+（跨平台）

直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci_py.py | python3 -
```

导出 CSV：

```bash
curl -fsSL https://raw.githubusercontent.com/fangyuan99/oci-latency-test/main/oci_py.py | python3 - results.csv
```

Clone 后本地运行：

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
python3 oci_py.py
```

Clone 后导出 CSV：

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
python3 oci_py.py results.csv
```

Clone 后使用 `uv` 运行 Python 版本：

```bash
git clone https://github.com/fangyuan99/oci-latency-test.git
cd oci-latency-test
uv run python oci_py.py
```

## 环境变量

Shell 脚本和 Python 版本都支持以下环境变量：

- `COUNT`：每个节点的 ping 次数，默认 `4`
- `MAX_JOBS`：最大并发任务数，默认 `8`

示例：

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

## 输出说明

不传文件名时，会直接打印排序后的表格，例如：

```text
region    subregion    city    hostname    avg_latency_ms    status
...
```

传入输出文件名时，会生成带时间戳的新文件，例如：

```text
results_20260320_120000.csv
```

## 说明

- 上面的远程一键运行命令，需要先把仓库内容推送到 `main` 分支后才能直接使用
- `oci.sh` 依赖系统自带的 `ping`
- `oci.ps1` 使用 PowerShell 的 `Test-Connection`
- `oci_py.py` 需要 Python `3.11+`
- 探测失败的节点会标记为 `failed`，并排在结果末尾

## 测试节点

| 大区 | 分区 | 城市 | 节点链接 |
| --- | --- | --- | --- |
| 亚太地区 | 日本东部 | 东京 | `objectstorage.ap-tokyo-1.oraclecloud.com` |
| 亚太地区 | 日本中部 | 大阪 | `objectstorage.ap-osaka-1.oraclecloud.com` |
| 亚太地区 | 韩国中部 | 首尔 | `objectstorage.ap-seoul-1.oraclecloud.com` |
| 亚太地区 | 韩国北部 | 春川 | `objectstorage.ap-chuncheon-1.oraclecloud.com` |
| 亚太地区 | 新加坡 | 新加坡 | `objectstorage.ap-singapore-1.oraclecloud.com` |
| 亚太地区 | 新加坡西部 | 新加坡 | `objectstorage.ap-singapore-2.oraclecloud.com` |
| 亚太地区 | 澳大利亚东部 | 悉尼 | `objectstorage.ap-sydney-1.oraclecloud.com` |
| 亚太地区 | 澳大利亚东南部 | 墨尔本 | `objectstorage.ap-melbourne-1.oraclecloud.com` |
| 亚太地区 | 印度西部 | 孟买 | `objectstorage.ap-mumbai-1.oraclecloud.com` |
| 亚太地区 | 印度南部 | 海得拉巴 | `objectstorage.ap-hyderabad-1.oraclecloud.com` |
| 亚太地区 | 印度尼西亚北部 | 巴淡岛 | `objectstorage.ap-batam-1.oraclecloud.com` |
| 亚太地区 | 马来西亚 | 古来 | `objectstorage.ap-kulai-2.oraclecloud.com` |
| 亚太地区 | 以色列中部 | 耶路撒冷 | `objectstorage.il-jerusalem-1.oraclecloud.com` |
| 北美地区 | 美国东部 | 阿什本 | `objectstorage.us-ashburn-1.oraclecloud.com` |
| 北美地区 | 美国中西部 | 芝加哥 | `objectstorage.us-chicago-1.oraclecloud.com` |
| 北美地区 | 美国西部 | 凤凰城 | `objectstorage.us-phoenix-1.oraclecloud.com` |
| 北美地区 | 美国西部 | 圣何塞 | `objectstorage.us-sanjose-1.oraclecloud.com` |
| 北美地区 | 加拿大东南部 | 蒙特利尔 | `objectstorage.ca-montreal-1.oraclecloud.com` |
| 北美地区 | 加拿大东南部 | 多伦多 | `objectstorage.ca-toronto-1.oraclecloud.com` |
| 北美地区 | 墨西哥中部 | 克雷塔罗 | `objectstorage.mx-queretaro-1.oraclecloud.com` |
| 北美地区 | 墨西哥东北部 | 蒙特雷 | `objectstorage.mx-monterrey-1.oraclecloud.com` |
| 欧洲地区 | 英国南部 | 伦敦 | `objectstorage.uk-london-1.oraclecloud.com` |
| 欧洲地区 | 英国西部 | 纽波特 | `objectstorage.uk-cardiff-1.oraclecloud.com` |
| 欧洲地区 | 德国中部 | 法兰克福 | `objectstorage.eu-frankfurt-1.oraclecloud.com` |
| 欧洲地区 | 瑞士北部 | 苏黎世 | `objectstorage.eu-zurich-1.oraclecloud.com` |
| 欧洲地区 | 瑞典中部 | 斯德哥尔摩 | `objectstorage.eu-stockholm-1.oraclecloud.com` |
| 欧洲地区 | 荷兰西北部 | 阿姆斯特丹 | `objectstorage.eu-amsterdam-1.oraclecloud.com` |
| 欧洲地区 | 法国中部 | 巴黎 | `objectstorage.eu-paris-1.oraclecloud.com` |
| 欧洲地区 | 法国南部 | 马赛 | `objectstorage.eu-marseille-1.oraclecloud.com` |
| 欧洲地区 | 西班牙中部 | 马德里 | `objectstorage.eu-madrid-1.oraclecloud.com` |
| 欧洲地区 | 西班牙中部 | 马德里3 | `objectstorage.eu-madrid-3.oraclecloud.com` |
| 欧洲地区 | 意大利西北部 | 米兰 | `objectstorage.eu-milan-1.oraclecloud.com` |
| 欧洲地区 | 意大利北部 | 都灵 | `objectstorage.eu-turin-1.oraclecloud.com` |
| 中东地区 | 阿联酋东部 | 迪拜 | `objectstorage.me-dubai-1.oraclecloud.com` |
| 中东地区 | 阿联酋中部 | 阿布扎比 | `objectstorage.me-abudhabi-1.oraclecloud.com` |
| 中东地区 | 沙特阿拉伯西部 | 吉达 | `objectstorage.me-jeddah-1.oraclecloud.com` |
| 中东地区 | 沙特阿拉伯中部 | 利雅得 | `objectstorage.me-riyadh-1.oraclecloud.com` |
| 南美地区 | 巴西东部 | 圣保罗 | `objectstorage.sa-saopaulo-1.oraclecloud.com` |
| 南美地区 | 巴西南部 | 文郝多 | `objectstorage.sa-vinhedo-1.oraclecloud.com` |
| 南美地区 | 智利中部 | 圣地亚哥 | `objectstorage.sa-santiago-1.oraclecloud.com` |
| 南美地区 | 智利西部 | 瓦尔帕莱索 | `objectstorage.sa-valparaiso-1.oraclecloud.com` |
| 南美地区 | 哥伦比亚中部 | 波哥大 | `objectstorage.sa-bogota-1.oraclecloud.com` |
| 非洲地区 | 南非中部 | 约翰内斯堡 | `objectstorage.af-johannesburg-1.oraclecloud.com` |
| 非洲地区 | 摩洛哥西部 | 卡萨布兰卡 | `objectstorage.af-casablanca-1.oraclecloud.com` |

## 开源协议

本项目基于 MIT License 开源，详见 `LICENSE` 文件。
