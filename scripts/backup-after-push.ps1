param(
    [Parameter(Mandatory=$true)][string]$RepoPath,
    [Parameter(Mandatory=$true)][string]$BackupDir,
    [switch]$SkipPush
)
$ErrorActionPreference = "Stop"
if (!(Test-Path -LiteralPath $RepoPath -PathType Container)) { throw "REPO_MISSING" }
if (!(Test-Path -LiteralPath $BackupDir -PathType Container)) { throw "BACKUP_DIR_MISSING" }
git -C $RepoPath rev-parse --is-inside-work-tree | Out-Null
if ($LASTEXITCODE -ne 0) { throw "INVALID_REPO" }
if (!$SkipPush) {
    git -C $RepoPath push
    if ($LASTEXITCODE -ne 0) { throw "PUSH_FAIL" }
}
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fffffff"
$file = Join-Path $BackupDir "andreslav_$stamp.bundle"
git -C $RepoPath bundle create $file --all
if ($LASTEXITCODE -ne 0) { throw "BUNDLE_CREATE_FAIL" }
git -C $RepoPath bundle verify $file
if ($LASTEXITCODE -ne 0) { throw "BUNDLE_VERIFY_FAIL" }
Write-Host "BACKUP=PASS"
Write-Host "FILE=$file"
Write-Host "CLOUD_SYNC=NOT_VERIFIED"
