# CatKey — Design

## Intent
A cat walking across the keyboard shouldn't be able to type, shut down, or sleep the machine.
CatKey is an AutoHotkey v2 script that locks the keyboard (and the power/sleep buttons) after a
period of no input, like a screensaver, and unlocks on a mouse double-click.

## Goals
- Lock automatically after `IdleTimeoutMin` minutes with no physical keyboard/mouse input.
- While locked: every key is swallowed; every monitor is dimmed with "CatKey locked"; single clicks do nothing.
- Double-click anywhere unlocks; idle timer starts over.
- While locked, the physical power and sleep buttons do nothing; original actions restored on unlock.

## Non-goals
- Configurable timeout at runtime (no INI, no settings dialog) — the timeout is a hardcoded constant.
- Blocking things Windows reserves: Ctrl+Alt+Del (kept as the emergency exit), Win+L (harmless),
  the ~4 s hardware power-button hold (forced power-off, can't be stopped in software).
- Guarding against a cat double-clicking.
- Lid close action (not requested).

## Anti-goals
- Leaving the power button stuck on "Do nothing" after a crash/kill without self-repair.
- Blocking the mouse (would make unlock impossible).
- Clicks leaking through the overlay to the desktop while locked.

## Constraints
- AutoHotkey v2 (v2.0.23 installed). Single file `CatKey.ahk`, no external libraries.
- Runs without admin. Verified: `powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION …`
  + `powercfg /setactive SCHEME_CURRENT` succeeds unelevated on this machine.
- This machine is a laptop with Modern Standby (S0). The button settings are hidden in the UI
  (`powercfg /qh` shows them). Current values: PBUTTONACTION AC=2 (Hibernate) DC=1 (Sleep);
  SBUTTONACTION AC=1 DC=1. Both AC and DC values must be saved and restored.

## Approaches considered
**Keyboard blocking**
- **A. `InputHook` suppressing `{All}` keys (chosen).** Start on lock, stop on unlock; minimal code; mouse untouched.
- B. A `*scXXX` blocking hotkey for every scan code, gated by `#HotIf locked`. Works equally well; more code.
- Rejected: `BlockInput` — also freezes the mouse, so double-click unlock would be impossible.

**Overlay**
- **A. Plain AHK GUIs (chosen).** Originally two per monitor (invisible click-catcher + transparent-color
  glyph window). The user then simplified it to **one window per monitor**: a dim tint with centered
  text, whole window at one alpha via `WinSetTransparent`. It receives clicks because alpha > 0.
- B. One GDI+ layered window per monitor (per-pixel alpha). Softer edges, much more code. Rejected.

Choice made by the user: 1A + 2A, then simplified to the single tinted window.

## Behavior (decided)
- **Idle detection:** `SetTimer` every 1 s checks `A_TimeIdlePhysical` (keyboard and mouse hooks
  installed so injected input doesn't count). When ≥ `IdleTimeoutMin * 60000` and not locked → lock.
- **Lock:**
  1. Save current AC/DC values of PBUTTONACTION and SBUTTONACTION, set all four to 0 (Do nothing), `/setactive`.
  2. Start the suppressing InputHook.
  3. Show the overlay on every monitor (`MonitorGetCount` / `MonitorGet`, full monitor bounds incl. taskbar).
- **Overlay look:** one borderless, always-on-top, tool window per monitor covering the full monitor,
  black background dimmed to ~30% opacity (`WinSetTransparent` ≈ 77), desktop visible underneath.
  Large white text **"CatKey locked"** centered (it fades with the tint, which is fine).
- **Unlock:** double-click anywhere (two left clicks within `GetDoubleClickTime()` on any overlay
  window) → destroy overlay, stop InputHook, restore saved button actions, resume idle timing.
- **Crash safety:** saved button values are also written to a small state file next to the script
  while locked; deleted on restore. On startup, if the file exists, restore from it first.
  `OnExit` also restores if locked.
- **Keyboard Sleep/Power keys:** swallowed by the InputHook where Windows reports them as keys.
- **Tray menu (my call):** Lock now, Pause CatKey (disables the idle trigger), Exit. Hardcoded
  `IdleTimeoutMin := 5` at the top of the script.

## Left to the builder
- Exact font size and tint opacity (text must stay readable through the tint).
- Re-checking monitor layout on each lock (so docking/undocking is handled) — recommended.
- State file name/format (e.g. `CatKey.state` as an INI).
- Ensuring the overlay stays topmost over fullscreen/always-on-top windows (re-assert on a timer if needed).
