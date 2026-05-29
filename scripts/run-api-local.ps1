$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $root ".env"

if (-not (Test-Path $envPath)) {
    throw "Missing .env file. Copy .env.example to .env and set GOOGLE_OAUTH_ALLOWED_CLIENT_IDS."
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

    if ($key -eq "GOOGLE_OAUTH_ALLOWED_CLIENT_IDS") {
        $env:GOOGLE_OAUTH_ALLOWED_CLIENT_IDS = $value
    }
}

if ([string]::IsNullOrWhiteSpace($env:GOOGLE_OAUTH_ALLOWED_CLIENT_IDS)) {
    throw "GOOGLE_OAUTH_ALLOWED_CLIENT_IDS is missing in .env."
}

Set-Location (Join-Path $root "apps/api")
.\mvnw.cmd spring-boot:run
