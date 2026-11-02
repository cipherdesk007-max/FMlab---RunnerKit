"""Test del motore X11 di TouchPad (tasti, accenti, clic, scambio tasti).
Gira senza grafica Tk: serve solo un display X (es. Xvfb).
    xvfb-run python3 tests/test_x11.py
"""
import os
import sys
import time
import types

sys.modules.setdefault("tkinter", types.ModuleType("tkinter"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "touchpad"))
from touchpad import X11  # noqa: E402
from Xlib import X, display  # noqa: E402


def main():
    lis = display.Display()
    s = lis.screen()
    w = s.root.create_window(0, 0, 300, 300, 0, s.root_depth,
                             event_mask=X.KeyPressMask | X.ButtonPressMask)
    w.map()
    lis.sync()
    time.sleep(0.3)
    w.set_input_focus(X.RevertToParent, X.CurrentTime)
    lis.sync()

    x = X11()
    for k in ["a", "A", "à", "è", "€", "!", "Return", "BackSpace"]:
        x.key(k)
    x.key("c", ["Control_L"])
    x.move(50, 50)
    x.click(1)
    x.click(3)
    x.swap(True)
    assert list(x.d.get_pointer_mapping()[:3]) == [3, 2, 1], "scambio tasti fallito"
    x.swap(False)
    assert list(x.d.get_pointer_mapping()[:3]) == [1, 2, 3], "ripristino tasti fallito"

    for ks, kc in x.assigned.items():  # à è € assegnati a keycode liberi
        assert x.d.get_keyboard_mapping(kc, 1)[0][0] == ks, f"accento {hex(ks)} non mappato"

    time.sleep(0.3)
    keys, buttons = 0, []
    while lis.pending_events():
        e = lis.next_event()
        if e.type == X.KeyPress:
            keys += 1
        elif e.type == X.ButtonPress:
            buttons.append(e.detail)
    assert buttons == [1, 3], f"clic ricevuti: {buttons}"
    assert keys >= 9, f"tasti ricevuti: {keys}"
    print(f"OK x11: {keys} tasti, clic {buttons}, accenti {len(x.assigned)}")


if __name__ == "__main__":
    main()
