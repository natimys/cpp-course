# VS Code + C/C++ configuration for natimys/cpp-course
# Run with Windows PowerShell 5.1 or PowerShell 7 (no admin rights required for user installs).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$compilerInstallerUrl = 'https://raw.githubusercontent.com/natimys/cpp-course/main/scripts/install-mingw.ps1'
$extensionId = 'ms-vscode.cpptools'

function Get-VSCodeCli {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )
    if (${env:ProgramFiles(x86)}) {
        $candidates += Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\bin\code.cmd'
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    $cmd = Get-Command code.cmd -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Get-Compiler {
    # Prefer the compiler provided by this course, regardless of other GCC installations.
    $known = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\WinLibs\mingw64\bin\g++.exe'),
        'C:\msys64\ucrt64\bin\g++.exe',
        'C:\msys64\mingw64\bin\g++.exe'
    )
    $onPath = Get-Command g++.exe -ErrorAction SilentlyContinue
    if ($onPath) { $known += $onPath.Source }
    foreach ($candidate in ($known | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try {
            & $candidate --version *> $null
            if ($LASTEXITCODE -eq 0) { return $candidate }
        } catch { }
    }
    return $null
}

function Save-CompilerSetting([string]$compilerPath) {
    # Set the extension's user-wide default without destroying existing VS Code settings.
    $settingsDir = Join-Path $env:APPDATA 'Code\User'
    $settingsPath = Join-Path $settingsDir 'settings.json'
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

    if (Test-Path -LiteralPath $settingsPath) {
        $original = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($original)) { $original = '{}' }
    } else { $original = '{}' }

    # Preserve VS Code JSONC: comments, trailing commas, and all other settings.
    # Match an existing compilerPath setting (a JSON string) or append a new one.
    $escapedPath = ConvertTo-Json -InputObject $compilerPath -Compress
    $settingRegex = '("C_Cpp\.default\.compilerPath"\s*:\s*)"(?:\\.|[^"\\])*"'
    if ([regex]::IsMatch($original, $settingRegex)) {
        $replacement = '${1}' + $escapedPath
        $updated = ([regex]::new($settingRegex)).Replace($original, $replacement, 1)
    } else {
        # Find final root-closing brace (normal VS Code user settings file).
        $closing = $original.LastIndexOf('}')
        if ($closing -lt 0 -or -not $original.TrimStart().StartsWith('{')) {
            throw "Unexpected VS Code settings format: $settingsPath (not modified)."
        }
        $before = $original.Substring(0, $closing)
        $after = $original.Substring($closing)
        $trimmed = $before.TrimEnd()
        $last = if ($trimmed.Length -gt 0) { $trimmed[$trimmed.Length - 1] } else { '' }
        $comma = if ($last -eq '{' -or $last -eq ',') { '' } else { ',' }
        $updated = $trimmed + $comma + "`r`n    `"C_Cpp.default.compilerPath`": $escapedPath`r`n" + $after
    }
    $backup = "$settingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    if (Test-Path -LiteralPath $settingsPath) {
        Copy-Item -LiteralPath $settingsPath -Destination $backup -Force
    }
    $tempPath = Join-Path $settingsDir ('settings.' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText($tempPath, $updated, (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $tempPath -Destination $settingsPath -Force
    } finally {
        if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
    }
    Write-Host "VS Code compilerPath: $compilerPath" -ForegroundColor Green
}

try {
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'This setup requires 64-bit Windows.' }

    Write-Host '[1/3] Checking VS Code...'
    $code = Get-VSCodeCli
    if (-not $code) {

