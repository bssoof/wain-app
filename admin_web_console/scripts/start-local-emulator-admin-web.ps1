$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$adminRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $adminRoot "..")
$tmpDir = Join-Path $projectRoot ".tmp"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$seedJsonPath = Join-Path $tmpDir "admin_web_console_local_emulator_seed.json"
$seedRaw = & node (Join-Path $scriptDir "seed-local-emulator.mjs")
if ($LASTEXITCODE -ne 0) {
  throw "Local emulator seed failed."
}

[System.IO.File]::WriteAllText(
  $seedJsonPath,
  $seedRaw,
  [System.Text.UTF8Encoding]::new($false)
)
$seed = $seedRaw | ConvertFrom-Json

$env:NEXT_PUBLIC_FIREBASE_PROJECT_ID = $seed.projectId
$env:NEXT_PUBLIC_FIREBASE_API_KEY = "local-emulator-key"
$env:NEXT_PUBLIC_WAIN_USE_FIREBASE_EMULATORS = "1"
$env:WAIN_USE_FIREBASE_EMULATORS = "1"
$env:FIREBASE_AUTH_EMULATOR_HOST = $seed.emulatorHosts.auth
$env:FIRESTORE_EMULATOR_HOST = $seed.emulatorHosts.firestore
$env:FIREBASE_STORAGE_EMULATOR_HOST = "127.0.0.1:9199"
$env:NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST = $seed.emulatorHosts.auth
$env:NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST = $seed.emulatorHosts.firestore
$env:NEXT_PUBLIC_FIREBASE_FIRESTORE_EMULATOR_HOST = $seed.emulatorHosts.firestore
$env:NEXT_PUBLIC_FIREBASE_STORAGE_EMULATOR_HOST = "127.0.0.1:9199"

$env:NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL = $seed.emulatorHosts.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL = $seed.emulatorHosts.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_VENUE_FUNCTIONS_BASE_URL = $seed.emulatorHosts.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_CONFIG_FUNCTIONS_BASE_URL = $seed.emulatorHosts.functionsBaseUrl
$env:NEXT_PUBLIC_WAIN_MEDIA_FUNCTIONS_BASE_URL = $seed.emulatorHosts.functionsBaseUrl

$env:NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN = $seed.tokens.authToken
$env:NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN = $seed.tokens.authToken
$env:NEXT_PUBLIC_WAIN_VENUE_AUTH_TOKEN = $seed.tokens.authToken
$env:NEXT_PUBLIC_WAIN_CONFIG_AUTH_TOKEN = $seed.tokens.authToken
$env:NEXT_PUBLIC_WAIN_MEDIA_AUTH_TOKEN = $seed.tokens.authToken

$env:NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN = $seed.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN = $seed.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_VENUE_APP_CHECK_TOKEN = $seed.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_CONFIG_APP_CHECK_TOKEN = $seed.tokens.appCheckToken
$env:NEXT_PUBLIC_WAIN_MEDIA_APP_CHECK_TOKEN = $seed.tokens.appCheckToken

$env:WAIN_FINANCE_SHARED_SNAPSHOT_CACHE = "0"
$env:WAIN_CONTENT_MODERATION_SHARED_CACHE = "0"
$env:WAIN_REVIEWS_SHARED_CACHE = "0"

$env:WAIN_ADMIN_UID = $seed.admin.uid
$env:WAIN_ADMIN_EMAIL = $seed.admin.email
$env:WAIN_ADMIN_DISPLAY_NAME = "Local Admin"
$env:WAIN_ADMIN_ROLE = "super_admin"
$env:WAIN_ADMIN_ROLES = '["super_admin"]'
$env:WAIN_ADMIN_ADMIN = "1"
$env:WAIN_ADMIN_IS_ADMIN = "1"
$env:WAIN_ADMIN_SESSION_VERIFY_REVOCATION = "0"

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
  Write-Host "Removing stale .next artifacts before starting local dev server."
  Remove-Item -Path $nextDir -Recurse -Force
}

Write-Host "Local emulator admin seed written to $seedJsonPath"
Write-Host "Starting admin web console against $($seed.emulatorHosts.functionsBaseUrl)"

Set-Location $adminRoot
npm run dev
