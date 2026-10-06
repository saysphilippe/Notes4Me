# Removes the Notes4Me program files and shortcuts. Your notes are kept.
$dest = Join-Path $env:LOCALAPPDATA 'Notes4Me'
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*Notes4Me.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
foreach ($folder in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Startup')) {
    Remove-Item (Join-Path $folder 'Notes4Me.lnk') -ErrorAction SilentlyContinue
}
foreach ($f in 'Notes4Me.ps1', 'Launch.vbs', 'uninstall.ps1') { Remove-Item (Join-Path $dest $f) -ErrorAction SilentlyContinue }
Write-Host 'Notes4Me uninstalled.' -ForegroundColor Green
Write-Host "Your notes and settings were kept in $dest (notes.json). Delete that folder to remove them too."
