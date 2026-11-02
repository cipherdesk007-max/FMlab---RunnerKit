# RunnerKit 📱🐧

**Il kit per usare Linux sull'iPhone con LinuxRunner.**
Tutto quello che serve installare sul Debian di LinuxRunner sta qui, con un comando solo.

| Strumento | Versione | A cosa serve |
|---|---|---|
| [TouchPad](#touchpad) | 2.4.0 | Mouse, tasto destro e tastiera italiana touch, fluttuanti sul desktop |
| *prossimi strumenti* | | |

> Pensato per i limiti di LinuxRunner: niente kernel né compositing, CPU emulata.
> Per questo gli strumenti evitano processi esterni e grafica pesante.

## TouchPad

Pulsantiera fluttuante e semitrasparente con **mini touchpad**, **tasto destro** e
**tastiera italiana completa**, pensata per usare il desktop Linux col dito.

![TouchPad v1](screenshots/v1.0-touchpad.png)

### Installare o aggiornare

Nel terminale **del desktop** (xterm):

```sh
apt install -y curl && curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
```

Poi aprilo dall'**icona sul desktop**, da **Applications → TouchPad** oppure scrivendo `touchpad` in qualsiasi terminale (anche il Terminal dell'app: si apre comunque sul desktop). Per aggiornare rilancia lo stesso comando.

### Come si usa

| Pagina | Cosa fa |
|---|---|
| **Mouse** | Trascina sul riquadro = muovi il mirino rosso · tocco = clic sinistro · tieni premuto = clic destro. Tasti Sx, Dx, 2×, scroll ▲▼, Trasc (segna partenza, sposta, ripremi), Dx fisso (ogni tocco sullo schermo = destro), ◎ centra il mirino. |
| **Tastiera** | QWERTY italiana con à è ì ò ù, `?123` per i simboli, ⇧ una volta / ⇪ bloccato, Ctrl e Alt valgono per il tasto successivo. ⌫ e frecce si ripetono tenendo premuto. |
| **Tasti** | Esc, Tab, frecce, Home/Fine, PgSu/PgGiù, F1–F12, Copia/Incolla (anche versione terminale), Annulla, Salva, Trova, Alt+Tab, Alt+F4. |
| **⚙** | Tema, dimensione S/M/L, opacità, velocità del mirino. |

Barra in alto: **⠿** sposta la finestra · **—** riduce · **×** chiude.
La finestra resta sempre dentro lo schermo.

**Avvio automatico:** dopo l'installazione TouchPad si apre da solo ogni volta che avvii il desktop.
Si spegne/riaccende da **⚙ → Avvio col desktop**.

**Pallino:** **—** (o Auto-riduci) trasforma TouchPad in un pallino rotondo nell'angolo.
Toccalo e torna esattamente dov'era, sulla stessa pagina. Trascinalo e si aggancia al bordo più vicino.
Se rilanci `touchpad` mentre è già aperto, non se ne apre un secondo: riappare quello che c'è.

**Trasparenza:** serve il *compositing*: TouchPad avvia `xcompmgr` da solo.
Su LinuxRunner funziona (provato al 45%, vedi `screenshots/v2.2-impostazioni-opacita-45.png`).
Se in **⚙** leggi "non disponibile", usa Auto-riduci.

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
