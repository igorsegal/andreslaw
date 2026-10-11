$ErrorActionPreference = "Stop"
$root = Join-Path ([IO.Path]::GetTempPath()) ("AS_BACKUP_GATE_" + [guid]::NewGuid().ToString("N"))
$script = Join-Path $PSScriptRoot "..\scripts\backup-after-push.ps1"
function Check-Native([string]$name) {
    if ($LASTEXITCODE -ne 0) { throw "$name FAIL ($LASTEXITCODE)" }
}
try {
    $repo = Join-Path $root "repo"
    $out = Join-Path $root "outside"
    $backup = Join-Path $root "backups"
    New-Item -ItemType Directory -Path $repo,$out,$backup -Force | Out-Null
    git -C $repo init -q
    Check-Native "INIT"
    git -C $repo config user.name "Quality Gate"
    git -C $repo config user.email "gate@example.invalid"
    Set-Content -LiteralPath (Join-Path $repo "proof.txt") -Value "PASS"
    git -C $repo add proof.txt
    Check-Native "ADD"
    git -C $repo commit -qm "fixture"
    Check-Native "COMMIT"
    $content = Get-Content -LiteralPath $script -Raw
    if ($content -notmatch 'git -C \$RepoPath bundle verify \$file') { throw "CONTRACT_FAIL" }
    Push-Location $out
    try {
        & $script -RepoPath $repo -BackupDir $backup -SkipPush
        $files = @(Get-ChildItem -LiteralPath $backup -Filter "*.bundle" -File)
        if ($files.Count -ne 1) { throw "BUNDLE_COUNT_FAIL" }
        git -C $repo bundle verify $files[0].FullName
        Check-Native "VERIFY"
        Write-Host "POSITIVE_CASE=PASS"
        $mutant = Join-Path $root "broken.ps1"
        $broken = $content.Replace('git -C $RepoPath bundle verify $file', 'git bundle verify $file')
        if ($broken -eq $content) { throw "MUTATION_FAILED" }
        Set-Content -LiteralPath $mutant -Value $broken
        $caught = $false
        try {
            & $mutant -RepoPath $repo -BackupDir $backup -SkipPush 2>$null | Out-Null
        } catch { $caught = $true }
        if (!$caught) { throw "NEGATIVE_CASE_NOT_REJECTED" }
        Write-Host "NEGATIVE_CASE=PASS"
    } finally { Pop-Location }
    Write-Host "QUALITY_GATE_BACKUP=PASS"
} finally {
    Remove-Item -LiteralPath $root -Force -Recurse -ErrorAction SilentlyContinue
}
