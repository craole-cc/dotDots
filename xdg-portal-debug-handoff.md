# Context: Fixing xdg-desktop-portal OpenURI on NixOS/Hyprland via runtime script only (no rebuild)

## Constraints (read first)

- **I cannot run `nixos-rebuild` right now.** Any fix must be achievable at runtime — shell
  commands, files written to `$HOME`, `systemctl --user` actions, symlinks, env exports — not
  changes to the NixOS module/flake configuration itself.
- I have a large POSIX-shell bootstrap script (`profile`, ~2300 lines, pasted in full below /
  attached) that I source manually after every reboot (`. profile all` or subcommands like
  `. profile darkman` / `. profile portals`). It already does a lot of this setup. **My goal is
  to get everything working end-to-end through this script alone** — i.e. the fix should take
  the form of edits to this script (new functions, fixed logic in existing functions like
  `setup_portals` / `setup_darkman`), not a one-off shell incantation I'll forget.
- Rebuilding the NixOS config is out of scope for this session, even though some of what we've
  found may ultimately "should" be a `programs.dconf.enable = true;`-style config fix. I'm aware
  of that; I want the runtime workaround for now.
- Host: `Victus`, hostname `Victus`, NixOS, Hyprland (compositor), Wayland session.
- Shell: bash with `ble.sh` (blesh) loaded interactively.

## Goal

Get `xdg-open <url>` (and by extension Zed's "open this URL to sign in" browser launch) working
again, driven entirely by re-running the attached `profile` script after each reboot — no manual
`export`/`systemctl` incantations needed afterward.

Two related but distinct things need to work:

1. `xdg-open` successfully opens URLs (currently fails with a DBus `OpenURI` error).
2. Darkman's light/dark GTK theme switching continues to work (it does right now, separately from the URL-opening issue).

## Symptom timeline

- It was working. I made some manual `systemctl --user` calls and/or manually edited some config
  files by hand (via `hx`, my editor) at some point before today. I do not have a clean list of
  every manual change, but I do have (see below) the current contents of the files I edited.
- Today: `xdg-open` fails, and Zed (an editor) can't open a browser for OAuth sign-in as a result,
  since it presumably shells out to `xdg-open` or calls the portal directly.
- Explicitly ruled out: this is **not** a `$BROWSER` env var problem. `$BROWSER=zen-twilight` was
  set, but unsetting it did **not** fix anything (I confirmed both with it set and unset, error is
  identical) — and I did not set `$BROWSER` differently yesterday, so it's not the regression
  cause. Please don't relitigate this.

## What we've established so far, in the order we found it

### 1. The direct error

```
❯ xdg-open https://example.com
Error: GDBus.Error:org.freedesktop.DBus.Error.UnknownMethod: No such interface
"org.freedesktop.portal.OpenURI" on object at path /org/freedesktop/portal/desktop
```

This is a well-known class of bug — see e.g.
https://discourse.nixos.org/t/xdg-portals-all-broken/48308 (long thread, many people hit variants
of this on NixOS + Hyprland/sway, several partial fixes suggested: `programs.dconf.enable`,
`xdgOpenUsePortal`, `systemctl --user import-environment PATH`, `withUWSM = true` for hyprland,
none of which are guaranteed and several people never fully solved it in that thread).

### 2. Versions / packages involved (found via `/nix/store` inspection, NOT necessarily what's

currently active/linked — my `nix profile list`, GC state, and generation may differ from
these being "live")

- `xdg-desktop-portal` **1.20.3** — main daemon. Systemd unit `xdg-desktop-portal.service`
  confirmed `active (running)`, PID stable.
- `xdg-desktop-portal-hyprland` — multiple versions present in store (1.3.11, 1.3.12, 1.4.1).
  Backend confirmed running via `busctl --user list` with a live PID.
- `xdg-desktop-portal-gtk` **1.15.3** — multiple store paths (at least 3 different hashes for the
  same version, from different derivations: home-manager-path, system-path, standalone). Only
  shows as `(activatable)` in `busctl --user list` (i.e., **not actually running**, dbus would
  need to auto-spawn it on demand). We manually launched one of these paths directly
  (`/nix/store/.../libexec/xdg-desktop-portal-gtk &`) and confirmed it starts and gets a PID, but
  **this did not fix the OpenURI error**.
