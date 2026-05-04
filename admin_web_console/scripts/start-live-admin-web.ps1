$ErrorActionPreference = "Stop"

if ($env:NODE_ENV -eq "production") {
  throw "start-live-admin-web.ps1 is a diagnostics helper and must not be used for production deployments. Use the server-side admin command proxy path."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$adminRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $adminRoot "..")
$tmpDir = Join-Path $projectRoot ".tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$tokensJsonPath = Join-Path $tmpDir "admin_web_console_live_tokens.json"
$tokensRaw = & node (Join-Path $scriptDir "mint-live-callable-tokens.mjs")
if ($LASTEXITCODE -ne 0) {
  throw "Live token mint failed."
}

[System.IO.File]::WriteAllText(
  $tokensJsonPath,
  $tokensRaw,
  [System.Text.UTF8Encoding]::new($false)
)
$tokens = $tokensRaw | ConvertFrom-Json

$env:NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS = "0"
$env:WAIN_USE_FIREBASE_EMULATORS = "0"

Remove-Item Env:FIREBASE_AUTH_EMULATOR_HOST -ErrorAction SilentlyContinue
Remove-Item Env:FIRESTORE_EMULATOR_HOST -ErrorAction SilentlyContinue
Remove-Item Env:FIREBASE_STORAGE_EMULATOR_HOST -ErrorAction SilentlyContinue
Remove-Item Env:NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST -ErrorAction SilentlyContinue
Remove-Item Env:NEXT_PUBLIC_FIREBASE_STORAGE_EMULATOR_HOST -ErrorAction SilentlyContinue

$env:NEXT_PUBLIC_FIREBASE_PROJECT_ID = $tokens.projectId
$env:NEXT_PUBLIC_FIREBASE_APP_ID = $tokens.appId
$env:NEXT_PUBLIC_FIREBASE_API_KEY = $tokens.apiKey

$env:NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL = $tokens.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL = $tokens.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL = $tokens.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL = $tokens.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL = $tokens.functionsBaseUrl

$env:NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN = $tokens.tokens.authToken
$env:NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN = $tokens.tokens.authToken
$env:NEXT_PUBLIC_WAIN_VENUE_AUTH_TOKEN = $tokens.tokens.authToken
$env:NEXT_PUBLIC_WAIN_CONFIG_AUTH_TOKEN = $tokens.tokens.authToken
$env:NEXT_PUBLIC_WAIN_MEDIA_AUTH_TOKEN = $tokens.tokens.authToken

$env:NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN = $tokens.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN = $tokens.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN = $tokens.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN = $tokens.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN = $tokens.tokens.appCheckToken

$listeners = Get-NetTCPConnection -LocalPort 3010 -State Listen -ErrorAction SilentlyContinue
if ($listeners) {
  $listener = $listeners | Select-Object -First 1
  $existingPid = $listener.OwningProcess
  $existingProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$existingPid" -ErrorAction SilentlyContinue
  $existingCommandLine = ""
  if ($existingProcess -and $null -ne $existingProcess.CommandLine) {
    $existingCommandLine = [string]$existingProcess.CommandLine
  }
  $existingCommand = $existingCommandLine.ToLowerInvariant()

  if (
    $existingProcess -and
    $existingProcess.Name -eq "node.exe" -and
    $existingCommand.Contains("next") -and
    $existingCommand.Contains("admin_web_console")
  ) {
    Write-Host "Stopping existing Next.js dev process on port 3010 (PID $existingPid)."
    Stop-Process -Id $existingPid -Force
  } else {
    throw "Port 3010 is already in use by PID $existingPid. Stop it, then rerun this script."
  }
}

$nextDir = Join-Path $adminRoot ".next"
if (Test-Path $nextDir) {
  Write-Host "Removing stale .next artifacts before starting live dev server."
  Remove-Item -Path $nextDir -Recurse -Force
}

$authExpiry = $tokens.tokenExpirations.authToken.iso
$appCheckExpiry = $tokens.tokenExpirations.appCheckToken.iso

Write-Host "Live token payload written to $tokensJsonPath"
Write-Host "Functions base URL: $($tokens.functionsBaseUrl)"
Write-Host "Auth token expires at: $authExpiry"
Write-Host "App Check token expires at: $appCheckExpiry"
Write-Warning "This script is for diagnostics only. Public NEXT_PUBLIC privileged tokens are forbidden in production."
Write-Host "Starting admin web console against live Firebase Functions"

Set-Location $adminRoot
npm run dev
