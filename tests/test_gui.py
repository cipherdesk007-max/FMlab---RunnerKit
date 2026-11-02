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
