param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$TerminalMql4 = "",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

function Get-Mql4Root([string]$Root) {
    $candidate = Join-Path $Root "MQL4"
    if (Test-Path $candidate) {
        return (Resolve-Path $candidate).Path
    }
    if ((Split-Path $Root -Leaf) -ieq "MQL4") {
        return (Resolve-Path $Root).Path
    }
    throw "MQL4_NOT_FOUND: $Root"
}

function Normalize-Stem([string]$Stem) {
    $s = $Stem.Trim()

    $prefixes = @("AS","SWTsr","SWTch","ASsr","sr")
    $semanticPrefixes = @("Waves","Targets")
    $suffixes = @("CompileTest","SelfTest","Compare","Probe","Test")

    do {
        $before = $s

        foreach ($p in $prefixes) {
            $escaped = [regex]::Escape($p)
            if ($s -match ("^(?i:" + $escaped + ")(?:[_-]+)?(.+)$")) {
                $candidate = $Matches[1].Trim([char[]]"_-")
                if ($candidate) {
                    $s = $candidate
                    break
                }
            }
        }

        foreach ($p in $semanticPrefixes) {
            $escaped = [regex]::Escape($p)
            if ($s -match ("^(?i:" + $escaped + ")(?:[_-]+)?(.+)$")) {
                $candidate = $Matches[1].Trim([char[]]"_-")
                if ($candidate) {
                    $s = $candidate
                    break
                }
            }
        }

        foreach ($x in $suffixes) {
            $escaped = [regex]::Escape($x)
            if ($s -match ("^(.+?)(?:[_-]+)?(?i:" + $escaped + ")$")) {
                $candidate = $Matches[1].Trim([char[]]"_-")
                if ($candidate) {
                    $s = $candidate
                    break
                }
            }
        }

        if ($s -match "^(.+?)(?:[_-]+)?(?i:AS)$") {
            $candidate = $Matches[1].Trim([char[]]"_-")
            if ($candidate) {
                $s = $candidate
            }
        }

        $s = $s.Trim([char[]]"_-")
    }
    while ($s -ne $before)

    if ([string]::IsNullOrWhiteSpace($s)) {
        throw "EMPTY_NAME_AFTER_NORMALIZE: $Stem"
    }

    return $s
}

function Get-NewLeaf([string]$Leaf) {
    $ext = [IO.Path]::GetExtension($Leaf)
    $stem = [IO.Path]::GetFileNameWithoutExtension($Leaf)
    $newStem = Normalize-Stem $stem
    return ($newStem + $ext)
}

function New-RenamePlan([string]$Mql4Root) {
    $plan = @()

    foreach ($kind in @("Experts","Indicators")) {
        $srcRoot = Join-Path $Mql4Root $kind
        if (-not (Test-Path $srcRoot)) {
            continue
        }

        $dstRoot = Join-Path $srcRoot "AS"
        $files = Get-ChildItem $srcRoot -Recurse -File | Where-Object { $_.Extension -in @(".mq4",".ex4") }

        foreach ($f in $files) {
            $newLeaf = Get-NewLeaf $f.Name
            $dst = Join-Path $dstRoot $newLeaf

            if ($f.FullName -ieq $dst) {
                continue
            }

            $plan += [pscustomobject]@{
                Kind        = $kind
                Source      = $f.FullName
                Destination = $dst
                OldLeaf     = $f.Name
                NewLeaf     = $newLeaf
                OldStem     = [IO.Path]::GetFileNameWithoutExtension($f.Name)
                NewStem     = [IO.Path]::GetFileNameWithoutExtension($newLeaf)
            }
        }
    }

    return $plan
}

