# Removes the reelgrab: link type and the desktop shortcut. Your downloaded files are not touched.
Remove-Item -Path 'HKCU:\Software\Classes\reelgrab' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path ([Environment]::GetFolderPath('Desktop')) 'ReelGrabber.lnk') -Force -ErrorAction SilentlyContinue
Write-Host "ReelGrabber removed. You can now delete this folder." -ForegroundColor Green
