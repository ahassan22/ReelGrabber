# Registers the reelgrab: link type (used by the browser extension) and adds a desktop shortcut.
# Everything is written under the current user only (HKCU); no administrator rights needed.
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path $here 'ReelGrabber.ps1'

if (-not (Test-Path $script)) { Write-Host "ReelGrabber.ps1 not found next to Install.ps1" -ForegroundColor Red; exit 1 }

# Unblock files that came from a downloaded zip
Get-ChildItem -Path $here -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

# ---------- install yt-dlp and ffmpeg automatically ----------
function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
                (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links')
}
Refresh-Path

$needs = @()
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) { $needs += 'yt-dlp.yt-dlp' }
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { $needs += 'Gyan.FFmpeg' }
if (-not (Get-Command deno -ErrorAction SilentlyContinue))   { $needs += 'DenoLand.Deno' }   # yt-dlp uses Deno for YouTube

if ($needs.Count -gt 0) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "winget is not available on this computer." -ForegroundColor Red
        Write-Host "Install 'App Installer' from the Microsoft Store, then run Install.bat again:"
        Write-Host "  https://apps.microsoft.com/detail/9NBLGGH4NNS1"
        exit 1
    }
    foreach ($id in $needs) {
        Write-Host ""
        Write-Host "Installing $id ... (needs internet, may take a few minutes)" -ForegroundColor Cyan
        winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent
    }
    Refresh-Path
} else {
    Write-Host "yt-dlp, ffmpeg and Deno are already installed." -ForegroundColor Green
}

# keep yt-dlp current (sites change often)
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Checking for yt-dlp updates..." -ForegroundColor Cyan
    winget upgrade --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements --silent | Out-Null
}

$cmd  = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`" `"%1`""
$base = 'HKCU:\Software\Classes\reelgrab'
New-Item -Path $base -Force | Out-Null
Set-ItemProperty -Path $base -Name '(default)' -Value 'URL:ReelGrabber Protocol'
New-ItemProperty -Path $base -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path "$base\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$base\shell\open\command" -Name '(default)' -Value $cmd

$desktop = [Environment]::GetFolderPath('Desktop')
$ws  = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $desktop 'ReelGrabber.lnk'))
$lnk.TargetPath       = 'powershell.exe'
$lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$lnk.WorkingDirectory = $here
$icon = Join-Path $here 'assets\fieldbuilt.ico'
if (Test-Path $icon) { $lnk.IconLocation = "$icon,0" } else { $lnk.IconLocation = "$env:SystemRoot\System32\imageres.dll,18" }
$lnk.Description      = "ReelGrabber - FieldBuilt by Ahmed Hassan"
$lnk.Save()

Write-Host ""
Write-Host "ReelGrabber installed." -ForegroundColor Green
Write-Host " - Desktop shortcut: ReelGrabber"
Write-Host " - Browser link type: reelgrab:"
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) { Write-Host " ! yt-dlp not found: winget install yt-dlp.yt-dlp" -ForegroundColor Yellow }
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { Write-Host " ! ffmpeg not found: winget install Gyan.FFmpeg" -ForegroundColor Yellow }
