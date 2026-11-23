$ErrorActionPreference = 'Stop'
$installDir = 'C:\msys64'
$bash = Join-Path $installDir 'usr\bin\bash.exe'
$compilerDir = Join-Path $installDir 'ucrt64\bin'
$compiler = Join-Path $compilerDir 'g++.exe'

function Run-Pacman([string]$command) {
    & $bash -lc $command
    return ($LASTEXITCODE -eq 0)
}

function Set-FallbackMirrors {
    Write-Host 'Switching to direct package mirrors...' -ForegroundColor Yellow
    $dir = Join-Path $installDir 'etc\pacman.d'
    $lists = @{
        'mirrorlist.msys'  = @('Server = https://mirror.yandex.ru/mirrors/msys2/msys/$arch/', 'Server = https://repo.msys2.org/msys/$arch/')
        'mirrorlist.mingw' = @('Server = https://mirror.yandex.ru/mirrors/msys2/mingw/$repo/', 'Server = https://repo.msys2.org/mingw/$repo/')
    }
    foreach ($name in $lists.Keys) {
        $path = Join-Path $dir $name
        if (-not (Test-Path "$path.setup-backup")) {
            Copy-Item $path "$path.setup-backup"
        }
        [System.IO.File]::WriteAllText($path, (($lists[$name] -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    }
}

try {
    Write-Host '[1/4] Checking MSYS2...' -ForegroundColor Cyan
    if (-not (Test-Path $bash)) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'winget is missing. Install App Installer first.'
        }
        & winget install --exact --id MSYS2.MSYS2 --source winget --location $installDir --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $bash)) {
            throw 'MSYS2 installation failed.'
        }
    }

    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'
    & $bash -lc 'true' | Out-Null

    Write-Host '[2/4] Updating MSYS2...' -ForegroundColor Cyan
    # MSYS2 core packages may require a second fresh bash process.
    $updated = $false
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        Write-Host "Update attempt $attempt/4"
        $updated = Run-Pacman 'pacman -Syuu --noconfirm'
        if ($updated) { break }
        if ($attempt -eq 1) { Set-FallbackMirrors }
        Start-Sleep -Seconds 3
    }
    if (-not $updated) {
        throw 'MSYS2 update failed after retries. Check your internet connection or mirror availability.'
    }
    # Always do a fresh second pass after the core-system update.
    if (-not (Run-Pacman 'pacman -Syuu --noconfirm')) {
        throw 'Second MSYS2 update failed. Rerun this script to resume safely.'
    }

    Write-Host '[3/4] Installing GCC and GDB...' -ForegroundColor Cyan
    $installed = $false
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $installed = Run-Pacman 'pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb'
        if ($installed -and (Test-Path $compiler)) { break }
        if ($attempt -eq 1) { Set-FallbackMirrors }
        Start-Sleep -Seconds 3
    }
    if (-not $installed -or -not (Test-Path $compiler)) {
        throw 'GCC installation failed. Check package download errors above.'
    }

    Write-Host '[4/4] Configuring user PATH...' -ForegroundColor Cyan
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_.Trim() -ne '' })
    $normalized = $compilerDir.TrimEnd('\')
    $exists = @($entries | Where-Object { $_.Trim().TrimEnd('\') -ieq $normalized }).Count -gt 0
    if (-not $exists) {
        [Environment]::SetEnvironmentVariable('Path', ((@($entries) + $compilerDir) -join ';'), 'User')
    }
    if (-not (@($env:Path -split ';' | Where-Object { $_.Trim().TrimEnd('\') -ieq $normalized }).Count -gt 0)) {
        $env:Path = "$compilerDir;$env:Path"
    }

    & $compiler --version
    if ($LASTEXITCODE -ne 0) { throw 'Compiler verification failed.' }
    Write-Host "`nSuccess! Open a NEW terminal and run: g++ --version" -ForegroundColor Green
} catch {
    Write-Host "`nInstallation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
