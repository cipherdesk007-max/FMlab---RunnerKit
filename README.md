# mia

Strumenti per il Linux (Debian) che gira in **LinuxRunner** sull'iPhone.

## TouchPad

Pulsantiera fluttuante e semitrasparente con **mini touchpad**, **tasto destro** e
**tastiera italiana completa**, pensata per usare il desktop Linux col dito.

![TouchPad v1](screenshots/v1.0-touchpad.png)

### Installare o aggiornare

Nel terminale **del desktop** (xterm):

```sh
apt install -y curl && curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
```

Poi apri **Applications → TouchPad**. Per aggiornare rilancia lo stesso comando.

### Come si usa

| Pagina | Cosa fa |
|---|---|
| **Mouse** | Trascina sul riquadro = muovi il mirino rosso · tocco = clic sinistro · tieni premuto = clic destro. Tasti Sx, Dx, 2×, scroll ▲▼, Trasc (segna partenza, sposta, ripremi), Dx fisso (ogni tocco sullo schermo = destro), ◎ centra il mirino. |
| **Tastiera** | QWERTY italiana con à è ì ò ù, `?123` per i simboli, ⇧ una volta / ⇪ bloccato, Ctrl e Alt valgono per il tasto successivo. ⌫ e frecce si ripetono tenendo premuto. |
| **Tasti** | Esc, Tab, frecce, Home/Fine, PgSu/PgGiù, F1–F12, Copia/Incolla (anche versione terminale), Annulla, Salva, Trova, Alt+Tab, Alt+F4. |
| **⚙** | Tema, dimensione S/M/L, opacità, velocità del mirino. |

Barra in alto: **⠿** sposta la finestra · **—** riduce · **×** chiude.
La trasparenza richiede `xcompmgr` (avviato in automatico dal menu); se rallenta: `pkill xcompmgr`.

### Versioni e test

- Storico: [CHANGELOG.md](CHANGELOG.md) · versione attuale nel file `touchpad/touchpad.py` (`__version__`).
- Ogni aggiornamento viene provato in automatico da GitHub Actions (scheda **Actions**):
  motore tasti/clic (`tests/test_x11.py`) e finestra completa con screenshot
  di ogni pagina (`tests/test_gui.py`, scaricabili come artifact "screenshots").
- Test manuale sul telefono: `xev -event button &`, porta il mirino sulla finestra bianca,
  premi **Dx** → deve comparire `button 3`.

### Struttura

```
install.sh            installatore/aggiornatore
touchpad/touchpad.py  il programma
tests/                test automatici
screenshots/          screenshot dal telefono (e ci/ dai test)
```
