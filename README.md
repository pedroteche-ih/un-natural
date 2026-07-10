# un-natural

An isomorphic grid keyboard for **Erv Wilson's Combination Product Sets (CPS)**,
for [norns](https://monome.org/docs/norns/) + a monome grid, with pitch/gate
output to **Monome Crow**.

CPS are just-intonation scales built by taking a set of *n* factors and
multiplying every *k*-element subset together, octave-reduced:

| set | *n*)*k* | notes | factors |
|---|---|---|---|
| Hexany | 2)4 | 6 | 1·3·5·7 |
| Dekany | 2)5 / 3)5 | 10 | 1·3·5·7·9 |
| Pentadekany | 2)6 | 15 | 1·3·5·7·9·11 |
| Eikosany | 3)6 | 20 | 1·3·5·7·9·11 |

The default is the **Hexany** (`35/32, 5/4, 21/16, 3/2, 7/4, 15/8`).

## Install

Copy the `un-natural/` folder to `~/dust/code/` on your norns and select
`un-natural` in SELECT / maiden.

## Output — Crow

Crow gives **exact** just intonation: CV is 1V/oct and continuous, so a ratio's
voltage is simply `base_volts + log2(ratio)` — no pitch-bend tricks.

- **1-voice** mode (default): `out1` = CV (1V/oct), `out2` = gate/envelope.
- **2-voice** mode: `out1/out2` = voice A, `out3/out4` = voice B.

Patch `out1 → VCO 1V/oct`, `out2 → envelope gate/trig`. The gate is an AR shape
(`gate attack` / `gate release` params); set attack to 0 for a hard gate.
`root volts` places the 1/1 reference; `cv slew` adds portamento.

## Controls

- **grid** — the keyboard, framed by two control strips. In **scale** layout
  only the **anchor pitch class** is lit (a landmark); played notes light on top.
  Moving **right** adds the column interval (default 1 pitch class); moving **up**
  adds the current *number of columns* — so the vertical interval follows the
  column count.
- **left column** (x=1) — octave transpose (scale layout) / slice rotation
  (lattice layout). Centre row is home; the lit row is current. (E2 does the same.)
- **bottom row** (from column 2) — sets the **number of active columns**. Fewer
  columns → a smaller up/down interval; this is the main way to explore the
  left/right vs up/down relationship. Unused columns go dark.
- **E1** — root volts (transpose the whole board).
- **K1** — panic (all notes off).
- **K2** — toggle scale-builder / play focus.
- **K3** — cycle the on-screen view: lattice graph → pitch ring → ratio list.
- **builder** (K2): **E2** moves the cursor across the factors, then *k*, then
  the factor-count; **E3** changes the value under the cursor.

Everything else lives in PARAMETERS → `un-natural` (presets, generators,
anchor, off-scale behaviour, output). Params save/load with PSET.

## How the layout works (and a note on geometry)

The grid is a **2D window into the JI lattice**. Two axis generators map to the
grid's axes — moving one cell right multiplies pitch by `gen_x`, one cell up by
`gen_y` — so **every chord is a fixed shape you can slide anywhere**. Octaves
are preserved across the board; a cell lights if its octave-reduced ratio is a
CPS member.

In **auto** generator mode, the two axes are derived from the CPS graph: the two
smallest factor-swap intervals from the anchor note. This keeps neighbouring
cells on CPS members, so members form compact, movable clusters.

**Geometry caveat (by design, not a bug):** a CPS over three or more independent
primes is genuinely higher-dimensional than a flat grid. The Hexany, for
instance, is an octahedron — no 2D isomorphic tiling can show all six notes at
once; a single projection shows a 4-note slice. The **rotation strip** (grid
column 1) solves this: it shifts the anchor along a third generator, sliding the
slice to a parallel one, so the whole set is reachable in a few presses. (You
can also change the **anchor note** or switch generators to **manual** in
PARAMETERS.) Larger sets (Eikosany) show most of their notes in a single view.

Set **off-scale cells** to *playable* to also sound the non-CPS lattice points
between members (they show dim) for free exploration.

## Files

- `un-natural.lua` — entry: lifecycle, note routing, builder, redraw.
- `lib/cps.lua` — CPS math (combinations, products, naming, graph, generators).
- `lib/ji.lua` — just-intonation helpers (octave-reduce, cents, ratio→volts).
- `lib/layout.lua` — isomorphic lattice projection onto grid cells.
- `lib/grid_ui.lua` — grid drawing + key handling.
- `lib/crow_out.lua` — CV/gate output + voice allocation.
- `lib/display.lua` — screen views + scale builder.
- `lib/params_setup.lua` — PARAMETERS menu.

## Roadmap

SuperCollider engine output, MPE MIDI out (for CPS chords on external synths),
spanning multiple physical grids as one surface, and a sequencer/arpeggiator.
`note_on`/`note_off` is the single fan-out point, so these slot in without
disturbing the CPS/layout core.
