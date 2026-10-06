# Notes4Me - desktop notes widget with customer tabs and checklists
#   (Customer)  anywhere in a note puts it in that customer's tab
#   = at the start of a line makes it a checkbox; checked lines are stored as "=x "
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$dir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath   = Join-Path $dir 'config.json'
$notesPath = Join-Path $dir 'notes.json'
$utf8      = New-Object Text.UTF8Encoding $false

$cfg = [ordered]@{ topmost = $true; left = 120; top = 120; language = 'en'; tab = ''; fxAmount = '100'; fxDir = 'toNok'; width = $null; height = $null
         fxImport = $false; fxImpCur = 'EUR'; fxShip = '0'; fxDuty = '0'; fxVoec = $false; fxSeller = ''; wakeWord = $false }
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}
function Save-Config { $cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8 }

$strings = @{
    en = @{
        title = 'My notes'; all = 'All'; save = 'Save'; update = 'Update'; cancel = 'Cancel'; editing = 'Editing note'
        hint = 'Write a note…  (Customer) adds it to a customer tab, = at the start of a line makes a checkbox. Ctrl+Enter saves.'
        deleteSel = 'Delete selected ({0})'; selectAll = 'Select all'; clearSel = 'Clear selection'
        confirmDel = 'Delete {0} note(s)? This cannot be undone.'; empty = 'No notes yet'; edit = 'Double-click to edit'; select = 'Select for deletion'
        mFolder = 'Open notes folder'; mTopmost = 'Always on top'; mLanguage = 'Language'; mClose = 'Close'
        voice = 'Voice command: note, task or currency (Windows voice typing, Win+H)'; voiceActive = 'Dictating – the first word becomes the customer'
        resetSize = 'Restore default size'; grip = 'Drag to resize'
        custLink = 'Delete customer…'; custTip = 'Right-click to delete the customer'; custDelAll = 'Delete customer "{0}" and its notes ({1})'; custRemoveTag = 'Remove customer "{0}", keep the notes'
        confirmCustDel = 'Delete the customer "{0}"? {1} note(s) will be deleted. Notes that also belong to other customers are kept there. This cannot be undone.'
        confirmCustRemove = 'Remove the customer "{0}" from {1} note(s)? The notes are kept under All.'
        tabTasks = 'Tasks'; archiveBtn = 'Archive done ({0})'; showArchive = 'Show archive ({0})'; hideArchive = 'Hide archive'; archiveHdr = 'Archive'
        tasksEmpty = 'No tasks with a date yet. Write a line with a date, e.g. "= Send offer 16.10".'; dToday = 'Today'; dTomorrow = 'Tomorrow'; dOverdue = 'Overdue'
        cmdHint = 'Just say it, e.g. "Remember to send the offer to Equinor on Friday", "Talked to Statkraft about the sensors" or "How much is 100 euro". Enter runs it, Esc closes.'; cmdRun = 'Run'
        pvTask = 'Task'; pvNote = 'Note'; pvFor = 'for {0}'; pvLoose = '(no customer)'; pvAuto = 'runs in {0} s – Enter now, Esc to cancel'
        impToggle = 'Import cost via Posten (VAT and fee)'; impShip = 'Shipping'; impDuty = 'Duty %'; impVoec = 'VAT paid at checkout (VOEC, under 3000 kr per item)'
        mWake = 'Listen for "Notater" / "Notes4Me"'; wakeTip = ' – or say "Notater" / "Notes4Me"'; wakeErr = 'Could not start listening: {0}'
        impGoods = 'Goods'; impFrom = 'from {0}'; impDutyL = 'Duty ({0} %)'; impVat = 'VAT 25 %'; impFee = 'Posten fee'; impTotal = 'Total'; pvImport = 'import, total {0}'
        impNote = 'Posten 2026: 46 kr (value 0–500), 78 kr (500–3000), 278 kr (over 3000); no fee for VOEC. VAT is 25 % of goods + shipping + duty.'
        tabFx = 'Currency'; fxAmtTo = 'Amount in foreign currency'; fxAmtFrom = 'Amount in NOK'; fxRate = '1 {0} = {1} NOK'; fxNok = 'NOK'; fxForeign = 'Foreign'
        fxSource = 'Norges Bank rates, {0}'; fxFetching = 'Fetching rates…'; fxOffline = 'Could not fetch new rates – showing rates from {0}'
        fxNone = 'No rates yet – check the internet connection'; fxDate = 'Rate date'; fxLatest = 'Latest rates'; fxHistNone = 'No rates found for this date'; fxRefresh = 'Refresh'; fxCopy = 'Click to copy'; fxCopied = 'Copied {0}'
    }
    no = @{
        title = 'Mine notater'; all = 'Alle'; save = 'Lagre'; update = 'Oppdater'; cancel = 'Avbryt'; editing = 'Redigerer notat'
        hint = 'Skriv et notat…  (Kunde) legger det i en kundefane, = først på linjen gir en sjekkboks. Ctrl+Enter lagrer.'
        deleteSel = 'Slett valgte ({0})'; selectAll = 'Velg alle'; clearSel = 'Fjern valg'
        confirmDel = 'Slette {0} notat(er)? Dette kan ikke angres.'; empty = 'Ingen notater ennå'; edit = 'Dobbeltklikk for å redigere'; select = 'Velg for sletting'
        mFolder = 'Åpne notatmappen'; mTopmost = 'Alltid øverst'; mLanguage = 'Språk'; mClose = 'Lukk'
        voice = 'Talekommando: notat, oppgave eller valuta (Windows stemmeskriving, Win+H)'; voiceActive = 'Dikterer – første ord blir kunden'
        resetSize = 'Tilbakestill størrelse'; grip = 'Dra for å endre størrelse'
        custLink = 'Slett kunde…'; custTip = 'Høyreklikk for å slette kunden'; custDelAll = 'Slett kunden «{0}» og notatene ({1})'; custRemoveTag = 'Fjern kunden «{0}», behold notatene'
        confirmCustDel = 'Slette kunden «{0}»? {1} notat(er) slettes. Notater som også gjelder andre kunder, beholdes der. Dette kan ikke angres.'
        confirmCustRemove = 'Fjerne kunden «{0}» fra {1} notat(er)? Notatene beholdes under Alle.'
        tabTasks = 'Oppgaver'; archiveBtn = 'Arkiver utførte ({0})'; showArchive = 'Vis arkiv ({0})'; hideArchive = 'Skjul arkiv'; archiveHdr = 'Arkiv'
        tasksEmpty = 'Ingen oppgaver med dato ennå. Skriv en linje med dato, f.eks. «= Sende tilbud 16.10».'; dToday = 'I dag'; dTomorrow = 'I morgen'; dOverdue = 'Forfalt'
        cmdHint = 'Si det med egne ord, f.eks. «Husk å sende tilbud til Equinor på fredag», «Snakket med Statkraft om sensorene» eller «Hvor mye er 100 euro». Enter utfører, Esc lukker.'; cmdRun = 'Utfør'
        pvTask = 'Oppgave'; pvNote = 'Notat'; pvFor = 'for {0}'; pvLoose = '(uten kunde)'; pvAuto = 'utføres om {0} s – Enter nå, Esc avbryter'
        impToggle = 'Importkostnad via Posten (mva og gebyr)'; impShip = 'Frakt'; impDuty = 'Toll %'; impVoec = 'Mva betalt i nettbutikken (VOEC, under 3000 kr per vare)'
        mWake = 'Lytt etter «Notater» / «Notes4Me»'; wakeTip = ' – eller si «Notater» / «Notes4Me»'; wakeErr = 'Kunne ikke starte lytting: {0}'
        impGoods = 'Varepris'; impFrom = 'fra {0}'; impDutyL = 'Toll ({0} %)'; impVat = 'Mva 25 %'; impFee = 'Postens gebyr'; impTotal = 'Sluttsum'; pvImport = 'import, sluttsum {0}'
        impNote = 'Posten 2026: 46 kr (verdi 0–500), 78 kr (500–3000), 278 kr (over 3000); ingen gebyr ved VOEC. Mva er 25 % av varepris + frakt + toll.'
        tabFx = 'Valuta'; fxAmtTo = 'Beløp i valuta'; fxAmtFrom = 'Beløp i kroner'; fxRate = '1 {0} = {1} kr'; fxNok = 'kr'; fxForeign = 'Valuta'
        fxSource = 'Kurser fra Norges Bank, {0}'; fxFetching = 'Henter kurser…'; fxOffline = 'Fikk ikke hentet nye kurser – viser kurser fra {0}'
        fxNone = 'Ingen kurser ennå – sjekk internettforbindelsen'; fxDate = 'Kursdato'; fxLatest = 'Siste kurser'; fxHistNone = 'Fant ingen kurser for denne datoen'; fxRefresh = 'Oppdater'; fxCopy = 'Klikk for å kopiere'; fxCopied = 'Kopierte {0}'
    }
    sv = @{
        title = 'Mina anteckningar'; all = 'Alla'; save = 'Spara'; update = 'Uppdatera'; cancel = 'Avbryt'; editing = 'Redigerar anteckning'
        hint = 'Skriv en anteckning…  (Kund) lägger den i en kundflik, = först på raden ger en kryssruta. Ctrl+Enter sparar.'
        deleteSel = 'Ta bort markerade ({0})'; selectAll = 'Markera alla'; clearSel = 'Avmarkera'
        confirmDel = 'Ta bort {0} anteckning(ar)? Det går inte att ångra.'; empty = 'Inga anteckningar ännu'; edit = 'Dubbelklicka för att redigera'; select = 'Markera för borttagning'
        mFolder = 'Öppna anteckningsmappen'; mTopmost = 'Alltid överst'; mLanguage = 'Språk'; mClose = 'Stäng'
        voice = 'Röstkommando: anteckning, uppgift eller valuta (Windows röstinmatning, Win+H)'; voiceActive = 'Dikterar – första ordet blir kunden'
        resetSize = 'Återställ storlek'; grip = 'Dra för att ändra storlek'
        custLink = 'Ta bort kund…'; custTip = 'Högerklicka för att ta bort kunden'; custDelAll = 'Ta bort kunden ”{0}” och anteckningarna ({1})'; custRemoveTag = 'Ta bort kunden ”{0}”, behåll anteckningarna'
        confirmCustDel = 'Ta bort kunden ”{0}”? {1} anteckning(ar) tas bort. Anteckningar som även hör till andra kunder behålls där. Det går inte att ångra.'
        confirmCustRemove = 'Ta bort kunden ”{0}” från {1} anteckning(ar)? Anteckningarna finns kvar under Alla.'
        tabTasks = 'Uppgifter'; archiveBtn = 'Arkivera klara ({0})'; showArchive = 'Visa arkiv ({0})'; hideArchive = 'Dölj arkiv'; archiveHdr = 'Arkiv'
        tasksEmpty = 'Inga uppgifter med datum ännu. Skriv en rad med datum, t.ex. ”= Skicka offert 16.10”.'; dToday = 'I dag'; dTomorrow = 'I morgon'; dOverdue = 'Försenad'
        cmdHint = 'Säg det med egna ord, t.ex. ”Kom ihåg att skicka offert till Equinor på fredag”, ”Pratade med Statkraft om sensorerna” eller ”Hur mycket är 100 euro”. Enter kör, Esc stänger.'; cmdRun = 'Kör'
        pvTask = 'Uppgift'; pvNote = 'Anteckning'; pvFor = 'för {0}'; pvLoose = '(utan kund)'; pvAuto = 'körs om {0} s – Enter nu, Esc avbryter'
        impToggle = 'Importkostnad via Posten (moms och avgift)'; impShip = 'Frakt'; impDuty = 'Tull %'; impVoec = 'Moms betald i webbutiken (VOEC, under 3000 kr per vara)'
        mWake = 'Lyssna efter ”Notater” / ”Notes4Me”'; wakeTip = ' – eller säg ”Notater” / ”Notes4Me”'; wakeErr = 'Kunde inte börja lyssna: {0}'
        impGoods = 'Varupris'; impFrom = 'från {0}'; impDutyL = 'Tull ({0} %)'; impVat = 'Moms 25 %'; impFee = 'Postens avgift'; impTotal = 'Totalt'; pvImport = 'import, totalt {0}'
        impNote = 'Posten 2026: 46 kr (värde 0–500), 78 kr (500–3000), 278 kr (över 3000); ingen avgift vid VOEC. Momsen är 25 % av varupris + frakt + tull.'
        tabFx = 'Valuta'; fxAmtTo = 'Belopp i utländsk valuta'; fxAmtFrom = 'Belopp i NOK'; fxRate = '1 {0} = {1} NOK'; fxNok = 'NOK'; fxForeign = 'Valuta'
        fxSource = 'Kurser från Norges Bank, {0}'; fxFetching = 'Hämtar kurser…'; fxOffline = 'Kunde inte hämta nya kurser – visar kurser från {0}'
        fxNone = 'Inga kurser ännu – kontrollera internetanslutningen'; fxDate = 'Kursdatum'; fxLatest = 'Senaste kurser'; fxHistNone = 'Hittade inga kurser för det datumet'; fxRefresh = 'Uppdatera'; fxCopy = 'Klicka för att kopiera'; fxCopied = 'Kopierade {0}'
    }
    da = @{
        title = 'Mine noter'; all = 'Alle'; save = 'Gem'; update = 'Opdater'; cancel = 'Annuller'; editing = 'Redigerer note'
        hint = 'Skriv en note…  (Kunde) lægger den i en kundefane, = først på linjen giver et afkrydsningsfelt. Ctrl+Enter gemmer.'
        deleteSel = 'Slet valgte ({0})'; selectAll = 'Vælg alle'; clearSel = 'Fravælg'
        confirmDel = 'Slet {0} note(r)? Det kan ikke fortrydes.'; empty = 'Ingen noter endnu'; edit = 'Dobbeltklik for at redigere'; select = 'Vælg til sletning'
        mFolder = 'Åbn notemappen'; mTopmost = 'Altid øverst'; mLanguage = 'Sprog'; mClose = 'Luk'
        voice = 'Stemmekommando: note, opgave eller valuta (Windows stemmeskrivning, Win+H)'; voiceActive = 'Dikterer – første ord bliver kunden'
        resetSize = 'Nulstil størrelse'; grip = 'Træk for at ændre størrelse'
        custLink = 'Slet kunde…'; custTip = 'Højreklik for at slette kunden'; custDelAll = 'Slet kunden »{0}« og noterne ({1})'; custRemoveTag = 'Fjern kunden »{0}«, behold noterne'
        confirmCustDel = 'Slet kunden »{0}«? {1} note(r) slettes. Noter, der også hører til andre kunder, beholdes der. Det kan ikke fortrydes.'
        confirmCustRemove = 'Fjern kunden »{0}« fra {1} note(r)? Noterne beholdes under Alle.'
        tabTasks = 'Opgaver'; archiveBtn = 'Arkivér udførte ({0})'; showArchive = 'Vis arkiv ({0})'; hideArchive = 'Skjul arkiv'; archiveHdr = 'Arkiv'
        tasksEmpty = 'Ingen opgaver med dato endnu. Skriv en linje med dato, f.eks. »= Send tilbud 16.10«.'; dToday = 'I dag'; dTomorrow = 'I morgen'; dOverdue = 'Forfalden'
        cmdHint = 'Sig det med dine egne ord, f.eks. »Husk at sende tilbud til Equinor på fredag«, »Talte med Statkraft om sensorerne« eller »Hvor meget er 100 euro«. Enter udfører, Esc lukker.'; cmdRun = 'Udfør'
        pvTask = 'Opgave'; pvNote = 'Note'; pvFor = 'for {0}'; pvLoose = '(uden kunde)'; pvAuto = 'udføres om {0} s – Enter nu, Esc annullerer'
        impToggle = 'Importomkostning via Posten (moms og gebyr)'; impShip = 'Fragt'; impDuty = 'Told %'; impVoec = 'Moms betalt i webshoppen (VOEC, under 3000 kr pr. vare)'
        mWake = 'Lyt efter »Notater« / »Notes4Me«'; wakeTip = ' – eller sig »Notater« / »Notes4Me«'; wakeErr = 'Kunne ikke starte lytning: {0}'
        impGoods = 'Varepris'; impFrom = 'fra {0}'; impDutyL = 'Told ({0} %)'; impVat = 'Moms 25 %'; impFee = 'Postens gebyr'; impTotal = 'I alt'; pvImport = 'import, i alt {0}'
        impNote = 'Posten 2026: 46 kr (værdi 0–500), 78 kr (500–3000), 278 kr (over 3000); intet gebyr ved VOEC. Momsen er 25 % af varepris + fragt + told.'
        tabFx = 'Valuta'; fxAmtTo = 'Beløb i udenlandsk valuta'; fxAmtFrom = 'Beløb i NOK'; fxRate = '1 {0} = {1} NOK'; fxNok = 'NOK'; fxForeign = 'Valuta'
        fxSource = 'Kurser fra Norges Bank, {0}'; fxFetching = 'Henter kurser…'; fxOffline = 'Kunne ikke hente nye kurser – viser kurser fra {0}'
        fxNone = 'Ingen kurser endnu – tjek internetforbindelsen'; fxDate = 'Kursdato'; fxLatest = 'Seneste kurser'; fxHistNone = 'Fandt ingen kurser for denne dato'; fxRefresh = 'Opdater'; fxCopy = 'Klik for at kopiere'; fxCopied = 'Kopierede {0}'
    }
}
$langNames = [ordered]@{ en = 'English'; no = 'Norsk'; sv = 'Svenska'; da = 'Dansk' }
function T($key) { $s = $strings[$cfg.language]; if (-not $s) { $s = $strings.en }; $s[$key] }

