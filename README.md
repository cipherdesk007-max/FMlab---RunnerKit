# RunnerKit 📱🐧

**Il kit tutto-in-uno per usare Linux sull'iPhone con [LinuxRunner](https://github.com/mxhm11cr/LinuxRunner).**
Tocco, tastiera, pulizia, velocità, backup e aggiornamenti per il desktop Debian di LinuxRunner.
Si installa con un comando e poi si aggiorna con un tocco.

<p align="center">
  <img src="screenshots/telefono/touchpad-tasti.png" width="49%" alt="TouchPad, pagina Tasti">
  <img src="screenshots/telefono/pallini.png" width="49%" alt="Colonna di pallini">
</p>

## Installazione

Nel terminale di Debian (in LinuxRunner):

```sh
apt install -y curl && curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/mia/main/install.sh | sh
```

Serve **solo la prima volta**. Poi si aggiorna da solo, senza comandi:
- pallino **⟳** di TouchPad, che **diventa arancione** quando c'è una novità (controllo ogni 6 ore);
- icona **Aggiorna RunnerKit** sul desktop;
- `rk aggiorna` nel terminale.

Provato su **iPhone 15 Pro Max, iOS 27.2, LinuxRunner 1.1.0 (build 900), Debian 13**, con desktop
LinuxRunner (Openbox) a 960×540 e GPU Metal attiva.

## Gli strumenti

