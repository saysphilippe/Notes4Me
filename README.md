# Notes4Me

A small always-on-top Windows desktop widget for quick notes, with a task overview, a tab per customer, simple checklists, voice notes and a currency calculator. The title in the widget is **My notes** (Mine notater / Mina anteckningar / Mine noter).

The tabs are, in order: **Tasks**, **Currency**, **All** and one tab per customer. The widget always opens on **Tasks**.

- **Tasks tab:** every line with a date (for example `= Send offer 16.10`) appears here, soonest first, with overdue tasks in red. Tick to strike through, then archive the ticked ones.
- **Customer/project tabs:** write a customer or project name in parentheses in a note, for example `(Equinor)` or `(Fjordbyen)`. A tab for it appears automatically and lists its notes, newest first. **All** shows every note.
- **Checkboxes:** start a line with `=` to turn it into a checkbox. Ticking it strikes the line through.
- **Voice commands:** click the microphone by the title and just say it, for example "Remember to send the offer to Equinor on Friday" or "How much is 100 euro".
- **Currency tab:** today's or historical exchange rates for €, £, $, Swedish kroner (SEK) and Danish kroner (DKK) from Norges Bank, with a calculator to or from Norwegian kroner – and the full import cost via Posten (VAT and fee). "Bambu 1500 euro" gives the total.
- **Outlook calendar:** tasks with a date can be synced both ways with your Outlook calendar.
- **Delete a customer/project:** right-click its tab to delete it with its notes, or just remove it and keep the notes.
- **Delete one or many:** tick the box in the top-left corner of each note (or use **Select all**), then click **Delete selected**.
- **Edit:** double-click a note.
- **Resizable:** drag the corner in the bottom right. The button next to the title restores the default size.
- **Languages:** English, Norsk, Svenska or Dansk. You choose during installation and can change it later from the right-click menu.

Your notes are stored locally on your PC. The only thing the widget fetches from the internet is the exchange rates.

## Requirements

- Windows 10 or 11 (uses the built-in Windows PowerShell 5.1 – nothing extra to install)
- Voice commands use Windows voice typing (Win+H), which needs an internet connection and must support your language

## Install