# --- Storage ----------------------------------------------------------------
# notes.json is written to a temp file first and swapped in, keeping the previous
# version as notes.json.bak. If notes.json cannot be read, the backup is used and
# the unreadable file is kept aside so nothing is silently overwritten.
$script:notes = New-Object System.Collections.Generic.List[object]
function Read-NotesFile($path) {
    $j = [IO.File]::ReadAllText($path, $utf8) | ConvertFrom-Json
    foreach ($n in @($j.notes)) {
        if ($n.id) { @{ id = [string]$n.id; created = [string]$n.created; updated = [string]$n.updated; text = [string]$n.text } }
    }
}
if (Test-Path $notesPath) {
    try { $loaded = @(Read-NotesFile $notesPath) }
    catch {
        Copy-Item $notesPath (Join-Path $dir ("notes.unreadable-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
        $loaded = @(); if (Test-Path "$notesPath.bak") { try { $loaded = @(Read-NotesFile "$notesPath.bak") } catch {} }
    }
    foreach ($n in $loaded) { $script:notes.Add($n) }
}
function Save-Notes {
    $json = @{ version = 1; notes = [object[]]$script:notes.ToArray() } | ConvertTo-Json -Depth 4
    $tmp = "$notesPath.tmp"
    [IO.File]::WriteAllText($tmp, $json, $utf8)
    if (Test-Path $notesPath) { [IO.File]::Replace($tmp, $notesPath, "$notesPath.bak") } else { [IO.File]::Move($tmp, $notesPath) }
}
function Get-Note($id) { foreach ($n in $script:notes) { if ($n.id -eq $id) { return $n } } }
function Now-Iso { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }

# --- Parsing ----------------------------------------------------------------
$custRx = [regex]'\(([^()\r\n]{1,40})\)'
$lineRx = [regex]'^=([xa]\s)?\s*(.*)$'   # '= ' open, '=x ' done, '=a ' done and archived (Tasks tab)
function Get-Customers($text) { foreach ($m in $custRx.Matches($text)) { $c = $m.Groups[1].Value.Trim(); if ($c) { $c } } }
function Test-Customer($note, $key) { foreach ($c in Get-Customers $note.text) { if ($c.ToLower() -eq $key) { return $true } }; $false }
function Set-LineChecked($id, $index, $checked) {
    $note = Get-Note $id; if (-not $note) { return }
    $lines = $note.text -split "`n"
    $m = $lineRx.Match($lines[$index])
    if ($m.Success) { $lines[$index] = $(if ($checked) { '=x ' } else { '= ' }) + $m.Groups[2].Value }
    elseif ($checked) { $lines[$index] = '=x ' + $lines[$index].Trim() }   # a plain dated line ticked in the Tasks tab
    else { return }
    $note.text = $lines -join "`n"; $note.updated = Now-Iso
    Save-Notes; Render
}

# --- Window -----------------------------------------------------------------
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="False" SizeToContent="Height" Width="340" MinWidth="300" MinHeight="220" ResizeMode="NoResize">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Background" Value="#D97757"/>
      <Setter Property="Padding" Value="10,3"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="b" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.85"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="6"/>
      <Setter Property="MinWidth" Value="6"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb"><Border Background="#555" CornerRadius="3"/></ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="DatePickerTextBox">
      <Setter Property="Background" Value="#2B2B2B"/>
      <Setter Property="Foreground" Value="#EEE"/>
      <Setter Property="CaretBrush" Value="#EEE"/>
    </Style>
  </Window.Resources>
  <Grid>
  <Border CornerRadius="10" Background="#E61E1E1E" Padding="12,10">
    <DockPanel>
      <DockPanel DockPanel.Dock="Top">
        <TextBlock Name="resetSize" DockPanel.Dock="Right" FontFamily="Segoe MDL2 Assets" Text="&#xE73F;" FontSize="12"
                   Foreground="#888" Cursor="Hand" VerticalAlignment="Center" Visibility="Collapsed" Margin="10,0,0,0"/>
        <TextBlock Name="titleMic" DockPanel.Dock="Right" FontFamily="Segoe MDL2 Assets" Text="&#xE720;" FontSize="15"
                   Foreground="#BBB" Cursor="Hand" VerticalAlignment="Center"/>
        <TextBlock Name="title" Foreground="#D97757" FontWeight="SemiBold" FontSize="13" TextTrimming="CharacterEllipsis"/>
      </DockPanel>
      <Border Name="cmdBar" DockPanel.Dock="Top" Visibility="Collapsed" Background="#262A30" CornerRadius="6" Padding="6"
              Margin="0,6,0,2" BorderBrush="#6A9BCC" BorderThickness="1">
        <StackPanel>
          <Grid>
            <TextBox Name="cmdBox" FontSize="13" Background="#2B2B2B" Foreground="#EEE" CaretBrush="#EEE" BorderThickness="0"
                     Padding="4,3" TextWrapping="Wrap" MinHeight="26"/>
            <TextBlock Name="cmdHint" Foreground="#777" FontSize="11" TextWrapping="Wrap" Margin="7,4,7,0" IsHitTestVisible="False"/>
          </Grid>
          <DockPanel Margin="0,5,0,0">
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Top">
              <Button Name="cmdClose" Background="#444" Padding="8,2" FontSize="11" Margin="0,0,6,0"/>
              <Button Name="cmdRun" Background="#6A9BCC" Padding="10,2" FontSize="11"/>
            </StackPanel>
            <TextBlock Name="cmdPreview" Foreground="#9DBEE0" FontSize="11" TextWrapping="Wrap" VerticalAlignment="Center"/>
          </DockPanel>
        </StackPanel>
      </Border>
      <WrapPanel Name="tabs" DockPanel.Dock="Top" Margin="0,6,0,4"/>
      <StackPanel Name="fxPanel" DockPanel.Dock="Top" Visibility="Collapsed" Margin="0,2,0,0">
        <StackPanel Name="fxDir" Orientation="Horizontal" Margin="0,0,0,6"/>
        <DockPanel Margin="0,0,0,8">
          <TextBlock Name="fxLatest" DockPanel.Dock="Right" Foreground="#888" FontSize="11" Cursor="Hand" VerticalAlignment="Center"/>
          <TextBlock Name="fxDateLbl" DockPanel.Dock="Left" Foreground="#999" FontSize="11" VerticalAlignment="Center" Margin="0,0,8,0"/>
          <DatePicker Name="fxDate" Width="130" HorizontalAlignment="Left" FontSize="11" Foreground="#EEE" Background="#2B2B2B" BorderBrush="#444"/>
        </DockPanel>
        <TextBlock Name="fxAmountLbl" Foreground="#999" FontSize="11"/>
        <TextBox Name="fxAmount" FontSize="18" Margin="0,3,0,8" Background="#2B2B2B" Foreground="#EEE" CaretBrush="#EEE"
                 BorderBrush="#444" BorderThickness="1" Padding="6,3"/>
        <StackPanel Name="fxResults"/>
        <Border Name="impCard" Background="#2B2B2B" CornerRadius="6" Padding="10,7" Margin="0,2,0,8">
          <StackPanel>
            <CheckBox Name="impToggle" Foreground="#DDD" FontSize="12" VerticalContentAlignment="Center"/>
            <StackPanel Name="impBody" Visibility="Collapsed" Margin="0,8,0,0">
              <StackPanel Name="impCurs" Orientation="Horizontal" Margin="0,0,0,8"/>
              <Grid Margin="0,0,0,6">
                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="10"/><ColumnDefinition/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                  <TextBlock Name="impShipLbl" Foreground="#999" FontSize="11"/>
                  <TextBox Name="impShip" FontSize="13" Background="#232323" Foreground="#EEE" CaretBrush="#EEE" BorderBrush="#444" Padding="4,2"/>
                </StackPanel>
                <StackPanel Grid.Column="2">
                  <TextBlock Name="impDutyLbl" Foreground="#999" FontSize="11"/>
                  <TextBox Name="impDuty" FontSize="13" Background="#232323" Foreground="#EEE" CaretBrush="#EEE" BorderBrush="#444" Padding="4,2"/>
                </StackPanel>
              </Grid>
              <CheckBox Name="impVoec" Foreground="#BBB" FontSize="11" Margin="0,0,0,8"/>
              <TextBlock Name="impTitle" Foreground="#D97757" FontSize="12" Margin="0,0,0,3"/>
              <StackPanel Name="impLines"/>
              <TextBlock Name="impNote" Foreground="#777" FontSize="10" TextWrapping="Wrap" Margin="0,6,0,0"/>
            </StackPanel>
          </StackPanel>
        </Border>
        <DockPanel Margin="0,2,0,0">
          <TextBlock Name="fxRefresh" DockPanel.Dock="Right" Foreground="#888" FontSize="11" Cursor="Hand" Margin="8,0,12,0" VerticalAlignment="Center"/>
          <TextBlock Name="fxStatus" Foreground="#777" FontSize="10" TextWrapping="Wrap" VerticalAlignment="Center"/>
        </DockPanel>
      </StackPanel>
      <DockPanel Name="notesPanel">
        <Grid DockPanel.Dock="Top">
          <TextBox Name="input" MinHeight="58" MaxHeight="160" AcceptsReturn="True" TextWrapping="Wrap"
                   VerticalScrollBarVisibility="Auto" Background="#2B2B2B" Foreground="#EEE" CaretBrush="#EEE"
                   BorderBrush="#444" BorderThickness="1" Padding="4,3" FontSize="12"/>
          <TextBlock Name="hint" Foreground="#777" FontSize="11" TextWrapping="Wrap" Margin="7,5,7,0" IsHitTestVisible="False"/>
        </Grid>
        <DockPanel DockPanel.Dock="Top" Margin="0,4,0,8">
          <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
            <Button Name="cancelBtn" Background="#444" Visibility="Collapsed" Margin="0,0,6,0"/>
            <Button Name="saveBtn"/>
          </StackPanel>
          <TextBlock Name="editLbl" Foreground="#999" FontSize="11" VerticalAlignment="Center" TextWrapping="Wrap" Visibility="Collapsed"/>
        </DockPanel>
        <DockPanel Name="toolbar" DockPanel.Dock="Top" Margin="0,0,0,4">
          <Button Name="delBtn" DockPanel.Dock="Right" Background="#B5523B" Padding="8,2" FontSize="11" Visibility="Collapsed"/>
          <Button Name="archBtn" DockPanel.Dock="Right" Background="#5E7F4A" Padding="8,2" FontSize="11" Visibility="Collapsed"/>
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
            <TextBlock Name="selAll" Foreground="#888" FontSize="11" Cursor="Hand"/>
            <TextBlock Name="custLink" Foreground="#888" FontSize="11" Cursor="Hand" Margin="14,0,0,0" Visibility="Collapsed"/>
            <TextBlock Name="archLink" Foreground="#888" FontSize="11" Cursor="Hand" Visibility="Collapsed"/>
          </StackPanel>
        </DockPanel>
        <TextBlock Name="emptyLbl" DockPanel.Dock="Top" Foreground="#777" FontSize="11" Margin="0,4,0,0"/>
        <ScrollViewer Name="listScroll" MaxHeight="430" VerticalScrollBarVisibility="Auto">
          <StackPanel Name="list" Margin="0,0,4,0"/>
        </ScrollViewer>
      </DockPanel>
    </DockPanel>
  </Border>
  <Thumb Name="grip" HorizontalAlignment="Right" VerticalAlignment="Bottom" Width="14" Height="14" Margin="0,0,3,3" Cursor="SizeNWSE">
    <Thumb.Template>
      <ControlTemplate TargetType="Thumb">
        <Grid Background="Transparent">
          <Path Data="M 12,3 L 3,12 M 12,7 L 7,12 M 12,11 L 11,12" Stroke="#777" StrokeThickness="1"/>
        </Grid>
      </ControlTemplate>
    </Thumb.Template>
  </Thumb>
  </Grid>
</Window>
'@
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$el = @{}
'title','tabs','input','hint','cancelBtn','saveBtn','editLbl','toolbar','delBtn','selAll','list','emptyLbl','titleMic','cmdBar','cmdBox','cmdHint','cmdPreview','cmdRun','cmdClose',
'notesPanel','fxPanel','fxDir','fxAmountLbl','fxAmount','fxResults','fxRefresh','fxStatus','fxLatest','fxDateLbl','fxDate',
'resetSize','grip','listScroll','custLink','archBtn','archLink',
'impCard','impToggle','impBody','impCurs','impShipLbl','impShip','impDutyLbl','impDuty','impVoec','impTitle','impLines','impNote' | ForEach-Object { $el[$_] = $win.FindName($_) }
$win.Left = $cfg.left; $win.Top = $cfg.top; $win.Topmost = [bool]$cfg.topmost

$brushConv = New-Object Windows.Media.BrushConverter
function Brush($c) { $brushConv.ConvertFromString($c) }
function Thick($l, $t, $r, $b) { New-Object Windows.Thickness $l, $t, $r, $b }

$script:selected = New-Object 'System.Collections.Generic.HashSet[string]'
$script:visible = @()
$script:editId = $null
$script:custNames = @{}

# The list hides (Customer) - you pick the customer tab instead. The All tab shows it in the card header.
# A tag at the start or end of a line is removed; inside a sentence only the parentheses go:
# "(Equinor) ring tilbake" -> "ring tilbake", "Møte med (Equinor) i dag" -> "Møte med Equinor i dag"
function Get-DisplayText($text) {
    $out = $custRx.Replace($text, [Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $before = $text.Substring(0, $m.Index).Trim(); $after = $text.Substring($m.Index + $m.Length).Trim()
        if (-not $before -or -not $after) { '' } else { $m.Groups[1].Value }
    })
    ($out -replace '\s{2,}', ' ').Trim()
}

function New-NoteCard($note) {
    $isSel = $script:selected.Contains($note.id)
    $card = New-Object Windows.Controls.Border
    $card.CornerRadius = New-Object Windows.CornerRadius 6; $card.Padding = Thick 8 6 8 7; $card.Margin = Thick 0 0 0 6
    $card.Background = Brush $(if ($isSel) { '#3A2D28' } else { '#2B2B2B' })
    $card.BorderBrush = Brush $(if ($isSel) { '#D97757' } else { '#2B2B2B' }); $card.BorderThickness = Thick 1 1 1 1
    $sp = New-Object Windows.Controls.StackPanel

    $head = New-Object Windows.Controls.DockPanel; $head.Margin = Thick 0 0 0 3
    $sel = New-Object Windows.Controls.CheckBox
    $sel.IsChecked = $isSel; $sel.Tag = $note.id; $sel.VerticalAlignment = 'Center'; $sel.Margin = Thick 0 0 6 0; $sel.ToolTip = T 'select'
    $sel.Add_Click({ param($s, $e) if ($s.IsChecked) { [void]$script:selected.Add($s.Tag) } else { [void]$script:selected.Remove($s.Tag) }; Render })
    [Windows.Controls.DockPanel]::SetDock($sel, 'Left')
    $custTb = New-Object Windows.Controls.TextBlock
    $custTb.Foreground = Brush '#D97757'; $custTb.FontSize = 10; $custTb.VerticalAlignment = 'Center'; $custTb.TextTrimming = 'CharacterEllipsis'; $custTb.MaxWidth = 150
    if (-not $cfg.tab) {   # same spelling as the tab, e.g. "Equinor" even if the note says "(equinor)"
        $custTb.Text = (@(Get-Customers $note.text | ForEach-Object { $k = $_.ToLower(); if ($script:custNames[$k]) { $script:custNames[$k] } else { $_ } }) | Sort-Object -Unique) -join ', '
    }
    [Windows.Controls.DockPanel]::SetDock($custTb, 'Right')
    $date = New-Object Windows.Controls.TextBlock
    $date.Text = ([datetime]::Parse($note.created, $null, 'RoundtripKind')).ToLocalTime().ToString('g')
    $date.Foreground = Brush '#888'; $date.FontSize = 10; $date.VerticalAlignment = 'Center'
    [void]$head.Children.Add($sel); [void]$head.Children.Add($custTb); [void]$head.Children.Add($date)
    [void]$sp.Children.Add($head)

    # Double-click a note to edit it. Clicks on a card never start dragging the window.
    $card.Tag = $note.id; $card.ToolTip = T 'edit'
    [Windows.Controls.ToolTipService]::SetInitialShowDelay($card, 1500)
    $card.Add_MouseLeftButtonDown({ param($s, $e) if ($e.ClickCount -ge 2) { Start-Edit $s.Tag }; $e.Handled = $true })

    $lines = $note.text -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $tb = New-Object Windows.Controls.TextBlock
        $tb.TextWrapping = 'Wrap'; $tb.FontSize = 12; $tb.Foreground = Brush '#DDD'
        $m = $lineRx.Match($line)
        if ($line.Trim() -ne '' -and -not (Get-DisplayText ($line -replace '^=([xa]\s)?', ''))) { continue }  # line held only (Customer)
        if ($m.Success) {
            $checked = $m.Groups[1].Success
            $tb.Text = Get-DisplayText $m.Groups[2].Value
            if ($checked) { $tb.TextDecorations = [Windows.TextDecorations]::Strikethrough; $tb.Foreground = Brush '#777' }
            $cb = New-Object Windows.Controls.CheckBox
            # Only the box itself ticks; the text is separate so a double-click on it edits the note
            $cb.IsChecked = $checked; $cb.Margin = Thick 0 2 6 0; $cb.VerticalAlignment = 'Top'
            $cb.Tag = @{ id = $note.id; line = $i }
            $cb.Add_Click({ param($s, $e) Set-LineChecked $s.Tag.id $s.Tag.line ([bool]$s.IsChecked) })
            $ln = New-Object Windows.Controls.DockPanel; $ln.Margin = Thick 0 1 0 1
            [Windows.Controls.DockPanel]::SetDock($cb, 'Left'); [void]$ln.Children.Add($cb); [void]$ln.Children.Add($tb)
            [void]$sp.Children.Add($ln)
        } elseif ($line.Trim() -eq '') {
            $tb.Height = 6; [void]$sp.Children.Add($tb)
        } else {
            $tb.Text = Get-DisplayText $line; [void]$sp.Children.Add($tb)
        }
    }
    $card.Child = $sp
    $card
}

function Render {
    # Customers: key = lower-case name, display = casing from the newest note
    $sorted = @($script:notes | Sort-Object { $_.created }, { $script:notes.IndexOf($_) } -Descending)  # ties: last added first
    $cust = [ordered]@{}; $counts = @{}
    foreach ($n in $sorted) {
        foreach ($k in @(Get-Customers $n.text | ForEach-Object { $_ } | Sort-Object -Unique)) {
            $key = $k.ToLower()
            if (-not $cust.Contains($key)) { $cust[$key] = $k; $counts[$key] = 0 }
            elseif ([char]::IsLower($cust[$key][0]) -and [char]::IsUpper($k[0])) { $cust[$key] = $k }  # prefer "Equinor" over "equinor"
        }
        foreach ($key in @(Get-Customers $n.text | ForEach-Object { $_.ToLower() } | Sort-Object -Unique)) { $counts[$key]++ }
    }
    if ($cfg.tab -and $cfg.tab -notin $fxTab, $tasksTab -and -not $cust.Contains([string]$cfg.tab)) { $cfg.tab = ''; Save-Config }
    $script:custNames = $cust

    # Tabs
    $el.tabs.Children.Clear()
    $openTasks = @(Get-Tasks | Where-Object { -not $_.checked }).Count
    $tabList = @(@{ key = $tasksTab; name = T 'tabTasks'; count = $openTasks }) +
               @(@{ key = $fxTab; name = T 'tabFx'; count = $null }) +
               @(@{ key = ''; name = T 'all'; count = $sorted.Count }) +
               @($cust.Keys | Sort-Object { $cust[$_] } | ForEach-Object { @{ key = $_; name = $cust[$_]; count = $counts[$_] } })
    foreach ($t in $tabList) {
        $active = $t.key -eq [string]$cfg.tab; $isFx = $t.key -eq $fxTab; $isTasks = $t.key -eq $tasksTab
        $chip = New-Object Windows.Controls.Border
        $chip.CornerRadius = New-Object Windows.CornerRadius 12; $chip.Padding = Thick 10 3 10 4; $chip.Margin = Thick 0 0 5 5; $chip.Cursor = 'Hand'
        $chip.Background = Brush $(if ($active -and $isFx) { '#6A9BCC' } elseif ($active -and $isTasks) { '#5E7F4A' } elseif ($active) { '#D97757' } else { '#2B2B2B' }); $chip.Tag = $t.key
        $tx = New-Object Windows.Controls.TextBlock
        $tx.Text = $(if ($isFx) { $t.name } else { "$($t.name)  $($t.count)" }); $tx.FontSize = 13
        $tx.Foreground = Brush $(if ($active) { '#FFF' } elseif ($isFx) { '#9DBEE0' } elseif ($isTasks) { '#B5D19E' } else { '#BBB' })
        $chip.Child = $tx
        if ($t.key -and -not $isFx -and -not $isTasks) { $chip.ContextMenu = New-CustomerMenu $t.key; $chip.ToolTip = T 'custTip' }
        $chip.Add_MouseLeftButtonDown({
            param($s, $e)
            $cfg.tab = [string]$s.Tag; Save-Config; $script:selected.Clear(); Render; $e.Handled = $true
            if ($cfg.tab -eq $fxTab) { $el.fxAmount.Focus() | Out-Null; $el.fxAmount.SelectAll() }
        })
        [void]$el.tabs.Children.Add($chip)
    }

    # Currency tab replaces the notes view
    $fx = $cfg.tab -eq $fxTab
    $el.fxPanel.Visibility = $(if ($fx) { 'Visible' } else { 'Collapsed' })
    $el.notesPanel.Visibility = $(if ($fx) { 'Collapsed' } else { 'Visible' })
    if ($fx) { Render-Fx; Update-Rates; return }
    if ($cfg.tab -eq $tasksTab) { Render-Tasks; return }
    $el.selAll.Visibility = 'Visible'; $el.archBtn.Visibility = 'Collapsed'; $el.archLink.Visibility = 'Collapsed'

    # Notes in the active tab, newest first
    $vis = if ($cfg.tab) { @($sorted | Where-Object { Test-Customer $_ ([string]$cfg.tab) }) } else { $sorted }
    $script:visible = @($vis | ForEach-Object { $_.id })
    foreach ($id in @($script:selected)) { if ($id -notin $script:visible) { [void]$script:selected.Remove($id) } }
    $el.list.Children.Clear()
    foreach ($n in $vis) { [void]$el.list.Children.Add((New-NoteCard $n)) }

    $el.emptyLbl.Text = T 'empty'
    $el.emptyLbl.Visibility = $(if ($vis.Count) { 'Collapsed' } else { 'Visible' })
    $el.toolbar.Visibility = $(if ($vis.Count) { 'Visible' } else { 'Collapsed' })
    $allSel = $vis.Count -gt 0 -and $script:selected.Count -eq $vis.Count
    $el.selAll.Text = T $(if ($allSel) { 'clearSel' } else { 'selectAll' })
    $el.delBtn.Content = (T 'deleteSel') -f $script:selected.Count
    $el.delBtn.Visibility = $(if ($script:selected.Count) { 'Visible' } else { 'Collapsed' })
    $el.custLink.Text = T 'custLink'
    $el.custLink.Visibility = $(if ($cfg.tab) { 'Visible' } else { 'Collapsed' })
}

function Set-Texts {
    $el.title.Text = T 'title'; $el.hint.Text = T 'hint'; $el.cancelBtn.Content = T 'cancel'; $el.titleMic.ToolTip = T 'voice'   # Set-MicColor adds the wake-word hint
    $el.resetSize.ToolTip = T 'resetSize'; $el.grip.ToolTip = T 'grip'; $el.editLbl.Text = T 'editing'
    $el.saveBtn.Content = T $(if ($script:editId) { 'update' } else { 'save' })
    $el.cmdHint.Text = T 'cmdHint'; $el.cmdRun.Content = T 'cmdRun'; $el.cmdClose.Content = T 'cancel'
    Set-MicColor
}

function Start-Edit($id) {
    $note = Get-Note $id; if (-not $note) { return }
    $script:editId = $id
    $el.input.Text = $note.text -replace "`n", "`r`n"
    $el.cancelBtn.Visibility = 'Visible'; $el.editLbl.Visibility = 'Visible'; Set-Texts
    $el.input.Focus() | Out-Null; $el.input.CaretIndex = $el.input.Text.Length
}
function Stop-Edit {
    $script:editId = $null; $el.input.Text = ''
    $el.cancelBtn.Visibility = 'Collapsed'; $el.editLbl.Visibility = 'Collapsed'; Set-Texts
}

# --- Voice commands -------------------------------------------------------------
# The microphone by the title opens a command box and starts Windows voice typing (Win+H).
# The whole sentence is analysed - no fixed command word is needed - and run after a
# 3 second pause (or Enter):
#   "Husk å sende tilbud til Equinor på fredag"  -> task for Equinor, dated next Friday
#   "Jeg må ringe Per i morgen"                   -> task without customer
#   "Snakket med Statkraft om sensorene"          -> note for Statkraft
#   "Hvor mye er 100 euro"                        -> Currency tab, 100 EUR -> NOK
# Known customers are found anywhere in the sentence; a new one is given as "kunde X"
# (or "Oppgave for X ..."). Task words (oppgave, husk, jeg må, ...) or a future date make a
# task, everything else becomes a note.
Add-Type -Namespace Notes4Me -Name Keys -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);'
$monthNo = @{ jan = 1; feb = 2; mar = 3; apr = 4; mai = 5; may = 5; maj = 5; jun = 6; jul = 7; aug = 8; sep = 9; okt = 10; oct = 10; nov = 11; des = 12; dec = 12 }
$weekdayNo = @{ mandag = 1; monday = 1; 'måndag' = 1; tirsdag = 2; tuesday = 2; tisdag = 2; onsdag = 3; wednesday = 3; torsdag = 4; thursday = 4
                fredag = 5; friday = 5; 'lørdag' = 6; saturday = 6; 'lördag' = 6; 'søndag' = 0; sunday = 0; 'söndag' = 0 }
