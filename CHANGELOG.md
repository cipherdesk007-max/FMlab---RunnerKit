# Changelog — FMlab - RunnerKit

Formato: [versione] - data. Le versioni seguono MAJOR.MINOR.PATCH
(MAJOR = cambia il modo d'uso, MINOR = funzioni nuove, PATCH = correzioni).

## FMlab - RunnerKit 2026.11.04-3 - TouchPad torna nel suo angolo
- **TouchPad 3.6**: quando giri il telefono anche la finestra di TouchPad (non solo i pallini) torna nel suo angolo
  invece di restare in mezzo allo schermo. L'angolo è quello più vicino a dove l'hai lasciata (di base in basso a
  destra), sempre fuori da Dynamic Island, indicatore Home e barra del desktop. Vale anche se il telefono è stato
  girato mentre TouchPad era ridotto a pallini.

## FMlab - RunnerKit 2026.11.04-2 - verticale, clear, lingua di Linux
- **TouchPad 3.5 in verticale**: con FMLAB Linux 0.8 lo schermo di Linux si gira col telefono. In verticale i
  pallini si mettono **in fila in basso**, sopra la barra del desktop (si spostano a destra/sinistra trascinandoli);
  tornando in orizzontale tornano in colonna sul lato. TouchPad si accorge da solo della misura nuova (entro 2 s).
- **Terminale**: `clear` e Ctrl+L puliscono ma **barra e riquadro RunnerKit restano**. Corretto il difetto delle
  righe sporche ("ffk = comandi", "o ff"): la seconda riga della barra era più lunga dello schermo del telefono e
  andava a capo nei comandi; ora si accorcia secondo la larghezza e non va mai a capo.
- **Lingua di Linux**: TouchPad (tastiera italiana o USA) e terminale prendono la lingua impostata in Linux
  (scelta di `rk italiano`, variabili, `/etc/default/locale`); se Linux non ne ha una (C/POSIX) resta l'italiano.
  In italiano la data è in italiano ("Mercoledì 04 novembre") anche senza il pacchetto della lingua, e lo stato
  del JIT è tradotto ("spento (solo gadget)").

## FMlab - RunnerKit 2026.11.04-1 - su misura per FMLAB Linux
- **TouchPad 3.4**: con FMLAB Linux a schermo intero il desktop arriva fino al bordo dell'iPhone. L'app (0.7.2)
  dice a Linux quale parte resta sotto Dynamic Island, angoli e indicatore Home (`fmlab-schermo` nella cartella
  della sessione) e TouchPad tiene **fuori da lì la colonna di pallini e la sua finestra**. Entrando o uscendo
  dallo schermo intero si risistema da solo entro 2 secondi.
- La colonna ricorda il **lato** (sinistra/destra), non i pixel: resta attaccata al bordo anche quando cambia la
  risoluzione (FMLAB Linux 0.7 sceglie da sola 1398×644 sul 15 Pro Max).
- **Riconosce FMLAB Linux** (che si firma in `/proc/ish/version`): Centro → riga **App** (es. "FMLAB Linux 0.7.2"),
  `rk collaudo` mostra versione e base e controlla i margini dello schermo, Pulizia e `alliphone` usano il nome
  giusto ("In questo iPhone > FMLAB Linux > Shared") e Pulizia indica Distribuzioni → Elimina e Impostazioni → Pulizia
  dell'app. Su LinuxRunner originale tutto resta com'era.
- Nuovo test automatico: pallini con margini a destra, a sinistra e uscendo dallo schermo intero.

## FMLAB Cleaner 1.3.1 (ex FMlab Pulizia)
- L'app per iPhone si chiama **FMLAB Cleaner** e ha un repository suo:
  https://github.com/cipherdesk007-max/FMLAB-cleaner — da qui in poi versioni e aggiornamenti sono lì.
  Questa versione fa da ponte: chi ha la 1.1–1.3.0 la riceve da qui, poi l'app si aggiorna dal repository nuovo.

## FMlab Pulizia 1.3.0
- **Svuota "Eliminati di recente" tutto in una volta** dall'app (l'app Foto li carica a pezzi da circa 3000):
  mostra quanti sono e quanto pesano, poi una conferma e iOS chiede la sua. Se la versione di iOS non lo
  permette, l'app spiega il modo manuale ("Elimina tutto").

## FMlab - RunnerKit 2026.11.03-2 e FMlab Pulizia 1.2.0 - logo FMlab
- **Logo FMlab** sulle icone del desktop Linux (RunnerKit Centro, Aggiorna RunnerKit), nella finestra e
  nell'intestazione del Centro, sulla pagina GitHub e come icona dell'app per iPhone.
