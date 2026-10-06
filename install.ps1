# Notes4Me installer - installs the widget, adds Desktop + Startup shortcuts, and starts it.
# From a downloaded copy:  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
# From GitHub:  irm https://raw.githubusercontent.com/saysphilippe/Notes4Me/main/install.ps1 | iex
# Keep this file ASCII-only: Invoke-Expression chokes on a UTF-8 BOM, so Nordic letters are built with [char].
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/saysphilippe/Notes4Me/main'
$dest = Join-Path $env:LOCALAPPDATA 'Notes4Me'
$cfgPath = Join-Path $dest 'config.json'
$ae = [char]0xE6; $oe = [char]0xF8; $aa = [char]0xE5; $auml = [char]0xE4; $ouml = [char]0xF6

$cfg = [ordered]@{}
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}

$langs = 'en', 'no', 'sv', 'da'
$lang = $env:NOTES4ME_LANG
if ($lang -notin $langs) {
    Write-Host ''
    Write-Host "Choose display language / Velg spr${aa}k / V${auml}lj spr${aa}k / V${ae}lg sprog:" -ForegroundColor Cyan
    Write-Host '  1) English'
    Write-Host '  2) Norsk'
    Write-Host '  3) Svenska'
    Write-Host '  4) Dansk'
    $default = [array]::IndexOf($langs, [string]$cfg.language) + 1
    if ($default -lt 1) { $default = 1 }
    $answer = Read-Host "[1-4] (default $default)"
    if ($answer -notmatch '^[1-4]$') { $answer = $default }
    $lang = $langs[[int]$answer - 1]
}
$cfg.language = $lang

$msg = @{
    en = @{
        installing = 'Installing Notes4Me...'
        done = "Done. Installed to $dest - Notes4Me is now running and will start at login."
        tip = 'Tip: write (Customer) in a note to get a customer tab, and start a line with = to make a checkbox.'
    }
    no = @{
        installing = 'Installerer Notes4Me...'
        done = "Ferdig. Installert i $dest - Notes4Me kj${oe}rer n${aa} og starter automatisk ved innlogging."
        tip = "Tips: skriv (Kunde) i et notat for ${aa} f${aa} en kundefane, og start en linje med = for ${aa} lage en sjekkboks."
    }
    sv = @{
        installing = 'Installerar Notes4Me...'
        done = "Klart. Installerad i $dest - Notes4Me k${ouml}rs nu och startar automatiskt vid inloggning."
        tip = "Tips: skriv (Kund) i en anteckning f${ouml}r att f${aa} en kundflik, och b${ouml}rja en rad med = f${ouml}r att f${aa} en kryssruta."
    }
    da = @{
        installing = 'Installerer Notes4Me...'
        done = "F${ae}rdig. Installeret i $dest - Notes4Me k${oe}rer nu og starter automatisk ved login."
        tip = "Tip: skriv (Kunde) i en note for at f${aa} en kundefane, og start en linje med = for at lave et afkrydsningsfelt."
    }
}[$lang]

Write-Host $msg.installing -ForegroundColor Cyan
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*Notes4Me.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($f in 'Notes4Me.ps1', 'Launch.vbs', 'uninstall.ps1') {
    # Run from a downloaded copy: install those files; run via irm | iex: download them
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot $f))) { Copy-Item (Join-Path $PSScriptRoot $f) (Join-Path $dest $f) -Force }
    else { Invoke-WebRequest "$base/$f" -OutFile (Join-Path $dest $f) -UseBasicParsing }
}
$cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8

$ws = New-Object -ComObject WScript.Shell
foreach ($folder in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Startup')) {
    $lnk = $ws.CreateShortcut((Join-Path $folder 'Notes4Me.lnk'))
    $lnk.TargetPath = 'wscript.exe'
    $lnk.Arguments = "`"$dest\Launch.vbs`""
    $lnk.IconLocation = 'powershell.exe,0'
    $lnk.Save()
}

Start-Process wscript.exe "`"$dest\Launch.vbs`""
Write-Host $msg.done -ForegroundColor Green
Write-Host $msg.tip