$datePre = '(?:\b(?:på|til|innen|senest|by|on|before|until|den|the|till|senast|inden|fra)\s+)*'
function Format-Cap($s) { $s = $s.Trim(); if ($s) { $s.Substring(0, 1).ToUpper() + $s.Substring(1) } else { $s } }
function Clear-Spoken($s) { (($s -replace '\s{2,}', ' ') -replace '^[\s,.:;-]+|[\s,.:;!?-]+$', '').Trim() }

# Finds a spoken or written date and returns it with the phrase removed from the text
function ConvertFrom-SpokenDate($text) {
    $today = (Get-Date).Date
    $found = { param($m, $date) @{ date = $date; text = $text.Remove($m.Index, $m.Length); numeric = $false } }
    $m = [regex]::Match($text, "(?i)$datePre\b(\d{1,2})\.?\s+(?:of\s+)?(jan|feb|mar|apr|mai|may|maj|jun|jul|aug|sep|okt|oct|nov|des|dec)\p{L}*\.?(?:\s+(\d{4}))?")
    if ($m.Success) {
        $y = if ($m.Groups[3].Success) { [int]$m.Groups[3].Value } else { $today.Year }
        try { $d = New-Object DateTime $y, $monthNo[$m.Groups[2].Value.ToLower()], ([int]$m.Groups[1].Value) } catch { $d = $null }
        if ($d) { if (-not $m.Groups[3].Success -and $d -lt $today.AddDays(-180)) { $d = $d.AddYears(1) }; return & $found $m $d }
    }
    foreach ($rel in @(@('i\s*overmorgen|overmorgen|i\s*övermorgon|övermorgon|day after tomorrow', 2), @('i\s*morgen|i\s*morgon|imorgon|tomorrow', 1), @('i\s*dag|idag|today', 0))) {
        $m = [regex]::Match($text, "(?i)$datePre\b(?:$($rel[0]))\b"); if ($m.Success) { return & $found $m $today.AddDays($rel[1]) }
    }
    $m = [regex]::Match($text, "(?i)$datePre\b(?:om|in|inom)\s+(\d+)\s+(?:dager|dagar|dage|days)\b")
    if ($m.Success) { return & $found $m $today.AddDays([int]$m.Groups[1].Value) }
    $m = [regex]::Match($text, "(?i)$datePre\b(?:neste|next|nästa|næste)\s+(?:uke|week|vecka|uge)\b")
    if ($m.Success) { return & $found $m $today.AddDays(((8 - [int]$today.DayOfWeek) % 7) + $(if ($today.DayOfWeek -eq 'Monday') { 7 } else { 0 })) }
    $m = [regex]::Match($text, "(?i)$datePre\b(?:(?:neste|next|nästa|næste|kommende)\s+)?(" + ($weekdayNo.Keys -join '|') + ")\b")
    if ($m.Success) {
        $add = ($weekdayNo[$m.Groups[1].Value.ToLower()] - [int]$today.DayOfWeek + 7) % 7; if ($add -eq 0) { $add = 7 }
        return & $found $m $today.AddDays($add)
    }
    $d = Get-TaskDate $text
    if ($d) { return @{ date = $d; text = $text; numeric = $true } }
    @{ date = $null; text = $text; numeric = $false }
}

