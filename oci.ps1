Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CountValue = if ($env:COUNT) { $env:COUNT } else { '4' }
$MaxJobsValue = if ($env:MAX_JOBS) { $env:MAX_JOBS } else { '8' }
$TestUrlValue = if ($env:TEST_URL) { $env:TEST_URL } else { 'https://{hostname}/' }
$OutputArg = if ($args.Count -gt 0) { $args[0] } else { $null }

function Get-PositiveInteger {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value,
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ($Value -notmatch '^[1-9][0-9]*$') {
        throw "$Name must be a positive integer."
    }

    return [int] $Value
}

function Get-OutputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InputPath
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $directory = Split-Path -Path $InputPath -Parent
    $fileName = Split-Path -Path $InputPath -Leaf

    if ([string]::IsNullOrEmpty($directory)) {
        $directory = '.'
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $extension = [System.IO.Path]::GetExtension($fileName)

    if ($extension -ieq '.csv') {
        $outputName = '{0}_{1}.csv' -f $baseName, $timestamp
    }
    else {
        $outputName = '{0}_{1}.csv' -f $fileName, $timestamp
    }

    return Join-Path -Path $directory -ChildPath $outputName
}

function Get-DisplayWidth {
    param(
        [AllowNull()]
        [string] $Text
    )

    if ($null -eq $Text) {
        return 0
    }

    $width = 0
    $enumerator = [System.Globalization.StringInfo]::GetTextElementEnumerator($Text)
    while ($enumerator.MoveNext()) {
        $element = [string] $enumerator.Current
        if ([string]::IsNullOrEmpty($element)) {
            continue
        }

        $rune = [int] [char] $element[0]
        if (
            ($rune -ge 0x1100 -and $rune -le 0x115F) -or
            ($rune -eq 0x2329) -or
            ($rune -eq 0x232A) -or
            ($rune -ge 0x2E80 -and $rune -le 0xA4CF) -or
            ($rune -ge 0xAC00 -and $rune -le 0xD7A3) -or
            ($rune -ge 0xF900 -and $rune -le 0xFAFF) -or
            ($rune -ge 0xFE10 -and $rune -le 0xFE19) -or
            ($rune -ge 0xFE30 -and $rune -le 0xFE6F) -or
            ($rune -ge 0xFF00 -and $rune -le 0xFF60) -or
            ($rune -ge 0xFFE0 -and $rune -le 0xFFE6)
        ) {
            $width += 2
        }
        else {
            $width += 1
        }
    }

    return $width
}

function Pad-Cell {
    param(
        [AllowNull()]
        [string] $Text,
        [Parameter(Mandatory = $true)]
        [int] $Width,
        [ValidateSet('left', 'right')]
        [string] $Align = 'left'
    )

    $value = if ($null -eq $Text) { '' } else { $Text }
    $padding = [Math]::Max($Width - (Get-DisplayWidth -Text $value), 0)
    if ($Align -eq 'right') {
        return (' ' * $padding) + $value
    }

    return $value + (' ' * $padding)
}

function Format-ResultsTable {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable] $Results
    )

    $rows = @(
        ,@('region', 'subregion', 'city', 'hostname', 'avg_latency_ms', 'http', 'status')
    )

    foreach ($result in $Results) {
        $rows += ,@(
            [string] $result.region,
            [string] $result.subregion,
            [string] $result.city,
            [string] $result.hostname,
            [string] $result.avg_latency_ms,
            [string] $result.http,
            [string] $result.status
        )
    }

    $widths = @()
    for ($column = 0; $column -lt $rows[0].Count; $column++) {
        $maxWidth = 0
        foreach ($row in $rows) {
            $cellWidth = Get-DisplayWidth -Text $row[$column]
            if ($cellWidth -gt $maxWidth) {
                $maxWidth = $cellWidth
            }
        }
        $widths += $maxWidth
    }

    $lines = foreach ($row in $rows) {
        $cells = for ($column = 0; $column -lt $row.Count; $column++) {
            $alignment = if ($column -eq 4 -or $column -eq 5) { 'right' } else { 'left' }
            Pad-Cell -Text $row[$column] -Width $widths[$column] -Align $alignment
        }
        $cells -join '  '
    }

    return $lines -join [Environment]::NewLine
}

function Write-ResultsCsv {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable] $Results,
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $Results |
        Select-Object region, subregion, city, hostname, avg_latency_ms, http, status |
        Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

try {
    $Count = Get-PositiveInteger -Value $CountValue -Name 'COUNT'
    $MaxJobs = Get-PositiveInteger -Value $MaxJobsValue -Name 'MAX_JOBS'
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}

