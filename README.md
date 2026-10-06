# Notes4Me

A small always-on-top Windows desktop widget for quick notes, with a tab per customer and simple checklists.

- **Customer tabs:** write a customer name in parentheses anywhere in a note, for example `(Equinor)`. A tab for that customer appears automatically and lists all its notes, newest first. The **All** tab shows every note.
- **Checkboxes:** start a line with `=` to turn it into a checkbox. Ticking it strikes the line through.
- **Delete one or many:** tick the box in the top-left corner of each note you want to remove (or use **Select all**), then click **Delete selected**.
- **Edit:** click ✎ on a note.
- **Languages:** English, Norsk, Svenska or Dansk. You choose during installation and can change it later from the right-click menu.

Everything is stored locally on your PC. Nothing is sent anywhere.

## Requirements

- Windows 10 or 11 (uses the built-in Windows PowerShell 5.1 – nothing extra to install)

## Install

1. Download the repository (**Code → Download ZIP**, then extract it) or clone it:
   ```powershell
   git clone https://github.com/saysphilippe/Notes4Me.git
   ```
2. Double-click `Install.cmd` in that folder, or run:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

The installer:

1. Asks which language to use (1 English, 2 Norsk, 3 Svenska, 4 Dansk). To skip the question, set `$env:NOTES4ME_LANG = 'no'` (or `'en'`, `'sv'`, `'da'`) first.
2. Copies the widget to `%LOCALAPPDATA%\Notes4Me`.
3. Adds a **Notes4Me** shortcut to your Desktop and Startup folder, so it starts when you log in.
4. Starts the widget.

Running the installer again updates the widget and keeps your notes and settings.

## Writing notes

Type in the box at the top and click **Save**, or press **Ctrl+Enter**. Press **Esc** to cancel an edit.

```
Meeting with (Equinor) about the new contract
= Send offer
= Check price with Ola
Next meeting in week 42
```

This note gets a checkbox in front of "Send offer" and "Check price with Ola", and appears in the **Equinor** tab.

- Customer names are matched regardless of case: `(Equinor)` and `(equinor)` belong to the same tab.
- A note can mention several customers and then shows up in each of their tabs.
- If you write a note while a customer tab is open and don't mention a customer, that customer is added to the note automatically, so the note stays in the tab.
- A ticked line is stored as `=x` in the note text, which is what you see when you edit it. You can also type `=x` yourself to add a line that is already ticked.

## Other options

- **Move it:** drag it with the left mouse button.
- **Right-click** for: Open notes folder, Always on top, Language and Close.
- If you close it, double-click the **Notes4Me** shortcut on your Desktop to start it again.
- When the list grows, the widget moves just enough to stay on screen.

## Where your notes are stored

`%LOCALAPPDATA%\Notes4Me\notes.json`

- Every save writes to a temporary file first and then replaces `notes.json`, so a crash or power cut can't leave it half-written.
- The previous version is kept as `notes.json.bak`.
- If `notes.json` ever can't be read, the widget loads the backup and keeps the unreadable file as `notes.unreadable-<date>.json` instead of overwriting it.

To back up your notes, copy `notes.json` somewhere safe. **Open notes folder** in the right-click menu takes you there.

## Uninstall

Double-click `Uninstall.cmd`, or run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Notes4Me\uninstall.ps1"
```

This removes the program and its shortcuts but **keeps your notes**. To remove them too, delete the `%LOCALAPPDATA%\Notes4Me` folder afterwards.
