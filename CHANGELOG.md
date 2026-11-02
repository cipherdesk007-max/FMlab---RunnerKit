# Changelog — RunnerKit

Formato: [versione] - data. Le versioni seguono MAJOR.MINOR.PATCH
(MAJOR = cambia il modo d'uso, MINOR = funzioni nuove, PATCH = correzioni).

## RunnerKit 2026.11.02-10 - aggiornamenti leggeri
- Un aggiornamento ha fatto chiudere LinuxRunner: l'installatore rilanciava ogni volta apt e la
  ricostruzione dell'archivio dei tipi di file, le operazioni più pesanti sotto l'interprete.
  Ora apt parte solo se manca un pacchetto (e prima completa installazioni interrotte con
  `dpkg --configure -a`), l'archivio dei tipi di file si ricostruisce solo la prima volta.
  Un aggiornamento normale scarica solo i file di RunnerKit.

## RunnerKit 2026.11.02-9 - Centro RunnerKit
- **Nuovo Centro RunnerKit** (`rkcentro` 1.0.0, icona sul desktop, pallini ♻ e ⚡, `rk centro`):
  - *Sistema*: indicatori circolari RAM/processore/disco, grafico degli ultimi 3 minuti, swap, carico,
    uptime, processi, GPU, JIT; tutto letto da /proc senza lanciare programmi, solo la scheda visibile.
  - *Pulizia*: categorie con dimensione e barra, scelta con caselle, pacchetti inutili "avanzati" non
    scelti di default, pulizia settimanale on/off, report completo.
  - *Processi*: i più pesanti per RAM e CPU, Chiudi poi Forza; processi di sistema protetti.
- **Pulizia 1.1.0**: `--json`, `--solo`, `--autoremove`.
- **TouchPad 2.9.0**: ♻ apre la Pulizia del Centro, ⚡ il Sistema.
- Aggiornamenti: curl segue i reindirizzamenti (pronto per il cambio di nome del repository).
- README rifatto con le foto dal telefono e i ringraziamenti a LinuxRunner e iSH.

## RunnerKit 2026.11.02-8 - niente più versioni vecchie dalla cache
- GitHub tiene in cache i file per circa 5 minuti: ⟳ diceva "già aggiornato" subito dopo una
  pubblicazione. Ora TouchPad 2.8.2, `rkaggiorna` e l'installatore aggiungono un parametro che salta
  la cache e scaricano sempre i file appena pubblicati.

## RunnerKit 2026.11.02-7 - barra fissa corretta
- **Terminale 1.3.1**: la barra in cima non chiede più la posizione del cursore al terminale (il Terminal
  dell'app non rispondeva e la barra non compariva); `clear` e Ctrl+L la ridisegnano subito; all'apertura
  la barra è in cima e le statistiche sotto. Testato in un pseudo-terminale.

## RunnerKit 2026.11.02-6 - aggiornamento più intelligente
- **⟳ controlla prima**: se RunnerKit è già aggiornato lo dice ("✔ già aggiornato") senza aprire niente;
  se manca la rete lo dice; solo se c'è una versione nuova apre il terminale e la installa.
- Dopo l'aggiornamento mostra **versione vecchia → nuova** e le **novità** (prima voce del registro).
- Le finestre aperte da ⟳, ⚡ e dagli strumenti **si chiudono da sole** con un conto alla rovescia
  ("Chiudo tra 20 s · Invio per chiudere subito") invece di aspettare Invio.
- `rkaggiorna --forza` reinstalla comunque.

## RunnerKit 2026.11.02-5 - aggiornamento con un tocco
- **Pallino ⟳** nella colonna di TouchPad (2.8.0), icona **Aggiorna RunnerKit** sul desktop e pulsante in ⚙:
  aggiornano senza scrivere comandi (`rkaggiorna` apre da solo un terminale con l'avanzamento).
- **Controllo automatico** ogni 6 ore: se su GitHub c'è una versione nuova (file `VERSIONE`) il pallino ⟳
  diventa arancione e compare un avviso.
- Il kit ha un numero di versione unico (`VERSIONE`), mostrato dall'installatore e da `rk versioni`.

## RunnerKit - aggiornamento completo 2026-11-02 (pomeriggio)
- **Nuovi**: `rk collaudo` (report di prova sul telefono), `rk backup` / `rk ripristina` (con copia di
  sicurezza, rotazione 5, elenco pacchetti), `rk italiano` (lingua passata ai programmi via UnaVolta,
  terminale e Firefox, perché il desktop di LinuxRunner non legge la lingua di Debian).
- **Appunti condivisi con l'iPhone** tramite `/dev/clipboard` di LinuxRunner: `rk copia` / `rk incolla`;
  TouchPad 2.7.0 con pulsanti → iPhone / Incolla iPhone e copia automatica Linux → iPhone.
- **Terminale 1.3.0: barra di stato fissa in cima** (area di scorrimento sotto, ridisegnata a ogni
  prompt: resta dopo clear); `rk fisso on|off`.
- **UnaVolta 1.2.0**: passa la lingua scelta ai programmi.

## Terminale [1.2.0] + installatore - 2026-11-02
- **La schermata RunnerKit resta in alto**: `clear` e Ctrl+L puliscono lo schermo e la rimettono subito.
- **Comando unico `rk`**: `rk info`, `rk top`, `rk gpu`, `rk boost`, `rk pulizia`, `rk pulisci`, `rk log`,
  `rk aggiorna`, `rk versioni`.
- `rkaggiorna` / `rk aggiorna` ricaricano subito il terminale con la versione nuova.
- Installatore: se TouchPad è aperto lo riavvia con la versione nuova; registra data di installazione;
  riepilogo finale pulito.

## RunnerBoost [1.2.0] - 2026-11-02
- `runnerboost --gpu` legge le statistiche di LinuxRunner: quanti disegni sono andati su Metal e quanti
  in software, con la percentuale sulla GPU (prova reale che il chip grafico lavora).
- Nuovo `runnerboost --gpu-stats`: tabella per programma (FPS, disegni Metal/software, % GPU).
- Spiegato perché il renderer si chiama "llvmpipe" anche con Metal attivo.
- Primo risultato sul 15 Pro Max (desktop 960×540, Metal resident): glxgears 68,7 FPS.

## RunnerKit - aggiornamento GPU 2026-11-02 (LinuxRunner 1.1.0)
Studiato il codice di LinuxRunner 1.1.0 (gpu-env.sh, desktop-env.sh) per leggere lo stato vero della GPU.
- **RunnerBoost 1.1.0**: sezione "Grafica (GPU del telefono)" con dispositivo Metal, GPU virgl e stato
  reale dei programmi del desktop; risoluzione del desktop; nuovo `runnerboost --gpu` (renderer +
  fotogrammi al secondo con glxgears, salvati nello storico); il JIT diventa un consiglio facoltativo.
- **Terminale 1.1.0**: riga "GPU: Metal / software · JIT" nella schermata iniziale.
- **TouchPad 2.6.0**: in ⚙ mostra GPU e risoluzione dello schermo.
- Installatore: aggiunge x11-utils (risoluzione). CI: prova `--gpu` in software.

## TouchPad [2.5.3] - 2026-11-02
### Corretto
- **✕ chiudeva i pallini di TouchPad** (spariti ⌨ e ✕): ora riconosce tutte le sue finestre
  (anche quelle interne, tramite PID e contenitori) e risponde "Quello è TouchPad: non lo chiudo".
- I pallini ignorano qualunque richiesta di chiusura esterna.
- Se un pallino sparisce lo stesso, la colonna si ricostruisce da sola entro 1,5 s.

## TouchPad [2.5.2] - 2026-11-02
### Corretto
- **✕ poteva chiudere il desktop o la barra** se si toccava lo sfondo, le icone o la barra in basso.
  Ora quelle finestre sono protette (tipo DESKTOP/DOCK, pcmanfm, pannelli): ✕ risponde "non la chiudo".
  Se è già successo: Stop Desktop -> Open Desktop rimette tutto, nessun file perso.

## TouchPad [2.5.1] - 2026-11-02
### Corretto
- **I pallini sparivano e tornava la tastiera:** l'avvio automatico lanciava un secondo TouchPad che
  "riapriva" quello già ridotto. Ora l'avvio automatico (`touchpad --avvio`) non tocca uno già aperto.
- **I pallini finivano sotto le altre finestre:** ogni 1,5 s vengono riportati davanti, e se erano
  stati nascosti per errore ricompaiono.
- Dopo un riavvio del desktop TouchPad riparte come l'avevi lasciato (ridotto = pallini).
- Gli errori interni non fanno sparire nulla: finiscono in `~/.touchpad.log`.

## TouchPad [2.5.0] - 2026-11-02
### Nuovo
- **Colonna di pallini** sul lato dello schermo quando è ridotto: ⌨ riapri, ✕ chiudi finestra
  (gentile, poi forzata se bloccata), ♻ pulizia sicura con risultato, ⚡ RunnerBoost, >_ terminale.
  Si trascina tutta insieme e si aggancia al lato.
- **Auto-riduci di default**: si riduce da solo dopo 1 minuto senza tocchi (Off / 30 s / 1 min / 2 min).

## RunnerKit - aggiornamento completo 2026-11-02
- **RunnerBoost 1.0.0** (nuovo): diagnosi con consigli, test di velocità con storico e confronto,
  profili veloce / bilanciato / normale (reversibili), report da mandare.
- **Terminale 1.0.0** (nuovo): prompt a colori con git/esito/durata, statistiche iniziali, `rktop`,
  storia comandi migliorata, scorciatoie e passaggio file verso l'app File (`aiphone`).
- **UnaVolta 1.1.0**: un programma lento ad aprirsi (Firefox su LinuxRunner) non viene più aperto due volte:
  se è già in esecuzione non se ne avvia un altro, anche senza finestra. Registro: `unavolta --log`.
- **TouchPad 2.4.1**: rispetta il profilo "veloce" (non riaccende la trasparenza).
- **Installatore**: installa tutti e 5 gli strumenti, aggiorna i tipi di file (icone .desktop che si
  aprono subito), stampa le versioni installate.

## Pulizia [1.0.0] - 2026-11-02
- Nuovo strumento RunnerKit: report del disco salvato nella cartella condivisa con l'app File,
  pulizia sicura (solo cache/cestino/log vecchi/temporanei/crash), modalità prova,
  pulizia automatica settimanale. Test: i file personali non vengono mai cancellati.

## UnaVolta [1.0.0] - 2026-11-02
- Nuovo strumento RunnerKit: tocchi ripetuti sulla stessa icona entro 4 s = un solo avvio
  (blocco atomico); se il programma è già aperto ne porta davanti la finestra (xdotool).
- `--applica` / `--ripristina` su icone del desktop e menu, senza toccare i file di sistema
  (copie personali in `~/.local/share/applications`). Esclusioni in `~/.config/unavolta/escludi`.
- L'installatore RunnerKit lo installa e lo attiva.

## [2.4.0] - 2026-11-02
### Nuovo
- **Si apre da solo** quando avvii il desktop (file standard `~/.config/autostart/touchpad.desktop`,
  creato dall'installatore). Interruttore in **⚙ → Avvio col desktop: Sì / No**.

## [2.3.0] - 2026-11-02
### Nuovo
- **Pallino intelligente:** "—" e Auto-riduci riducono TouchPad a un pallino rotondo nell'angolo
  (in alto a destra la prima volta). Tocco = torna dov'era, sulla stessa pagina.
  Trascinato = si aggancia al bordo più vicino e ricorda la posizione.
- **Una sola istanza:** rilanciare `touchpad` (o l'icona) mentre è aperto riapre quello esistente.
- La trasparenza vale anche per il pallino.
### Verificato
- Opacità funzionante su LinuxRunner con xcompmgr (screenshot dal telefono al 45%).

## [2.2.0] - 2026-11-02
### Nuovo
- **Auto-riduci** (⚙ → Off / 10 s / 30 s): se non lo tocchi resta solo la barra;
  toccando una scheda si riapre. Alternativa alla trasparenza su LinuxRunner.
- **⚙ mostra i valori** in chiaro: opacità, velocità, auto-riduci, tema, dimensione.
### Corretto
- Le pagine Tastiera e Tasti uscivano dal bordo destro dello schermo (× non visibile):
  ora la finestra viene sempre riportata dentro lo schermo.
- Opacità: su LinuxRunner non ha effetto perché manca il compositing. TouchPad ora lo rileva,
  prova ad avviare `xcompmgr` e, se non è disponibile, lo scrive e disattiva i pulsanti.
### Progetto
- Il repository diventa **RunnerKit**, il contenitore di tutti gli strumenti per LinuxRunner.

## [2.1.0] - 2026-11-02
### Nuovo
- `touchpad` funziona anche dal **Terminal dell'app**: trova da solo lo schermo del desktop
  (niente più "Can't open display") e si apre lì, restituendo subito il prompt.
  Eventuali errori finiscono in `~/.touchpad.log`. Con `touchpad --qui` resta in primo piano.
- L'installatore mette l'icona TouchPad anche **sul desktop**.

## [2.0.1] - 2026-11-02
### Corretto
- Tastiera: ultima riga con tasti "ù" e "-" troppo stretti, ora tutti i tasti hanno larghezza minima uguale.

## [2.0.0] - 2026-11-02
### Nuovo
- Tastiera completa italiana: lettere accentate (à è ì ò ù é), pagina simboli (?123),
  Shift una volta / Caps (doppio tocco), Ctrl e Alt "appiccicosi".
- Pagina "Tasti": frecce, Home/Fine/PgSu/PgGiù, F1–F12, Copia/Incolla (anche da terminale), Alt+F4.
- Pagina "⚙": 4 temi (scuro, blu, chiaro, verde), dimensioni S/M/L, opacità, velocità. Tutto salvato.
- Ripetizione tenendo premuto su ⌫, frecce e spazio.
### Più veloce
- Mouse e tastiera parlano direttamente con X11 (XTEST via python3-xlib):
  niente più un processo `xdotool` a ogni tocco.
- Eliminato il controllo della finestra attiva ogni 0,7 s.
- Mirino ridisegnato al massimo 30 volte al secondo; pagine create solo al primo uso.
### Corretto
- "Dx🔒" mostrava un quadratino (emoji senza font): ora "Dx fisso".
- Mirino più grande e visibile (20 px, rosso con freccia bianca).

## [1.0.0] - 2026-11-02
- Prima versione: mini touchpad con mirino, clic Sx/Dx/doppio, scroll, trascina,
  "tocco = destro", tasti Esc/Tab/frecce/Copia/Incolla. Basata su xdotool.
- Screenshot: `screenshots/v1.0-touchpad.png`