$fxWordRx = '(?i)(svenske?\s+kron(?:er|or)|svenska\s+kronor|sek|danske?\s+kron(?:er|or)|dkk|euro(?:s|er)?|eur|€|pund|pounds?|gbp|£|dollars?|usd|\$|norske?\s+kron(?:er|or)|kroner|kronor|kr|nok)'
function Get-FxCode($word) {
    switch -Regex ($word) {
        '(?i)svensk|sek' { 'SEK'; break } '(?i)dansk|dkk' { 'DKK'; break } '(?i)euro|eur|€' { 'EUR'; break }
        '(?i)pund|pound|gbp|£' { 'GBP'; break } '(?i)dollar|usd|\$' { 'USD'; break } default { 'NOK' }
    }
}

$wb = '(?<![\p{L}\p{N}])'; $we = '(?![\p{L}\p{N}])'   # word boundaries that also work for æøå
$taskRx  = "(?i)$wb(?:oppgave\p{L}*|oppgåve|task|todo|to-do|gjøremål|uppgift|opgave|påminnelse|påminn\p{L}*|reminder|remind|husk\p{L}*|remember|kom ihåg|(?:jeg|vi|jag|i|we)\s+(?:må|skal|bør|ska|måste|behöver|need to|have to|must|should))$we|^(?:må|skal|ska|måste|need to|must)$we"
$noteRx  = "(?i)$wb(?:notat|note|notis|anteckning|memo)$we"
$fxKeyRx = "(?i)^(?:valuta|currency|kurs|omregn\p{L}*|regn om|veksle|växla)$we"
$looseRx = "(?i)$wb(?:løs oppgave|uten kunde|ingen kunde|without (?:a )?customer|no customer|utan kund|uden kunde|løs|loose|lös)$we"
$stopRx  = '^(?i)(å|att|at|to|i|på|om|og|and|med|the|en|et|ei|a|an|' + ($weekdayNo.Keys -join '|') + ')$'
# Words that are never a shop name in a currency sentence
$fxStopRx = '^(?i)(hva|hvor|mye|mange|er|koster|kostet|blir|what|how|much|many|is|are|does|do|cost|costs|vad|hur|mycket|är|kostar|hvad|meget|' +
            'valuta|currency|kurs|omregn\p{L}*|regn|regne|om|i|til|in|to|into|på|for|en|et|ei|a|an|the|det|it|this|dette|og|and|med|with|' +
            'kjøp\p{L}*|bestill\p{L}*|buy|bought|order\p{L}*|inkl\p{L}*|mva|moms|vat|import\p{L}*|posten|kroner|kronor|kr|nok|norske|' +
            'euro\p{L}*|eur|dollar\p{L}*|usd|pund|pounds?|gbp|sek|dkk|svenske?|svenska|danske?|\d.*)$'
$impWordRx = "(?i)$wb(?:fra|from|från|hos|kjøp\p{L}*|bestill\p{L}*|buy|bought|order\p{L}*|import\p{L}*|toll|tull|told|duty|frakt|fragt|shipping|posten|mva|moms|vat|inkl\p{L}*)$we"
$fillerRx = @(
    '^(?:kan du|kunne du|could you|please|vær så snill og)\s+'
    '^(?:ny|nytt|nye|new|lag|lage|opprett|opprette|skriv|create|make|add|legg til|sett opp)\s+(?:en|et|ei|a|an)?\s*'
    "^(?:oppgave\p{L}*|oppgåve|task|todo|gjøremål|uppgift|opgave|påminnelse|reminder|notat|note|notis|anteckning|memo)$we(?:\s+(?:om|on|about|to|til|på|at|att)$we)?[\s:,.-]*"
    '^(?:husk på|husk|huske|remember|kom ihåg|påminn meg om|remind me to)\s+(?:å|to|att|at)?\s*'
    '^(?:jeg|vi|jag|i|we|du|man)\s+(?:må|skal|bør|ska|måste|behöver|skulle|need to|have to|must|should)\s+(?:å|att|at)?\s*'
    '^(?:må|skal|ska|måste|need to|must)\s+(?:å\s+)?'
    '^(?:å|to|att|at)\s+'
)
function Remove-Fillers($s, [switch]$NoteOnly) {
    $list = if ($NoteOnly) { $fillerRx[0..2] } else { $fillerRx }
    do { $before = $s; foreach ($f in $list) { $s = Clear-Spoken ([regex]::Replace($s, "(?i)$f", '')) } } while ($s -ne $before)
    $s
}

# Finds the customer anywhere in the sentence (see rules above)
function Find-Customer($text) {
    $m = [regex]::Match($text, $looseRx)
    if ($m.Success) { return @{ customer = $null; text = Clear-Spoken $text.Remove($m.Index, $m.Length) } }
    $m = [regex]::Match($text, "(?i)$wb(?:for\s+|för\s+)?(?:kunde|customer|kund)\s+([\p{L}\p{N}&'-]+)")
    if ($m.Success -and $m.Groups[1].Value -notmatch $stopRx) {
        $name = $m.Groups[1].Value; $known = $script:custNames[$name.ToLower()]
        return @{ customer = $(if ($known) { $known } else { Format-Cap $name }); text = Clear-Spoken $text.Remove($m.Index, $m.Length) }
    }
    foreach ($name in @($script:custNames.Values | Sort-Object Length -Descending)) {
        $m = [regex]::Match($text, "(?i)$wb$([regex]::Escape($name))$we")
        if ($m.Success) {
            # "Equinor: send offer" -> the name is a label and is removed; inside a sentence it stays
            $after = [regex]::Match($text.Substring($m.Index + $m.Length), '^\s*[:,]')
            if ($after.Success) { $text = Clear-Spoken $text.Remove($m.Index, $m.Length + $after.Length) }
            return @{ customer = $name; text = $text }
        }
    }
    # "Oppgave for Hydro bestille kort" -> new customer Hydro; the keyword stays for Remove-Fillers
    $m = [regex]::Match($text, "(?i)^((?:oppgave\p{L}*|task|todo|uppgift|opgave|notat|note|anteckning)\s+)(?:for|för)\s+([\p{L}\p{N}&'-]+)")
    if ($m.Success -and $m.Groups[2].Value -notmatch $stopRx) {
        return @{ customer = Format-Cap $m.Groups[2].Value; text = Clear-Spoken ($m.Groups[1].Value + $text.Substring($m.Length)) }
    }
    @{ customer = $null; text = $text }
}

