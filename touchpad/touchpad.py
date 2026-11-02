#!/usr/bin/env python3
"""TouchPad 2 - mouse + tastiera fluttuante per LinuxRunner.
Parla direttamente con X11 (XTEST): nessun processo esterno per tocco."""
__version__ = "2.5.2"

import glob
import json
import shutil
import socket
import time
import os
import subprocess
import sys


def _trova_display():
    """Se lanciato dal Terminal dell'app (senza DISPLAY) usa lo schermo del desktop."""
    if os.environ.get("DISPLAY"):
        return
    socks = sorted(glob.glob("/tmp/.X11-unix/X*"))
    os.environ["DISPLAY"] = ":" + socks[0].rsplit("X", 1)[1] if socks else ":0"


def _stacca_dal_terminale():
    """Da terminale: apre TouchPad sul desktop e restituisce subito il prompt."""
    if os.environ.get("TP_FIGLIO") or not sys.stdin.isatty() or "--qui" in sys.argv:
        return
    env = dict(os.environ, TP_FIGLIO="1")
    log = open(os.path.expanduser("~/.touchpad.log"), "w")
    subprocess.Popen([sys.executable, os.path.abspath(__file__)], env=env,
                     stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                     start_new_session=True)
    print(f"TouchPad v{__version__} aperto sul desktop ({os.environ['DISPLAY']}).")
    print("Errori eventuali in ~/.touchpad.log")
    sys.exit(0)


SOCK = f"/tmp/touchpad-{os.getuid()}.sock"


def _gia_aperto(messaggio=b"show"):
    """Se TouchPad e' gia' aperto glielo dice ed esce. "show" = riapriti, "ping" = solo controllo."""
    try:
        c = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        c.settimeout(1)
        c.connect(SOCK)
        c.sendall(messaggio)
        c.close()
        return True
    except OSError:
        return False


_trova_display()
if __name__ == "__main__":
    if "--avvio" in sys.argv:  # avvio automatico: se c'e' gia', non toccarlo
        if _gia_aperto(b"ping"):
            sys.exit(0)
    elif _gia_aperto():
        print("TouchPad era gia' aperto: l'ho riaperto sul desktop.")
        sys.exit(0)
    _stacca_dal_terminale()

import tkinter as tk  # noqa: E402

from Xlib import X, XK, display  # noqa: E402
from Xlib.ext import xtest  # noqa: E402

CFG = os.path.expanduser("~/.config/touchpad.json")
AUTOSTART = os.path.expanduser("~/.config/autostart/touchpad.desktop")
AUTOSTART_TXT = """[Desktop Entry]
Type=Application
Name=TouchPad
Comment=Avvia TouchPad con il desktop (RunnerKit)
Exec=sh -c "sleep 3; [ -f ~/.config/runnerboost/no-compositing ] || pgrep -x xcompmgr >/dev/null || xcompmgr & exec touchpad --avvio"
X-GNOME-Autostart-enabled=true
X-XFCE-Autostart-Override=true
Hidden=false
"""
THEMES = {
    "scuro": dict(bg="#1b1f27", key="#2a303c", fg="#e6e6e6", acc="#3b82f6", dim="#7c8696"),
    "blu": dict(bg="#0f1b2d", key="#1d3557", fg="#f1faee", acc="#e63946", dim="#8da9c4"),
    "chiaro": dict(bg="#e9edf2", key="#ffffff", fg="#1b1f27", acc="#2563eb", dim="#6b7280"),
    "verde": dict(bg="#0d1f17", key="#163828", fg="#d8f3dc", acc="#40c057", dim="#74a98a"),
}
SIZES = {"S": (9, 3, 220, 110), "M": (11, 6, 270, 140), "L": (14, 9, 340, 180)}

ABC = [list("1234567890'"), list("qwertyuiopè"), list("asdfghjklòà"),
       ["⇧"] + list("zxcvbnm,.") + ["⌫"], ["?123", "Ctrl", "Alt", "␣", "ù", "-", "⏎"]]
SYM = [list('!"£$%&/()=?'), list("@#[]{}<>|\\^"), list("*+~_;:€°éì`"),
       ["⇧"] + list("ç§«»¿¡ñ,.") + ["⌫"], ["abc", "Ctrl", "Alt", "␣", "ù", "-", "⏎"]]
SPECIAL = {"⌫": "BackSpace", "⏎": "Return", "␣": "space"}
REPEAT = {"⌫", "←", "→", "↑", "↓", "␣"}


