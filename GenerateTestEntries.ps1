# Generator test dnevnih vnosov za HealthTrackMe
# PowerShell skripte

$BaseUrl = "http://localhost:8080/api/v1"

$Moods = @("odličnog", "dobrog", "nevtralnega", "slabega", "zelo_slabega")
$Symptoms = @(
    "Glavobol",
    "Vrtoglavica",
    "Bolečine",
    "Utrujenost",
    "Slabost",
    "Zasoplost",
    "Povišan stres"
)

$Notes = @(
    "Jutro sem se počutil slabo, popoldne je bilo boljše.",
    "Dober dan, malo več korakov kot običajno.",
    "Zelo mučno, malo sem spal.",
    "Odličen dan! Dosegel sem svoj cilj aktivnosti.",
    "Normalen dan, nič posebnega.",
    "Malo pod stresom, ampak v redu.",
    "Počutil sem se fantastično!",
    "Težka noč, malo sem spavil."
)

function Get-AllUsers {
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/users" -Method Get
        if ($response.data) {
            return $response.data
        } else {
            return $response
        }
    } catch {
        Write-Host "Napaka pri pridobivanju uporabnikov: $_"
        return @()
    }
}

function New-HealthEntry {
    $today = Get-Date -Format "yyyy-MM-dd"

    $numSymptoms = Get-Random -Minimum 0 -Maximum 4
    $symptomsArray = if ($numSymptoms -gt 0) {
        $Symptoms | Get-Random -Count $numSymptoms
    } else {
        @()
    }

    $energy = Get-Random -Minimum 30 -Maximum 101
    $stress = Get-Random -Minimum 20 -Maximum 81
    $sleepHours = [math]::Round((Get-Random -Minimum 50 -Maximum 100) / 10.0, 1)
    $steps = Get-Random -Minimum 3000 -Maximum 15001
    $mood = $Moods | Get-Random

    $wellbeing = ($energy * 0.6 + (100 - $stress) * 0.4) / 10.0
    $wellbeingScore = [math]::Min(10, [math]::Max(0, [math]::Floor($wellbeing)))

    $entry = @{
        entryDate = $today
        wellbeingScore = [int]$wellbeingScore
        symptoms = @($symptomsArray)
        mood = $mood
        energyLevel = [int]$energy
        sleepHours = [double]$sleepHours
        sleepQuality = @("odlično", "dobro", "slabo") | Get-Random
        stressLevel = [int]$stress
        notes = $Notes | Get-Random
    }

    return $entry
}

function Create-HealthEntry {
    param(
        [int]$UserId,
        [hashtable]$EntryData
    )

    try {
        $uri = "$BaseUrl/health-entries/users/$UserId"
        $body = $EntryData | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"

        Write-Host "[OK] Vnos ustvarjen za uporabnika $UserId"
        return $true
    } catch {
        Write-Host "[NAPAKA] Problem pri ustvarjanju vnosa za uporabnika $UserId"
        return $false
    }
}

# MAIN

Write-Host ""
Write-Host "======================================================"
Write-Host "HealthTrackMe - Generator test dnevnih vnosov"
Write-Host "======================================================"
Write-Host ""

$users = Get-AllUsers

if ($users.Count -eq 0) {
    Write-Host "NAPAKA: Ni uporabnikov v bazi ali API ni dostopen."
    Write-Host "Preverite: $BaseUrl"
    exit
}

Write-Host "Najdenih: $($users.Count) uporabnikov"
Write-Host ""

$totalCreated = 0

foreach ($user in $users) {
    $userId = $user.id
    $userName = "$($user.firstName) $($user.lastName)"

    Write-Host ""
    Write-Host "Uporabnik: $userName (ID: $userId)"
    Write-Host "---"

    $numEntries = Get-Random -Minimum 5 -Maximum 8
    $entriesCreated = 0

    for ($i = 0; $i -lt $numEntries; $i++) {
        $entry = New-HealthEntry
        if (Create-HealthEntry -UserId $userId -EntryData $entry) {
            $entriesCreated++
            $totalCreated++
        }
    }

    Write-Host "Skupaj: $entriesCreated/$numEntries vnosov"
}

Write-Host ""
Write-Host "======================================================"
Write-Host "Zaključeno!"
Write-Host "Skupaj ustvarjenih vnosov: $totalCreated"
Write-Host "======================================================"
Write-Host ""