function Read-VoiceCommand($raw) {
    $text = Clear-Spoken $raw
    if (-not $text) { return $null }
    $hasTask = [regex]::Match($text, $taskRx); $hasNote = [regex]::Match($text, $noteRx)
    # Currency: starts with Valuta/Currency, or an amount with a currency and no task/note words
    if ($text -match $fxKeyRx -or (-not $hasTask.Success -and -not $hasNote.Success -and $text -match '\d' -and $text -match $fxWordRx)) {
        $dt = ConvertFrom-SpokenDate $text; $t2 = $dt.text
        # "… med frakt 30 euro" / "… toll 10 prosent" for the import calculation
        $ship = $null; $duty = $null
        $m = [regex]::Match($t2, '(?i)(?:frakt|fragt|shipping)\s+(?:på\s+|of\s+|er\s+|is\s+)?(\d[\d  .,]*)\s*' + ($fxWordRx -replace '^\(\?i\)', '') + '?')
        if ($m.Success) { $ship = ConvertTo-Amount $m.Groups[1].Value; $t2 = $t2.Remove($m.Index, $m.Length) }
        $m = [regex]::Match($t2, '(?i)(?:toll|tull|told|duty)\s+(?:på\s+|of\s+)?(\d+(?:[.,]\d+)?)\s*(?:%|prosent|procent|percent)')
        if ($m.Success) { $duty = ConvertTo-Amount $m.Groups[1].Value; $t2 = $t2.Remove($m.Index, $m.Length) }
        $m = [regex]::Match($t2, '(\d[\d  .,]*)\s*' + $fxWordRx + '?')
        $amount = if ($m.Success) { ConvertTo-Amount $m.Groups[1].Value } else { $null }
        $code = if ($m.Success -and $m.Groups[2].Success) { Get-FxCode $m.Groups[2].Value } elseif ($t2 -match $fxWordRx) { Get-FxCode $matches[1] } else { $null }
        if ($dt.date -and $dt.date -gt (Get-Date).Date) { $dt.date = $dt.date.AddYears(-1) }   # rates only exist for past dates
        # A shop name makes it a purchase: "Bambu 1500 euro", "1500 euro fra Bambu Lab". Question words
        # ("hvor mye er 100 euro") are not a shop, so that stays a plain conversion.
        $seller = $null
        $sm = [regex]::Match($t2, "(?i)$wb(?:fra|from|från|hos)\s+([\p{L}\p{N}&'.-]+(?:\s+[\p{Lu}\p{N}][\p{L}\p{N}&'.-]*)?)")
        if ($sm.Success) { $seller = $sm.Groups[1].Value }
        else {
            $rest = if ($m.Success) { $t2.Remove($m.Index, $m.Length) } else { $t2 }
            $words = @($rest -split '[\s,.:;!?]+' | Where-Object { $_ -and $_ -notmatch $fxStopRx })
            if ($words.Count) { $seller = ($words | Select-Object -First 3) -join ' ' }
        }
        if ($seller) { $seller = Format-Cap $seller }
        $import = [bool]$seller -or $t2 -match $impWordRx -or $null -ne $ship -or $null -ne $duty
        return @{ kind = 'fx'; amount = $amount; code = $code; dir = $(if ($code -eq 'NOK' -and -not $import) { 'fromNok' } else { 'toNok' }); date = $dt.date
                  import = $import; seller = $seller; ship = $ship; duty = $duty }
    }
    $c = Find-Customer $text
    $dt = ConvertFrom-SpokenDate $c.text
    # A task: task words, or a date that is not just "today" ("Equinor ringte i dag" stays a note).
    # A note word before any task word wins ("Notat: husk at ...").
    $noteFirst = $hasNote.Success -and (-not $hasTask.Success -or $hasNote.Index -lt $hasTask.Index)
    $isTask = -not $noteFirst -and ($hasTask.Success -or ($dt.date -and $dt.date -ne (Get-Date).Date))
    if ($isTask) {
        $date = if ($dt.date) { $dt.date } else { (Get-Date).Date }
        $label = Format-Cap (Remove-Fillers $dt.text); $body = $label
        if (-not $dt.numeric) { $body = "$body " + $date.ToString($(if ($date.Year -eq (Get-Date).Year) { 'd.M' } else { 'd.M.yyyy' })) }
        return @{ kind = 'task'; customer = $c.customer; body = $body.Trim(); label = $label; date = $date }
    }
    @{ kind = 'note'; customer = $c.customer; body = Format-Cap (Remove-Fillers $c.text -NoteOnly) }
}

function Get-CommandText($cmd) {
    if (-not $cmd) { return '' }
    $who = if ($cmd.customer) { (T 'pvFor') -f $cmd.customer } else { T 'pvLoose' }
    switch ($cmd.kind) {
        'task' { '{0} {1} · {2}: {3}' -f (T 'pvTask'), $who, $cmd.date.ToString('ddd d.M.'), $cmd.label }
        'note' { '{0} {1}: {2}' -f (T 'pvNote'), $who, $cmd.body }
        'fx'   {
            $amt = if ($null -ne $cmd.amount) { '{0:N2} {1}' -f $cmd.amount, $(if ($cmd.code) { $cmd.code } else { '' }) } else { '' }
            $imp = if ($cmd.seller) { ' · ' + ((T 'impFrom') -f $cmd.seller) } elseif ($cmd.import) { ' · import' } else { '' }
            ('{0} {1}{2}{3}' -f (T 'tabFx'), $amt, $imp, $(if ($cmd.date) { ' · ' + $cmd.date.ToString('d') } else { '' })).Trim()
        }
    }
}

function Invoke-VoiceCommand {
    $cmd = Read-VoiceCommand $el.cmdBox.Text
    if (-not $cmd -or (($cmd.kind -ne 'fx') -and -not $cmd.body)) { return }
    $done = Get-CommandText $cmd
    $now = Now-Iso
    switch ($cmd.kind) {
        'task' {
            $line = "= $($cmd.body)" + $(if ($cmd.customer) { " ($($cmd.customer))" } else { '' })
            $script:notes.Add(@{ id = [guid]::NewGuid().ToString('N'); created = $now; updated = $now; text = $line }); Save-Notes
            $cfg.tab = $tasksTab
        }
        'note' {
            $txt = $(if ($cmd.customer) { "($($cmd.customer)) " } else { '' }) + $cmd.body
            $script:notes.Add(@{ id = [guid]::NewGuid().ToString('N'); created = $now; updated = $now; text = $txt }); Save-Notes
            $cfg.tab = $(if ($cmd.customer) { $cmd.customer.ToLower() } else { '' })
        }
        'fx' {
            if ($null -ne $cmd.amount) { $cfg.fxDir = $cmd.dir; $el.fxAmount.Text = $cmd.amount.ToString('0.##') }
            $el.fxDate.SelectedDate = $(if ($cmd.date) { $cmd.date } else { (Get-Date).Date })
            $cfg.fxImport = [bool]$cmd.import; $cfg.fxSeller = [string]$cmd.seller
            if ($cmd.import) {   # a purchase: fill in the import calculator
                if ($cmd.code -and $cmd.code -ne 'NOK') { $cfg.fxImpCur = $cmd.code }
                $el.impShip.Text = $(if ($null -ne $cmd.ship) { $cmd.ship.ToString('0.##') } else { '0' })
                $el.impDuty.Text = $(if ($null -ne $cmd.duty) { $cmd.duty.ToString('0.##') } else { '0' })
            }
            $cfg.tab = $fxTab
        }
    }
    Save-Config; $script:selected.Clear(); Render
    if ($cmd.kind -eq 'fx' -and $cmd.import -and $null -ne $script:impTotal) { $done += ' · ' + ((T 'pvImport') -f ('{0:N2} {1}' -f $script:impTotal, (T 'fxNok'))) }
    # Done: close the box (which also stops voice typing) and confirm briefly in the title bar
    Close-CommandBar
    Show-TitleMessage ([string][char]0x2713 + ' ' + $done)
}

# Shows a short confirmation in place of the title for a few seconds
$script:titleTimer = New-Object Windows.Threading.DispatcherTimer
$script:titleTimer.Interval = [TimeSpan]::FromSeconds(6)
$script:titleTimer.Add_Tick({ $script:titleTimer.Stop(); $el.title.Text = T 'title'; $el.title.Foreground = Brush '#D97757'; $el.title.FontWeight = 'SemiBold'; $el.title.ToolTip = $null })
function Show-TitleMessage($text) {
    $el.title.Text = $text; $el.title.ToolTip = $text
    $el.title.Foreground = Brush '#B5D19E'; $el.title.FontWeight = 'Normal'
    $script:titleTimer.Stop(); $script:titleTimer.Start()
}

function Open-CommandBar {
    $el.cmdBar.Visibility = 'Visible'; Set-MicColor
    $script:cmdLast = $el.cmdBox.Text; $script:cmdLastChange = Get-Date; $script:cmdTimer.Start()
    $win.Activate() | Out-Null; $el.cmdBox.Focus() | Out-Null
    # Win+H opens Windows voice typing, which types into the focused box
    [Notes4Me.Keys]::keybd_event(0x5B, 0, 0, [UIntPtr]::Zero); [Notes4Me.Keys]::keybd_event(0x48, 0, 0, [UIntPtr]::Zero)
    [Notes4Me.Keys]::keybd_event(0x48, 0, 2, [UIntPtr]::Zero); [Notes4Me.Keys]::keybd_event(0x5B, 0, 2, [UIntPtr]::Zero)
}
function Close-CommandBar {
    $script:cmdTimer.Stop(); $script:cmdDone = $true; $el.cmdBox.Text = ''; $el.cmdPreview.Text = ''; $script:cmdLast = ''
    $el.cmdBar.Visibility = 'Collapsed'; Set-MicColor
    # Take the keyboard focus away from any text box: Windows voice typing stops listening
    # when no text field has focus, so the microphone is turned off.
    [Windows.Input.Keyboard]::ClearFocus()
    [Windows.Input.FocusManager]::SetFocusedElement($win, $win)
}

# While the box is open, its text is checked four times a second (voice typing does not always
# raise change events while it is still writing). When the text has not changed for 2.5 s,
# the command runs by itself; the preview counts down until then.
$cmdPause = 2.5
$script:cmdLast = ''; $script:cmdLastChange = Get-Date
$script:cmdTimer = New-Object Windows.Threading.DispatcherTimer
$script:cmdTimer.Interval = [TimeSpan]::FromMilliseconds(250)
$script:cmdTimer.Add_Tick({
    $text = $el.cmdBox.Text
    if ($text -ne $script:cmdLast) { $script:cmdLast = $text; $script:cmdLastChange = Get-Date; Update-CommandPreview; return }
    if (-not $text.Trim()) { return }
    $left = $cmdPause - ((Get-Date) - $script:cmdLastChange).TotalSeconds
    if ($left -le 0) { Invoke-VoiceCommand } else { Update-CommandPreview $left }
})
function Update-CommandPreview($left = $cmdPause) {
    if ($script:cmdDone) { return }   # keep the "done" message until something new is said
    $text = $el.cmdBox.Text
    if (-not $text.Trim()) { $el.cmdPreview.Text = ''; return }
    $el.cmdPreview.Text = (Get-CommandText (Read-VoiceCommand $text)) + '  ·  ' + ((T 'pvAuto') -f [math]::Ceiling($left))
    $el.cmdPreview.Foreground = Brush '#9DBEE0'
}
$el.titleMic.Add_MouseLeftButtonDown({ param($s, $e) Open-CommandBar; $e.Handled = $true })
$el.cmdRun.Add_Click({ Invoke-VoiceCommand })
$el.cmdClose.Add_Click({ Close-CommandBar })
$el.cmdBox.Add_TextChanged({
    $el.cmdHint.Visibility = $(if ($el.cmdBox.Text) { 'Collapsed' } else { 'Visible' })
    if ($el.cmdBox.Text) { $script:cmdDone = $false }
})
$el.cmdBox.Add_PreviewKeyDown({
    param($s, $e)
    if ($e.Key -eq 'Return') { Invoke-VoiceCommand; $e.Handled = $true }
    elseif ($e.Key -eq 'Escape') { Close-CommandBar; $e.Handled = $true }
})

# --- Wake word ------------------------------------------------------------------
# Saying "Notater" or "Notes4Me" opens the command box, as if the microphone was clicked.
# Uses Windows' built-in offline English recognizer with a grammar of only the wake phrases;
# "notater" is given a Norwegian pronunciation (IPA). Recognition runs in a small C# class
# so no PowerShell code runs on the recognizer's thread; a UI timer polls its hit counter.
$wakeSource = @'
using System;
using System.Threading;
using System.Speech.Recognition;
using System.Speech.Recognition.SrgsGrammar;
namespace Notes4Me {
    public class WakeWord : IDisposable {
        private SpeechRecognitionEngine eng;
        private int hits;
        public int Hits { get { return hits; } }
        public double MinConfidence = 0.8;
        public double LastConfidence;
        public string LastText;
        public string Error;
        public bool Start(string waveFile) {
            try {
                RecognizerInfo ri = null;
                foreach (RecognizerInfo r in SpeechRecognitionEngine.InstalledRecognizers()) { if (r.Culture.Name.StartsWith("en")) { ri = r; break; } }
                if (ri == null) { Error = "no English speech recognizer is installed in Windows"; return false; }
                SrgsDocument doc = new SrgsDocument();
                doc.Culture = ri.Culture; doc.PhoneticAlphabet = SrgsPhoneticAlphabet.Ipa;
                SrgsRule rule = new SrgsRule("wake");
                SrgsOneOf one = new SrgsOneOf();
                one.Add(new SrgsItem("notes for me"));
                foreach (string ipa in new string[] { "nuːˈtɑːtəɾ", "nuːˈtɑːtər", "nʊˈtɑːtər", "noʊˈtɑːtər", "nuˈtɑtɚ", "nəˈtɑːtɚ" }) {
                    SrgsToken t = new SrgsToken("notater"); t.Pronunciation = ipa; one.Add(new SrgsItem(t));
                }
                rule.Add(one); doc.Rules.Add(rule); doc.Root = rule;
                eng = new SpeechRecognitionEngine(ri);
                eng.LoadGrammar(new Grammar(doc));
                eng.SpeechRecognized += OnRecognized;
                if (!string.IsNullOrEmpty(waveFile)) eng.SetInputToWaveFile(waveFile); else eng.SetInputToDefaultAudioDevice();   // PowerShell passes $null as ""
                eng.RecognizeAsync(RecognizeMode.Multiple);
                return true;
            } catch (Exception ex) { Error = ex.Message; Stop(); return false; }
        }
        private void OnRecognized(object sender, SpeechRecognizedEventArgs e) {
            LastConfidence = e.Result.Confidence; LastText = e.Result.Text;
            if (e.Result.Confidence >= MinConfidence) Interlocked.Increment(ref hits);
        }
        public void Stop() {
            if (eng == null) return;
            try { eng.RecognizeAsyncCancel(); } catch { }
            try { eng.Dispose(); } catch { }
            eng = null;
        }
        public void Dispose() { Stop(); }
    }
}
'@
$script:wake = $null; $script:wakeHits = 0
function Set-MicColor {
    $el.titleMic.Foreground = Brush $(if ($el.cmdBar.Visibility -eq 'Visible') { '#6A9BCC' } elseif ($script:wake) { '#8FB573' } else { '#BBB' })
    $el.titleMic.ToolTip = (T 'voice') + $(if ($script:wake) { T 'wakeTip' } else { '' })
}
function Set-WakeWord([bool]$on, $waveFile = $null) {
    if ($script:wake) { $script:wake.Dispose(); $script:wake = $null }
    if ($on) {
        if (-not ('Notes4Me.WakeWord' -as [type])) { Add-Type -TypeDefinition $wakeSource -ReferencedAssemblies System.Speech }
        $w = New-Object Notes4Me.WakeWord
        if ($w.Start($waveFile)) { $script:wake = $w; $script:wakeHits = 0 }
        else { $on = $false; Show-TitleMessage ((T 'wakeErr') -f $w.Error) }
    }
    $cfg.wakeWord = $on; Save-Config
    if ($script:wakeItem) { $script:wakeItem.IsChecked = $on }
    Set-MicColor
}
$wakeTimer = New-Object Windows.Threading.DispatcherTimer
$wakeTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$wakeTimer.Add_Tick({
    if (-not $script:wake -or $script:wake.Hits -eq $script:wakeHits) { return }
    $script:wakeHits = $script:wake.Hits
    if ($el.cmdBar.Visibility -ne 'Visible') { Open-CommandBar }
})
$wakeTimer.Start()
$win.Add_Closed({ if ($script:wake) { $script:wake.Dispose() } })