function Assert-NoCollisions($Plan) {
    $dupes = $Plan | Group-Object Destination | Where-Object { $_.Count -gt 1 }

    if ($dupes) {
        Write-Host "[CONFLICT] duplicate destinations:"
        $dupes | ForEach-Object { Write-Host $_.Name }
        throw "RENAME_COLLISION"
    }

    foreach ($p in $Plan) {
        if ((Test-Path $p.Destination) -and ($p.Source -ine $p.Destination)) {
            Write-Host "[CONFLICT] destination exists:"
            Write-Host $p.Destination
            throw "DESTINATION_EXISTS"
        }
    }
}

function Update-RepoReferences([string]$RepoRoot, $Plan, [switch]$DoApply) {
    $extensions = @(".mq4",".mqh",".md",".csv",".txt",".ps1",".bat",".json",".yml",".yaml")
    $files = Get-ChildItem $RepoRoot -Recurse -File | Where-Object { $_.Extension -in $extensions -and $_.FullName -notmatch '[\\/]\.git[\\/]' }
    $changed = 0

    foreach ($file in $files) {
        $original = Get-Content $file.FullName -Raw -Encoding UTF8
        $updated = $original

        foreach ($p in $Plan) {
            $updated = $updated.Replace($p.OldLeaf, $p.NewLeaf)

            if ($p.Kind -eq "Indicators") {
                $updated = $updated.Replace(('"AS\\' + $p.OldStem + '"'), ('"AS\\' + $p.NewStem + '"'))
                $updated = $updated.Replace(('"AS/' + $p.OldStem + '"'), ('"AS/' + $p.NewStem + '"'))
            }
        }

        if ($updated -cne $original) {
            $changed++
            Write-Host "[REF] $($file.FullName)"
            if ($DoApply) {
                Set-Content -LiteralPath $file.FullName -Value $updated -Encoding UTF8 -NoNewline
            }
        }
    }

    Write-Host "[REF_COUNT] $changed"
}

function Invoke-Normalize([string]$Mql4Root, [switch]$DoApply) {
    $plan = New-RenamePlan $Mql4Root
    Assert-NoCollisions $plan

    if (-not $plan -or $plan.Count -eq 0) {
        Write-Host "[PASS] already normalized: $Mql4Root"
        return $plan
    }

    foreach ($p in $plan) {
        Write-Host ("[{0}] {1} -> {2}" -f $p.Kind, $p.Source, $p.Destination)
    }

    if ($DoApply) {
        foreach ($kind in @("Experts","Indicators")) {
            $dir = Join-Path (Join-Path $Mql4Root $kind) "AS"
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        foreach ($p in $plan) {
            Move-Item -LiteralPath $p.Source -Destination $p.Destination
        }

        foreach ($kind in @("Experts","Indicators")) {
            $root = Join-Path $Mql4Root $kind
            Get-ChildItem $root -Directory -Recurse | Sort-Object FullName -Descending | Where-Object { $_.Name -ne "AS" -and -not (Get-ChildItem $_.FullName -Force | Select-Object -First 1) } | Remove-Item -Force
        }
    }

    return $plan
}

$repoMql4 = Get-Mql4Root $RepoRoot

Write-Host ""
Write-Host "ANDRESLAW_NAME_NORMALIZER"
Write-Host ("MODE=" + $(if ($Apply) { "APPLY" } else { "PREVIEW" }))
Write-Host "DEST=Experts/AS + Indicators/AS"
Write-Host ""

$repoPlan = Invoke-Normalize $repoMql4 -DoApply:$Apply
Update-RepoReferences $RepoRoot $repoPlan -DoApply:$Apply

if ($TerminalMql4) {
    Write-Host ""
    Write-Host "[TERMINAL] $TerminalMql4"
    $terminalRoot = Get-Mql4Root $TerminalMql4
    Invoke-Normalize $terminalRoot -DoApply:$Apply | Out-Null
}

Write-Host ""

if ($Apply) {
    Write-Host "[PASS] normalize complete"
    Write-Host "[NEXT] recompile mq4 in Experts/AS and Indicators/AS"
}
else {
    Write-Host "[PREVIEW] no changes applied"
    Write-Host "[NEXT] review mapping, then run with -Apply"
}