class X11:
    def __init__(self):
        self.d = display.Display()
        info = self.d.display.info
        lo, hi = info.min_keycode, info.max_keycode
        maps = self.d.get_keyboard_mapping(lo, hi - lo + 1)
        # keycode liberi: ci assegno al volo i caratteri che la tastiera X non ha (à è €...)
        self.spares = [lo + i for i in range(len(maps) - 1, -1, -1) if not any(maps[i])]
        self.assigned = {}

    def move(self, x, y):
        xtest.fake_input(self.d, X.MotionNotify, x=x, y=y)
        self.d.flush()

    def button(self, b, press):
        xtest.fake_input(self.d, X.ButtonPress if press else X.ButtonRelease, b)
        self.d.flush()

    def click(self, b, n=1):
        for _ in range(n):
            self.button(b, True)
            self.button(b, False)
        self.d.sync()

    def _code(self, ks):
        for kc, idx in self.d.keysym_to_keycodes(ks):
            if idx in (0, 1):
                return kc, idx == 1
        if ks in self.assigned:
            return self.assigned[ks], False
        if not self.spares:
            return None, False
        n = len(self.assigned)
        kc = self.spares[n % len(self.spares)]
        for k, v in list(self.assigned.items()):
            if v == kc:
                del self.assigned[k]
        self.d.change_keyboard_mapping(kc, [(ks,) * 4])
        self.d.sync()
        self.assigned[ks] = kc
        return kc, False

    def key(self, name, mods=()):
        if len(name) == 1:
            o = ord(name)
            ks = o if o < 256 else 0x1000000 + o
        else:
            ks = XK.string_to_keysym(name)
        kc, shift = self._code(ks)
        if not kc:
            return
        held = [self._code(XK.string_to_keysym(m))[0] for m in mods]
        if shift and "Shift_L" not in mods:
            held.append(self._code(XK.XK_Shift_L)[0])
        for m in held:
            xtest.fake_input(self.d, X.KeyPress, m)
        xtest.fake_input(self.d, X.KeyPress, kc)
        xtest.fake_input(self.d, X.KeyRelease, kc)
        for m in reversed(held):
            xtest.fake_input(self.d, X.KeyRelease, m)
        self.d.sync()

    def compositing(self):
        """True se un compositing manager e' attivo (serve per la trasparenza)."""
        owner = self.d.get_selection_owner(self.d.intern_atom("_NET_WM_CM_S0"))
        return getattr(owner, "id", owner) not in (0, None)

    def has_composite(self):
        return self.d.has_extension("Composite")

    def swap(self, on):
        m = list(self.d.get_pointer_mapping())
        if len(m) >= 3:
            m[0], m[2] = (3, 1) if on else (1, 3)
            self.d.set_pointer_mapping(m)
            self.d.sync()