function Save-Input {
    $text = ($el.input.Text -replace "`r`n", "`n").Trim()
    if (-not $text) { return }
    if ($script:editId -and ($note = Get-Note $script:editId)) {
        $note.text = $text; $note.updated = Now-Iso
    } else {
        # A note written in a customer tab without naming any customer belongs to that customer
        if ($cfg.tab -and $cfg.tab -notin $fxTab, $tasksTab -and -not $custRx.IsMatch($text)) {
            $name = @($script:notes | ForEach-Object { Get-Customers $_.text } | Where-Object { $_.ToLower() -eq $cfg.tab })[0]
            $lines = $text -split "`n"; $lines[0] = "$($lines[0]) ($name)"; $text = $lines -join "`n"
        }
        $now = Now-Iso
        $script:notes.Add(@{ id = [guid]::NewGuid().ToString('N'); created = $now; updated = $now; text = $text })
    }
    Save-Notes; Stop-Edit; Render
}
function Remove-Selected {
    $n = $script:selected.Count; if (-not $n) { return }
    $answer = [Windows.MessageBox]::Show($win, ((T 'confirmDel') -f $n), (T 'title'), 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }
    foreach ($id in @($script:selected)) {
        $note = Get-Note $id; if ($note) { [void]$script:notes.Remove($note) }
        if ($script:editId -eq $id) { Stop-Edit }
    }
    $script:selected.Clear(); Save-Notes; Render
}

# --- Deleting a customer --------------------------------------------------------
# Either delete the customer with its notes (notes shared with other customers are kept
# there, only this customer's tag is removed), or just remove the tag and keep every note.
function Remove-CustomerTag($text, $key) {
    $lines = foreach ($line in $text -split "`n") {
        $new = $custRx.Replace($line, [Text.RegularExpressions.MatchEvaluator]{ param($m) if ($m.Groups[1].Value.Trim().ToLower() -eq $key) { '' } else { $m.Value } })
        $new = ($new -replace '\s{2,}', ' ').TrimEnd()
        if ($line.Trim() -eq '' -or $new.Trim() -notmatch '^(=(x\s)?)?\s*$') { $new }   # drop lines that held only the tag
    }
    (@($lines) -join "`n").Trim()
}
function Remove-Customer($key, [switch]$DeleteNotes) {
    $name = $script:custNames[$key]
    $affected = @($script:notes | Where-Object { Test-Customer $_ $key })
    $only = @($affected | Where-Object { @(Get-Customers $_.text | ForEach-Object { $_.ToLower() } | Sort-Object -Unique).Count -eq 1 })
    $msg = if ($DeleteNotes) { (T 'confirmCustDel') -f $name, $only.Count } else { (T 'confirmCustRemove') -f $name, $affected.Count }
    if ([Windows.MessageBox]::Show($win, $msg, (T 'title'), 'YesNo', 'Warning') -ne 'Yes') { return }
    foreach ($n in $affected) {
        $newText = Remove-CustomerTag $n.text $key
        if (($DeleteNotes -and $only -contains $n) -or -not $newText) {
            [void]$script:notes.Remove($n); if ($script:editId -eq $n.id) { Stop-Edit }
        } else { $n.text = $newText; $n.updated = Now-Iso }
    }
    $cfg.tab = ''; Save-Config; $script:selected.Clear(); Save-Notes; Render
}
function New-CustomerMenu($key) {
    $m = New-Object Windows.Controls.ContextMenu
    $count = @($script:notes | Where-Object { Test-Customer $_ $key } | Where-Object { @(Get-Customers $_.text | ForEach-Object { $_.ToLower() } | Sort-Object -Unique).Count -eq 1 }).Count
    $a = New-Object Windows.Controls.MenuItem; $a.Header = (T 'custDelAll') -f $script:custNames[$key], $count; $a.Tag = $key
    $a.Add_Click({ param($s, $e) Remove-Customer $s.Tag -DeleteNotes })
    $b = New-Object Windows.Controls.MenuItem; $b.Header = (T 'custRemoveTag') -f $script:custNames[$key]; $b.Tag = $key
    $b.Add_Click({ param($s, $e) Remove-Customer $s.Tag })
    [void]$m.Items.Add($a); [void]$m.Items.Add($b)
    $m
}
$el.custLink.Add_MouseLeftButtonDown({
    param($s, $e)
    $m = New-CustomerMenu ([string]$cfg.tab); $m.PlacementTarget = $s; $m.Placement = 'Bottom'; $m.IsOpen = $true
    $e.Handled = $true
})

# --- Tasks tab ----------------------------------------------------------------
# Every line with a date is a task: "= Send offer 16.10", "Meeting agreed 16/10".
# Shown soonest first; ticked tasks are struck through and can be archived ("=a ").
$tasksTab = '::tasks'
$script:showArchive = $false
# 16.10  16.10.  16/10  16.10.2026  16.10.26  16-10-2026  2026-10-16
$dateRx = [regex]'(?<![\w./-])(?:(?<y>\d{4})-(?<m>\d{1,2})-(?<d>\d{1,2})|(?<d>\d{1,2})[./](?<m>\d{1,2})(?:[./](?<y>\d{4}|\d{2}))?\.?|(?<d>\d{1,2})-(?<m>\d{1,2})-(?<y>\d{4}|\d{2}))(?![\d/-]|\.\d)'
function Get-TaskDate($text) {
    $today = (Get-Date).Date
    foreach ($m in $dateRx.Matches($text)) {
        if ($text.Substring(0, $m.Index) -match '(?i)\bkl\.?\s*$') { continue }   # "kl 12.10" is a time
        $hasYear = $m.Groups['y'].Success
        $y = if ($hasYear) { [int]$m.Groups['y'].Value } else { $today.Year }; if ($y -lt 100) { $y += 2000 }
        try { $date = New-Object DateTime $y, ([int]$m.Groups['m'].Value), ([int]$m.Groups['d'].Value) } catch { continue }
        if (-not $hasYear -and $date -lt $today.AddDays(-180)) { $date = $date.AddYears(1) }   # "3.1" written in October = next January
        return $date
    }
    $null
}
function Get-Tasks {
    foreach ($n in $script:notes) {
        $lines = $n.text -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $m = $lineRx.Match($lines[$i])
            $content = if ($m.Success) { $m.Groups[2].Value } else { $lines[$i] }
            $date = Get-TaskDate $content; if (-not $date) { continue }
            $flag = if ($m.Success) { $m.Groups[1].Value.Trim() } else { '' }
            [pscustomobject]@{ id = $n.id; line = $i; text = $content; date = $date; checked = [bool]$flag; archived = $flag -eq 'a'
                               created = $n.created; customers = @(Get-Customers $n.text) }
        }
    }
}
function New-TaskRow($t) {
    $today = (Get-Date).Date; $days = ($t.date - $today).Days
    $row = New-Object Windows.Controls.Border
    $row.CornerRadius = New-Object Windows.CornerRadius 6; $row.Padding = Thick 8 5 8 6; $row.Margin = Thick 0 0 0 5
    $row.Background = Brush '#2B2B2B'; $row.Tag = $t.id; $row.ToolTip = T 'edit'
    [Windows.Controls.ToolTipService]::SetInitialShowDelay($row, 1500)
    $row.Add_MouseLeftButtonDown({ param($s, $e) if ($e.ClickCount -ge 2) { Start-Edit $s.Tag }; $e.Handled = $true })
    $dp = New-Object Windows.Controls.DockPanel

    $right = New-Object Windows.Controls.StackPanel; $right.Margin = Thick 8 0 0 0; $right.VerticalAlignment = 'Center'
    [Windows.Controls.DockPanel]::SetDock($right, 'Right')
    $dl = New-Object Windows.Controls.TextBlock; $dl.FontSize = 11; $dl.HorizontalAlignment = 'Right'
    $dl.Text = if (-not $t.checked -and $days -lt 0) { '{0} · {1}' -f (T 'dOverdue'), $t.date.ToString('d.M.') }
               elseif ($days -eq 0) { T 'dToday' } elseif ($days -eq 1) { T 'dTomorrow' } else { $t.date.ToString('ddd d.M.') }
    $dl.Foreground = Brush $(if ($t.checked) { '#666' } elseif ($days -lt 0) { '#E06C5A' } elseif ($days -eq 0) { '#D97757' } else { '#999' })
    [void]$right.Children.Add($dl)
    if ($t.customers.Count) {
        $ct = New-Object Windows.Controls.TextBlock; $ct.FontSize = 10; $ct.Foreground = Brush '#D97757'; $ct.HorizontalAlignment = 'Right'
        $ct.Text = (@($t.customers | ForEach-Object { $k = $_.ToLower(); if ($script:custNames[$k]) { $script:custNames[$k] } else { $_ } }) | Sort-Object -Unique) -join ', '
        [void]$right.Children.Add($ct)
    }

    $tb = New-Object Windows.Controls.TextBlock
    $tb.TextWrapping = 'Wrap'; $tb.FontSize = 12; $tb.Foreground = Brush '#DDD'; $tb.Text = Get-DisplayText $t.text
    if ($t.checked) { $tb.TextDecorations = [Windows.TextDecorations]::Strikethrough; $tb.Foreground = Brush '#777' }
    $cb = New-Object Windows.Controls.CheckBox
    $cb.IsChecked = $t.checked; $cb.VerticalAlignment = 'Center'; $cb.Margin = Thick 0 0 6 0; $cb.Tag = @{ id = $t.id; line = $t.line }   # only the box ticks
    $cb.Add_Click({ param($s, $e) Set-LineChecked $s.Tag.id $s.Tag.line ([bool]$s.IsChecked) })
    [Windows.Controls.DockPanel]::SetDock($cb, 'Left'); $tb.VerticalAlignment = 'Center'
    [void]$dp.Children.Add($right); [void]$dp.Children.Add($cb); [void]$dp.Children.Add($tb)
    $row.Child = $dp
    $row
}
function Render-Tasks {
    $all = @(Get-Tasks)
    $open = @($all | Where-Object { -not $_.archived } | Sort-Object { $_.date }, { $_.created })
    $arch = @($all | Where-Object { $_.archived } | Sort-Object { $_.date } -Descending)
    $done = @($open | Where-Object { $_.checked })
    $el.list.Children.Clear()
    foreach ($t in $open) { [void]$el.list.Children.Add((New-TaskRow $t)) }
    if ($script:showArchive -and $arch.Count) {
        $h = New-Object Windows.Controls.TextBlock; $h.Text = T 'archiveHdr'; $h.Foreground = Brush '#888'; $h.FontSize = 11; $h.Margin = Thick 0 8 0 4
        [void]$el.list.Children.Add($h)
        foreach ($t in $arch) { $r = New-TaskRow $t; $r.Opacity = 0.7; [void]$el.list.Children.Add($r) }
    }
    $el.emptyLbl.Text = T 'tasksEmpty'
    $el.emptyLbl.Visibility = $(if ($open.Count -or ($script:showArchive -and $arch.Count)) { 'Collapsed' } else { 'Visible' })
    $el.toolbar.Visibility = $(if ($done.Count -or $arch.Count) { 'Visible' } else { 'Collapsed' })
    $el.selAll.Visibility = 'Collapsed'; $el.custLink.Visibility = 'Collapsed'; $el.delBtn.Visibility = 'Collapsed'
    $el.archLink.Text = $(if ($script:showArchive) { T 'hideArchive' } else { (T 'showArchive') -f $arch.Count })
    $el.archLink.Visibility = $(if ($arch.Count) { 'Visible' } else { 'Collapsed' })
    $el.archBtn.Content = (T 'archiveBtn') -f $done.Count
    $el.archBtn.Visibility = $(if ($done.Count) { 'Visible' } else { 'Collapsed' })
}
function Save-ArchiveDone {
    foreach ($t in @(Get-Tasks | Where-Object { $_.checked -and -not $_.archived })) {
        $n = Get-Note $t.id; $lines = $n.text -split "`n"
        $lines[$t.line] = '=a ' + $lineRx.Match($lines[$t.line]).Groups[2].Value
        $n.text = $lines -join "`n"; $n.updated = Now-Iso
    }
    Save-Notes; Render
}
$el.archBtn.Add_Click({ Save-ArchiveDone })
$el.archLink.Add_MouseLeftButtonDown({ param($s, $e) $script:showArchive = -not $script:showArchive; Render; $e.Handled = $true })

# --- Currency tab -------------------------------------------------------------
# Daily mid rates from Norges Bank (published around 16:00 CET on business days).
# The last rates are kept in rates.json so the tab also works offline.
$fxTab = '::fx'
$fxCurrencies = [ordered]@{ EUR = '€'; GBP = '£'; USD = '$'; SEK = 'SEK'; DKK = 'DKK' }
$fxUrl = 'https://data.norges-bank.no/api/data/EXR/B.EUR+GBP+USD+SEK+DKK.NOK.SP?format=sdmx-json&lastNObservations=1'
$ratesPath = Join-Path $dir 'rates.json'
$inv = [Globalization.CultureInfo]::InvariantCulture
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$script:rates = $null; $script:fxFetching = $false; $script:fxError = $false; $script:fxNote = $null; $script:loaded = $false
if (Test-Path $ratesPath) { try { $script:rates = Get-Content $ratesPath -Raw | ConvertFrom-Json } catch {} }

