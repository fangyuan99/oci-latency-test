Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Host.Name -eq 'ConsoleHost') {
    $null = chcp 65001
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
}

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

$Endpoints = (ConvertFrom-Json ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
    'W3sicmVnaW9uIjoi5Lqa5aSq5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5pel5pys5Lic6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmFwLXRva3lvLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuS4nOS6rCJ9LHsicmVnaW9uIjoi5Lqa5aSq5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5pel5pys5Lit6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmFwLW9zYWthLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuWkp+mYqiJ9LHsicmVnaW9uIjoi5Lqa5aSq5Zyw5Yy6Iiwic3VicmVnaW9uIjoi6Z+p5Zu95Lit6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmFwLXNlb3VsLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IummluWwlCJ9LHsicmVnaW9uIjoi5Lqa5aSq5Zyw5Yy6Iiwic3VicmVnaW9uIjoi6Z+p5Zu95YyX6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmFwLWNodW5jaGVvbi0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLmmKXlt50ifSx7InJlZ2lvbiI6IuS6muWkquWcsOWMuiIsInN1YnJlZ2lvbiI6IuaWsOWKoOWdoSIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5hcC1zaW5nYXBvcmUtMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi5paw5Yqg5Z2hIn0seyJyZWdpb24iOiLkuprlpKrlnLDljLoiLCJzdWJyZWdpb24iOiLmvrPlpKfliKnkuprkuJzpg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UuYXAtc3lkbmV5LTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuaCieWwvCJ9LHsicmVnaW9uIjoi5Lqa5aSq5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5r6z5aSn5Yip5Lqa5Lic5Y2X6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmFwLW1lbGJvdXJuZS0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLloqjlsJTmnKwifSx7InJlZ2lvbiI6IuS6muWkquWcsOWMuiIsInN1YnJlZ2lvbiI6IuWNsOW6puilv+mDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5hcC1tdW1iYWktMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi5a2f5LmwIn0seyJyZWdpb24iOiLkuprlpKrlnLDljLoiLCJzdWJyZWdpb24iOiLljbDluqbljZfpg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UuYXAtaHlkZXJhYmFkLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6Iua1t+W+l+aLieW3tCJ9LHsicmVnaW9uIjoi5Lqa5aSq5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5Lul6Imy5YiX5Lit6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmlsLWplcnVzYWxlbS0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLogLbot6/mkpLlhrcifSx7InJlZ2lvbiI6IuWMl+e+juWcsOWMuiIsInN1YnJlZ2lvbiI6Iue+juWbveS4nOmDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS51cy1hc2hidXJuLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IumYv+S7gOacrCJ9LHsicmVnaW9uIjoi5YyX576O5Zyw5Yy6Iiwic3VicmVnaW9uIjoi576O5Zu96KW/6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLnVzLXBob2VuaXgtMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi5Yek5Yew5Z+OIn0seyJyZWdpb24iOiLljJfnvo7lnLDljLoiLCJzdWJyZWdpb24iOiLnvo7lm73opb/pg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UudXMtc2Fuam9zZS0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLlnKPkvZXloZ4ifSx7InJlZ2lvbiI6IuWMl+e+juWcsOWMuiIsInN1YnJlZ2lvbiI6IuWKoOaLv+Wkp+S4nOWNl+mDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5jYS1tb250cmVhbC0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLokpnnibnliKnlsJQifSx7InJlZ2lvbiI6IuWMl+e+juWcsOWMuiIsInN1YnJlZ2lvbiI6IuWKoOaLv+Wkp+S4nOWNl+mDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5jYS10b3JvbnRvLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuWkmuS8puWkmiJ9LHsicmVnaW9uIjoi5YyX576O5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5aKo6KW/5ZOl5Lit6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLm14LXF1ZXJldGFyby0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLlhYvpm7floZTnvZcifSx7InJlZ2lvbiI6IuWMl+e+juWcsOWMuiIsInN1YnJlZ2lvbiI6IuWiqOilv+WTpeS4nOWMl+mDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5teC1tb250ZXJyZXktMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi6JKZ54m56Zu3In0seyJyZWdpb24iOiLmrKfmtLLlnLDljLoiLCJzdWJyZWdpb24iOiLoi7Hlm73ljZfpg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UudWstbG9uZG9uLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuS8puaVpiJ9LHsicmVnaW9uIjoi5qyn5rSy5Zyw5Yy6Iiwic3VicmVnaW9uIjoi6Iux5Zu96KW/6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLnVrLWNhcmRpZmYtMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi57q95rOi54m5In0seyJyZWdpb24iOiLmrKfmtLLlnLDljLoiLCJzdWJyZWdpb24iOiLlvrflm73kuK3pg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UuZXUtZnJhbmtmdXJ0LTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuazleWFsOWFi+emjyJ9LHsicmVnaW9uIjoi5qyn5rSy5Zyw5Yy6Iiwic3VicmVnaW9uIjoi55Ge5aOr5YyX6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmV1LXp1cmljaC0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLoi4/pu47kuJYifSx7InJlZ2lvbiI6Iuasp+a0suWcsOWMuiIsInN1YnJlZ2lvbiI6IueRnuWFuOS4remDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5ldS1zdG9ja2hvbG0tMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi5pav5b635ZOl5bCU5pGpIn0seyJyZWdpb24iOiLmrKfmtLLlnLDljLoiLCJzdWJyZWdpb24iOiLojbflhbDopb/ljJfpg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UuZXUtYW1zdGVyZGFtLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IumYv+WnhuaWr+eJueS4uSJ9LHsicmVnaW9uIjoi5qyn5rSy5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5rOV5Zu95Lit6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmV1LXBhcmlzLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuW3tOm7jiJ9LHsicmVnaW9uIjoi5qyn5rSy5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5rOV5Zu95Y2X6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmV1LW1hcnNlaWxsZS0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLpqazotZsifSx7InJlZ2lvbiI6Iuasp+a0suWcsOWMuiIsInN1YnJlZ2lvbiI6Iuilv+ePreeJmeS4remDqCIsImhvc3RuYW1lIjoib2JqZWN0c3RvcmFnZS5ldS1tYWRyaWQtMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi6ams5b636YeMIn0seyJyZWdpb24iOiLmrKfmtLLlnLDljLoiLCJzdWJyZWdpb24iOiLmhI/lpKfliKnopb/ljJfpg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UuZXUtbWlsYW4tMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi57Gz5YWwIn0seyJyZWdpb24iOiLkuK3kuJzlnLDljLoiLCJzdWJyZWdpb24iOiLpmL/ogZTphYvkuJzpg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UubWUtZHViYWktMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi6L+q5oucIn0seyJyZWdpb24iOiLkuK3kuJzlnLDljLoiLCJzdWJyZWdpb24iOiLpmL/ogZTphYvkuK3pg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UubWUtYWJ1ZGhhYmktMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi6Zi/5biD5omO5q+UIn0seyJyZWdpb24iOiLkuK3kuJzlnLDljLoiLCJzdWJyZWdpb24iOiLmspnnibnpmL/mi4nkvK/opb/pg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2UubWUtamVkZGFoLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuWQiei+viJ9LHsicmVnaW9uIjoi5Y2X576O5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5be06KW/5Lic6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLnNhLXNhb3BhdWxvLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuWco+S/nee9lyJ9LHsicmVnaW9uIjoi5Y2X576O5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5be06KW/5Y2X6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLnNhLXZpbmhlZG8tMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi5paH6YOd5aSaIn0seyJyZWdpb24iOiLljZfnvo7lnLDljLoiLCJzdWJyZWdpb24iOiLmmbrliKnkuK3pg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2Uuc2Etc2FudGlhZ28tMS5vcmFjbGVjbG91ZC5jb20iLCJjaXR5Ijoi5Zyj5Zyw5Lqa5ZOlIn0seyJyZWdpb24iOiLljZfnvo7lnLDljLoiLCJzdWJyZWdpb24iOiLlk6XkvKbmr5TkuprkuK3pg6giLCJob3N0bmFtZSI6Im9iamVjdHN0b3JhZ2Uuc2EtYm9nb3RhLTEub3JhY2xlY2xvdWQuY29tIiwiY2l0eSI6IuazouWTpeWkpyJ9LHsicmVnaW9uIjoi6Z2e5rSy5Zyw5Yy6Iiwic3VicmVnaW9uIjoi5Y2X6Z2e5Lit6YOoIiwiaG9zdG5hbWUiOiJvYmplY3RzdG9yYWdlLmFmLWpvaGFubmVzYnVyZy0xLm9yYWNsZWNsb3VkLmNvbSIsImNpdHkiOiLnuqbnv7DlhoXmlq/loKEifV0='
)))) | ForEach-Object { @{ region = $_.region; subregion = $_.subregion; city = $_.city; hostname = $_.hostname } }

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