$Endpoints = @(
    @{ region = '亚太地区'; subregion = '日本东部'; city = '东京'; hostname = 'objectstorage.ap-tokyo-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '日本中部'; city = '大阪'; hostname = 'objectstorage.ap-osaka-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '韩国中部'; city = '首尔'; hostname = 'objectstorage.ap-seoul-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '韩国北部'; city = '春川'; hostname = 'objectstorage.ap-chuncheon-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '新加坡'; city = '新加坡'; hostname = 'objectstorage.ap-singapore-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '澳大利亚东部'; city = '悉尼'; hostname = 'objectstorage.ap-sydney-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '澳大利亚东南部'; city = '墨尔本'; hostname = 'objectstorage.ap-melbourne-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '印度西部'; city = '孟买'; hostname = 'objectstorage.ap-mumbai-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '印度南部'; city = '海得拉巴'; hostname = 'objectstorage.ap-hyderabad-1.oraclecloud.com' },
    @{ region = '亚太地区'; subregion = '以色列中部'; city = '耶路撒冷'; hostname = 'objectstorage.il-jerusalem-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '美国东部'; city = '阿什本'; hostname = 'objectstorage.us-ashburn-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '美国西部'; city = '凤凰城'; hostname = 'objectstorage.us-phoenix-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '美国西部'; city = '圣何塞'; hostname = 'objectstorage.us-sanjose-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '加拿大东南部'; city = '蒙特利尔'; hostname = 'objectstorage.ca-montreal-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '加拿大东南部'; city = '多伦多'; hostname = 'objectstorage.ca-toronto-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '墨西哥中部'; city = '克雷塔罗'; hostname = 'objectstorage.mx-queretaro-1.oraclecloud.com' },
    @{ region = '北美地区'; subregion = '墨西哥东北部'; city = '蒙特雷'; hostname = 'objectstorage.mx-monterrey-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '英国南部'; city = '伦敦'; hostname = 'objectstorage.uk-london-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '英国西部'; city = '纽波特'; hostname = 'objectstorage.uk-cardiff-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '德国中部'; city = '法兰克福'; hostname = 'objectstorage.eu-frankfurt-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '瑞士北部'; city = '苏黎世'; hostname = 'objectstorage.eu-zurich-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '瑞典中部'; city = '斯德哥尔摩'; hostname = 'objectstorage.eu-stockholm-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '荷兰西北部'; city = '阿姆斯特丹'; hostname = 'objectstorage.eu-amsterdam-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '法国中部'; city = '巴黎'; hostname = 'objectstorage.eu-paris-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '法国南部'; city = '马赛'; hostname = 'objectstorage.eu-marseille-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '西班牙中部'; city = '马德里'; hostname = 'objectstorage.eu-madrid-1.oraclecloud.com' },
    @{ region = '欧洲地区'; subregion = '意大利西北部'; city = '米兰'; hostname = 'objectstorage.eu-milan-1.oraclecloud.com' },
    @{ region = '中东地区'; subregion = '阿联酋东部'; city = '迪拜'; hostname = 'objectstorage.me-dubai-1.oraclecloud.com' },
    @{ region = '中东地区'; subregion = '阿联酋中部'; city = '阿布扎比'; hostname = 'objectstorage.me-abudhabi-1.oraclecloud.com' },
    @{ region = '中东地区'; subregion = '沙特阿拉伯西部'; city = '吉达'; hostname = 'objectstorage.me-jeddah-1.oraclecloud.com' },
    @{ region = '南美地区'; subregion = '巴西东部'; city = '圣保罗'; hostname = 'objectstorage.sa-saopaulo-1.oraclecloud.com' },
    @{ region = '南美地区'; subregion = '巴西南部'; city = '文郝多'; hostname = 'objectstorage.sa-vinhedo-1.oraclecloud.com' },
    @{ region = '南美地区'; subregion = '智利中部'; city = '圣地亚哥'; hostname = 'objectstorage.sa-santiago-1.oraclecloud.com' },
    @{ region = '南美地区'; subregion = '哥伦比亚中部'; city = '波哥大'; hostname = 'objectstorage.sa-bogota-1.oraclecloud.com' },
    @{ region = '非洲地区'; subregion = '南非中部'; city = '约翰内斯堡'; hostname = 'objectstorage.af-johannesburg-1.oraclecloud.com' }
)

$jobScript = {
    param(
        [hashtable] $Endpoint,
        [int] $PingCount,
        [string] $TestUrlTemplate
    )

    # Ping test
    $avgLatency = 'N/A'
    $sortKey = 999999.0
    $pingOk = $false
    try {
        $responses = Test-Connection -ComputerName $Endpoint.hostname -Count $PingCount -ErrorAction Stop
        if ($null -eq $responses) {
            throw 'No response.'
        }

        $samples = @(
            $responses |
                ForEach-Object {
                    if ($null -ne $_.PSObject.Properties['ResponseTime']) {
                        $_.ResponseTime
                    }
                    elseif ($null -ne $_.PSObject.Properties['Latency']) {
                        $_.Latency
                    }
                } |
                Where-Object { $null -ne $_ }
        )

        if ($samples.Count -eq 0) {
            throw 'No latency samples.'
        }

        $avg = [Math]::Round((($samples | Measure-Object -Average).Average), 3)
        $avgLatency = $avg.ToString('0.###', [System.Globalization.CultureInfo]::InvariantCulture)
        $sortKey = [double] $avg
        $pingOk = $true
    }
    catch { }

    # HTTP test: TTFB when no custom URL, download speed when TEST_URL provides enough data
    $httpResult = 'N/A'
    try {
        $testUri = $TestUrlTemplate -replace '\{hostname\}', $Endpoint.hostname
        $req = [System.Net.HttpWebRequest]::Create($testUri)
        $req.Timeout = 20000
        $req.ReadWriteTimeout = 20000

        $resp = $null
        $swTotal = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $resp = $req.GetResponse()
        }
        catch [System.Net.WebException] {
            if ($null -ne $_.Exception.Response) {
                $resp = $_.Exception.Response
            }
            else {
                throw
            }
        }
        $ttfbMs = $swTotal.ElapsedMilliseconds

        $stream = $resp.GetResponseStream()
        $buffer = [byte[]]::new(65536)
        $totalBytes = 0L
        $swRead = [System.Diagnostics.Stopwatch]::StartNew()

        do {
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) { break }
            $totalBytes += $read
        } while ($swRead.ElapsedMilliseconds -lt 8000)

        $swTotal.Stop()
        $stream.Dispose()
        $resp.Dispose()

        # Need at least 10 KB to report a meaningful throughput figure
        if ($totalBytes -ge 10240 -and $swTotal.Elapsed.TotalSeconds -gt 0) {
            $bps = $totalBytes / $swTotal.Elapsed.TotalSeconds
            $mbps = [Math]::Round($bps * 8 / 1000000, 2)
            $httpResult = $mbps.ToString('0.##', [System.Globalization.CultureInfo]::InvariantCulture) + ' Mbps'
        }
        elseif ($ttfbMs -gt 0) {
            $httpResult = $ttfbMs.ToString() + ' ms'
        }
    }
    catch { }

    return [pscustomobject] @{
        region         = $Endpoint.region
        subregion      = $Endpoint.subregion
        city           = $Endpoint.city
        hostname       = $Endpoint.hostname
        avg_latency_ms = $avgLatency
        http           = $httpResult
        status         = if ($pingOk) { 'ok' } else { 'failed' }
        sort_key       = $sortKey
    }
}

