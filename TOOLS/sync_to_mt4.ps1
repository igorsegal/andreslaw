$ErrorActionPreference = "Stop"

$Repo = Split-Path -Parent $PSScriptRoot
$Mt4  = "C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\619E963F477248A9FDCF5F38F45D8C98\MQL4"

if (-not (Test-Path $Mt4)) {
    throw "MT4 MQL4 folder not found: $Mt4"
}

$sets = @(
    @{ Src = Join-Path $Repo "MQL4\Experts\AS";   Dst = Join-Path $Mt4 "Experts\AS";   Filter = @("*.mq4") },
    @{ Src = Join-Path $Repo "MQL4\Indicators\AS"; Dst = Join-Path $Mt4 "Indicators\AS"; Filter = @("*.mq4") },
    @{ Src = Join-Path $Repo "MQL4\Include\AS";    Dst = Join-Path $Mt4 "Include\AS";    Filter = @("*.mqh") }
)

$copied = @()

foreach ($set in $sets) {
    New-Item -ItemType Directory -Force -Path $set.Dst | Out-Null

    foreach ($pattern in $set.Filter) {
        Get-ChildItem -Path $set.Src -Filter $pattern -File | ForEach-Object {
            $dest = Join-Path $set.Dst $_.Name
            Copy-Item $_.FullName $dest -Force

            $srcHash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash $dest -Algorithm SHA256).Hash

            if ($srcHash -ne $dstHash) {
                throw "HASH MISMATCH: $($_.Name)"
            }

            $copied += $dest
        }
    }
}

Write-Host ""
Write-Host "ANDRESLAW -> MT4 SYNC"
Write-Host "====================="
Write-Host "FILES=$($copied.Count)"
Write-Host "STATUS=PASS"
Write-Host "MT4=$Mt4"