- `darkman` **2.2.0** — running fine (`systemctl --user status darkman.service` shows
  `active (running)`), it's a genuinely separate concern from the OpenURI issue except that it
  logs `gtk-theme.sh: No schemas installed` as a warning (this points at the same root cause as
  finding #4 below, but darkman itself is functioning: it _does_ run the light/dark hook scripts,
  just with a schema warning in the log).

### 3. Interfaces actually implemented by each portal backend (checked directly via the `.portal`

files, which declare `Interfaces=` — this is the ground truth for what DBus will route where)

`hyprland.portal` (`xdg-desktop-portal-hyprland-1.3.12`):

```ini
[portal]
DBusName=org.freedesktop.impl.portal.desktop.hyprland
Interfaces=org.freedesktop.impl.portal.Screenshot;org.freedesktop.impl.portal.ScreenCast;org.freedesktop.impl.portal.GlobalShortcuts;
UseIn=wlroots;Hyprland;sway;Wayfire;river;
```

**No OpenURI.** Expected — hyprland's backend never implemented OpenURI.

`gtk.portal` (`xdg-desktop-portal-gtk-1.15.3`, checked one of the several store copies):

```ini
[portal]
DBusName=org.freedesktop.impl.portal.desktop.gtk
Interfaces=org.freedesktop.impl.portal.FileChooser;org.freedesktop.impl.portal.AppChooser;org.freedesktop.impl.portal.Print;org.freedesktop.impl.portal.Notification;org.freedesktop.impl.portal.Inhibit;org.freedesktop.impl.portal.Access;org.freedesktop.impl.portal.Account;org.freedesktop.impl.portal.Email;org.freedesktop.impl.portal.DynamicLauncher;org.freedesktop.impl.portal.Lockdown;org.freedesktop.impl.portal.Settings;org.freedesktop.impl.portal.Wallpaper;
UseIn=gnome
```

**Also no OpenURI**, which surprised us — gtk's backend has historically been the canonical
OpenURI implementer (confirmed by multiple web sources, e.g. an Arch forum thread saying
"xdg-desktop-portal-gtk (implements many things for GTK, including OpenURI)"). Either:
(a) this specific 1.15.3 build genuinely doesn't advertise OpenURI in its `.portal` file even
though the binary might support it (possible packaging quirk), or
(b) OpenURI moved into the _core_ `xdg-desktop-portal` daemon itself in some version ≥1.18
(there is a changelog entry: "1.18.2 — Pass the token to the OpenURI portal..." implying
OpenURI is core-daemon logic, not backend-provided, in that version line) and we haven't
correctly verified whether 1.20.3's core daemon exposes it.

- We tried to check directly:
  ```
  busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
    org.freedesktop.DBus.Introspectable Introspect | grep -A2 OpenURI
  ```
  This returned **nothing** (exit 1) — i.e. `OpenURI` doesn't appear anywhere in the
  introspection of the main portal object, meaning **the core daemon itself is not exposing an
  OpenURI interface either**, regardless of which backend is "supposed" to implement it. This
  is the crux of the unresolved problem. This needs deeper investigation — a stronger model
  should look at the actual xdg-desktop-portal 1.20.x source/release notes to determine
  (a) whether the outward-facing `org.freedesktop.portal.OpenURI` is core-daemon-provided in
  1.20.x, and if so, why it's not registering, or (b) whether it still requires a backend
  implementation and if so which backend/package actually ships one for a Hyprland/wlroots
  (non-GNOME) session on Nix.

### 4. GSettings/dconf schema system was fully broken, partially fixed at runtime

Found via:

```
❯ gsettings list-schemas | grep -i notification
No schemas installed
```

This matches darkman's own log line (`gtk-theme.sh: No schemas installed`) and is a known
Nix-specific gotcha: compiled GSettings schema indexes live inside individual package store
paths, and nothing puts them on `XDG_DATA_DIRS` automatically outside a full GNOME session /
without `programs.dconf.enable = true;` at the NixOS module level.