- **FMlab Pulizia 1.2.0**:
  - **Comprimi video**: dai "Video grandi" scegli i video e li riduci (HEVC, al massimo 1080p) a circa metà
    peso; data, luogo e preferiti restano, l'originale va in Eliminati di recente solo dopo la copia.
    Rallentatori e video Cinematografici si saltano.
  - **Scheda App** (dentro LiveContainer): quanto occupa ogni app installata in LiveContainer, svuota cache e
    file temporanei, toglie i file .ipa rimasti e i dati di app già disinstallate. Documenti e dati non si toccano.

## FMlab Pulizia 1.1.0 (app per iPhone, nuova)
- Pulizia di foto e video (video grandi, doppioni, registrazioni, screenshot, raffiche) e scheda Telefono
  (batteria, temperatura, spazio, consigli). Si installa in LiveContainer, che dà il permesso alle Foto.
- Controllo aggiornamenti da GitHub; il file .ipa si ricompila da solo a ogni modifica.

## FMlab - RunnerKit 2026.11.03-1 - verifiche dell'avvio col desktop
- Nuovo test automatico del meccanismo vero: bus D-Bus di sessione + due programmi GTK che partono insieme
  (come lxpanel e pcmanfm) → TouchPad deve partire **una volta sola** e i programmi non devono aspettare.
- **Trovato e corretto grazie a quel test**: l'aggancio della versione -17 faceva aspettare il desktop fino a
  **25 secondi** all'apertura (D-Bus considera "ancora in avvio" un servizio che esce senza errore). Ora risponde
  subito: con RunnerKit i programmi GTK partono in 1 s, come senza.
- Registro degli avvii (`~/.config/runnerkit/avvio.log`, in `rk log`): quando il desktop ha fatto partire
  TouchPad e **in quanti secondi** TouchPad è comparso (misura reale sul telefono).
- `rk collaudo` controlla anche l'aggancio all'apertura del desktop, l'ultimo avvio e il registro del visore.

## FMlab - RunnerKit 2026.11.02-17 - avvio col desktop che funziona davvero
Trovato leggendo il codice di LinuxRunner (session.sh, desktop-components.sh): il desktop avvia openbox,
lxpanel e pcmanfm direttamente e **non legge mai `~/.config/autostart`**. Quindi TouchPad non partiva da solo
(sembrava di sì solo perché la sessione restava aperta) e anche la pulizia settimanale non partiva.
- Nuovo **rkavvio**: all'apertura del desktop i programmi GTK chiedono a D-Bus il servizio di accessibilità;
  RunnerKit si registra lì, fa partire TouchPad (e la pulizia settimanale, se accesa) e passa la mano al vero
  servizio se è installato. Si spegne come prima: ⚙ → Avvio col desktop → No.
- **Ogni "Open Desktop"** (anche tornando al desktop già aperto) TouchPad si rimette subito come colonna di
  pallini sul lato: se ne accorge dal registro del visore di LinuxRunner (display.log della sessione).
- TouchPad avviato così prende l'ambiente del desktop (GPU Metal compresa) per i programmi che apre.
- **Pulizia 1.3**: toglie le **sessioni vecchie del desktop** che LinuxRunner crea a ogni avvio e non cancella mai
  (mai quella in uso né quelle di programmi aperti) e i report vecchi di RunnerKit nella cartella Shared; il report
  spiega come liberare lo spazio dell'iPhone che Linux non può toccare (foto, aggiornamento iOS, altre app).
- TouchPad e Centro aperti dal Terminal dell'app trovano lo schermo giusto: prima potevano scegliere il socket
  di una sessione vecchia (nel report ce n'erano 15 in /tmp/.X11-unix).

## FMlab - RunnerKit 2026.11.02-16 - TouchPad 3.1
- All'apertura del desktop TouchPad compare **subito come colonna di pallini sul lato** (attesa ridotta da 3 a 1
  secondo, nessuna finestra grande che lampeggia e sparisce). Tocca ⌨ per aprirlo.
- All'avvio la trasparenza non parte più: si accende solo quando apri TouchPad (meno lavoro, avvio più rapido).

## FMlab - RunnerKit 2026.11.02-15 - velocità senza sciupare il telefono
Studiato sul codice e sui dati degli sviluppatori di LinuxRunner (docs/PERFORMANCE.md, kernel/resource.c):
- **Trasparenza solo quando serve**: TouchPad spegne il compositing quando è ridotto a pallini (la prova GPU
  sul telefono passava da ~68 a ~33 FPS con la trasparenza accesa) e lo riaccende solo se lo riapri non opaco.
- **Nuovo `rk riposo`** (anche nel Centro → Prestazioni → Consumo a riposo): misura quanto lavora il processore
  quando non fai niente e chi ne è la causa; il risultato va nello storico per i confronti prima/dopo.
- Meno risvegli in sottofondo: TouchPad ridotto controlla ogni 2,5 s invece di 1,5; il Centro ridotto a icona si ferma.
- Profilo veloce/bilanciato: Firefox a 30 fotogrammi al secondo, cache in RAM invece che sulla memoria flash
  (meno scritture = meno usura), niente Pocket e notizie nella nuova scheda.