| Strumento | Cosa fa |
|---|---|
| [**TouchPad**](#touchpad) | Mouse con mirino, tasto destro, tastiera italiana, tasti speciali e colonna di pallini sul lato |
| [**Centro**](#centro-runnerkit) | Finestra con sistema (RAM, CPU, disco dal vivo), pulizia del disco a scelta e processi |
| [**UnaVolta**](#unavolta) | Tocchi ripetuti su un'icona aprono il programma una volta sola |
| [**Pulizia**](#pulizia) | Pulizia sicura del disco, report, automatica una volta a settimana |
| [**RunnerBoost**](#runnerboost) | Diagnosi della velocità, prova della GPU Metal, test ripetibile con storico, profili |
| [**Terminale**](#terminale) | Barra di stato, prompt a colori, comando unico `rk`, appunti condivisi con l'iPhone |
| [**Collaudo · Backup · Italiano**](#collaudo-backup-italiano-appunti) | Report di prova, salvataggio dei file, Linux in italiano |

Scrivi `rk` in un terminale per vedere tutti i comandi, e `rk versioni` per sapere cosa è installato.

## TouchPad

<p align="center">
  <img src="screenshots/telefono/touchpad-mouse.png" width="32%" alt="Pagina Mouse">
  <img src="screenshots/telefono/touchpad-tasti.png" width="32%" alt="Pagina Tasti">
  <img src="screenshots/telefono/touchpad-impostazioni.png" width="32%" alt="Impostazioni">
</p>

| Pagina | Cosa fa |
|---|---|
| **Mouse** | Trascini sul riquadro per muovere il mirino rosso: tocco = clic sinistro, pressione lunga = clic destro. Tasti Sx, Dx, doppio clic, scroll, Trascina, Dx fisso, centra il mirino, velocità |
| **Tastiera** | QWERTY italiana con à è ì ò ù, simboli (`?123`), ⇧ e ⇪, Ctrl e Alt per il tasto successivo. ⌫ e frecce si ripetono tenendo premuto |
| **Tasti** | Esc, Tab, frecce, Home/Fine, PgSu/PgGiù, F1–F12, Copia/Incolla (anche da terminale), Alt+Tab, Alt+F4, **→ iPhone** e **Incolla iPhone** |
| **⚙** | Tema, dimensione, opacità, velocità, Auto-riduci, avvio col desktop, copia automatica verso l'iPhone, aggiornamento. In fondo mostra GPU e risoluzione |

**Colonna di pallini.** Con **—**, o da solo dopo 1 minuto che non lo usi, TouchPad diventa una colonna sul lato:

| Pallino | Tocco |
|---|---|
| ⌨ | Riapre TouchPad dov'era, sulla stessa pagina |
| ✕ | Tocchi una finestra e si chiude. Se è bloccata, ✕ di nuovo la forza. Desktop, barra e TouchPad sono protetti |
| ♻ | Apre il Centro sulla **Pulizia** |
| ⚡ | Apre il Centro sul **Sistema** |
| >_ | Apre il terminale |
| ⟳ | Aggiorna RunnerKit. Se è già aggiornato lo dice soltanto. **Arancione** = c'è una novità |

Trascinando un pallino si sposta tutta la colonna, che si aggancia al lato più vicino. TouchPad parte con
il desktop, riprende lo stato in cui l'avevi lasciato, si apre una volta sola e resta sempre sopra le altre finestre.

## Centro RunnerKit

Si apre dall'icona **RunnerKit Centro**, dai pallini ♻ e ⚡, oppure con `rk centro`.

| Scheda | Cosa mostra |
|---|---|
| **Sistema** | Indicatori circolari per RAM, processore e disco (verde, giallo, rosso), grafico degli ultimi 3 minuti, swap, carico, da quanto è acceso, processi, GPU e JIT |
| **Pulizia** | Ogni categoria con la sua dimensione e una barra: scegli e premi **Pulisci selezionati**. I pacchetti inutili sono "avanzati" e non vengono scelti di default. Pulizia settimanale on/off e report completo |
| **Processi** | I programmi che usano più memoria e CPU, aggiornati ogni 3 s, con **Chiudi**, poi **Forza** se non rispondono. I processi del sistema sono protetti |

Legge tutto direttamente dal sistema, senza lanciare programmi per misurare, e aggiorna solo la scheda visibile.

## UnaVolta

Sul telefono un tocco "sporco" vale due o tre clic. UnaVolta sta davanti a icone, menu e barra:
più tocchi entro 4 secondi producono **un solo avvio**. Se il programma è già aperto, anche se lento a comparire
come Firefox, UnaVolta **porta davanti la sua finestra** invece di aprirne un'altra.
`unavolta --log` mostra cosa è successo, `unavolta --ripristina` lo toglie.

## Pulizia

Non tocca **mai** i file personali (Desktop, documenti, Shared, progetti).

| Comando | Cosa fa |
|---|---|
| `pulizia` | Report: disco, RAM, cosa si può cancellare, pacchetti inutili e più grandi, cartelle e file più grandi. Lo salva in Shared, quindi lo vedi dall'app **File** |
| `pulizia --sicura` | Cancella solo ciò che si ricrea da solo: cache di apt e dei programmi, cestino, log vecchi, file temporanei con più di 3 giorni, dump di crash |
| `pulizia --sicura --solo apt,cache` | Pulisce solo le categorie indicate |
| `pulizia --auto-on` / `--auto-off` | Pulizia automatica all'avvio del desktop, al massimo una volta a settimana |

## RunnerBoost

| Comando | Cosa fa |
|---|---|
| `runnerboost` | Diagnosi: JIT, GPU Metal, risoluzione, RAM, disco, programmi all'avvio, con i **consigli in ordine di effetto** |
| `runnerboost --gpu` | Prova la GPU: fotogrammi al secondo e **% di disegni fatti su Metal** (dalle statistiche di LinuxRunner) |
| `runnerboost --gpu-stats` | Per ogni programma: FPS, disegni su Metal e in software |
| `runnerboost --test "etichetta"` | Test ripetibile (Python, avvio programmi, compressione, sha256, ordinamento), con confronto e storico |
| `runnerboost --profilo veloce \| bilanciato \| normale` | Meno animazioni e un Firefox più leggero; normale rimette tutto com'era |

**Come usa la GPU LinuxRunner 1.1.0**, letto dal suo codice: i programmi aperti dal desktop disegnano l'OpenGL
sul chip grafico dell'iPhone tramite una libreria che LinuxRunner carica nei processi
(`LR_GUI_GPU_ACTIVE=mesa-metal-resident`, dispositivo `/dev/linuxrunner-gpu`). I browser restano in software
per scelta di LinuxRunner. Primo risultato su 15 Pro Max: **glxgears a 68,7 FPS** a 960×540 con Metal.

## Terminale

- **Barra di stato fissa** in cima (RAM, disco, GPU, JIT) mentre i comandi scorrono sotto; si spegne con `rk fisso off`
- Prompt a colori: utente, cartella, ramo git, ✘ se l'ultimo comando fallisce, ⏱ se dura più di 3 s
- Storia dei comandi lunga, senza doppioni, con data e ora
- Comando unico **`rk`**: `rk centro`, `rk info`, `rk top`, `rk gpu`, `rk boost`, `rk pulizia`, `rk pulisci`,
  `rk log`, `rk collaudo`, `rk backup`, `rk ripristina`, `rk italiano`, `rk copia`, `rk incolla`, `rk aggiorna`, `rk versioni`

## Collaudo, Backup, Italiano, Appunti

| Comando | Cosa fa |
|---|---|
| `rk collaudo` | Prova ogni strumento sul telefono vero (GPU, XTEST, TouchPad, UnaVolta con 4 tocchi, icone, pulizia, spazio, backup) e salva un report in Shared |
| `rk backup` / `rk ripristina` | Impostazioni, desktop, script, chiavi ed elenco dei pacchetti in `Shared/RunnerKit-backup` (ultimi 5). Prima di ripristinare fa una copia di sicurezza |
| `rk italiano` / `rk italiano off` | Lingua italiana per Debian, per i programmi aperti da icone e menu (tramite UnaVolta), per il terminale e per Firefox |
| `rk copia TESTO` · `comando \| rk copia` · `rk incolla` | Appunti condivisi con l'iPhone, tramite il dispositivo `/dev/clipboard` di LinuxRunner |

## Qualità e verifiche

- Ogni modifica viene provata da **GitHub Actions** su uno schermo virtuale: motore di tasti e clic, finestre
  di TouchPad e del Centro, pallini, istanza unica, appunti, UnaVolta, Pulizia, backup e ripristino,
  italiano, barra del terminale in un pseudo-terminale, prova GPU.
- Gli screenshot dei test si aggiornano da soli in [`screenshots/ultima-versione/`](screenshots/ultima-versione/);
  le foto dal telefono sono in [`screenshots/telefono/`](screenshots/telefono/).
- Storico delle versioni: [CHANGELOG.md](CHANGELOG.md) · versione del kit: [VERSIONE](VERSIONE).

## Ringraziamenti

- **[LinuxRunner](https://github.com/mxhm11cr/LinuxRunner)** di Leminos (@mxhm11cr): l'app che porta Linux
  ARM64 su iPhone e iPad senza jailbreak, con GPU Metal e JIT. RunnerKit esiste perché esiste LinuxRunner.
- **[iSH](https://github.com/ish-app/ish)**: la base su cui è costruito LinuxRunner.
- Debian, Mesa, Openbox, Tk e tutti i progetti open source su cui poggia il desktop.

RunnerKit è un progetto indipendente e non è affiliato a LinuxRunner.

## Struttura

```
install.sh        installatore/aggiornatore     VERSIONE     versione del kit
touchpad/         TouchPad                      strumenti/   Centro, Collaudo, Backup, Italiano, Aggiorna
unavolta/         UnaVolta                      pulizia/     Pulizia
runnerboost/      RunnerBoost                   terminale/   Terminale
tests/            test automatici               screenshots/ foto dal telefono e dai test
```
