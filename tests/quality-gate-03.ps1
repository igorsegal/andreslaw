$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
$root = Join-Path ([System.IO.Path]::GetTempPath()) (
    "AS_QG_" + [guid]::NewGuid().ToString("N")
)
try {
    New-Item -ItemType Directory -Path $root | Out-Null
    $repo = Join-Path $root "source"
    $other = Join-Path $root "outside"
    $bundle = Join-Path $root "test.bundle"
    New-Item -ItemType Directory -Path $repo,$other | Out-Null
    git -C $repo init -q
    if ($LASTEXITCODE -ne 0) { throw "GIT_INIT_FAIL" }
    git -C $repo config user.name "Quality Gate"
    git -C $repo config user.email "quality@example.invalid"
    Set-Content -LiteralPath (Join-Path $repo "test.txt") -Value "PASS"
    git -C $repo add test.txt
    git -C $repo commit -qm "test"
    if ($LASTEXITCODE -ne 0) { throw "COMMIT_FAIL" }
    git -C $repo bundle create $bundle --all
    if ($LASTEXITCODE -ne 0) { throw "BUNDLE_CREATE_FAIL" }
    Push-Location $other
    try {
        git -C $repo bundle verify $bundle
        if ($LASTEXITCODE -ne 0) { throw "BUNDLE_VERIFY_FAIL" }
    }
    finally {
        Pop-Location
    }
    Write-Host "QUALITY_GATE_06=PASS"
}
catch {
    Write-Host "QUALITY_GATE_06=FAIL"
    throw
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