- Diagnosi: spazio dell'iPhone quasi pieno come primo consiglio, dati reali sul JIT, spiegazione del perché
  `nice` non funziona su LinuxRunner; la prova GPU avvisa se la trasparenza abbassa il risultato.
- TouchPad: tasti larghi come "?123" non più tagliati; "Esci" con un simbolo che tutti i font hanno.

## FMlab - RunnerKit 2026.11.02-14 - TouchPad 3.0
- **×** di TouchPad non chiude più tutto: lo riduce alla colonna di pallini, come gli altri strumenti.
  Il tasto **—** non serve più ed è stato tolto. Per chiudere TouchPad del tutto: ⚙ → **✕ Esci**.
- Pagina ⚙ compatta: il riepilogo (opacità, velocità, GPU, versioni...) è nel quadro **ℹ Info**, che si apre
  accanto a TouchPad solo quando lo chiedi e si chiude da solo dopo 30 secondi.
- Tastiera: tasti funzione con un colore a parte, Invio evidenziato, ogni tasto si illumina al tocco,
  barra "spazio"; nei simboli ora ci sono **Esc, Tab, ← →** per usare meglio il terminale.
- Installatore: se la versione nuova non è ancora pubblicata lo dice chiaramente (prima diceva "connessione").

## FMlab - RunnerKit 2026.11.02-13 - versione finale (revisione completa)
**Aggiornamenti a prova di errore**
- Nuovo ramo `stabile`: i telefoni installano e si aggiornano solo da una versione che ha superato tutti i test.
- L'installatore scarica tutto, controlla ogni file e solo dopo installa: una rete che cade a metà o una
  pagina di accesso Wi-Fi non lasciano più il kit mezzo vecchio e mezzo nuovo.
- Un solo aggiornamento alla volta (due tocchi su ⟳ non ne aprono due), controllo dello spazio libero,
  ripetizione automatica dei download, messaggi chiari se apt non riesce.
- `rkaggiorna` scarica l'installatore intero prima di eseguirlo; TouchPad accetta solo versioni vere (AAAA.MM.GG-N).
- Repo spostato su `FMlab---RunnerKit` (i vecchi indirizzi vengono reindirizzati da GitHub).

**Nuovo: `rk disinstalla`** — toglie RunnerKit e annulla tutte le sue modifiche; `--tutto` anche le impostazioni.

**Sicurezza e dati**
- Backup: le chiavi SSH private non finiscono più nella cartella dell'app File (solo con `RKB_CHIAVI=1`); file leggibili solo dal proprietario.
- Pulizia: non tocca la cache di Firefox mentre è aperto, né socket e cartelle di programmi in funzione in /tmp;
  tiene le cache lente da ricreare (font, shader); si ferma se la home non è valida.

**Correzioni**
- UnaVolta: terminali, gestori di file ed editor si aprono sempre (prima l'icona "File" poteva non aprire nulla
  perché pcmanfm è anche il desktop); guarda solo i propri processi; le copie dei lanciatori seguono gli
  aggiornamenti di Debian e spariscono con i programmi tolti.
- Terminale 1.4.0: dopo `rk top` Ctrl+C torna normale; la barra si rimette a posto quando ruoti il telefono;
  all'uscita lo schermo torna normale; convive con altri PROMPT_COMMAND; lingua corretta anche non italiana.
- Test nuovi: prova completa dell'installatore (installa, già aggiornato, file rovinato, pagina HTML, disinstalla).
- Dal report di LinuxRunner: la Pulizia non tocca la cartella di lavoro della sessione (`/tmp/lr-runtime.*`)
  né i socket del display; creata `~/Templates` che pannello e desktop cercavano a ogni avvio.
- Licenza MIT.

## FMlab - RunnerKit 2026.11.02-12
- Il progetto si chiama **FMlab - RunnerKit**: titolo della pagina GitHub (italiano e inglese),
  installatore, aggiornamento, collaudo, finestra del Centro, schermata e barra del terminale.

## RunnerKit 2026.11.02-11 - prestazioni e pulizia rapida
- **Centro 1.1.0**: finestra più piccola e compatta; **⚡ Pulizia rapida** (un tocco, tutte le categorie
  sicure); nuova scheda **Prestazioni** (profili Veloce/Bilanciato/Normale, trasparenza on/off, test
  velocità, prova GPU, diagnosi, pulizia rapida); avviso quando è lo spazio dell'iPhone a essere finito.
- **RAM corretta nel Terminal dell'app**: lì manca MemAvailable e risultava sempre 100%; ora si stima da
  MemFree+Buffers+Cached (Terminale 1.3.2, RunnerBoost, Collaudo, Centro).
- **TouchPad 2.9.1**: la tastiera segue la lingua di Linux (italiano → layout italiano, altrimenti USA).
- **README in inglese** ([README.en.md](README.en.md)), l'italiano resta principale.

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
