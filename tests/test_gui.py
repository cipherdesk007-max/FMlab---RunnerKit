"""Smoke test della finestra: apre TouchPad, visita tutte le pagine,
prova temi e dimensioni, preme alcuni tasti e salva uno screenshot per pagina.
    xvfb-run -s "-screen 0 1280x720x24" python3 tests/test_gui.py
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "touchpad"))
os.environ["HOME"] = "/tmp/tp-home"  # config pulita
os.environ["TP_CLIPBOARD"] = "/tmp/tp-clipboard"
open("/tmp/tp-ver-remota", "w").write("9999.01.01-1\n")
open("/tmp/tp-ver-locale", "w").write("2026.11.02-1\n")
os.environ["TP_VERSIONE_URL"] = "file:///tmp/tp-ver-remota"
os.environ["TP_VERSIONE_LOCALE"] = "/tmp/tp-ver-locale"
open("/tmp/tp-clipboard", "w").close()
import touchpad  # noqa: E402

OUT = os.path.join(HERE, "..", "screenshots", "ci")
os.makedirs(OUT, exist_ok=True)


def shot(app, name):
    app.root.update()
    subprocess.run(["import", "-window", "root", os.path.join(OUT, name + ".png")],
                   check=False)


def main():
    app = touchpad.App()
    app.root.update()
    for page in ("Mouse", "Tastiera", "Tasti", "⚙"):
        app.show(page)
        shot(app, "pagina-" + {"⚙": "impostazioni"}.get(page, page.lower()))

    app.show("Tastiera")
    for k in ("⇧", "a", "?123", "€", "abc", "Ctrl", "c"):
        app.kpress(k)
        app._stop_rep()
    assert app.shift == 0 and not app.ctrl, "modificatori non azzerati"

    # la finestra deve restare dentro lo schermo su ogni pagina
    app.root.geometry(f"+{app.sw - 50}+{app.sh - 50}")
    for page in ("Tasti", "Tastiera", "⚙", "Mouse"):
        app.show(page)
        app._clamp()
        app.root.update()
        r = app.root
        assert r.winfo_x() + r.winfo_reqwidth() <= app.sw, f"{page} esce a destra"
        assert r.winfo_y() + r.winfo_reqheight() <= app.sh, f"{page} esce in basso"
    print("trasparenza disponibile:", app.trasp)
    # pallino: riduci, deve comparire; tocco = riapre nella stessa posizione
    app.root.geometry("+300+200")
    app.root.update()
    app.toggle_mini()
    app.root.update()
    assert app.bubble.winfo_viewable() and not app.root.winfo_viewable(), "pallino non mostrato"
    assert len(app.dock) == 6, "attesi 6 pallini"
    xs = {b.winfo_x() for b, *_ in app.dock}
    ys = [b.winfo_y() for b, *_ in app.dock]
    assert len(xs) == 1 and ys == sorted(ys) and len(set(ys)) == 6, f"pallini non in colonna: {xs} {ys}"
    app._toast("prova messaggio")
    app.root.update()
    shot(app, "pallino")
    app.toggle_mini()
    app.root.update()
    assert app.root.winfo_viewable() and (app.root.winfo_x(), app.root.winfo_y()) == (300, 200), \
        f"non e' tornato dov'era: {app.root.winfo_x()},{app.root.winfo_y()}"
    # seconda istanza: deve riaprire quella esistente
    app.toggle_mini()
    app.root.update()
    assert touchpad._gia_aperto(), "socket istanza unica non risponde"
    for _ in range(20):
        app.root.update()
    assert not app.mini, "la seconda istanza non ha riaperto"

    app.set_autostart(True)
    assert os.path.exists(touchpad.AUTOSTART), "avvio automatico non creato"
    app.set_autostart(False)
    assert not os.path.exists(touchpad.AUTOSTART), "avvio automatico non rimosso"

    # l'avvio automatico ("ping") non deve riaprire un TouchPad ridotto
    app.toggle_mini()
    app.root.update()
    assert touchpad._gia_aperto(b"ping")
    for _ in range(20):
        app.root.update()
    assert app.mini, "il ping dell'avvio automatico ha riaperto TouchPad"
    # i pallini nascosti per errore tornano da soli
    app.dock[2][0].withdraw()
    app._sempre_sopra()
    app.root.update()
    assert app.dock[2][0].winfo_viewable(), "pallino sparito non ripristinato"
    assert app.cfg.get("mini") is True, "stato ridotto non salvato"
    app.toggle_mini()
    app.root.update()

    # ✕ non deve mai chiudere TouchPad stesso (pallini compresi)
    app.toggle_mini(); app.root.update()
    for bb, *_ in app.dock:
        assert app._mia(bb.winfo_id()) and app._mia(int(bb.wm_frame(), 16)), "pallino non riconosciuto come mio"
    app.dock[0][0].destroy(); app.dock[1][0].destroy()      # simula pallini distrutti
    app._sempre_sopra(); app.root.update()
    assert len(app.dock) == 6 and all(bb.winfo_viewable() for bb, *_ in app.dock), "colonna non ricostruita"
    app.toggle_mini(); app.root.update()

    # ✕ non deve mai chiudere desktop o barra
    import tkinter as _tk
    finto = _tk.Toplevel(app.root)
    finto.title("finto pannello")
    finto.update()
    fw = app.x.d.create_resource_object("window", int(finto.wm_frame(), 16))
    fw.change_property(app.x.d.intern_atom("_NET_WM_WINDOW_TYPE"), app.x.d.intern_atom("ATOM"), 32,
                       [app.x.d.intern_atom("_NET_WM_WINDOW_TYPE_DOCK")])
    app.x.d.sync()
    assert app._protetta(fw), "una barra (DOCK) deve essere protetta"
    assert app._protetta(app.x.d.screen().root), "lo sfondo deve essere protetto"
    finto.destroy()

    # appunti condivisi: copia automatica Linux -> iPhone (file finto al posto di /dev/clipboard)
    app.root.clipboard_clear(); app.root.clipboard_append("ciao iPhone")
    app._appunti_loop(); app.root.update()
    assert open(touchpad.CLIP).read() == "ciao iPhone", "copia verso iPhone non riuscita"
    with open(touchpad.CLIP, "w") as f:
        f.write("dall'iPhone")
    app.incolla_da_iphone(False); app.root.update()
    assert app.root.clipboard_get() == "dall'iPhone", "incolla da iPhone non riuscito"

    # controllo aggiornamenti: versione remota diversa -> pallino ⟳ arancione
    import time as _t
    app._controlla_aggiornamenti()
    for _ in range(60):
        app.root.update(); _t.sleep(0.1)
        if app._nuova:
            break
    assert app._nuova == "9999.01.01-1", f"aggiornamento non rilevato: {app._nuova}"
    assert app._aggiorna_decidi("9999.01.01-1") == "nuova"
    assert app._aggiorna_decidi(open("/tmp/tp-ver-locale").read().strip()) == "aggiornato"
    assert app._aggiorna_decidi("") == "offline"
    app.toggle_mini(); app.root.update()
    shot(app, "pallino-aggiornamento")
    app.toggle_mini(); app.root.update()

    # × riduce a pallini (non chiude); il riepilogo sta nel quadro Info a parte
    app.show("⚙"); app.root.update()
    assert "✕ Esci" in app.cfg_btn and "ℹ Info" in app.cfg_btn, "mancano Info/Esci in ⚙"
    shot(app, "impostazioni")
    app.info_quadro(); app.root.update()
    assert app._quadro is not None and "TouchPad" in app._quadro_lbl.cget("text"), "quadro Info non aperto"
    shot(app, "impostazioni-info")
    app.info_quadro(); app.root.update()
    assert app._quadro is None, "il quadro Info non si chiude col secondo tocco"
    app.toggle_mini(); app.root.update()
    assert app.mini and app.root.state() == "withdrawn", "× deve ridurre a pallini"
    app.toggle_mini(); app.root.update()
    # tastiera: Esc/Tab/frecce nel livello simboli
    app.show("Tastiera"); app.set_layer("sym"); app.root.update()
    tasti = [k for k, _ in app.layers["sym"][1]]
    assert all(t in tasti for t in ("Esc", "Tab", "←", "→")), f"tasti mancanti: {tasti}"
    app.kpress("←"); app._stop_rep(); app.kpress("Esc")
    shot(app, "tastiera-simboli")
    app.set_layer("abc")

    # FMLAB Linux a schermo intero: i pallini e la finestra stanno fuori da Dynamic Island, angoli e indicatore Home
    schermo = "/tmp/tp-fmlab-schermo"
    with open(schermo, "w") as f:
        f.write("# prova\nmargini=90 0 90 32\nschermo_intero=1\n")
    os.environ["TP_SCHERMO"] = schermo
    app.toggle_mini(); app.root.update()
    app._autohide_loop(); app.root.update()
    S = app.S
    xs = {b.winfo_x() for b, *_ in app.dock}
    assert xs == {app.sw - 90 - S - 6}, f"pallini sotto la zona coperta a destra: {xs}"
    assert max(b.winfo_y() + S for b, *_ in app.dock) <= app.sh - 32, "pallini sotto l'indicatore Home"
    shot(app, "pallini-fmlab-schermo-intero")
    # trascinata a sinistra: si aggancia fuori dalla Dynamic Island anche li'
    app._bx, app._by = 0, 0; app._bmoved = 0
    app._place_dock(40, 100); app.root.update()
    class _E: x_root = y_root = 0
    app._bmoved = 50; app._b_up(_E(), "apri"); app.root.update()
    assert app.cfg.get("lato") == "sx" and {b.winfo_x() for b, *_ in app.dock} == {90 + 6}, "lato sinistro non rispettato"
    # uscendo dallo schermo intero (margini 0) la colonna torna al bordo
    with open(schermo, "w") as f:
        f.write("margini=0 0 0 0\nschermo_intero=0\n")
    os.utime(schermo, (1, 1))
    app._autohide_loop(); app.root.update()
    assert {b.winfo_x() for b, *_ in app.dock} == {6}, "margini non aggiornati uscendo dallo schermo intero"
    app.cfg["lato"] = "dx"; app._place_dock(*app._dock_xy()); app.root.update()
    del os.environ["TP_SCHERMO"]
    app.toggle_mini(); app.root.update()

    app.set_autohide(10)
    app.last_touch -= 60
    app._autohide_loop()
    assert app.mini, "auto-riduci non ha ridotto"
    app.show("Mouse")
    assert not app.mini, "toccare una scheda deve riaprire"
    app.set_autohide(0)

    app.show("Mouse")
    app.toggle_lock()
    app.toggle_lock()
    app.click(1)

    for theme in touchpad.THEMES:
        app.cfg["theme"] = theme
        app.build()
        app.root.update()
    app.cfg["theme"] = "scuro"
    for size in touchpad.SIZES:
        app.cfg["size"] = size
        app.build()
        app.show("Tastiera")
        shot(app, "tastiera-" + size)
    app.quit()
    print("OK gui: pagine, temi, dimensioni, tasti")


if __name__ == "__main__":
    main()
