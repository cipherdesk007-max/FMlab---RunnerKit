"""Test del Centro RunnerKit: tre schede, analisi della pulizia, screenshot.
    xvfb-run python3 tests/test_centro.py"""
import importlib.machinery
import os
import subprocess
import sys
import time

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, "..")
os.environ["PATH"] = os.path.join(RADICE, "pulizia") + os.pathsep + os.environ["PATH"]
os.environ["HOME"] = "/tmp/centro-home"
os.makedirs("/tmp/centro-home/.cache/prova", exist_ok=True)
open("/tmp/centro-home/.cache/prova/file.bin", "wb").write(b"0" * 300000)
sys.argv = ["rkcentro"]
centro = importlib.machinery.SourceFileLoader("rkcentro", os.path.join(RADICE, "strumenti", "rkcentro")).load_module()
OUT = os.path.join(RADICE, "screenshots", "ci")
os.makedirs(OUT, exist_ok=True)


def shot(app, nome):
    app.root.update()
    subprocess.run(["import", "-window", "root", os.path.join(OUT, nome + ".png")], check=False)


app = centro.Centro("sistema")
for _ in range(3):
    app._aggiorna_sistema()
    app.root.update()
    time.sleep(0.3)
assert app.info["RAM"].cget("text") != "…", "statistiche di sistema non aggiornate"
shot(app, "centro-sistema")

app.mostra("pulizia")
for _ in range(240):
    app.root.update()
    time.sleep(0.25)
    if app.categorie:
        break
assert app.categorie, "analisi della pulizia non completata"
nomi = [c[0] for c in app.categorie]
assert "cache" in nomi and "autoremove" in nomi, nomi
cache_kb = dict((n, k) for n, _, k in app.categorie)["cache"]
assert cache_kb >= 250, f"la cache di prova non e' stata misurata: {cache_kb} KB"
assert app.scelte["autoremove"].get() is False, "i pacchetti (avanzato) non devono essere scelti di default"
shot(app, "centro-pulizia")

# pulizia solo della cache
for n in app.scelte:
    app.scelte[n].set(n == "cache")
app.pulisci()
for _ in range(120):
    app.root.update()
    time.sleep(0.25)
    if app._lav is None and not os.path.exists("/tmp/centro-home/.cache/prova/file.bin"):
        break
assert not os.path.exists("/tmp/centro-home/.cache/prova/file.bin"), "la cache non e' stata pulita"

app.mostra("processi")
app._aggiorna_processi()
app.root.update()
assert len(app.p_righe.winfo_children()) > 0, "elenco processi vuoto"
shot(app, "centro-processi")

# istanza unica: una seconda chiamata cambia scheda invece di aprire un'altra finestra
assert centro.gia_aperto("sistema")
for _ in range(10):
    app.root.update()
assert app.attiva == "sistema"
app.chiudi()
print("OK centro: sistema, pulizia (analisi + pulizia cache), processi, istanza unica")
