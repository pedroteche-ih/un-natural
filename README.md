# un-natural

A **Hexany chord-trigger instrument** for [norns](https://monome.org/docs/norns/)
+ a monome grid, with a built-in sine engine and pitch/envelope output to
**Monome Crow**.

A Hexany is Erv Wilson's 2-of-4 Combination Product Set: take four factors
(default `1·3·5·7`), multiply every pair, octave-reduce → six just-intonation
notes: `35/32, 5/4, 21/16, 3/2, 7/4, 15/8`. You pick up to three of them and
strike the chord with a one-shot AR envelope chosen from an 8×8 pad.

## Install

Copy the `un-natural/` folder to `~/dust/code/` on your norns. Because it ships a
SuperCollider engine, run `;restart` in maiden once (to compile it), then select
`un-natural` in SELECT / maiden.

## Grid (8 rows × 16 cols)

```
col  1     2 3 4 5 6 7 8 9        10..16
     ┌──┐ ┌─────────────────┐
     │N6│ │                 │     (unused)
     │N5│ │   ENVELOPE PAD  │
     │N4│ │   X = attack →  │
     │N3│ │   Y = release ↑ │
     │N2│ │                 │
     │N1│ │                 │
     │O+│ │                 │
     │O-│ └─────────────────┘
     └──┘
```

- **Column 1** — note selector: rows 1–6 are the six hexany notes (bottom =
  lowest); row 7 = octave up, row 8 = octave down. Select up to **three** notes;
  a 4th press drops the oldest, and pressing a selected note deselects it.
  Selecting is silent — it just arms the chord and sets the Crow pitch CVs.
- **Columns 2–9** — 8×8 AR-envelope pad. Left→right = attack (short→long),
  bottom→top = release (short→long). **Press a cell to trigger** the armed chord
  with that envelope (one-shot; retriggerable).
- **Columns 10–16** — unused.

## Output

Both sound at once:

- **Sine engine** — plays the selected notes as sine voices through the chosen
  AR envelope.
- **Crow** — `out1/2/3` = the three selected pitches (1V/oct, exact just
  intonation: `volts = base_volts + log2(ratio)`); `out4` = the shared AR
  envelope, fired on each trigger. Patch `out1–3 → VCO 1V/oct`, `out4 → VCA`.

## Screen & knobs

The screen shows the factor set, the six ratios (selected ones underlined), the
octave, and the last-triggered attack/release. **E1** = sine level, **E2** =
octave, **K1** = panic (clear selection / silence).

## PARAMETERS

Grouped into sections: **hexany** (four factor numbers + root Hz), **envelope**
(attack/release min–max for the pad), **crow** (root volts, envelope peak, CV
slew), **engine** (sine level). Params save/load with PSET.

## Files

- `un-natural.lua` — entry: state, selection, trigger, lifecycle.
- `lib/cps.lua` — CPS math (combinations, products, naming).
- `lib/ji.lua` — just-intonation helpers (octave-reduce, cents, ratio→volts, expmap).
- `lib/grid_ui.lua` — grid zones (note selector + envelope pad).
- `lib/crow_out.lua` — Crow output (3 pitch CVs + AR envelope).
- `lib/display.lua` — the instrument screen.
- `lib/params_setup.lua` — PARAMETERS menu.
- `lib/Engine_UnNatural.sc` — one-shot AR sine engine (run `;restart` after edits).

## Roadmap

Waveform choice beyond sine, per-note envelopes, a sustain/gated mode, velocity,
chord/envelope snapshots, MIDI.
