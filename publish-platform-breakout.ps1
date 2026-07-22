[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
  [string]$ReportPath,

  [Parameter(Mandatory)]
  [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
  [string]$DataDate,

  [Parameter(Mandatory)]
  [ValidateLength(1, 4000)]
  [string]$Summary,

  [string]$RepoPath = 'C:\github\dbaupload0031-SIRC'
)

$ErrorActionPreference = 'Stop'
$reportDirectory = Join-Path $RepoPath 'reports\platform-breakout'
$token = [Environment]::GetEnvironmentVariable('LINE_CHANNEL_ACCESS_TOKEN', 'User')
if ([string]::IsNullOrWhiteSpace($token)) {
  $token = $env:LINE_CHANNEL_ACCESS_TOKEN
}
$groupId = [Environment]::GetEnvironmentVariable('LINE_GROUP_ID', 'User')
if ([string]::IsNullOrWhiteSpace($groupId)) {
  $groupId = $env:LINE_GROUP_ID
}
if ([string]::IsNullOrWhiteSpace($token) -or [string]::IsNullOrWhiteSpace($groupId)) {
  throw 'LINE_CHANNEL_ACCESS_TOKEN 與 LINE_GROUP_ID 必須先設定於 Windows 使用者環境變數。'
}

if (-not (Test-Path -LiteralPath (Join-Path $RepoPath '.git') -PathType Container)) {
  throw "Git repository not found: $RepoPath"
}
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
$fileName = Split-Path -Leaf $ReportPath
$destination = Join-Path $reportDirectory $fileName
Copy-Item -LiteralPath $ReportPath -Destination $destination -Force

function Invoke-SircGit {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & git -c "safe.directory=$RepoPath" -C $RepoPath @Arguments
  if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed." }
}

$relativeReportPath = "reports/platform-breakout/$fileName"
Invoke-SircGit add -- $relativeReportPath
$staged = & git -c "safe.directory=$RepoPath" -C $RepoPath diff --cached --quiet -- $relativeReportPath
if ($LASTEXITCODE -eq 0) {
  throw "No report change to publish: $relativeReportPath"
}
if ($LASTEXITCODE -ne 1) { throw 'Unable to inspect staged report changes.' }

& git -c "safe.directory=$RepoPath" -c user.name='SamChang' -c user.email='16096426+dbaupload0031@users.noreply.github.com' -C $RepoPath commit -m "Publish platform breakout report for $DataDate" -- $relativeReportPath
if ($LASTEXITCODE -ne 0) { throw 'Unable to commit the report.' }
Invoke-SircGit push origin main

$reportUrl = "https://dbaupload0031.github.io/SIRC/platform-breakout/$([uri]::EscapeDataString($fileName))"
$deploymentDeadline = (Get-Date).AddMinutes(4)
$pageAvailable = $false
do {
  try {
    $pageResponse = Invoke-WebRequest -Uri $reportUrl -Method Head -UseBasicParsing -TimeoutSec 20
    $pageAvailable = $pageResponse.StatusCode -eq 200
  } catch {
    $pageAvailable = $false
  }
  if (-not $pageAvailable) { Start-Sleep -Seconds 10 }
} while (-not $pageAvailable -and (Get-Date) -lt $deploymentDeadline)
if (-not $pageAvailable) {
  throw "GitHub Pages report was not available within four minutes; LINE notification was not sent: $reportUrl"
}

$message = "SIRC 每日平台突破監控報告｜$DataDate`n$Summary`n完整報告：$reportUrl`n僅供監控與研究，不構成投資建議。"
if ($message.Length -gt 5000) { throw 'LINE 訊息超過 5,000 字元限制。' }
$payload = @{ to = $groupId; messages = @(@{ type = 'text'; text = $message }) } | ConvertTo-Json -Depth 5 -Compress
$utf8Payload = [System.Text.Encoding]::UTF8.GetBytes($payload)
$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri 'https://api.line.me/v2/bot/message/push' -Method Post -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $utf8Payload | Out-Null

[pscustomobject]@{
  data_date = $DataDate
  report_url = $reportUrl
  git_push = 'success'
  line_push = 'success'
} | ConvertTo-Json -Compress
