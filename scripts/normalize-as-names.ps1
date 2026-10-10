param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$TerminalMql4 = "",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

function Get-Mql4Root([string]$Root) {
    $candidate = Join-Path $Root "MQL4"
    if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
    if ((Split-Path $Root -Leaf) -ieq "MQL4") { return (Resolve-Path $Root).Path }
    throw "Не найден MQL4: $Root"
}

function Get-NewLeaf([string]$Leaf) {
    # Каталог AS уже задаёт namespace проекта.
    # Удаляем только избыточный начальный префикс AS_.
    return ($Leaf -replace '^AS_', '')
}

function New-RenamePlan([string]$Mql4Root) {
    $plan = @()

    foreach ($kind in @("Experts","Indicators")) {
        $srcRoot = Join-Path $Mql4Root $kind
        if (-not (Test-Path $srcRoot)) { continue }

        $dstRoot = Join-Path $srcRoot "AS"
        $files = Get-ChildItem $srcRoot -Recurse -File |
            Where-Object { $_.Extension -in @(".mq4",".ex4") }

        foreach ($f in $files) {
            $newLeaf = Get-NewLeaf $f.Name
            $dst = Join-Path $dstRoot $newLeaf

            if ($f.FullName -ieq $dst) { continue }

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
    $groups = $Plan | Group-Object Destination | Where-Object Count -gt 1
    if ($groups) {
        $msg = ($groups | ForEach-Object { $_.Name }) -join [Environment]::NewLine
        throw ("КОНФЛИКТ: несколько файлов дают одно имя:" + [Environment]::NewLine + $msg)
    }

    foreach ($p in $Plan) {
        if ((Test-Path $p.Destination) -and ($p.Source -ine $p.Destination)) {
            throw "КОНФЛИКТ: файл уже существует: $($p.Destination)"
        }
    }
}

function Update-RepoReferences([string]$RepoRoot, $Plan, [switch]$DoApply) {
    $extensions = @(
        ".mq4",".mqh",".md",".csv",".txt",".ps1",".bat",
        ".json",".yml",".yaml"
    )

    $textFiles = Get-ChildItem $RepoRoot -Recurse -File |
        Where-Object {
            $_.Extension -in $extensions -and
            $_.FullName -notmatch '[\\/]\.git[\\/]'
        }

    $changed = 0

    foreach ($file in $textFiles) {
        $original = Get-Content $file.FullName -Raw -Encoding UTF8
        $updated = $original

        foreach ($p in $Plan) {
            # Безопасные замены: только ссылки на файлы/пути.
            # Идентификаторы вида AS_sr_State не трогаем.
            $updated = $updated.Replace($p.OldLeaf, $p.NewLeaf)

            $oldMq4 = $p.OldStem + ".mq4"
            $newMq4 = $p.NewStem + ".mq4"
            $updated = $updated.Replace($oldMq4, $newMq4)

            $oldEx4 = $p.OldStem + ".ex4"
            $newEx4 = $p.NewStem + ".ex4"
            $updated = $updated.Replace($oldEx4, $newEx4)

            if ($p.Kind -eq "Indicators") {
                $updated = $updated.Replace(
                    ('"AS\\' + $p.OldStem + '"'),
                    ('"AS\\' + $p.NewStem + '"')
                )
                $updated = $updated.Replace(
                    ('"AS/' + $p.OldStem + '"'),
                    ('"AS/' + $p.NewStem + '"')
                )
            }
        }

        if ($updated -cne $original) {
            $changed++
            Write-Host "[REF] $($file.FullName)"
            if ($DoApply) {
                Set-Content $file.FullName $updated -Encoding UTF8 -NoNewline
            }
        }
    }

    Write-Host "[REF] files_changed=$changed"
}

function Invoke-Normalize([string]$Mql4Root, [switch]$DoApply) {
    $plan = New-RenamePlan $Mql4Root
    Assert-NoCollisions $plan

    if (-not $plan -or $plan.Count -eq 0) {
        Write-Host "[PASS] Уже нормализовано: $Mql4Root"
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

        # Удаляем только пустые каталоги. Include/AS не затрагивается.
        foreach ($kind in @("Experts","Indicators")) {
            $root = Join-Path $Mql4Root $kind
            Get-ChildItem $root -Directory -Recurse |
                Sort-Object FullName -Descending |
                Where-Object {
                    $_.Name -ne "AS" -and
                    -not (Get-ChildItem $_.FullName -Force | Select-Object -First 1)
                } |
                Remove-Item -Force
        }
    }

    return $plan
}

$repoMql4 = Get-Mql4Root $RepoRoot

Write-Host ""
Write-Host "ANDRESLAW NAME NORMALIZER"
Write-Host "MODE=" $(if ($Apply) { "APPLY" } else { "PREVIEW" })
Write-Host "RULE=strip leading AS_ ; keep Experts/AS and Indicators/AS"
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
    Write-Host "[PASS] Нормализация выполнена."
    Write-Host "[NEXT] Перекомпилировать mq4 в Experts/AS и Indicators/AS."
} else {
    Write-Host "[PREVIEW] Изменений нет."
    Write-Host "[NEXT] Повтори команду с -Apply после проверки списка."
}