We found the compiled schema file exists, but at a nested/non-standard path relative to what
`gsettings`'s lookup convention expects:

```
/nix/store/xsfc5fcy12nmcdsdwm3dx1xfffh7xv30-gsettings-desktop-schemas-49.1/share/gsettings-schemas/gsettings-desktop-schemas-49.1/glib-2.0/schemas/gschemas.compiled
```

Normal convention is `$XDG_DATA_DIRS_ENTRY/glib-2.0/schemas/gschemas.compiled` — i.e. a plain
`share/glib-2.0/schemas/gschemas.compiled` directly, with NO extra `gsettings-schemas/<pkgname>/`
nesting in between. This package's `share/` puts an extra `gsettings-schemas/gsettings-desktop-schemas-49.1/`
layer before the conventional `glib-2.0/schemas/` layer.

**Runtime fix that worked for schema lookup** (confirmed just now, this session):

```sh
export XDG_DATA_DIRS="/nix/store/xsfc5fcy12nmcdsdwm3dx1xfffh7xv30-gsettings-desktop-schemas-49.1/share/gsettings-schemas/gsettings-desktop-schemas-49.1:${XDG_DATA_DIRS}"
gsettings list-schemas | grep -i notification
# => org.gnome.desktop.notifications   (previously: "No schemas installed")
```

This resolved schema lookups successfully. However:

```sh
systemctl --user import-environment XDG_DATA_DIRS
dbus-update-activation-environment --systemd XDG_DATA_DIRS
systemctl --user restart xdg-desktop-portal-gtk.service xdg-desktop-portal.service
xdg-open https://example.com
# => still: Error: ... No such interface "org.freedesktop.portal.OpenURI" ...
```

**So the schema fix, while real and worth keeping/automating, did NOT fix OpenURI.** This
confirms OpenURI's absence is NOT (solely, or at all) a GSettings-schema problem — it's a portal
interface registration problem independent of dconf/gsettings. The schema fix is still valuable
to bake into the script for darkman's own sake (removes its log warning, and any other
gsettings-dependent behavior we might rely on later, e.g. GTK dark/light theme correctness for
non-Nix-aware apps).

Also note: `glib-compile-schemas` is **not on PATH** at all in my current shell (`command not
found`), which may matter if the fix path involves compiling a local schema override directory
under `~/.local/share/glib-2.0/schemas/`.

### 5. Systemd unit inventory

```
❯ systemctl --user list-unit-files | grep -i portal
xdg-desktop-portal-gtk.service                    linked-runtime ignored
xdg-desktop-portal-hyprland.service               linked-runtime ignored
xdg-desktop-portal-rewrite-launchers.service      linked-runtime ignored
xdg-desktop-portal.service                        linked-runtime ignored
xdg-document-portal.service                       linked-runtime ignored
```

