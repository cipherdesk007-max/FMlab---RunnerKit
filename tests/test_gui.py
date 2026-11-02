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
