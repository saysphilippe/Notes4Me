# Notes4Me - desktop notes widget with customer tabs and checklists
#   (Customer)  anywhere in a note puts it in that customer's tab
#   = at the start of a line makes it a checkbox; checked lines are stored as "=x "
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$dir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath   = Join-Path $dir 'config.json'
$notesPath = Join-Path $dir 'notes.json'
$utf8      = New-Object Text.UTF8Encoding $false

$cfg = [ordered]@{ topmost = $true; left = 120; top = 120; language = 'en'; tab = ''; fxAmount = '100'; fxDir = 'toNok'; width = $null; height = $null }
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
        voice = 'Dictate a note – the first word becomes the customer (Windows voice typing, Win+H)'; voiceActive = 'Dictating – the first word becomes the customer'
        resetSize = 'Restore default size'; grip = 'Drag to resize'
        custLink = 'Delete customer…'; custTip = 'Right-click to delete the customer'; custDelAll = 'Delete customer "{0}" and its notes ({1})'; custRemoveTag = 'Remove customer "{0}", keep the notes'
        confirmCustDel = 'Delete the customer "{0}"? {1} note(s) will be deleted. Notes that also belong to other customers are kept there. This cannot be undone.'
        confirmCustRemove = 'Remove the customer "{0}" from {1} note(s)? The notes are kept under All.'
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
        voice = 'Diktér et notat – første ord blir kunden (Windows stemmeskriving, Win+H)'; voiceActive = 'Dikterer – første ord blir kunden'
        resetSize = 'Tilbakestill størrelse'; grip = 'Dra for å endre størrelse'
        custLink = 'Slett kunde…'; custTip = 'Høyreklikk for å slette kunden'; custDelAll = 'Slett kunden «{0}» og notatene ({1})'; custRemoveTag = 'Fjern kunden «{0}», behold notatene'
        confirmCustDel = 'Slette kunden «{0}»? {1} notat(er) slettes. Notater som også gjelder andre kunder, beholdes der. Dette kan ikke angres.'
        confirmCustRemove = 'Fjerne kunden «{0}» fra {1} notat(er)? Notatene beholdes under Alle.'
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
        voice = 'Diktera en anteckning – första ordet blir kunden (Windows röstinmatning, Win+H)'; voiceActive = 'Dikterar – första ordet blir kunden'
        resetSize = 'Återställ storlek'; grip = 'Dra för att ändra storlek'
        custLink = 'Ta bort kund…'; custTip = 'Högerklicka för att ta bort kunden'; custDelAll = 'Ta bort kunden ”{0}” och anteckningarna ({1})'; custRemoveTag = 'Ta bort kunden ”{0}”, behåll anteckningarna'
        confirmCustDel = 'Ta bort kunden ”{0}”? {1} anteckning(ar) tas bort. Anteckningar som även hör till andra kunder behålls där. Det går inte att ångra.'
        confirmCustRemove = 'Ta bort kunden ”{0}” från {1} anteckning(ar)? Anteckningarna finns kvar under Alla.'
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
        voice = 'Diktér en note – første ord bliver kunden (Windows stemmeskrivning, Win+H)'; voiceActive = 'Dikterer – første ord bliver kunden'
        resetSize = 'Nulstil størrelse'; grip = 'Træk for at ændre størrelse'
        custLink = 'Slet kunde…'; custTip = 'Højreklik for at slette kunden'; custDelAll = 'Slet kunden »{0}« og noterne ({1})'; custRemoveTag = 'Fjern kunden »{0}«, behold noterne'
        confirmCustDel = 'Slet kunden »{0}«? {1} note(r) slettes. Noter, der også hører til andre kunder, beholdes der. Det kan ikke fortrydes.'
        confirmCustRemove = 'Fjern kunden »{0}« fra {1} note(r)? Noterne beholdes under Alle.'
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
$lineRx = [regex]'^=(x\s)?\s*(.*)$'
function Get-Customers($text) { foreach ($m in $custRx.Matches($text)) { $c = $m.Groups[1].Value.Trim(); if ($c) { $c } } }
function Test-Customer($note, $key) { foreach ($c in Get-Customers $note.text) { if ($c.ToLower() -eq $key) { return $true } }; $false }
function Set-LineChecked($id, $index, $checked) {
    $note = Get-Note $id; if (-not $note) { return }
    $lines = $note.text -split "`n"
    $m = $lineRx.Match($lines[$index]); if (-not $m.Success) { return }
    $lines[$index] = $(if ($checked) { '=x ' } else { '= ' }) + $m.Groups[2].Value
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
                   Foreground="#888" Cursor="Hand" VerticalAlignment="Center" Visibility="Collapsed"/>
        <TextBlock Name="title" Foreground="#D97757" FontWeight="SemiBold" FontSize="13"/>
      </DockPanel>
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
          <Button Name="micBtn" DockPanel.Dock="Left" Background="#2B2B2B" Padding="8,4" Margin="0,0,8,0">
            <TextBlock Name="micIcon" FontFamily="Segoe MDL2 Assets" Text="&#xE720;" FontSize="13"/>
          </Button>
          <TextBlock Name="editLbl" Foreground="#999" FontSize="11" VerticalAlignment="Center" TextWrapping="Wrap" Visibility="Collapsed"/>
        </DockPanel>
        <DockPanel Name="toolbar" DockPanel.Dock="Top" Margin="0,0,0,4">
          <Button Name="delBtn" DockPanel.Dock="Right" Background="#B5523B" Padding="8,2" FontSize="11" Visibility="Collapsed"/>
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
            <TextBlock Name="selAll" Foreground="#888" FontSize="11" Cursor="Hand"/>
            <TextBlock Name="custLink" Foreground="#888" FontSize="11" Cursor="Hand" Margin="14,0,0,0" Visibility="Collapsed"/>
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
'title','tabs','input','hint','cancelBtn','saveBtn','editLbl','toolbar','delBtn','selAll','list','emptyLbl','micBtn','micIcon',
'notesPanel','fxPanel','fxDir','fxAmountLbl','fxAmount','fxResults','fxRefresh','fxStatus','fxLatest','fxDateLbl','fxDate',
'resetSize','grip','listScroll','custLink' | ForEach-Object { $el[$_] = $win.FindName($_) }
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
        if ($line.Trim() -ne '' -and -not (Get-DisplayText ($line -replace '^=(x\s)?', ''))) { continue }  # line held only (Customer)
        if ($m.Success) {
            $checked = $m.Groups[1].Success
            $tb.Text = Get-DisplayText $m.Groups[2].Value
            if ($checked) { $tb.TextDecorations = [Windows.TextDecorations]::Strikethrough; $tb.Foreground = Brush '#777' }
            $cb = New-Object Windows.Controls.CheckBox
            $cb.IsChecked = $checked; $cb.Content = $tb; $cb.Margin = Thick 0 1 0 1; $cb.Foreground = Brush '#DDD'
            $cb.Tag = @{ id = $note.id; line = $i }
            $cb.Add_Click({ param($s, $e) Set-LineChecked $s.Tag.id $s.Tag.line ([bool]$s.IsChecked) })
            [void]$sp.Children.Add($cb)
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
    if ($cfg.tab -and $cfg.tab -ne $fxTab -and -not $cust.Contains([string]$cfg.tab)) { $cfg.tab = ''; Save-Config }
    $script:custNames = $cust

    # Tabs
    $el.tabs.Children.Clear()
    $tabList = @(@{ key = ''; name = T 'all'; count = $sorted.Count }) +
               @($cust.Keys | Sort-Object { $cust[$_] } | ForEach-Object { @{ key = $_; name = $cust[$_]; count = $counts[$_] } }) +
               @(@{ key = $fxTab; name = T 'tabFx'; count = $null })
    foreach ($t in $tabList) {
        $active = $t.key -eq [string]$cfg.tab; $isFx = $t.key -eq $fxTab
        $chip = New-Object Windows.Controls.Border
        $chip.CornerRadius = New-Object Windows.CornerRadius 10; $chip.Padding = Thick 8 2 8 2; $chip.Margin = Thick 0 0 4 4; $chip.Cursor = 'Hand'
        $chip.Background = Brush $(if ($active -and $isFx) { '#6A9BCC' } elseif ($active) { '#D97757' } else { '#2B2B2B' }); $chip.Tag = $t.key
        $tx = New-Object Windows.Controls.TextBlock
        $tx.Text = $(if ($isFx) { "€ £ $  $($t.name)" } else { "$($t.name)  $($t.count)" }); $tx.FontSize = 11
        $tx.Foreground = Brush $(if ($active) { '#FFF' } elseif ($isFx) { '#9DBEE0' } else { '#BBB' })
        $chip.Child = $tx
        if ($t.key -and -not $isFx) { $chip.ContextMenu = New-CustomerMenu $t.key; $chip.ToolTip = T 'custTip' }
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
    $el.title.Text = T 'title'; $el.hint.Text = T 'hint'; $el.cancelBtn.Content = T 'cancel'; $el.micBtn.ToolTip = T 'voice'
    $el.resetSize.ToolTip = T 'resetSize'; $el.grip.ToolTip = T 'grip'
    $el.editLbl.Text = T $(if ($script:voiceMode) { 'voiceActive' } else { 'editing' })
    $el.saveBtn.Content = T $(if ($script:editId) { 'update' } else { 'save' })
    $el.micIcon.Foreground = Brush $(if ($script:voiceMode) { '#D97757' } else { '#BBB' })
}

function Start-Edit($id) {
    $note = Get-Note $id; if (-not $note) { return }
    $script:editId = $id; $script:voiceMode = $false
    $el.input.Text = $note.text -replace "`n", "`r`n"
    $el.cancelBtn.Visibility = 'Visible'; $el.editLbl.Visibility = 'Visible'; Set-Texts
    $el.input.Focus() | Out-Null; $el.input.CaretIndex = $el.input.Text.Length
}
function Stop-Edit {
    $script:editId = $null; $script:voiceMode = $false; $el.input.Text = ''
    $el.cancelBtn.Visibility = 'Collapsed'; $el.editLbl.Visibility = 'Collapsed'; Set-Texts
}

# --- Voice notes --------------------------------------------------------------
# Uses Windows voice typing (Win+H), which types into the focused text box. When the
# dictated note is saved, its first word becomes the customer: "Equinor ring tilbake" -> "(Equinor) Ring tilbake".
Add-Type -Namespace Notes4Me -Name Keys -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);'
$script:voiceMode = $false
function Start-Voice {
    if ($script:editId) { Stop-Edit }
    $script:voiceMode = $true
    $el.editLbl.Visibility = 'Visible'; $el.cancelBtn.Visibility = 'Visible'; Set-Texts
    $win.Activate() | Out-Null; $el.input.Focus() | Out-Null; $el.input.CaretIndex = $el.input.Text.Length
    # Win+H
    [Notes4Me.Keys]::keybd_event(0x5B, 0, 0, [UIntPtr]::Zero); [Notes4Me.Keys]::keybd_event(0x48, 0, 0, [UIntPtr]::Zero)
    [Notes4Me.Keys]::keybd_event(0x48, 0, 2, [UIntPtr]::Zero); [Notes4Me.Keys]::keybd_event(0x5B, 0, 2, [UIntPtr]::Zero)
}
function ConvertFrom-Dictation($text) {
    if ($custRx.IsMatch($text)) { return $text }   # customer already given
    $m = [regex]::Match($text, '^\s*([\p{L}\p{N}&''\-]+)[\s,.:;!?]*(.*)$', 'Singleline')
    if (-not $m.Success) { return $text }
    $name = $m.Groups[1].Value; $rest = $m.Groups[2].Value
    $name = $name.Substring(0, 1).ToUpper() + $name.Substring(1)
    if ($rest) { $rest = $rest.Substring(0, 1).ToUpper() + $rest.Substring(1) }
    "($name) $rest".Trim()
}

function Save-Input {
    $text = ($el.input.Text -replace "`r`n", "`n").Trim()
    if (-not $text) { return }
    if ($script:voiceMode -and -not $script:editId) { $text = ConvertFrom-Dictation $text }
    if ($script:editId -and ($note = Get-Note $script:editId)) {
        $note.text = $text; $note.updated = Now-Iso
    } else {
        # A note written in a customer tab without naming any customer belongs to that customer
        if ($cfg.tab -and $cfg.tab -ne $fxTab -and -not $custRx.IsMatch($text)) {
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
}

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
$el.micBtn.Add_Click({ Start-Voice })
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
Render
[void]$win.ShowDialog()