function ConvertFrom-NorgesBank($json) {
    $r = $json | ConvertFrom-Json
    $st = $r.data.structure
    $dims = @($st.dimensions.series)
    $pos = [array]::IndexOf(@($dims | ForEach-Object { $_.id }), 'BASE_CUR')
    $curs = @($dims[$pos].values | ForEach-Object { $_.id })
    $multIdx = [array]::IndexOf(@($st.attributes.series | ForEach-Object { $_.id }), 'UNIT_MULT')
    $obsDates = @($st.dimensions.observation[0].values | ForEach-Object { $_.id })
    $out = [ordered]@{ date = $null; fetched = (Get-Date).ToUniversalTime().ToString('o') }
    foreach ($p in $r.data.dataSets[0].series.psobject.Properties) {
        $cur = $curs[[int]($p.Name -split ':')[$pos]]
        # Newest observation in the response (a date range is requested for historical rates)
        $lastObs = @($p.Value.observations.psobject.Properties | Sort-Object { [int]$_.Name })[-1]
        $obs = $lastObs.Value
        $d = $obsDates[[int]$lastObs.Name]; if (-not $out.date -or $d -gt $out.date) { $out.date = $d }
        $mult = 0   # UNIT_MULT 2 would mean the rate is per 100 units
        if ($multIdx -ge 0 -and $null -ne $p.Value.attributes[$multIdx]) { $mult = [int]$st.attributes.series[$multIdx].values[$p.Value.attributes[$multIdx]].id }
        $out[$cur] = [double]::Parse($obs[0], $inv) / [math]::Pow(10, $mult)
    }
    foreach ($c in $fxCurrencies.Keys) { if (-not $out[$c]) { throw "Missing rate for $c" } }
    [pscustomobject]$out
}
# Downloads run as .NET tasks and a timer on the UI thread picks up finished ones, so no
# PowerShell code ever runs on a background thread (that would crash the widget).
$script:downloads = New-Object System.Collections.Generic.List[object]
$dlTimer = New-Object Windows.Threading.DispatcherTimer
$dlTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$dlTimer.Add_Tick({
    foreach ($d in $script:downloads.ToArray()) {   # @() fails on a list holding Task objects in PS 5.1
        if (-not $d.task.IsCompleted) { continue }
        [void]$script:downloads.Remove($d); $d.client.Dispose()
        $ok = -not ($d.task.IsFaulted -or $d.task.IsCanceled)
        & $d.done $ok $(if ($ok) { $d.task.Result } else { $null }) $d.key
    }
    if (-not $script:downloads.Count) { $dlTimer.Stop() }
})
function Start-Download($url, $key, $done) {
    $wc = New-Object Net.WebClient; $wc.Encoding = [Text.Encoding]::UTF8
    $script:downloads.Add(@{ client = $wc; task = $wc.DownloadStringTaskAsync([uri]$url); key = $key; done = $done })
    $dlTimer.Start()
}

function Update-Rates([switch]$Force) {
    if ($script:fxFetching -or -not $script:loaded) { return }
    if (-not $Force -and $script:rates -and
        @($fxCurrencies.Keys | Where-Object { -not $script:rates.$_ }).Count -eq 0 -and
        ((Get-Date).ToUniversalTime() - [datetime]::Parse($script:rates.fetched, $null, 'RoundtripKind').ToUniversalTime()).TotalMinutes -lt 60) { return }
    $script:fxFetching = $true; $script:fxError = $false
    Start-Download $fxUrl $null {
        param($ok, $result, $key)
        $script:fxFetching = $false
        if ($ok) {
            try { $script:rates = ConvertFrom-NorgesBank $result; $script:rates | ConvertTo-Json | Set-Content $ratesPath -Encoding UTF8 }
            catch { $script:fxError = $true }
        } else { $script:fxError = $true }
        if ($cfg.tab -eq $fxTab) { Render-Fx }
    }
    if ($cfg.tab -eq $fxTab) { Render-Fx }
}

# Historical rates for a chosen date. Norges Bank has no rates for weekends and holidays,
# so the last 10 days up to the date are requested and the newest one is used.
$script:histDate = $null; $script:histRates = @{}; $script:histFetching = $false; $script:histError = $false
function Get-ActiveRates { if ($script:histDate) { $script:histRates[$script:histDate.ToString('yyyy-MM-dd')] } else { $script:rates } }
function Update-HistRates {
    $key = $script:histDate.ToString('yyyy-MM-dd')
    $script:histError = $false
    if ($script:histRates.ContainsKey($key)) { Render-Fx; return }
    $script:histFetching = $true; Render-Fx
    $url = $fxUrl -replace '&lastNObservations=1', ('&startPeriod={0}&endPeriod={1}' -f $script:histDate.AddDays(-10).ToString('yyyy-MM-dd'), $key)
    Start-Download $url $key {
        param($ok, $result, $key)
        $script:histFetching = @($script:downloads.ToArray() | Where-Object { $_.key }).Count -gt 0
        if ($ok) { try { $script:histRates[$key] = ConvertFrom-NorgesBank $result } catch { $script:histError = $true } } else { $script:histError = $true }
        if ($cfg.tab -eq $fxTab) { Render-Fx }
    }
}

# Small flag icons (30x20) drawn with shapes, so they look the same on every PC
function New-FlagIcon($code) {
    $W = 30; $H = 20
    $cv = New-Object Windows.Controls.Canvas; $cv.Width = $W; $cv.Height = $H; $cv.ClipToBounds = $true
    function Add-Rect($x, $y, $w, $h, $c) {
        $r = New-Object Windows.Shapes.Rectangle; $r.Width = $w; $r.Height = $h; $r.Fill = Brush $c
        [Windows.Controls.Canvas]::SetLeft($r, $x); [Windows.Controls.Canvas]::SetTop($r, $y); [void]$cv.Children.Add($r)
    }
    function Add-Line($x1, $y1, $x2, $y2, $t, $c) {
        $l = New-Object Windows.Shapes.Line; $l.X1 = $x1; $l.Y1 = $y1; $l.X2 = $x2; $l.Y2 = $y2; $l.StrokeThickness = $t; $l.Stroke = Brush $c
        [void]$cv.Children.Add($l)
    }
    switch ($code) {
        'EUR' {
            Add-Rect 0 0 $W $H '#003399'
            for ($i = 0; $i -lt 12; $i++) {   # 12 stars in a circle
                $a = $i * [math]::PI / 6; $s = New-Object Windows.Shapes.Ellipse; $s.Width = 2.6; $s.Height = 2.6; $s.Fill = Brush '#FFCC00'
                [Windows.Controls.Canvas]::SetLeft($s, 15 + 6.2 * [math]::Cos($a) - 1.3); [Windows.Controls.Canvas]::SetTop($s, 10 + 6.2 * [math]::Sin($a) - 1.3); [void]$cv.Children.Add($s)
            }
        }
        'GBP' {
            Add-Rect 0 0 $W $H '#012169'
            Add-Line 0 0 $W $H 4 '#FFFFFF'; Add-Line $W 0 0 $H 4 '#FFFFFF'
            Add-Line 0 0 $W $H 1.4 '#C8102E'; Add-Line $W 0 0 $H 1.4 '#C8102E'
            Add-Rect 12 0 6 $H '#FFFFFF'; Add-Rect 0 7 $W 6 '#FFFFFF'
            Add-Rect 13.25 0 3.5 $H '#C8102E'; Add-Rect 0 8.25 $W 3.5 '#C8102E'
        }
        'USD' {
            for ($i = 0; $i -lt 13; $i++) { Add-Rect 0 ($i * $H / 13) $W ($H / 13 + 0.2) $(if ($i % 2) { '#FFFFFF' } else { '#B22234' }) }
            Add-Rect 0 0 13 (7 * $H / 13) '#3C3B6E'
            foreach ($y in 1.8, 4.6, 7.4) { foreach ($x in 2, 5.5, 9) { $d = New-Object Windows.Shapes.Ellipse; $d.Width = 1.4; $d.Height = 1.4; $d.Fill = Brush '#FFFFFF'
                [Windows.Controls.Canvas]::SetLeft($d, $x); [Windows.Controls.Canvas]::SetTop($d, $y); [void]$cv.Children.Add($d) } }
        }
        'SEK' { Add-Rect 0 0 $W $H '#006AA7'; Add-Rect 9 0 4 $H '#FECC00'; Add-Rect 0 8 $W 4 '#FECC00' }
        'DKK' { Add-Rect 0 0 $W $H '#C8102E'; Add-Rect 9 0 3.5 $H '#FFFFFF'; Add-Rect 0 8.25 $W 3.5 '#FFFFFF' }
    }
    $cv.Clip = New-Object Windows.Media.RectangleGeometry (New-Object Windows.Rect 0, 0, $W, $H), 3, 3
    $b = New-Object Windows.Controls.Border
    $b.Child = $cv; $b.CornerRadius = New-Object Windows.CornerRadius 3; $b.BorderBrush = Brush '#555'; $b.BorderThickness = Thick 0.5 0.5 0.5 0.5
    $b
}

# Accepts "1 000,50", "1000.50", "1.000" (thousands) and ignores currency signs
function ConvertTo-Amount($s) {
    $s = $s -replace '[\s €£$]|kr|nok|eur|gbp|usd|sek|dkk', ''
    if (-not $s) { return $null }
    $i = [math]::Max($s.LastIndexOf(','), $s.LastIndexOf('.'))
    if ($i -ge 0 -and -not ($s[$i] -eq '.' -and $s.Length - $i - 1 -eq 3)) { $s = ($s.Substring(0, $i) -replace '[,.]', '') + '.' + $s.Substring($i + 1) }
    else { $s = $s -replace '[,.]', '' }
    $v = 0.0
    if ([double]::TryParse($s, [Globalization.NumberStyles]::Float, $inv, [ref]$v)) { $v } else { $null }
}

function Render-Fx {
    $dirKey = $(if ($cfg.fxDir -eq 'fromNok') { 'fromNok' } else { 'toNok' }); $toNok = $dirKey -eq 'toNok'
    $nok = T 'fxNok'; $syms = T 'fxForeign'
    foreach ($c in $el.fxDir.Children) {
        $on = $c.Tag -eq $dirKey
        $c.Child.Text = $(if ($c.Tag -eq 'toNok') { "$syms  →  $nok" } else { "$nok  →  $syms" })
        $c.Background = Brush $(if ($on) { '#6A9BCC' } else { '#2B2B2B' }); $c.Child.Foreground = Brush $(if ($on) { '#FFF' } else { '#BBB' })
    }
    $el.fxAmountLbl.Text = T $(if ($toNok) { 'fxAmtTo' } else { 'fxAmtFrom' })
    $el.fxRefresh.Text = T 'fxRefresh'
    $amount = ConvertTo-Amount $el.fxAmount.Text
    $el.fxResults.Children.Clear()
    $el.fxDateLbl.Text = T 'fxDate'; $el.fxLatest.Text = T 'fxLatest'
    $el.fxLatest.Visibility = $(if ($script:histDate) { 'Visible' } else { 'Collapsed' })
    $r = Get-ActiveRates
    if ($r) {
        foreach ($code in $fxCurrencies.Keys) {
            if (-not $r.$code) { continue }   # e.g. rates saved before this currency was added
            if ($cfg.fxImport -and $toNok -and $code -ne $cfg.fxImpCur) { continue }   # import calculation: only the purchase currency
            $rate = [double]$r.$code; $sym = $fxCurrencies[$code]
            $value = if ($null -eq $amount) { $null } elseif ($toNok) { $amount * $rate } else { $amount / $rate }
            $row = New-Object Windows.Controls.Border
            $row.CornerRadius = New-Object Windows.CornerRadius 6; $row.Padding = Thick 10 5 10 6; $row.Margin = Thick 0 0 0 6
            $row.Background = Brush '#2B2B2B'; $row.Cursor = 'Hand'; $row.ToolTip = T 'fxCopy'
            $row.Tag = $(if ($null -ne $value) { $value.ToString('F2') } else { '' })
            $row.Add_MouseLeftButtonDown({
                param($s, $e)
                if ($s.Tag) { [Windows.Clipboard]::SetText($s.Tag); $script:fxNote = (T 'fxCopied') -f $s.Tag; Render-Fx }
                $e.Handled = $true
            })
            $dp = New-Object Windows.Controls.DockPanel
            $symTb = New-FlagIcon $code
            $symTb.Margin = Thick 0 0 12 0; $symTb.VerticalAlignment = 'Center'
            [Windows.Controls.DockPanel]::SetDock($symTb, 'Left')
            $codeTb = New-Object Windows.Controls.TextBlock
            $codeTb.Text = $code; $codeTb.FontSize = 11; $codeTb.Foreground = Brush '#777'; $codeTb.VerticalAlignment = 'Center'
            [Windows.Controls.DockPanel]::SetDock($codeTb, 'Right')
            $mid = New-Object Windows.Controls.StackPanel
            $res = New-Object Windows.Controls.TextBlock
            $res.FontSize = 16; $res.Foreground = Brush '#EEE'
            $res.Text = if ($null -eq $value) { '–' } elseif ($toNok) { '{0:N2} {1}' -f $value, $nok } else { '{0} {1:N2}' -f $sym, $value }
            $rateTb = New-Object Windows.Controls.TextBlock
            $rateTb.FontSize = 10; $rateTb.Foreground = Brush '#888'; $rateTb.Text = (T 'fxRate') -f $sym, $rate.ToString('0.00##')
            [void]$mid.Children.Add($res); [void]$mid.Children.Add($rateTb)
            [void]$dp.Children.Add($symTb); [void]$dp.Children.Add($codeTb); [void]$dp.Children.Add($mid)
            $row.Child = $dp
            [void]$el.fxResults.Children.Add($row)
        }
    }
    $fetching = $(if ($script:histDate) { $script:histFetching } else { $script:fxFetching })
    $status = if ($r) {
        $d = [datetime]::ParseExact($r.date, 'yyyy-MM-dd', $inv).ToString('d')
        $(if ($script:fxError -and -not $script:histDate) { (T 'fxOffline') -f $d } else { (T 'fxSource') -f $d }) + $(if ($fetching) { ' · ' + (T 'fxFetching') } else { '' })
    } elseif ($fetching) { T 'fxFetching' } elseif ($script:histDate) { T 'fxHistNone' } else { T 'fxNone' }
    if ($script:fxNote) { $status = $script:fxNote; $script:fxNote = $null }
    $el.fxStatus.Text = $status
    Render-Import
}

