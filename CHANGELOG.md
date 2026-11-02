# Changelog

Formato: [versione] - data. Le versioni seguono MAJOR.MINOR.PATCH
(MAJOR = cambia il modo d'uso, MINOR = funzioni nuove, PATCH = correzioni).

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
