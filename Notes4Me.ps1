# Notes4Me - desktop notes widget with customer tabs and checklists
#   (Customer)  anywhere in a note puts it in that customer's tab
#   = at the start of a line makes it a checkbox; checked lines are stored as "=x "
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$dir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath   = Join-Path $dir 'config.json'
$notesPath = Join-Path $dir 'notes.json'
$utf8      = New-Object Text.UTF8Encoding $false

$cfg = [ordered]@{ topmost = $true; left = 120; top = 120; language = 'en'; tab = '' }
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}
function Save-Config { $cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8 }

$strings = @{
    en = @{
        title = 'My notes'; all = 'All'; save = 'Save'; update = 'Update'; cancel = 'Cancel'; editing = 'Editing note'
        hint = 'Write a note…  (Customer) adds it to a customer tab, = at the start of a line makes a checkbox. Ctrl+Enter saves.'
        deleteSel = 'Delete selected ({0})'; selectAll = 'Select all'; clearSel = 'Clear selection'
        confirmDel = 'Delete {0} note(s)? This cannot be undone.'; empty = 'No notes yet'; edit = 'Edit'; select = 'Select for deletion'
        mFolder = 'Open notes folder'; mTopmost = 'Always on top'; mLanguage = 'Language'; mClose = 'Close'
    }
    no = @{
        title = 'Mine notater'; all = 'Alle'; save = 'Lagre'; update = 'Oppdater'; cancel = 'Avbryt'; editing = 'Redigerer notat'
        hint = 'Skriv et notat…  (Kunde) legger det i en kundefane, = først på linjen gir en sjekkboks. Ctrl+Enter lagrer.'
        deleteSel = 'Slett valgte ({0})'; selectAll = 'Velg alle'; clearSel = 'Fjern valg'
        confirmDel = 'Slette {0} notat(er)? Dette kan ikke angres.'; empty = 'Ingen notater ennå'; edit = 'Rediger'; select = 'Velg for sletting'
        mFolder = 'Åpne notatmappen'; mTopmost = 'Alltid øverst'; mLanguage = 'Språk'; mClose = 'Lukk'
    }
    sv = @{
        title = 'Mina anteckningar'; all = 'Alla'; save = 'Spara'; update = 'Uppdatera'; cancel = 'Avbryt'; editing = 'Redigerar anteckning'
        hint = 'Skriv en anteckning…  (Kund) lägger den i en kundflik, = först på raden ger en kryssruta. Ctrl+Enter sparar.'
        deleteSel = 'Ta bort markerade ({0})'; selectAll = 'Markera alla'; clearSel = 'Avmarkera'
        confirmDel = 'Ta bort {0} anteckning(ar)? Det går inte att ångra.'; empty = 'Inga anteckningar ännu'; edit = 'Redigera'; select = 'Markera för borttagning'
        mFolder = 'Öppna anteckningsmappen'; mTopmost = 'Alltid överst'; mLanguage = 'Språk'; mClose = 'Stäng'
    }
    da = @{
        title = 'Mine noter'; all = 'Alle'; save = 'Gem'; update = 'Opdater'; cancel = 'Annuller'; editing = 'Redigerer note'
        hint = 'Skriv en note…  (Kunde) lægger den i en kundefane, = først på linjen giver et afkrydsningsfelt. Ctrl+Enter gemmer.'
        deleteSel = 'Slet valgte ({0})'; selectAll = 'Vælg alle'; clearSel = 'Fravælg'
        confirmDel = 'Slet {0} note(r)? Det kan ikke fortrydes.'; empty = 'Ingen noter endnu'; edit = 'Rediger'; select = 'Vælg til sletning'
        mFolder = 'Åbn notemappen'; mTopmost = 'Altid øverst'; mLanguage = 'Sprog'; mClose = 'Luk'
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
        ShowInTaskbar="False" SizeToContent="WidthAndHeight" ResizeMode="NoResize">
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
  </Window.Resources>
  <Border CornerRadius="10" Background="#E61E1E1E" Padding="12,10" Width="340">
    <StackPanel>
      <TextBlock Name="title" Foreground="#D97757" FontWeight="SemiBold" FontSize="13"/>
      <WrapPanel Name="tabs" Margin="0,6,0,4"/>
      <Grid>
        <TextBox Name="input" MinHeight="58" MaxHeight="160" AcceptsReturn="True" TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto" Background="#2B2B2B" Foreground="#EEE" CaretBrush="#EEE"
                 BorderBrush="#444" BorderThickness="1" Padding="4,3" FontSize="12"/>
        <TextBlock Name="hint" Foreground="#777" FontSize="11" TextWrapping="Wrap" Margin="7,5,7,0" IsHitTestVisible="False"/>
      </Grid>
      <DockPanel Margin="0,4,0,8">
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
          <Button Name="cancelBtn" Background="#444" Visibility="Collapsed" Margin="0,0,6,0"/>
          <Button Name="saveBtn"/>
        </StackPanel>
        <TextBlock Name="editLbl" Foreground="#999" FontSize="11" VerticalAlignment="Center" Visibility="Collapsed"/>
      </DockPanel>
      <DockPanel Name="toolbar" Margin="0,0,0,4">
        <Button Name="delBtn" DockPanel.Dock="Right" Background="#B5523B" Padding="8,2" FontSize="11" Visibility="Collapsed"/>
        <TextBlock Name="selAll" Foreground="#888" FontSize="11" Cursor="Hand" VerticalAlignment="Center"/>
      </DockPanel>
      <ScrollViewer MaxHeight="430" VerticalScrollBarVisibility="Auto">
        <StackPanel Name="list" Margin="0,0,4,0"/>
      </ScrollViewer>
      <TextBlock Name="emptyLbl" Foreground="#777" FontSize="11" Margin="0,4,0,0"/>
    </StackPanel>
  </Border>
</Window>
'@
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$el = @{}
'title','tabs','input','hint','cancelBtn','saveBtn','editLbl','toolbar','delBtn','selAll','list','emptyLbl' | ForEach-Object { $el[$_] = $win.FindName($_) }
$win.Left = $cfg.left; $win.Top = $cfg.top; $win.Topmost = [bool]$cfg.topmost

$brushConv = New-Object Windows.Media.BrushConverter
function Brush($c) { $brushConv.ConvertFromString($c) }
function Thick($l, $t, $r, $b) { New-Object Windows.Thickness $l, $t, $r, $b }

$script:selected = New-Object 'System.Collections.Generic.HashSet[string]'
$script:visible = @()
$script:editId = $null

# Text with (Customer) highlighted
function Add-Inlines($tb, $text) {
    $pos = 0
    foreach ($m in $custRx.Matches($text)) {
        if ($m.Index -gt $pos) { $tb.Inlines.Add([Windows.Documents.Run]::new($text.Substring($pos, $m.Index - $pos))) }
        $r = [Windows.Documents.Run]::new($m.Value); $r.Foreground = Brush '#D97757'; $tb.Inlines.Add($r)
        $pos = $m.Index + $m.Length
    }
    if ($pos -lt $text.Length) { $tb.Inlines.Add([Windows.Documents.Run]::new($text.Substring($pos))) }
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
    $edit = New-Object Windows.Controls.TextBlock
    $edit.Text = [string][char]0x270E; $edit.Foreground = Brush '#888'; $edit.FontSize = 13; $edit.Cursor = 'Hand'; $edit.ToolTip = T 'edit'; $edit.Tag = $note.id
    $edit.Add_MouseLeftButtonDown({ param($s, $e) Start-Edit $s.Tag; $e.Handled = $true })
    [Windows.Controls.DockPanel]::SetDock($edit, 'Right')
    $date = New-Object Windows.Controls.TextBlock
    $date.Text = ([datetime]::Parse($note.created, $null, 'RoundtripKind')).ToLocalTime().ToString('g')
    $date.Foreground = Brush '#888'; $date.FontSize = 10; $date.VerticalAlignment = 'Center'
    [void]$head.Children.Add($sel); [void]$head.Children.Add($edit); [void]$head.Children.Add($date)
    [void]$sp.Children.Add($head)

    $lines = $note.text -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $tb = New-Object Windows.Controls.TextBlock
        $tb.TextWrapping = 'Wrap'; $tb.FontSize = 12; $tb.Foreground = Brush '#DDD'
        $m = $lineRx.Match($line)
        if ($m.Success) {
            $checked = $m.Groups[1].Success
            Add-Inlines $tb $m.Groups[2].Value
            if ($checked) { $tb.TextDecorations = [Windows.TextDecorations]::Strikethrough; $tb.Foreground = Brush '#777' }
            $cb = New-Object Windows.Controls.CheckBox
            $cb.IsChecked = $checked; $cb.Content = $tb; $cb.Margin = Thick 0 1 0 1; $cb.Foreground = Brush '#DDD'
            $cb.Tag = @{ id = $note.id; line = $i }
            $cb.Add_Click({ param($s, $e) Set-LineChecked $s.Tag.id $s.Tag.line ([bool]$s.IsChecked) })
            [void]$sp.Children.Add($cb)
        } elseif ($line.Trim() -eq '') {
            $tb.Height = 6; [void]$sp.Children.Add($tb)
        } else {
            Add-Inlines $tb $line; [void]$sp.Children.Add($tb)
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
    if ($cfg.tab -and -not $cust.Contains([string]$cfg.tab)) { $cfg.tab = ''; Save-Config }

    # Tabs
    $el.tabs.Children.Clear()
    $tabList = @(@{ key = ''; name = T 'all'; count = $sorted.Count }) +
               @($cust.Keys | Sort-Object { $cust[$_] } | ForEach-Object { @{ key = $_; name = $cust[$_]; count = $counts[$_] } })
    foreach ($t in $tabList) {
        $active = $t.key -eq [string]$cfg.tab
        $chip = New-Object Windows.Controls.Border
        $chip.CornerRadius = New-Object Windows.CornerRadius 10; $chip.Padding = Thick 8 2 8 2; $chip.Margin = Thick 0 0 4 4; $chip.Cursor = 'Hand'
        $chip.Background = Brush $(if ($active) { '#D97757' } else { '#2B2B2B' }); $chip.Tag = $t.key
        $tx = New-Object Windows.Controls.TextBlock
        $tx.Text = "$($t.name)  $($t.count)"; $tx.FontSize = 11; $tx.Foreground = Brush $(if ($active) { '#FFF' } else { '#BBB' })
        $chip.Child = $tx
        $chip.Add_MouseLeftButtonDown({ param($s, $e) $cfg.tab = [string]$s.Tag; Save-Config; $script:selected.Clear(); Render; $e.Handled = $true })
        [void]$el.tabs.Children.Add($chip)
    }

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
}

function Set-Texts {
    $el.title.Text = T 'title'; $el.hint.Text = T 'hint'; $el.cancelBtn.Content = T 'cancel'; $el.editLbl.Text = T 'editing'
    $el.saveBtn.Content = T $(if ($script:editId) { 'update' } else { 'save' })
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
function Save-Input {
    $text = ($el.input.Text -replace "`r`n", "`n").Trim()
    if (-not $text) { return }
    if ($script:editId -and ($note = Get-Note $script:editId)) {
        $note.text = $text; $note.updated = Now-Iso
    } else {
        # A note written while a customer tab is open belongs to that customer
        if ($cfg.tab -and -not (@(Get-Customers $text | ForEach-Object { $_.ToLower() }) -contains [string]$cfg.tab)) {
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

Set-Texts
Render
[void]$win.ShowDialog()
