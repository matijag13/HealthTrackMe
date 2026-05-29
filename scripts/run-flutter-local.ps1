$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $root ".env"
$googleWebClientId = $null

if (-not (Test-Path $envPath)) {
    throw "Missing .env file. Copy .env.example to .env and set GOOGLE_WEB_CLIENT_ID."
}

Get-Content $envPath | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("#")) {
        return
    }

    $separator = $line.IndexOf("=")
    if ($separator -lt 1) {
        return
    }

    $key = $line.Substring(0, $separator).Trim()
    $value = $line.Substring($separator + 1).Trim().Trim('"').Trim("'")

    if ($key -eq "GOOGLE_WEB_CLIENT_ID") {
        $googleWebClientId = $value
    }
}

if ([string]::IsNullOrWhiteSpace($googleWebClientId)) {
    throw "GOOGLE_WEB_CLIENT_ID is missing in .env."
}

Set-Location (Join-Path $root "apps/mobile_flutter")
flutter run -d edge --web-port=52145 --dart-define="GOOGLE_WEB_CLIENT_ID=$googleWebClientId"
