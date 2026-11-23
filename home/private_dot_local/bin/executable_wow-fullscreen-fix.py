#!/usr/bin/env python3
"""Work around WoW starting black under GNOME when a monitor uses fractional scaling.

WoW (Proton, X11/Xwayland) shows only a black window until it is resized or moved.
This helper watches for new "World of Warcraft" windows and, a few seconds after each
appears, takes it out of fullscreen, moves it 1px from where it is, and makes it
fullscreen again. WoW stays on the monitor it opened on.

Usage: wow-fullscreen-fix.py [--parent PID] [--timeout SECONDS]
  --parent   exit when this process exits (the launcher passes Battle.net's PID)
  --timeout  exit after this many seconds (default: run until the parent exits)
"""
import argparse
import os
import sys
import time

from Xlib import X, display
from Xlib.protocol import event

WOW_TITLE = b"World of Warcraft"
SETTLE_SECONDS = 3  # let WoW finish creating its swapchain before nudging


def log(*args):
    print(time.strftime("%T"), "wow-fullscreen-fix:", *args, flush=True)


class Nudger:
    def __init__(self):
        self.d = display.Display()
        self.root = self.d.screen().root
        atom = self.d.intern_atom
        self.client_list = atom("_NET_CLIENT_LIST")
        self.wm_name = atom("_NET_WM_NAME")
        self.wm_state = atom("_NET_WM_STATE")
        self.fullscreen = atom("_NET_WM_STATE_FULLSCREEN")
        self.utf8 = atom("UTF8_STRING")

    def wow_windows(self):
        prop = self.root.get_full_property(self.client_list, X.AnyPropertyType)
        found = []
        for wid in (prop.value if prop else []):
            w = self.d.create_resource_object("window", wid)
            try:
                name = w.get_full_property(self.wm_name, self.utf8)
            except Exception:  # window vanished
                continue
            if name and name.value == WOW_TITLE:
                found.append(w)
        return found

    def set_fullscreen(self, w, on):
        ev = event.ClientMessage(window=w, client_type=self.wm_state,
                                 data=(32, [1 if on else 0, self.fullscreen, 0, 1, 0]))
        self.root.send_event(ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask)
        self.d.flush()

    def nudge(self, w):
        pos = w.translate_coords(self.root, 0, 0)  # window origin in root coordinates
        x, y = -pos.x, -pos.y
        self.set_fullscreen(w, False)
        time.sleep(0.4)
        w.configure(x=x + 1, y=y + 1)
        self.d.flush()
        time.sleep(0.4)
        self.set_fullscreen(w, True)
        self.d.flush()
        log(f"nudged {hex(w.id)} at ({x},{y})")


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--parent", type=int)
    ap.add_argument("--timeout", type=float)
    args = ap.parse_args()

    n = Nudger()
    seen = {w.id for w in n.wow_windows()}  # leave already-open windows alone
    pending = {}                            # window id -> time first seen
    deadline = time.time() + args.timeout if args.timeout else None
    log("watching for WoW windows")

    while True:
        if args.parent and not alive(args.parent):
            break
        if deadline and time.time() > deadline:
            break
        try:
            current = n.wow_windows()
        except Exception as e:  # X connection hiccup; keep going
            log("error listing windows:", e)
            time.sleep(1)
            continue
        now = time.time()
        for w in current:
            if w.id in seen:
                continue
            first = pending.setdefault(w.id, now)
            if now - first >= SETTLE_SECONDS:
                try:
                    n.nudge(w)
                except Exception as e:
                    log(f"could not nudge {hex(w.id)}:", e)
                seen.add(w.id)
                pending.pop(w.id, None)
        time.sleep(0.25)
    log("exiting")


if __name__ == "__main__":
    sys.exit(main())