# --- Import cost via Posten -----------------------------------------------------
# Posten's customs fee 2026 (posten.no/priser): 46 kr for a value of 0-500 kr, 78 kr for 500-3000 kr,
# 278 kr over 3000 kr; no fee when VAT was paid at checkout (VOEC, under 3000 kr per item).
# Norwegian import VAT is 25 % of goods + shipping + duty.
function Get-PostenFee($valueNok, $voec) {
    if ($voec -and $valueNok -lt 3000) { 0 } elseif ($valueNok -le 500) { 46 } elseif ($valueNok -le 3000) { 78 } else { 278 }
}
$script:impTotal = $null
function Add-ImportLine($label, $value, [switch]$Total) {
    $dp = New-Object Windows.Controls.DockPanel; $dp.Margin = Thick 0 $(if ($Total) { 5 } else { 1 }) 0 0
    $v = New-Object Windows.Controls.TextBlock; $v.Text = '{0:N2} {1}' -f $value, (T 'fxNok')
    $l = New-Object Windows.Controls.TextBlock; $l.Text = $label
    foreach ($tb in $v, $l) { $tb.FontSize = $(if ($Total) { 15 } else { 12 }); $tb.Foreground = Brush $(if ($Total) { '#EEE' } else { '#BBB' }) }
    if ($Total) { $l.FontWeight = 'SemiBold'; $v.FontWeight = 'SemiBold' }
    [Windows.Controls.DockPanel]::SetDock($v, 'Right'); [void]$dp.Children.Add($v); [void]$dp.Children.Add($l)
    [void]$el.impLines.Children.Add($dp)
}
function Render-Import {
    $script:impTotal = $null
    $el.impCard.Visibility = $(if ($cfg.fxDir -eq 'fromNok') { 'Collapsed' } else { 'Visible' })
    $el.impToggle.Content = T 'impToggle'; $el.impToggle.IsChecked = [bool]$cfg.fxImport
    $el.impBody.Visibility = $(if ($cfg.fxImport) { 'Visible' } else { 'Collapsed' })
    $el.impShipLbl.Text = T 'impShip'; $el.impDutyLbl.Text = T 'impDuty'; $el.impVoec.Content = T 'impVoec'; $el.impNote.Text = T 'impNote'
    $el.impVoec.IsChecked = [bool]$cfg.fxVoec
    foreach ($c in $el.impCurs.Children) {
        $on = $c.Tag -eq $cfg.fxImpCur
        $c.Background = Brush $(if ($on) { '#6A9BCC' } else { '#232323' }); $c.Child.Foreground = Brush $(if ($on) { '#FFF' } else { '#BBB' })
    }
    $el.impLines.Children.Clear()
    $r = Get-ActiveRates; $amount = ConvertTo-Amount $el.fxAmount.Text
    if (-not $cfg.fxImport -or -not $r -or $null -eq $amount -or -not $r.($cfg.fxImpCur)) { $el.impTitle.Text = ''; return }
    $rate = [double]$r.($cfg.fxImpCur)
    $ship = ConvertTo-Amount $el.impShip.Text; if ($null -eq $ship) { $ship = 0 }
    $dutyPct = ConvertTo-Amount $el.impDuty.Text; if ($null -eq $dutyPct) { $dutyPct = 0 }
    $goods = $amount * $rate; $shipNok = $ship * $rate
    $duty = ($goods + $shipNok) * $dutyPct / 100
    $vat = 0.25 * ($goods + $shipNok + $duty)
    $fee = Get-PostenFee ($goods + $shipNok) $cfg.fxVoec
    $total = $goods + $shipNok + $duty + $vat + $fee
    $el.impTitle.Text = ('{0:N2} {1}' -f $amount, $cfg.fxImpCur) + $(if ($cfg.fxSeller) { '  ' + ((T 'impFrom') -f $cfg.fxSeller) } else { '' })
    Add-ImportLine (T 'impGoods') $goods
    if ($shipNok) { Add-ImportLine (T 'impShip') $shipNok }
    if ($dutyPct) { Add-ImportLine ((T 'impDutyL') -f $dutyPct) $duty }
    Add-ImportLine (T 'impVat') $vat
    Add-ImportLine (T 'impFee') $fee
    Add-ImportLine (T 'impTotal') $total -Total
    $script:impTotal = $total
}
foreach ($code in $fxCurrencies.Keys) {
    $chip = New-Object Windows.Controls.Border
    $chip.CornerRadius = New-Object Windows.CornerRadius 8; $chip.Padding = Thick 8 1 8 2; $chip.Margin = Thick 0 0 4 0; $chip.Cursor = 'Hand'; $chip.Tag = $code
    $chip.Child = New-Object Windows.Controls.TextBlock; $chip.Child.Text = $code; $chip.Child.FontSize = 11
    $chip.Add_MouseLeftButtonDown({ param($s, $e) $cfg.fxImpCur = $s.Tag; Save-Config; Render-Fx; $e.Handled = $true })
    [void]$el.impCurs.Children.Add($chip)
}
$el.impShip.Text = [string]$cfg.fxShip; $el.impDuty.Text = [string]$cfg.fxDuty
$el.impToggle.Add_Click({ $cfg.fxImport = [bool]$el.impToggle.IsChecked; if (-not $cfg.fxImport) { $cfg.fxSeller = ''; wakeWord = $false }; Save-Config; Render-Fx })
$el.impVoec.Add_Click({ $cfg.fxVoec = [bool]$el.impVoec.IsChecked; Save-Config; Render-Import })
$el.impShip.Add_TextChanged({ $cfg.fxShip = $el.impShip.Text; Render-Import })
$el.impDuty.Add_TextChanged({ $cfg.fxDuty = $el.impDuty.Text; Render-Import })
$el.impShip.Add_LostFocus({ Save-Config }); $el.impDuty.Add_LostFocus({ Save-Config })

foreach ($k in 'toNok', 'fromNok') {
    $chip = New-Object Windows.Controls.Border
    $chip.CornerRadius = New-Object Windows.CornerRadius 10; $chip.Padding = Thick 10 2 10 2; $chip.Margin = Thick 0 0 4 0; $chip.Cursor = 'Hand'; $chip.Tag = $k
    $chip.Child = New-Object Windows.Controls.TextBlock; $chip.Child.FontSize = 11
    $chip.Add_MouseLeftButtonDown({ param($s, $e) $cfg.fxDir = $s.Tag; Save-Config; Render-Fx; $e.Handled = $true })
    [void]$el.fxDir.Children.Add($chip)
}
$el.fxAmount.Text = [string]$cfg.fxAmount
$el.fxAmount.Add_TextChanged({ $cfg.fxAmount = $el.fxAmount.Text; if ($cfg.tab -eq $fxTab) { Render-Fx } })
$el.fxAmount.Add_LostFocus({ Save-Config })
$el.fxRefresh.Add_MouseLeftButtonDown({ param($s, $e) if ($script:histDate) { $script:histRates.Remove($script:histDate.ToString('yyyy-MM-dd')); Update-HistRates } else { Update-Rates -Force }; $e.Handled = $true })
$el.fxDate.DisplayDateEnd = (Get-Date).Date
$el.fxDate.DisplayDateStart = [datetime]'1999-01-04'
$el.fxDate.Add_SelectedDateChanged({
    $d = $el.fxDate.SelectedDate
    $script:histDate = $(if ($d -and $d.Date -lt (Get-Date).Date) { $d.Date } else { $null })
    if ($script:histDate) { Update-HistRates } else { Render-Fx }
})
$el.fxLatest.Add_MouseLeftButtonDown({ param($s, $e) $el.fxDate.SelectedDate = (Get-Date).Date; $e.Handled = $true })
$el.fxDate.SelectedDate = (Get-Date).Date   # today = latest rates
$fxTimer = New-Object Windows.Threading.DispatcherTimer
$fxTimer.Interval = [TimeSpan]::FromMinutes(30); $fxTimer.Add_Tick({ if ($cfg.tab -eq $fxTab) { Update-Rates } }); $fxTimer.Start()
$win.Add_Loaded({ $script:loaded = $true; if ($cfg.tab -eq $fxTab) { Update-Rates } })

$el.saveBtn.Add_Click({ Save-Input })
$el.cancelBtn.Add_Click({ Stop-Edit })
$el.delBtn.Add_Click({ Remove-Selected })
$el.selAll.Add_MouseLeftButtonDown({
    param($s, $e)
    if ($script:selected.Count -eq $script:visible.Count) { $script:selected.Clear() } else { foreach ($id in $script:visible) { [void]$script:selected.Add($id) } }
    Render; $e.Handled = $true
})
$el.input.Add_TextChanged({ $el.hint.Visibility = $(if ($el.input.Text) { 'Collapsed' } else { 'Visible' }) })
$el.input.Add_PreviewKeyDown({
    param($s, $e)
    if ($e.Key -eq 'Return' -and [Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) { Save-Input; $e.Handled = $true }
    elseif ($e.Key -eq 'Escape') { Stop-Edit; $e.Handled = $true }
})

# --- Menu, dragging, staying on screen --------------------------------------
$menu = New-Object Windows.Controls.ContextMenu
$menuItems = @{}
function AddItem($key, $action, $parent = $menu) { $mi = New-Object Windows.Controls.MenuItem; $mi.Add_Click($action); [void]$parent.Items.Add($mi); if ($key) { $menuItems[$key] = $mi }; $mi }
AddItem 'mFolder' { Start-Process explorer.exe $dir } | Out-Null
$top = AddItem 'mTopmost' { $win.Topmost = -not $win.Topmost; $this.IsChecked = $win.Topmost; $cfg.topmost = $win.Topmost; Save-Config }
$top.IsChecked = $win.Topmost
$script:wakeItem = AddItem 'mWake' { Set-WakeWord (-not $script:wake) }
$langMenu = AddItem 'mLanguage' {}
$langItems = @{}
foreach ($code in $langNames.Keys) {
    $li = AddItem $null { $cfg.language = $this.Tag; Save-Config; Set-MenuText; Set-Texts; Render } $langMenu
    $li.Tag = $code; $li.Header = $langNames[$code]; $langItems[$code] = $li
}
AddItem 'mClose' { $win.Close() } | Out-Null
function Set-MenuText {
    foreach ($k in $menuItems.Keys) { $menuItems[$k].Header = T $k }
    foreach ($c in $langItems.Keys) { $langItems[$c].IsChecked = ($c -eq $cfg.language) }
}
Set-MenuText
$win.ContextMenu = $menu

$win.Add_MouseLeftButtonDown({ try { $win.DragMove() } catch {}; $cfg.left = $win.Left; $cfg.top = $win.Top; Save-Config })

# Place the window at the user's chosen position, shifted only as far as needed to fit the
# monitor's work area. The shift is not saved, so the widget returns once it shrinks again.
function Keep-OnScreen {
    $src = [Windows.PresentationSource]::FromVisual($win)
    $sx = 1.0; $sy = 1.0
    if ($src) { $m = $src.CompositionTarget.TransformToDevice; $sx = $m.M11; $sy = $m.M22 }
    $pt = New-Object Drawing.Point ([int]($cfg.left * $sx)), ([int]($cfg.top * $sy))
    $wa = [Windows.Forms.Screen]::FromPoint($pt).WorkingArea
    $left = [math]::Max($wa.Left / $sx, [math]::Min([double]$cfg.left, $wa.Right / $sx - $win.ActualWidth))
    $top  = [math]::Max($wa.Top / $sy,  [math]::Min([double]$cfg.top,  $wa.Bottom / $sy - $win.ActualHeight))
    if ($win.Left -ne $left) { $win.Left = $left }
    if ($win.Top -ne $top) { $win.Top = $top }
}
$win.Add_SizeChanged({ Keep-OnScreen })

# --- Resizing -----------------------------------------------------------------
# By default the widget is 340 px wide and grows with its content (list capped at 430 px).
# Dragging the grip in the bottom-right corner switches to a fixed size where the list fills
# the window; the button next to the title goes back to the default.
$defaultWidth = 340; $defaultListHeight = 430
function Set-CustomSize($w, $h) {
    $win.SizeToContent = 'Manual'; $el.listScroll.MaxHeight = [double]::PositiveInfinity
    $win.Width = [math]::Max($win.MinWidth, $w); $win.Height = [math]::Max($win.MinHeight, $h)
    $el.resetSize.Visibility = 'Visible'
}
function Reset-Size {
    $cfg.width = $null; $cfg.height = $null; Save-Config
    $el.listScroll.MaxHeight = $defaultListHeight; $win.Width = $defaultWidth; $win.SizeToContent = 'Height'
    $el.resetSize.Visibility = 'Collapsed'
}
$el.grip.Add_DragDelta({
    param($s, $e)
    if ($win.SizeToContent -ne 'Manual') { Set-CustomSize $win.ActualWidth $win.ActualHeight }
    Set-CustomSize ($win.Width + $e.HorizontalChange) ($win.Height + $e.VerticalChange)
})
$el.grip.Add_DragCompleted({ $cfg.width = $win.Width; $cfg.height = $win.Height; Save-Config })
$el.resetSize.Add_MouseLeftButtonDown({ param($s, $e) Reset-Size; $e.Handled = $true })
if ($cfg.width -and $cfg.height) { Set-CustomSize ([double]$cfg.width) ([double]$cfg.height) }

Set-Texts
Set-WakeWord ([bool]$cfg.wakeWord)
$cfg.tab = $tasksTab   # the widget always opens on the Tasks tab
Render
[void]$win.ShowDialog()
