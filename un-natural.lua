-- un-natural
-- Erv Wilson Hexany chord-trigger
--
-- grid : col 1 = note select (rows 1-6) + octave up/down (rows 7/8)
--        cols 2-9 = 8x8 AR envelope pad (X attack, Y release); press to trigger
-- select up to 3 notes (rolling), then tap the pad to strike the chord.
-- E1   : sine level     E2 : octave
-- K1   : panic (clear selection / notes off)
--
-- output: sine engine + Monome Crow (out1-3 = pitch CV, out4 = AR envelope)

local util = require("util")

local ji         = include("un-natural/lib/ji")
local cps        = include("un-natural/lib/cps")
local grid_ui    = include("un-natural/lib/grid_ui")
local crow_out   = include("un-natural/lib/crow_out")
local display    = include("un-natural/lib/display")
local params_setup = include("un-natural/lib/params_setup")

-- Only claim the engine if it actually compiled. Otherwise setting engine.name
-- fails the whole script load (blank screen). If missing, the script still runs
-- (Crow works, sine silent) and prompts to run ;restart in maiden.
local function engine_available(name)
  if engine and engine.names then
    for _, n in ipairs(engine.names) do
      if n == name then return true end
    end
  end
  return false
end

local engine_ok = engine_available("UnNatural")
if engine_ok then engine.name = "UnNatural" end

-- ---- state ----
local scale
local selected = {}            -- ordered list of note indices (max 3)
local selected_set = {}        -- {[note_index] = true}
local octave = 0
local last_env = nil           -- { atk=, rel=, atk_idx=, rel_idx= }
local redraw_metro

-- ---- helpers ----
local function rebuild_selected_set()
  selected_set = {}
  for _, i in ipairs(selected) do selected_set[i] = true end
end

local function chord_mults()
  local m = {}
  for _, i in ipairs(selected) do
    m[#m + 1] = scale.notes[i].ratio * (2 ^ octave)
  end
  return m
end

local function update_cv()
  crow_out.set_chord(chord_mults())
end

local function grid_redraw()
  grid_ui.redraw({
    selected = selected_set,
    last_env = last_env and { atk = last_env.atk_idx, rel = last_env.rel_idx } or nil,
  })
end

function redraw()
  display.redraw({
    scale = scale,
    selected_set = selected_set,
    octave = octave,
    last_env = last_env,
    amp = params:get("un_amp"),
    engine_ok = engine_ok,
  })
end

-- rebuild the hexany from the factor params; the single structural funnel
local function rebuild()
  local factors = {
    params:get("un_factor_a"), params:get("un_factor_b"),
    params:get("un_factor_c"), params:get("un_factor_d"),
  }
  scale = cps.build(factors, 2)          -- hexany = 2)4
  -- prune any selection beyond the note count (defensive; hexany is always 6)
  local pruned = {}
  for _, i in ipairs(selected) do
    if scale.notes[i] then pruned[#pruned + 1] = i end
  end
  selected = pruned
  rebuild_selected_set()
  update_cv()
  grid_redraw()
  redraw()
end

-- ---- grid handlers ----
local function select_note(i)
  local pos
  for idx, v in ipairs(selected) do if v == i then pos = idx break end end
  if pos then
    table.remove(selected, pos)          -- toggle off
  else
    selected[#selected + 1] = i          -- add; drop oldest beyond 3
    if #selected > 3 then table.remove(selected, 1) end
  end
  rebuild_selected_set()
  update_cv()
  grid_redraw()
  redraw()
end

local function set_octave(d)
  octave = util.clamp(octave + d, -3, 3)
  update_cv()
  grid_redraw()
  redraw()
end

local function trigger(atk_idx, rel_idx)
  local atk = ji.expmap(atk_idx, 8, params:get("un_atk_min"), params:get("un_atk_max"))
  local rel = ji.expmap(rel_idx, 8, params:get("un_rel_min"), params:get("un_rel_max"))
  last_env = { atk = atk, rel = rel, atk_idx = atk_idx, rel_idx = rel_idx }

  update_cv()
  crow_out.trigger_env(atk, rel)

  local amp = params:get("un_amp")
  local root = params:get("un_root_hz")
  for _, i in ipairs(selected) do
    local f = root * scale.notes[i].ratio * (2 ^ octave)
    if engine and engine.trig then engine.trig(f, atk, rel, amp) end
  end

  grid_redraw()
  redraw()
end

local function panic()
  selected = {}
  rebuild_selected_set()
  crow_out.all_off()
  grid_redraw()
  redraw()
end

-- ---- lifecycle ----
function init()
  crow_out.setup()
  grid_ui.set_handlers(select_note, set_octave, trigger)
  params_setup.init(rebuild, crow_out)
  params:bang()                                  -- fires factor actions incl. rebuild()

  redraw_metro = metro.init(function() redraw() end, 1 / 15, -1)
  redraw_metro:start()
  grid_redraw()
  redraw()
end

function enc(n, d)
  if n == 1 then
    params:delta("un_amp", d)
  elseif n == 2 then
    set_octave(d)
  end
  redraw()
end

function key(n, z)
  if z == 1 and n == 1 then panic() end
  redraw()
end

function cleanup()
  if redraw_metro then redraw_metro:stop() end
  crow_out.all_off()
  crow_out.reset()
end