All show `linked-runtime` (home-manager/Nix-managed symlinked units, not classic
`/etc/systemd/user/*`) and preset column `ignored` (systemd isn't applying enable/disable preset
policy to them — this is normal for Nix-managed units, not itself a red flag, but noting it in
case it's relevant).

There is **no separate persistent state** suggesting any of these units are masked, failed, or
disabled — they all restart cleanly and show `active (running)` after restart, they just don't
collectively produce a working `OpenURI` interface.

### 6. Files I manually created/edited before this broke (from shell history, `hx` = my editor)

```
9707  hx ~/.config/xdg-desktop-portal/portals.conf
9721  hx ~/.config/systemd/user/primary-to-clipboard.service
9726  hx ~/.config/environment.d/xdg-data-dirs.conf
9767  hx ~/.local/share/dark-mode.d/gtk-theme.sh
9769  hx ~/.local/share/light-mode.d/gtk-theme.sh
9776  hx ~/.local/share/dark-mode.d/gtk-theme.sh
9778  hx ~/.local/share/light-mode.d/gtk-theme.sh
```

Current contents of the relevant ones:

`~/.config/xdg-desktop-portal/portals.conf`:

```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.OpenURI=gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.Settings=darkman
```

(Note: this explicitly routes `OpenURI` to `gtk`, but per finding #3, gtk's own `.portal` file
doesn't declare it implements `OpenURI` at all — so even a perfectly running gtk backend can
never satisfy this routing. This config line may itself be wrong/stale for the installed
package version, or the mapping convention may have changed since I wrote it.)

`~/.config/environment.d/xdg-data-dirs.conf`:

```
XDG_DATA_DIRS=${HOME}/.local/share:${XDG_DATA_DIRS}
```

(This only prepends the user's own `.local/share`, which does nothing for Nix-store-provided
gsettings schemas — see finding #4. This is very likely the actual regression: whatever used to
correctly populate `XDG_DATA_DIRS` with the Nix store schema paths was probably overwritten or
narrowed by this manual file, OR this file was written in addition to some other now-missing
mechanism, and this alone was never sufficient — I did something else that also broke, or the
"something else" was never a `environment.d` file to begin with and lived somewhere I haven't
found yet, e.g. a session-manager/greeter env import that's since stopped running.)

`~/.local/share/dark-mode.d/gtk-theme.sh` / `light-mode.d/gtk-theme.sh` — darkman hook scripts,
functioning correctly already (content matches what my `profile` script's `setup_darkman`
function would generate — see below).

`~/.config/systemd/user/primary-to-clipboard.service` — unrelated to this issue as far as I
know, included for completeness in case it matters (clipboard-related unit, not portal-related).

### 7. My `profile` script's existing relevant functions (already source-available, will attach in full)

- `setup_portals()` — detects compositor (`hyprland`/`niri`/`mango`/`cosmic`), restarts the
  compositor-specific backend service + `xdg-desktop-portal.service` via systemd if `dbus` is
  active, else falls back to manually `exec`-ing the backend binary and the main portal binary
  found via `find -L "$NIX_PROFILE_DIR" -name ...`. **Never touches `xdg-desktop-portal-gtk` at
  all** — this is a known gap we identified: since `portals.conf` routes several interfaces
  (OpenURI, FileChooser) to `gtk`, and `setup_portals` never starts/restarts gtk's backend, gtk
  only ever comes up via dbus auto-activation-on-demand, which we've now confirmed doesn't
  reliably happen or doesn't help even when it does.
- `setup_darkman()` — writes `portals.conf` (matching what's on disk now, so no drift there),
  writes the two `gtk-theme.sh` hook scripts, runs `dbus-update-activation-environment` for
  session vars, and does `systemctl --user enable/restart darkman.service`. Doesn't touch
  `XDG_DATA_DIRS`/gsettings schemas at all currently.
- `NIX_PROFILE_DIR` is resolved via a function called `find_nix_profile_dir` (not yet inspected
  in this session, worth double-checking — earlier in troubleshooting `echo "$NIX_PROFILE_DIR"`
  printed empty in an interactive shell, which broke the `find -L "$NIX_PROFILE_DIR" ...`
  fallback path inside `setup_portals`; need to confirm whether `configure()` (which sets it) had
  actually run in that shell or whether `find_nix_profile_dir` itself is failing to resolve
  anything on this machine right now).
- `XDG_DATA_DIRS` is initialized once in `configure()` as:
  `XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"` — i.e. it only sets a fallback
  if unset, and never adds any Nix-store gsettings-schema paths. This is a second, independent
  confirmation of finding #4's likely root cause: nothing in the script (and nothing outside it,
  apparently, on my current login) puts compiled GSettings schemas anywhere `gsettings`/GTK will
  find them.

## What I need from you (stronger model)

1. **Diagnose definitively why `org.freedesktop.portal.OpenURI` is absent from
   `org.freedesktop.portal.Desktop`'s introspection on `xdg-desktop-portal 1.20.3`**, given:
   - hyprland backend doesn't implement it (expected/normal)
   - gtk backend's `.portal` file doesn't list it either (needs explanation — packaging bug?
     wrong file inspected? version where this interface moved into core but isn't registering
     for another reason, e.g. missing a build flag/dependency, or needing `UseIn=` to include the
     current `XDG_CURRENT_DESKTOP` value?)
   - Look specifically at whether `UseIn=gnome` in the gtk `.portal` file matters here — my
     `XDG_CURRENT_DESKTOP` is set to `Hyprland` (per `setup_portals`'s compositor mapping), not
     `gnome`, and portal backend selection can depend on `UseIn` matching `XDG_CURRENT_DESKTOP`
     (colon or semicolon separated list, case sensitivity unclear) rather than only on
     `portals.conf`'s `[preferred]` routing. If `UseIn=gnome` excludes it from ever being
     considered under a Hyprland session regardless of `portals.conf`, that would fully explain
     the failure and point at the real fix: either add `Hyprland`/`hyprland` to that file's
     `UseIn=` locally (runtime file edit, no rebuild), or find a different, already-installed
     backend package whose `.portal` file both implements OpenURI AND lists a compatible `UseIn=`.
2. **Give me the exact runtime-only fix** — files to write/edit under `$HOME` (I can edit
   `.portal` files under `$HOME`-writable locations if such an override mechanism exists per
   `xdg-desktop-portal` docs — need confirmation of whether `.portal` files are look-up-able from
   a user XDG data dir override, not just the immutable Nix store, and if so which directory to
   place a corrected copy under), env vars to export, services to restart, in the exact order
   needed for a fresh session with zero manual state.
3. **Turn that fix into concrete shell functions I can paste into my `profile` script**, following
   its existing conventions (POSIX `sh`, not bash-only syntax; existing `print --info/--success/--warn`
   logging helper already defined; `join_path` helper already defined for path building; functions
   named/dispatched the same way `setup_portals`/`setup_darkman` are, wired into the existing
   `execute()`/`run()` case dispatch and `show_info` command list if a new command is warranted).
   Specifically I'd like:
   - A fix (or confirmation the existing `setup_darkman`-written `portals.conf` is already
     correct) for whatever the real OpenURI routing/UseIn problem turns out to be.
   - A new or modified function that correctly exports `XDG_DATA_DIRS` to include
     Nix-store-resolved gsettings schema paths (ideally resolved dynamically, e.g. via
     `nix eval`/`nix profile list`/`find`, not a hardcoded store hash that will break on the next
     package update/GC), and propagates it via both `systemctl --user import-environment` and
     `dbus-update-activation-environment` so freshly-activated services see it too.
   - Confirmation of whether `setup_portals` should be modified to also manage
     `xdg-desktop-portal-gtk.service` explicitly (start/restart it, not just rely on dbus
     auto-activation), given we've observed dbus activation not reliably bringing it up as
     needed.
4. If, after your analysis, the true fix genuinely **requires** a NixOS module-level change
   (e.g. `programs.dconf.enable = true;`) with **no possible full runtime workaround**, tell me
   plainly which specific piece of functionality would remain broken/degraded without it (e.g.
   "schemas will keep needing manual XDG_DATA_DIRS injection every boot, but OpenURI itself can
   still be fixed at runtime via X" or the reverse) — don't blur this distinction, I want to know
   exactly what the ceiling of the runtime-only approach is.

## What NOT to do

- Don't re-suggest checking/unsetting `$BROWSER` — already ruled out.
- Don't re-suggest restarting `xdg-desktop-portal-hyprland.service` alone as if untried — it's
  been restarted multiple times already, always comes back healthy, never the bottleneck.
- Don't suggest a plain `nixos-rebuild` as "the fix" without first exhausting whether a runtime
  equivalent exists — if you determine one doesn't exist for some sub-piece, say so explicitly
  per point 4 above rather than defaulting to "just rebuild."
- Don't propose renaming existing variables or refactoring unrelated parts of the `profile`
  script — I want surgical, additive changes (new functions or minimal, explained edits to
  `setup_portals`/`setup_darkman`) that preserve the existing file's structure, comments, and
  style exactly.

## Attachments to include alongside this prompt

- The full `profile` script (referenced above; ~2300 lines, POSIX shell, sectioned with
  `# SECTION: ...` banner comments — sections relevant here: `xdg_portals.sh`
  [`setup_xdg_open`, `setup_portals`], `darkman.sh` [`setup_darkman`], `config.sh` [`configure`,
  defines `XDG_DATA_DIRS` fallback and other XDG vars], `orchestrate.sh` [command dispatch]).
- The `_envrc` file (direnv entrypoint, less relevant to this issue but included since it's part
  of the same dev environment bootstrap).