$jobs = [System.Collections.Generic.List[System.Management.Automation.Job]]::new()
$results = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($endpoint in $Endpoints) {
        Write-Host ('Testing {0} ...' -f $endpoint.hostname)
        $jobs.Add((Start-Job -ScriptBlock $jobScript -ArgumentList $endpoint, $Count, $TestUrlValue))

        while ($jobs.Count -ge $MaxJobs) {
            $finishedJob = Wait-Job -Job $jobs -Any
            if ($null -eq $finishedJob) {
                continue
            }

            $result = Receive-Job -Job $finishedJob
            if ($null -ne $result) {
                $results.Add($result)
            }

            Remove-Job -Job $finishedJob
            [void] $jobs.Remove($finishedJob)
        }
    }

    while ($jobs.Count -gt 0) {
        $finishedJob = Wait-Job -Job $jobs -Any
        if ($null -eq $finishedJob) {
            continue
        }

        $result = Receive-Job -Job $finishedJob
        if ($null -ne $result) {
            $results.Add($result)
        }

        Remove-Job -Job $finishedJob
        [void] $jobs.Remove($finishedJob)
    }
}
finally {
    foreach ($job in $jobs) {
        try {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
        catch {
        }
    }
}

$sortedResults = @($results | Sort-Object -Property sort_key)

if ($OutputArg) {
    $outputPath = Get-OutputPath -InputPath $OutputArg
    Write-ResultsCsv -Results $sortedResults -Path $outputPath
    Write-Host ('CSV written to {0}' -f $outputPath)
}
else {
    Write-Host (Format-ResultsTable -Results $sortedResults)
}