### Option 1 – one-line install

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/saysphilippe/Notes4Me/main/install.ps1 | iex
```

### Option 2 – from a downloaded copy

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

- **The easiest way:** open the customer/project tab first and just write or speak – no need to mention the customer. Notes, tasks and voice commands in a customer/project tab belong to it automatically (unless you name another customer, or say "no customer"). The hint in the text box shows which tab you are writing to.
- In the list, `(Customer)` is hidden – the tab already tells you who the note is about. A name at the start or end of a line disappears; inside a sentence only the parentheses go ("Meeting with Equinor about…"). In **All**, the customer is shown next to the date.
- Customer names are matched regardless of case: `(Equinor)` and `(equinor)` belong to the same tab.
- A note can mention several customers and then shows up in each of their tabs.
- When you edit a note (double-click), you see the full text including `(Customer)`. A ticked line is stored as `=x`; you can also type `=x` yourself to add a line that is already ticked.

### Task archive per customer/project

Each customer/project tab has its own archive for the checkbox tasks in its notes – with or without a date:

- **Archive done (n)** above the list moves the ticked tasks of that customer/project to the archive (stored as `=a`).
- Archived tasks are hidden from the notes. A note that has nothing left but archived tasks disappears from the list.
- **Show archive (n)** lists the archived tasks at the bottom; untick one to make it an open task again.
- Other customers/projects are not affected.

## Deleting a customer or project

Right-click a customer tab, or open the tab and click **Delete customer…** above the list. You get two choices, both asking for confirmation:

- **Delete customer "X" and its notes** – deletes the notes that belong only to this customer. Notes that also mention other customers are kept there; only this customer is removed from them.
- **Remove customer "X", keep the notes** – removes the customer from its notes, so they stay under **All**. A note that contained nothing but `(X)` is removed.

## Tasks

Any line in any note that contains a date is a task and is listed in the **Tasks** tab:

```
(Equinor) Meeting agreed 16/10 on Teams
= Send offer 8.10
= Order new boards 2026-10-20
```

- **Date formats:** `16.10`, `16.10.`, `16/10`, `16.10.2026`, `16.10.26`, `16-10-2026` and `2026-10-16`. Without a year the nearest sensible year is used (`3.1` written in October means next January). Times such as `kl 12.10` are not treated as dates. A version number like `version 1.2` is read as 1 February; write `v1.2` to avoid that.
- **Times:** "kl. 12", "kl 12:30", "klokka 9" or "12:30" are stored as `kl. 12:00`, shown next to the date (for example "Tomorrow 12:00") and used to sort tasks on the same day.
- **Typing a task:** a new line with a task word ("Task – call Asgeir tomorrow at 12", "Oppgave - ringe Asgeir i morgen kl. 12", "husk å …", "jeg må …") or a future date in words ("tomorrow", "on Friday") is saved as a task with a real date, just like a voice command: `= Ringe Asgeir 7.10 kl. 12:00`.
- **Order:** soonest first. Overdue tasks are marked in red, and **Today** and **Tomorrow** are labelled. The customer is shown under the date.
- **Tick the box** to strike a task through (clicking the text does nothing, so double-click always edits). A ticked plain line (without `=`) becomes a ticked checkbox in its note.
- **Archive done (n)** moves the ticked tasks to the archive (they are stored as `=a` in the note and still show as ticked there). **Show archive** lists them; untick one to make it an open task again.
- **Double-click** a task to edit the note it belongs to.
- The number on the tab is the count of open tasks.

## Outlook calendar sync

Right-click the widget and tick **Sync tasks to the Outlook calendar**. Every task with a date then becomes an appointment in your default Outlook calendar – and it works both ways:

| You do | In Outlook |
|---|---|
| Add a task with a date | New appointment. With a time: 30 minutes, reminder 15 minutes before. Without a time: all-day. |
| Change its text, date or time | The appointment is updated |
| Tick or archive it | The appointment gets "✓" in front and no reminder (it stays as history) |
| Delete the task or the note | The appointment is deleted |
| **Delete the appointment in Outlook** | **The task line is deleted in the widget** (and the note, if nothing else is left in it) |
| **Move the appointment in Outlook** (other day or time) | **The task gets the new date and time in the widget** |

- Appointments are marked with the category **Notes4Me** and the subject "Task – Customer", e.g. *Ringe Asgeir – Nordan*.
- Sync uses **classic Outlook** in the background (it starts hidden; you can keep using new Outlook). Classic Outlook must be installed and set up with your account. Changes reach new Outlook, the web and your phone through Exchange.
- Changes in the widget are sent to Outlook (and pushed to the server) right away; Outlook is checked every 10 seconds for deleted or moved appointments.
- Only open tasks create new appointments; tasks that were already ticked when sync was switched on are left out.
- The link between tasks and appointments is kept in `outlook-sync.json` in the notes folder.

## Voice commands

Click the **microphone** next to the title. A command box opens and Windows voice typing (Win+H) starts. Just say what you want in your own words – there are no fixed commands. The line under the box shows how it was understood. When you have been quiet for 2.5 seconds it runs by itself (a countdown is shown), or straight away with **Enter**. **Esc** closes the box. You can also type.

| You say | Result |
|---|---|
| "Remember to send the offer to Equinor on Friday" | Task for Equinor, next Friday: "Send the offer to Equinor" |
| "I need to call Per tomorrow" | Task without a customer, tomorrow |
| "Equinor wants a demo next week" | Task for Equinor, next Monday |
| "Talked to Statkraft about the sensors" | Note for Statkraft |
| "Equinor called today and wants a new offer" | Note for Equinor |
| "Create a task for customer Hydro: order new boards 16 October" | Task for a new customer Hydro |
| "How much is 100 euro" / "Currency 500 kroner" | Currency tab with the amount and the right direction |

How the sentence is read (in English, Norwegian, Swedish and Danish):

- **Customer:** a customer you already have is recognised anywhere in the sentence, and the name stays where you said it. A new customer or project is given as "customer X" / "kunde X" or "project X" / "prosjekt X" (or "Task for X …"). Say "no customer" / "uten kunde" / "løs" to make sure there is none.
- **Task or note:** it becomes a task if the sentence has a task word (task/oppgave, remember/husk, remind/påminn, "I need to"/"jeg må", "we should"/"vi skal" …) or a future date. Otherwise it is a note. "Today" on its own does not make a task ("Equinor called today" stays a note). If you start with "Note"/"Notat", it is always a note.
- **Filler words** such as "remember to", "I need to", "create a task about", "husk å", "jeg må" are removed, so the task text is short.
- **Dates:** today, tomorrow, the day after tomorrow, weekdays ("on Friday"), "next week", "in 3 days", "16 October" and written dates. A task without a date gets today's date.
- **Currency:** an amount with a currency ("100 euro", "250 dollars") or a sentence starting with "Currency"/"Valuta". An amount in a foreign currency gives foreign → NOK, an amount in kroner gives NOK → foreign. A date gives that day's rates.
- After a task, the widget switches to **Tasks**; after a note, to the customer's tab; after a currency question, to **Currency**. The command box then closes and the microphone stops; a confirmation is shown in the title for a few seconds. Click the microphone again for the next command.

Voice typing is provided by Windows. If your language isn't supported there, Windows will tell you.

**Words voice typing gets wrong** can be fixed automatically: right-click the widget, choose **Voice corrections…** and add a line such as `Bambull ab => BambuLab`. The file (`corrections.txt` in the notes folder) is read on every command, so changes work at once. It already contains a few spellings of BambuLab.

### Wake word: "Notater" or "Notes4Me"

Right-click the widget and tick **Listen for "Notater" / "Notes4Me"**. Then you don't need to click the microphone – just say **"Notater"** (Norwegian pronunciation works) or **"Notes4Me"**, wait a moment for the command box to open, and say your command. The microphone icon is green while the widget is listening and blue while the command box is open.

- Listening runs **offline on your PC** with Windows' built-in speech recognizer, which only listens for these two words. Nothing is recorded or sent anywhere.
- Windows shows the microphone as in use while listening is switched on. Untick the menu item to stop.
- Pause briefly after the wake word: Windows voice typing needs a second to start before it writes what you say.
- If the wake word is triggered by accident, press **Esc** or **Cancel**.

## Currency tab

Click **Currency** (Valuta) in the tab row.

- Choose the direction: **Foreign → NOK** or **NOK → Foreign** (in Norwegian: **Valuta → kr** / **kr → Valuta**).
- Type an amount. The result is shown for all five currencies (EUR, GBP, USD, SEK, DKK) at once. Both `1 000,50` and `1000.50` work.
- **Rate date** is today by default and shows the latest rates. Pick another date in the calendar to see and calculate with historical rates. Norges Bank has no rates for weekends and public holidays, so the last business day before is used; the actual date is shown at the bottom. **Latest rates** goes back to today.
- Each currency is shown with its flag. Click a result to copy the amount.
- Rates are the official daily rates from Norges Bank (published around 16:00 on business days). Norges Bank quotes SEK and DKK per 100; the widget shows them per 1 krone. The latest rates are saved, so the tab also works offline.

### Import cost via Posten

Tick **Import cost via Posten (VAT and fee)** under the results to see what a purchase from abroad really costs, delivered by Posten:

| | |
|---|---|
| Goods | the amount in the chosen currency (EUR, GBP, USD, SEK or DKK) converted to NOK |
| Shipping | optional, in the same currency |
| Duty % | optional – 0 % for most goods (for example 3D printers and electronics); clothing and some other goods have duty |
| VAT 25 % | of goods + shipping + duty |
| Posten fee | 46 kr for a value of 0–500 kr, 78 kr for 500–3000 kr, 278 kr over 3000 kr (Posten's 2026 prices) |
| **Total** | everything above |

Tick **VAT paid at checkout (VOEC)** when the shop already charged Norwegian VAT (VOEC scheme, items under 3000 kr). Posten then charges no fee.

While the calculator is on, only the purchase currency is shown, to keep the widget compact.

**By voice or typing**, a shop name with an amount is enough: *"Bambu 1500 euro"* or *"1500 euro from Bambu Lab"* switches on the calculator and shows the total straight away (1500 € → **20 486,75 kr** with the rate of 6.10.2026). You can add *"with shipping 30 euro"* or *"duty 10 percent"*. A plain question such as *"How much is 100 euro"* is just a conversion.

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