class App:
    def __init__(self):
        try:
            with open(CFG) as f:
                self.cfg = json.load(f)
        except Exception:
            self.cfg = {}
        c = self.cfg
        c.setdefault("theme", "scuro"); c.setdefault("size", "M")
        c.setdefault("alpha", 0.8); c.setdefault("speed", 1.8)
        c.setdefault("page", "Mouse"); c.setdefault("autohide", 60)
        if c.get("cfgver", 1) < 2:  # dalla 2.5: si riduce da solo quando non lo usi
            c["autohide"] = 60
            c["cfgver"] = 2
        self.x = X11()
        r = self.root = tk.Tk()
        r.title("TouchPad")
        r.overrideredirect(True)
        r.attributes("-topmost", True)
        self.sw, self.sh = r.winfo_screenwidth(), r.winfo_screenheight()
        self.cx, self.cy = self.sw // 2, self.sh // 2
        self.shift = 0  # 0 no, 1 una volta, 2 bloccato
        self.ctrl = self.alt = False
        self.lock = False
        self.drag_from = None
        self.mini = False
        self._rep = self._mk_job = None
        self._marker()
        self.build()
        r.geometry(c.get("geo", f"+{self.sw - 460}+{self.sh - 360}"))
        self.trasp = None  # None = da verificare, True/False
        self._check_comp(first=True)
        self.last_touch = time.time()
        r.bind_all("<ButtonPress>", self._touched, add="+")
        r.after(100, self._clamp)
        if c.get("mini"):  # era ridotto: riparte come colonna di pallini
            c["mini"] = False
            r.after(400, self.toggle_mini)
        r.after(1500, self._sempre_sopra)
        r.report_callback_exception = self._errore
        r.after(2000, self._autohide_loop)
        self.bubble = None   # pallino principale (apre TouchPad)
        self.dock = []       # colonna di pallini: (finestra, canvas, simbolo, azione)
        self._da_forzare = None
        self._server()
        self.say(f"TouchPad v{__version__}")

    # ---------- costruzione ----------
    def T(self, k):
        return THEMES[self.cfg["theme"]][k]

    def build(self):
        for w in self.root.winfo_children():
            if w is not self.mk:
                w.destroy()
        self.font, self.pady, self.pw, self.ph = SIZES[self.cfg["size"]]
        self.root.configure(bg=self.T("bg"))
        bar = tk.Frame(self.root, bg=self.T("bg"))
        bar.pack(fill="x")
        g = tk.Label(bar, text="⠿", bg=self.T("bg"), fg=self.T("dim"),
                     font=("DejaVu Sans", self.font + 3), padx=6)
        g.pack(side="left")
        g.bind("<ButtonPress-1>", self._grab)
        g.bind("<B1-Motion>", self._drag_win)
        g.bind("<ButtonRelease-1>", lambda e: (self._clamp(), self.save()))
        self.tabs = {}
        for name in ("Mouse", "Tastiera", "Tasti", "⚙"):
            b = self.btn(bar, name, lambda n=name: self.show(n), bg=self.T("bg"))
            b.pack(side="left", padx=1)
            self.tabs[name] = b
        for t, f in (("×", self.quit), ("—", self.toggle_mini)):
            self.btn(bar, t, f, bg=self.T("bg"), w=2).pack(side="right", padx=1)
        self.holder = tk.Frame(self.root, bg=self.T("bg"))
        self.holder.pack(fill="both", padx=5, pady=(0, 5))
        self.status = tk.Label(self.root, text="", bg=self.T("bg"), fg=self.T("dim"),
                               font=("DejaVu Sans", max(8, self.font - 2)))
        self.status.pack(fill="x")
        self.pages = {}
        self.page = None
        self.cfg_btn = None
        self.show(self.cfg["page"])

    def btn(self, parent, text, cmd=None, bg=None, w=None):
        b = tk.Button(parent, text=text, command=cmd, bg=bg or self.T("key"),
                      fg=self.T("fg"), activebackground=self.T("acc"),
                      activeforeground="white", relief="flat", bd=0,
                      highlightthickness=0, takefocus=0, padx=3, pady=self.pady,
                      font=("DejaVu Sans", self.font, "bold"))
        if w:
            b.config(width=w)
        return b

    def grid_rows(self, parent, rows, wide=None):
        out = {}
        for row in rows:
            fr = tk.Frame(parent, bg=self.T("bg"))
            fr.pack(fill="x", pady=(3, 0))
            for item in row:
                text, cmd = item if isinstance(item, tuple) else (item, None)
                b = self.btn(fr, text, cmd)
                b.pack(side="left", expand=True, fill="x", padx=1,
                       ipadx=40 if wide and text in wide else 0)
                out[text] = b
        return out

    def show(self, name):
        if self.mini:
            self.toggle_mini()
        if name == self.page:
            return
        if self.page:
            self.pages[self.page].pack_forget()
        if name not in self.pages:  # le pagine si creano solo al primo uso
            f = tk.Frame(self.holder, bg=self.T("bg"))
            getattr(self, "page_" + {"⚙": "cfg"}.get(name, name.lower()))(f)
            self.pages[name] = f
        self.pages[name].pack(fill="both")
        for n, b in self.tabs.items():
            b.config(bg=self.T("acc") if n == name else self.T("bg"))
        self.page = name
        if name != "⚙":
            self.cfg["page"] = name
        self.root.after_idle(self._clamp)

    # ---------- pagina Mouse ----------
    def page_mouse(self, f):
        p = self.pad = tk.Canvas(f, width=self.pw, height=self.ph, bg=self.T("key"),
                                 highlightthickness=0)
        p.pack(fill="x")
        p.create_text(self.pw // 2, self.ph // 2, fill=self.T("dim"),
                      font=("DejaVu Sans", max(8, self.font - 2)), justify="center",
                      text="trascina = muovi mirino\ntocco = sinistro · tieni = destro")
        p.bind("<ButtonPress-1>", self._pad_down)
        p.bind("<B1-Motion>", self._pad_move)
        p.bind("<ButtonRelease-1>", self._pad_up)
        self.mb = self.grid_rows(f, [
            [("Sx", lambda: self.click(1)), ("Dx", lambda: self.click(3)),
             ("2×", lambda: self.click(1, 2)), ("▲", lambda: self.click(4, 3)),
             ("▼", lambda: self.click(5, 3))],
            [("Trasc", self.drag), ("Dx fisso", self.toggle_lock), ("◎", self.center),
             ("Vel−", lambda: self.speed(-0.4)), ("Vel+", lambda: self.speed(0.4))]])

    # ---------- pagina Tastiera ----------
    def page_tastiera(self, f):
        self.layers = {}
        for name, rows in (("abc", ABC), ("sym", SYM)):
            fr = tk.Frame(f, bg=self.T("bg"))
            self.layers[name] = (fr, self.keyrows(fr, rows))
        self.layer = None
        self.set_layer("abc")

    def keyrows(self, parent, rows):
        out = []
        for row in rows:
            fr = tk.Frame(parent, bg=self.T("bg"))
            fr.pack(fill="x", pady=(3, 0))
            for k in row:
                b = self.btn(fr, k, w=2 if k != "␣" else None)
                b.pack(side="left", expand=True, fill="x", padx=1,
                       ipadx=40 if k == "␣" else 0)
                b.bind("<ButtonPress-1>", lambda e, k=k: self.kpress(k))
                b.bind("<ButtonRelease-1>", lambda e: self._stop_rep())
                out.append((k, b))
        return out

    def set_layer(self, name):
        if self.layer:
            self.layers[self.layer][0].pack_forget()
        self.layers[name][0].pack(fill="both")
        self.layer = name
        self.refresh_keys()

    def refresh_keys(self):
        if not getattr(self, "layer", None):
            return
        for k, b in self.layers[self.layer][1]:
            if len(k) == 1 and k.isalpha():
                b.config(text=k.upper() if self.shift else k)
            on = (k == "⇧" and self.shift) or (k == "Ctrl" and self.ctrl) or \
                 (k == "Alt" and self.alt)
            b.config(bg=self.T("acc") if on else self.T("key"))
        lock = self.layers[self.layer][1]
        for k, b in lock:
            if k == "⇧":
                b.config(text="⇪" if self.shift == 2 else "⇧")

    def kpress(self, k):
        if k == "⇧":
            self.shift = (self.shift + 1) % 3
        elif k == "Ctrl":
            self.ctrl = not self.ctrl
        elif k == "Alt":
            self.alt = not self.alt
        elif k in ("?123", "abc"):
            self.set_layer("sym" if k == "?123" else "abc")
            return
        else:
            mods = [m for m, on in (("Control_L", self.ctrl), ("Alt_L", self.alt)) if on]
            name = SPECIAL.get(k, k)
            if len(name) == 1 and self.shift and not mods:
                name = name.upper()
            self.x.key(name, mods)
            if k in REPEAT:
                self._rep = self.root.after(400, self._repeat, name, mods)
            if self.shift == 1:
                self.shift = 0
            self.ctrl = self.alt = False
        self.refresh_keys()

    def _repeat(self, name, mods):
        self.x.key(name, mods)
        self._rep = self.root.after(70, self._repeat, name, mods)

    def _stop_rep(self):
        if self._rep:
            self.root.after_cancel(self._rep)
            self._rep = None

    # ---------- pagina Tasti ----------
    def page_tasti(self, f):
        def k(label, combo, rep=False):
            mods, _, key = combo.rpartition("+")
            mods = [{"ctrl": "Control_L", "alt": "Alt_L", "shift": "Shift_L",
                     "super": "Super_L"}[m] for m in mods.split("+") if m]
            return (label, lambda: self.x.key(key, mods))
        rows = [
            [k("Esc", "Escape"), k("Tab", "Tab"), k("Canc", "Delete"),
             k("Ins", "Insert"), k("⏎", "Return")],
            [k("Home", "Home"), k("↑", "Up"), k("Fine", "End"), k("PgSu", "Prior")],
            [k("←", "Left"), k("↓", "Down"), k("→", "Right"), k("PgGiù", "Next")],
            [k("Copia", "ctrl+c"), k("Incolla", "ctrl+v"), k("Taglia", "ctrl+x"),
             k("Annulla", "ctrl+z"), k("Rifai", "ctrl+y")],
            [k("Tutto", "ctrl+a"), k("Salva", "ctrl+s"), k("Trova", "ctrl+f"),
             k("Alt⇥", "alt+Tab"), k("Super", "Super_L")],
            [k("Copia term", "ctrl+shift+c"), k("Incolla term", "ctrl+shift+v"),
             k("Stop ^C", "ctrl+c"), k("Chiudi", "alt+F4")],
            [k(f"F{i}", f"F{i}") for i in range(1, 7)],
            [k(f"F{i}", f"F{i}") for i in range(7, 13)],
        ]
        self.grid_rows(f, rows)

    # ---------- pagina Impostazioni ----------
    def page_cfg(self, f):
        def setv(key, val):
            self.cfg[key] = val
            self.save()
            self.build()
        rows = [[(t, lambda t=t: setv("theme", t)) for t in THEMES],
                [(f"Dim {s}", lambda s=s: setv("size", s)) for s in SIZES],
                [("Opacità −", lambda: self._alpha(-0.15)),
                 ("Opacità +", lambda: self._alpha(0.15))],
                [("Vel −", lambda: self.speed(-0.4)), ("Vel +", lambda: self.speed(0.4)),
                 ("Mirino ◎", self.center)],
                [("Auto-riduci", None)] +
                [(lab, lambda v=v: self.set_autohide(v))
                 for lab, v in (("Off", 0), ("30 s", 30), ("1 min", 60), ("2 min", 120))],
                [("Avvio col desktop", None), ("Sì", lambda: self.set_autostart(True)),
                 ("No", lambda: self.set_autostart(False))]]
        b = self.cfg_btn = self.grid_rows(f, rows)
        b[self.cfg["theme"]].config(bg=self.T("acc"))
        b["Dim " + self.cfg["size"]].config(bg=self.T("acc"))
        for k in ("Auto-riduci", "Avvio col desktop"):
            b[k].config(bg=self.T("bg"), state="disabled", disabledforeground=self.T("fg"))
        if self.trasp is False:
            for k in ("Opacità −", "Opacità +"):
                b[k].config(state="disabled", disabledforeground=self.T("dim"))
        self.cfg_info = tk.Label(f, text="", bg=self.T("bg"), fg=self.T("fg"),
                                 justify="left", anchor="w",
                                 font=("DejaVu Sans", max(9, self.font - 1)))
        self.cfg_info.pack(fill="x", pady=(6, 2), padx=4)
        self._cfg_refresh()

    def _cfg_refresh(self):
        b = getattr(self, "cfg_btn", None)
        try:
            if not b or not self.cfg_info.winfo_exists():
                return
        except tk.TclError:
            return
        for lab, v in (("Off", 0), ("30 s", 30), ("1 min", 60), ("2 min", 120)):
            b[lab].config(bg=self.T("acc") if self.cfg["autohide"] == v else self.T("key"))
        auto = os.path.exists(AUTOSTART)
        b["Sì"].config(bg=self.T("acc") if auto else self.T("key"))
        b["No"].config(bg=self.T("key") if auto else self.T("acc"))
        if self.trasp:
            t = f"Opacità: {int(self.cfg['alpha'] * 100)}%"
        elif self.trasp is None:
            t = "Opacità: verifica in corso..."
        else:
            t = "Opacità: non disponibile su questo schermo\n(manca il compositing). Usa Auto-riduci."
        ah = self.cfg["autohide"]
        self.cfg_info.config(text=f"{t}\nVelocità mirino: {self.cfg['speed']}\n"
                                  f"Auto-riduci: {'spento' if not ah else f'dopo {ah} s senza tocchi'}\n"
                                  f"Avvio col desktop: {'sì' if auto else 'no'}\n"
                                  f"Tema: {self.cfg['theme']} · Dimensione: {self.cfg['size']}")

    # ---------- mirino e touchpad ----------
    def _marker(self):
        m = self.mk = tk.Toplevel(self.root)
        m.title("tp-marker")
        m.overrideredirect(True)
        m.attributes("-topmost", True)
        cv = tk.Canvas(m, width=20, height=20, bg="#ff2d55", highlightthickness=0)
        cv.pack()
        cv.create_polygon(0, 0, 19, 8, 10, 10, 8, 19, fill="white", outline="black")
        self._place()

    def _place(self):
        self._mk_job = None
        # la punta sta 2px fuori dalla finestra del mirino: il clic non colpisce il mirino
        self.mk.geometry(f"20x20+{self.cx + 2}+{self.cy + 2}")
        self.mk.lift()

    def _pad_down(self, e):
        self._lx, self._ly, self._moved = e.x, e.y, 0
        self._long = self.root.after(550, self._pad_long)

    def _pad_move(self, e):
        dx, dy = e.x - self._lx, e.y - self._ly
        self._lx, self._ly = e.x, e.y
        self._moved += abs(dx) + abs(dy)
        if self._moved > 6 and self._long:
            self.root.after_cancel(self._long)
            self._long = None
        acc = self.cfg["speed"] * (1 + min(abs(dx) + abs(dy), 30) / 15)
        self.cx = max(0, min(self.sw - 1, int(self.cx + dx * acc)))
        self.cy = max(0, min(self.sh - 1, int(self.cy + dy * acc)))
        if not self._mk_job:  # ridisegna al massimo ~30 volte al secondo
            self._mk_job = self.root.after(33, self._place)

    def _pad_up(self, e):
        if self._long:
            self.root.after_cancel(self._long)
            self._long = None
            if self._moved <= 6:
                self.click(1)

    def _pad_long(self):
        self._long = None
        self.click(3)

    # ---------- azioni mouse ----------
    def click(self, b, n=1):
        self.x.move(self.cx, self.cy)
        self.x.click(b, n)
        self.say({1: "clic sinistro", 3: "clic destro", 4: "su", 5: "giù"}.get(b, ""))

    def drag(self):
        b = self.mb["Trasc"]
        if self.drag_from is None:
            self.drag_from = (self.cx, self.cy)
            b.config(bg=self.T("acc"))
            self.say("partenza segnata: sposta il mirino e ripremi Trasc")
            return
        (sx, sy), self.drag_from = self.drag_from, None
        b.config(bg=self.T("key"))
        self.x.move(sx, sy)
        self.x.button(1, True)
        for i in range(1, 9):
            self.x.move(sx + (self.cx - sx) * i // 8, sy + (self.cy - sy) * i // 8)
            self.root.update_idletasks()
        self.x.button(1, False)
        self.x.d.sync()
        self.say("trascinato")

    def toggle_lock(self):
        self.lock = not self.lock
        self.x.swap(self.lock)
        self.mb["Dx fisso"].config(bg=self.T("acc") if self.lock else self.T("key"))
        self.say("ogni tocco = DESTRO" if self.lock else "tocco normale")

    def center(self):
        self.cx, self.cy = self.sw // 2, self.sh // 2
        self._place()

    def speed(self, d):
        self.cfg["speed"] = max(0.6, min(5.0, round(self.cfg["speed"] + d, 1)))
        self.say(f"velocità {self.cfg['speed']}")
        self.save()
        self._cfg_refresh()

    # ---------- finestra ----------
    def _grab(self, e):
        self._ox = e.x_root - self.root.winfo_x()
        self._oy = e.y_root - self.root.winfo_y()

    def _drag_win(self, e):
        self.root.geometry(f"+{e.x_root - self._ox}+{e.y_root - self._oy}")

    def _alpha(self, d=0):
        a = self.cfg["alpha"] = max(0.3, min(1.0, round(self.cfg["alpha"] + d, 2)))
        for w in (self.root, self.mk, *[b for b, *_ in getattr(self, "dock", [])]):
            if w is None:
                continue
            try:
                w.attributes("-alpha", a if self.trasp else 1.0)
            except tk.TclError:
                pass
        if d:
            self.say(f"opacità {int(a * 100)}%" if self.trasp
                     else "opacità non disponibile qui")
            self.save()
        self._cfg_refresh()

    def _check_comp(self, first=False):
        """La trasparenza funziona solo con un compositing manager.
        LinuxRunner di solito non ce l'ha: provo ad avviare xcompmgr, poi verifico."""
        if self.x.compositing():
            self.trasp = True
        elif os.path.exists(os.path.expanduser("~/.config/runnerboost/no-compositing")):
            self.trasp = False  # profilo "veloce" di RunnerBoost: niente xcompmgr
        elif first and self.x.has_composite() and shutil.which("xcompmgr"):
            subprocess.Popen(["xcompmgr"], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
            self.root.after(1500, self._check_comp)
            return
        else:
            self.trasp = False
        self._alpha()

    def set_autostart(self, on):
        try:
            if on:
                os.makedirs(os.path.dirname(AUTOSTART), exist_ok=True)
                with open(AUTOSTART, "w") as f:
                    f.write(AUTOSTART_TXT)
            elif os.path.exists(AUTOSTART):
                os.remove(AUTOSTART)
            self.say("si apre da solo all'avvio" if on else "avvio automatico spento")
        except OSError as ex:
            self.say(f"errore: {ex}")
        self._cfg_refresh()

    def _sempre_sopra(self):
        """Openbox mette sopra ogni finestra nuova: ogni 1,5 s riporto davanti TouchPad.
        Se i pallini sono stati nascosti per errore, li rimostro."""
        try:
            if self.mini:
                for b, *_ in self.dock:
                    if not b.winfo_viewable():
                        b.deiconify()
                    b.lift()
            elif self.root.winfo_viewable():
                self.root.lift()
                self.mk.lift()
        except tk.TclError:
            pass
        self.root.after(1500, self._sempre_sopra)

    def _errore(self, tipo, valore, tb):
        """Un errore in un pulsante non deve far sparire niente: lo scrivo nel log e vado avanti."""
        import traceback
        try:
            with open(os.path.expanduser("~/.touchpad.log"), "a") as f:
                f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + "".join(
                    traceback.format_exception(tipo, valore, tb)))
        except OSError:
            pass

    def _touched(self, e=None):
        self.last_touch = time.time()

    def set_autohide(self, v):
        self.cfg["autohide"] = v
        self.save()
        self._cfg_refresh()
        self.say("auto-riduci " + (f"dopo {v} s" if v else "spento"))

    def _autohide_loop(self):
        ah = self.cfg.get("autohide", 0)
        if ah and not self.mini and time.time() - self.last_touch > ah:
            self.toggle_mini()
        self.root.after(2000, self._autohide_loop)

    def _clamp(self):
        """Tiene la finestra dentro lo schermo (le pagine larghe uscivano a destra)."""
        r = self.root
        r.update_idletasks()
        w, h = r.winfo_reqwidth(), r.winfo_reqheight()
        x, y = r.winfo_x(), r.winfo_y()
        nx = max(0, min(x, self.sw - w))
        ny = max(0, min(y, self.sh - h))
        if (nx, ny) != (x, y):
            r.geometry(f"+{nx}+{ny}")

    # ---------- colonna di pallini ----------
    DOCK = (("⌨", "apri"), ("✕", "chiudi"), ("♻", "pulizia"), ("⚡", "boost"), (">_", "term"))
    S, G = 48, 10   # diametro pallino, spazio tra pallini

    def toggle_mini(self):
        """— (o Auto-riduci) riduce TouchPad a una colonna di pallini sul lato dello schermo.
        Pallino ⌨: torna dov'era. Gli altri: chiudi finestra, pulizia, boost, terminale."""
        self.mini = not self.mini
        self.cfg["mini"] = self.mini
        if self.mini:
            self.save()  # posizione e pagina da ritrovare alla riapertura
            self._stop_rep()
            self.root.withdraw()
            self.mk.withdraw()
            self._show_bubble()
        else:
            for b, *_ in self.dock:
                b.withdraw()
            self.root.deiconify()
            self.root.geometry(self.cfg.get("geo", ""))
            self.root.attributes("-topmost", True)
            self.root.lift()
            self.mk.deiconify()
            self._place()
            self.last_touch = time.time()
            self.root.after_idle(self._clamp)

    def _dock_xy(self):
        S, G, n = self.S, self.G, len(self.DOCK)
        x, y = self.cfg.get("bubble", (self.sw - S - 6, 40))
        x = max(0, min(x, self.sw - S))
        y = max(0, min(y, self.sh - n * (S + G)))
        return x, y

    def _place_dock(self, x, y):
        for i, (b, *_) in enumerate(self.dock):
            b.geometry(f"{self.S}x{self.S}+{x}+{y + i * (self.S + self.G)}")

    def _show_bubble(self):
        S = self.S
        if not self.dock:
            for sym, act in self.DOCK:
                b = tk.Toplevel(self.root)
                b.title("tp-bubble")
                b.overrideredirect(True)
                b.attributes("-topmost", True)
                cv = tk.Canvas(b, width=S, height=S, highlightthickness=0, bd=0)
                cv.pack()
                cv.bind("<ButtonPress-1>", self._b_down)
                cv.bind("<B1-Motion>", self._b_move)
                cv.bind("<ButtonRelease-1>", lambda e, a=act: self._b_up(e, a))
                self.dock.append((b, cv, sym, act))
            self.bubble = self.dock[0][0]
        for i, (b, cv, sym, act) in enumerate(self.dock):
            cv.delete("all")
            cv.config(bg=self.T("bg"))
            fill = self.T("acc") if act == "apri" else self.T("key")
            cv.create_oval(1, 1, S - 2, S - 2, fill=fill, outline=self.T("fg"), width=2)
            cv.create_text(S // 2, S // 2, text=sym, fill="white" if act == "apri" else self.T("fg"),
                           font=("DejaVu Sans", 16 if len(sym) == 1 else 12, "bold"))
        self._place_dock(*self._dock_xy())
        for b, *_ in self.dock:
            b.deiconify()
            b.lift()
            if self.trasp:
                b.attributes("-alpha", max(0.6, self.cfg["alpha"]))
        self.root.update_idletasks()
        for b, *_ in self.dock:
            self._round(b, S)

    def _round(self, win, S):
        """Ritaglia la finestra a cerchio (estensione SHAPE di X11), se c'e'."""
        try:
            from Xlib.ext import shape
            d = self.x.d
            if not d.has_extension("SHAPE"):
                return
            inner = d.create_resource_object("window", win.winfo_id())
            wins = [inner, inner.query_tree().parent]  # finestra Tk + suo contenitore
            pm = inner.create_pixmap(S, S, 1)
            gc = pm.create_gc(foreground=0, background=0)
            pm.fill_rectangle(gc, 0, 0, S, S)
            gc.change(foreground=1)
            pm.fill_arc(gc, 0, 0, S, S, 0, 360 * 64)
            for w in wins:
                if w and w.id != d.screen().root.id:
                    w.shape_mask(shape.SO.Set, shape.SK.Bounding, 0, 0, pm)
            gc.free()
            pm.free()
            d.sync()
        except Exception as ex:  # resta quadrato: funziona lo stesso
            print("pallino rotondo non disponibile:", ex, file=sys.stderr)

    def _b_down(self, e):
        self._bx, self._by = e.x_root, e.y_root
        self._bo = (self.bubble.winfo_x(), self.bubble.winfo_y())
        self._bmoved = 0

    def _b_move(self, e):
        dx, dy = e.x_root - self._bx, e.y_root - self._by
        self._bmoved = max(self._bmoved, abs(dx) + abs(dy))
        if self._bmoved > 8:  # trascinando un pallino si sposta tutta la colonna
            self._place_dock(self._bo[0] + dx, self._bo[1] + dy)

    def _b_up(self, e, act):
        if self._bmoved <= 8:  # tocco
            {"apri": self.toggle_mini, "chiudi": self.chiudi_finestra,
             "pulizia": self.pulizia_rapida, "boost": lambda: self._in_terminale("runnerboost"),
             "term": lambda: self._in_terminale(None)}[act]()
            return
        S, n = self.S, len(self.DOCK)  # trascinata: si aggancia al lato piu' vicino
        x = 6 if self.bubble.winfo_x() + S // 2 < self.sw // 2 else self.sw - S - 6
        y = max(6, min(self.bubble.winfo_y(), self.sh - n * (S + self.G)))
        self._place_dock(x, y)
        self.cfg["bubble"] = (x, y)
        self.save()

    # ---------- azioni dei pallini ----------
    def _toast(self, testo, secondi=4):
        """Messaggio breve accanto alla colonna di pallini."""
        t = tk.Toplevel(self.root)
        t.overrideredirect(True)
        t.attributes("-topmost", True)
        tk.Label(t, text=testo, bg=self.T("key"), fg=self.T("fg"), padx=10, pady=6,
                 font=("DejaVu Sans", 10, "bold"), justify="left").pack()
        t.update_idletasks()
        w = t.winfo_reqwidth()
        bx, by = (self.bubble.winfo_x(), self.bubble.winfo_y()) if self.bubble else (self.sw - 60, 40)
        x = bx - w - 8 if bx > self.sw // 2 else bx + self.S + 8
        t.geometry(f"+{max(0, x)}+{by}")
        t.after(secondi * 1000, t.destroy)
        return t

    def chiudi_finestra(self):
        """✕: tocca una finestra e si chiude (gentilmente). Se non risponde: ✕ di nuovo = forza."""
        f = self._da_forzare
        if f and time.time() - f[1] < 15:
            self._da_forzare = None
            try:
                self.x.d.kill_client(f[0])
                self.x.d.sync()
                self._toast("Chiusura forzata ✔")
            except Exception:
                self._toast("Già chiusa")
            return
        if not shutil.which("xdotool"):
            self._toast("Serve xdotool: rilancia l'installatore")
            return
        self._toast("Tocca la finestra da chiudere", 5)
        self._sel = subprocess.Popen(["xdotool", "selectwindow"], stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, text=True)
        self.root.after(200, self._chiudi_attendi)

    def _chiudi_attendi(self):
        if self._sel.poll() is None:
            self.root.after(200, self._chiudi_attendi)
            return
        try:
            wid = int((self._sel.stdout.read() or "0").strip() or 0)
        except ValueError:
            wid = 0
        mie = {int(w.wm_frame(), 16) for w in [self.root, self.mk] + [b for b, *_ in self.dock]}
        if not wid or wid in mie:
            return
        from Xlib.protocol import event
        d = self.x.d
        w = d.create_resource_object("window", wid)
        if self._protetta(w):
            self._toast("Quella è il desktop o la barra:\nnon la chiudo")
            return
        try:
            ev = event.ClientMessage(window=w, client_type=d.intern_atom("WM_PROTOCOLS"),
                                     data=(32, [d.intern_atom("WM_DELETE_WINDOW"), X.CurrentTime, 0, 0, 0]))
            w.send_event(ev, event_mask=0)
            d.sync()
        except Exception:
            return
        self.root.after(5000, lambda: self._chiudi_verifica(wid))

    def _protetta(self, w):
        """Desktop (icone), barra delle applicazioni, sfondo: non si chiudono mai con ✕."""
        d = self.x.d
        try:
            if w.id == d.screen().root.id:
                return True
            tipi = w.get_full_property(d.intern_atom("_NET_WM_WINDOW_TYPE"), X.AnyPropertyType)
            nomi = {d.get_atom_name(a) for a in (tipi.value if tipi else [])}
            if nomi & {"_NET_WM_WINDOW_TYPE_DESKTOP", "_NET_WM_WINDOW_TYPE_DOCK"}:
                return True
            cls = w.get_wm_class() or ("", "")
            testo = " ".join(cls).lower()
            if any(k in testo for k in ("pcmanfm", "panel", "desktop", "xfdesktop", "tint2", "plank", "lxqt-panel")):
                return True
        except Exception:
            return True  # nel dubbio non chiudo
        return False

    def _chiudi_verifica(self, wid):
        try:
            self.x.d.create_resource_object("window", wid).get_attributes()
            self.x.d.sync()
        except Exception:
            return  # chiusa
        self._da_forzare = (wid, time.time())
        self._toast("Non risponde: tocca ✕ entro 15 s\nper forzare la chiusura", 6)

    def pulizia_rapida(self):
        """♻: pulizia sicura in sottofondo (solo cache, cestino, log vecchi...)."""
        if not shutil.which("pulizia"):
            self._toast("Pulizia non installata: rilancia l'installatore")
            return
        self._toast("Pulizia sicura in corso...", 3)
        self._pul = subprocess.Popen(["pulizia", "--sicura"], stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, text=True)
        self.root.after(500, self._pulizia_attendi)

    def _pulizia_attendi(self):
        if self._pul.poll() is None:
            self.root.after(500, self._pulizia_attendi)
            return
        out = self._pul.stdout.read() or ""
        riga = next((r for r in out.splitlines() if "Liberati" in r), "Pulizia fatta")
        self._toast(riga.strip("= ").replace(". ", "\n"), 6)

    def _in_terminale(self, comando):
        """Apre un terminale; con un comando lo esegue e aspetta Invio prima di chiudersi."""
        for t in ("x-terminal-emulator", "xterm", "lxterminal", "qterminal", "xfce4-terminal"):
            if shutil.which(t):
                break
        else:
            self._toast("Nessun terminale trovato")
            return
        cmd = [t]
        if comando:
            cmd += ["-e", "bash", "-c", f"{comando}; echo; read -p 'Invio per chiudere ' x"]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)

    # ---------- una sola istanza ----------
    def _server(self):
        """Ascolta: se rilanci touchpad mentre e' aperto, si riapre invece di duplicarsi."""
        try:
            if os.path.exists(SOCK):
                os.unlink(SOCK)
            s = self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.bind(SOCK)
            s.listen(2)
            self.root.tk.createfilehandler(s, tk.READABLE, self._on_sock)
        except Exception:
            self.sock = None

    def _on_sock(self, *_):
        try:
            c, _ = self.sock.accept()
            msg = c.recv(16)
            c.close()
        except OSError:
            return
        if msg != b"show":
            return
        if self.mini:
            self.toggle_mini()
        else:
            self.root.lift()
            self.mk.lift()

    def say(self, t):
        self.status.config(text=t)

    def save(self):
        if not self.mini and self.root.winfo_viewable():
            self.cfg["geo"] = f"+{self.root.winfo_x()}+{self.root.winfo_y()}"
        try:
            os.makedirs(os.path.dirname(CFG), exist_ok=True)
            with open(CFG, "w") as f:
                json.dump(self.cfg, f)
        except Exception:
            pass

    def quit(self):
        if self.lock:
            self.x.swap(False)
        if not self.mini:
            self.save()
        try:
            if self.sock:
                self.root.tk.deletefilehandler(self.sock)
                self.sock.close()
                os.unlink(SOCK)
        except Exception:
            pass
        self.root.destroy()


if __name__ == "__main__":
    App().root.mainloop()
