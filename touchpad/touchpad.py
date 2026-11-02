#!/usr/bin/env python3
"""TouchPad 2 - mouse + tastiera fluttuante per LinuxRunner.
Parla direttamente con X11 (XTEST): nessun processo esterno per tocco."""
__version__ = "2.0.0"

import json
import os
import tkinter as tk

from Xlib import X, XK, display
from Xlib.ext import xtest

CFG = os.path.expanduser("~/.config/touchpad.json")
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
        c.setdefault("page", "Mouse")
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
        self._alpha()
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
        g.bind("<ButtonRelease-1>", lambda e: self.save())
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
                b = self.btn(fr, k)
                b.pack(side="left", expand=True, fill="x", padx=1,
                       ipadx=50 if k == "␣" else 0)
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
                 ("Mirino ◎", self.center)]]
        b = self.grid_rows(f, rows)
        b[self.cfg["theme"]].config(bg=self.T("acc"))
        b["Dim " + self.cfg["size"]].config(bg=self.T("acc"))
        tk.Label(f, text="Le scelte restano salvate.", bg=self.T("bg"),
                 fg=self.T("dim"), font=("DejaVu Sans", max(8, self.font - 2))).pack(pady=4)

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

    # ---------- finestra ----------
    def _grab(self, e):
        self._ox = e.x_root - self.root.winfo_x()
        self._oy = e.y_root - self.root.winfo_y()

    def _drag_win(self, e):
        self.root.geometry(f"+{e.x_root - self._ox}+{e.y_root - self._oy}")

    def _alpha(self, d=0):
        a = self.cfg["alpha"] = max(0.3, min(1.0, round(self.cfg["alpha"] + d, 2)))
        for w in (self.root, self.mk):
            try:
                w.attributes("-alpha", a)
            except tk.TclError:
                pass
        if d:
            self.say(f"opacità {int(a * 100)}%")
            self.save()

    def toggle_mini(self):
        self.mini = not self.mini
        if self.mini:
            self.holder.pack_forget()
            self.status.pack_forget()
        else:
            self.holder.pack(fill="both", padx=5, pady=(0, 5))
            self.status.pack(fill="x")

    def say(self, t):
        self.status.config(text=t)

    def save(self):
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
        self.save()
        self.root.destroy()


if __name__ == "__main__":
    App().root.mainloop()
