# Notes4Me

A small always-on-top Windows desktop widget for quick notes, with a tab per customer, simple checklists, voice notes and a currency calculator. The title in the widget is **My notes** (Mine notater / Mina anteckningar / Mine noter).

- **Customer tabs:** write a customer name in parentheses in a note, for example `(Equinor)`. A tab for that customer appears automatically and lists its notes, newest first. **All** shows every note.
- **Checkboxes:** start a line with `=` to turn it into a checkbox. Ticking it strikes the line through.
- **Voice notes:** click the microphone and speak. The first word you say becomes the customer.
- **Currency tab:** today's or historical exchange rates for €, £ and $ from Norges Bank, with a calculator to or from Norwegian kroner.
- **Delete one or many:** tick the box in the top-left corner of each note (or use **Select all**), then click **Delete selected**.
- **Edit:** double-click a note.
- **Resizable:** drag the corner in the bottom right. The button next to the title restores the default size.
- **Languages:** English, Norsk, Svenska or Dansk. You choose during installation and can change it later from the right-click menu.

Your notes are stored locally on your PC. The only thing the widget fetches from the internet is the exchange rates.

## Requirements

- Windows 10 or 11 (uses the built-in Windows PowerShell 5.1 – nothing extra to install)
- Voice notes use Windows voice typing (Win+H), which needs an internet connection and must support your language

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

Type in the box at the top and click **Save**, or press **Ctrl+Enter**. Press **Esc** to cancel.

```
Meeting with (Equinor) about the new contract
= Send offer
= Check price with Ola
Next meeting in week 42
```

This note appears in the **Equinor** tab, with checkboxes in front of "Send offer" and "Check price with Ola".

- **The easiest way:** open the customer's tab first and just write. A note written in a customer tab that doesn't name a customer is added to that customer automatically.
- In the list, `(Customer)` is hidden – the tab already tells you who the note is about. A name at the start or end of a line disappears; inside a sentence only the parentheses go ("Meeting with Equinor about…"). In **All**, the customer is shown next to the date.
- Customer names are matched regardless of case: `(Equinor)` and `(equinor)` belong to the same tab.
- A note can mention several customers and then shows up in each of their tabs.
- When you edit a note (double-click), you see the full text including `(Customer)`. A ticked line is stored as `=x`; you can also type `=x` yourself to add a line that is already ticked.

## Voice notes

1. Click the **microphone** next to Save. Windows voice typing (Win+H) opens and the text box is ready.
2. Say the customer first, then the note: *"Equinor, call back tomorrow about the offer"*.
3. Click **Save** or press **Ctrl+Enter**. The note is saved as `(Equinor) Call back tomorrow about the offer`.

If the dictated text already contains `(Customer)`, it is left as it is. Voice typing is provided by Windows; if your language isn't supported there, Windows will tell you.

## Currency tab

Click **€ £ $ Currency** in the tab row.

- Choose the direction: **€ £ $ → kr** (foreign currency to Norwegian kroner) or **kr → € £ $**.
- Type an amount. The result is shown for all three currencies at once. Both `1 000,50` and `1000.50` work.
- **Rate date** is today by default and shows the latest rates. Pick another date in the calendar to see and calculate with historical rates. Norges Bank has no rates for weekends and public holidays, so the last business day before is used; the actual date is shown at the bottom. **Latest rates** goes back to today.
- Click a result to copy the amount.
- Rates are the official daily rates from Norges Bank (published around 16:00 on business days). The latest rates are saved, so the tab also works offline.

## Other options

- **Move it:** drag the title, the tabs or the edge. (Dragging a note does nothing, so double-click always works.)
- **Resize it:** drag the corner in the bottom right. The list then fills the window. Click the button next to the title to restore the default size.
- **Right-click** for: Open notes folder, Always on top, Language and Close.
- If you close it, double-click the **Notes4Me** shortcut on your Desktop to start it again.
- The widget always stays inside the screen.

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
