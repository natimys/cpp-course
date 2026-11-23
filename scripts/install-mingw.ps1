$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$installRoot = Join-Path $env:LOCALAPPDATA 'Programs\WinLibs'
$compilerDir = Join-Path $installRoot 'mingw64'
$binDir = Join-Path $compilerDir 'bin'
$tempDir = Join-Path $env:TEMP ('winlibs-install-' + [guid]::NewGuid().ToString('N'))
$backupDir = $null

function Test-Compiler([string]$dir) {
    $exe = Join-Path $dir 'bin\g++.exe'
    if (-not (Test-Path -LiteralPath $exe)) { return $false }
    try { & $exe --version *> $null; return ($LASTEXITCODE -eq 0) }
    catch { return $false }
}

function Add-ToUserPath([string]$pathEntry) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_.Trim() })
    $normalized = $pathEntry.TrimEnd('\')
    $exists = @($entries | Where-Object { $_.Trim().TrimEnd('\') -ieq $normalized }).Count -gt 0
    if (-not $exists) {
        [Environment]::SetEnvironmentVariable('Path', (($entries + $pathEntry) -join ';'), 'User')
        Write-Host 'Added compiler to user PATH.' -ForegroundColor Green
    } else {
        Write-Host 'Compiler already exists in user PATH.'
    }
    $sessionEntries = @($env:Path -split ';' | Where-Object { $_.Trim() })
    if (-not (@($sessionEntries | Where-Object { $_.Trim().TrimEnd('\') -ieq $normalized }).Count -gt 0)) {
        $env:Path = "$pathEntry;$env:Path"
    }
}

try {
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'This installer requires 64-bit Windows.'
    }
    Write-Host '[1/4] Checking WinLibs...'
    if (Test-Compiler $compilerDir) {
        Write-Host 'WinLibs already installed; skipping download.' -ForegroundColor Green
    } else {
        Write-Host '[2/4] Selecting WinLibs GCC 16.2.0 (x64, UCRT, POSIX)...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        # Pinned GCC-only archive published by the WinLibs project.
        # Avoid GitHub Releases API enumeration and naming-pattern changes.
        $archiveName = 'winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip'
        $downloadUrl = 'https://github.com/brechtsanders/winlibs_mingw/releases/download/16.2.0posix-23.1.3-14.0.0-ucrt-r3/' + $archiveName
        Write-Host "Archive: $archiveName"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $zip = Join-Path $tempDir 'winlibs.zip'
        Write-Host '[3/4] Downloading and unpacking WinLibs (this archive can be large)...'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zip -UseBasicParsing -TimeoutSec 1800
        $extractDir = Join-Path $tempDir 'extracted'
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        Expand-Archive -LiteralPath $zip -DestinationPath $extractDir -Force
        $sourceDir = Join-Path $extractDir 'mingw64'
        if (-not (Test-Compiler $sourceDir)) {
            throw 'Archive does not contain a working mingw64\bin\g++.exe.'
        }
        New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
        if (Test-Path -LiteralPath $compilerDir) {
            $backupDir = Join-Path $installRoot ('mingw64.backup-' + [guid]::NewGuid().ToString('N'))
            Move-Item -LiteralPath $compilerDir -Destination $backupDir
        }
        try {
            Move-Item -LiteralPath $sourceDir -Destination $compilerDir
            if (-not (Test-Compiler $compilerDir)) { throw 'Compiler failed after installation.' }
        } catch {
            if (Test-Path -LiteralPath $compilerDir) { Remove-Item -LiteralPath $compilerDir -Recurse -Force }
            if ($backupDir -and (Test-Path -LiteralPath $backupDir)) {
                Move-Item -LiteralPath $backupDir -Destination $compilerDir
                $backupDir = $null
            }
            throw
        }
        if ($backupDir -and (Test-Path -LiteralPath $backupDir)) {
            Remove-Item -LiteralPath $backupDir -Recurse -Force
        }
    }

    Write-Host '[4/4] Configuring PATH and verifying GCC...'
    Add-ToUserPath $binDir
    & (Join-Path $binDir 'g++.exe') --version | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) { throw 'g++ verification failed.' }
    Write-Host "Success! WinLibs installed at: $compilerDir" -ForegroundColor Green
    Write-Host 'Open a NEW terminal, then run: g++ --version'
} catch {
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

