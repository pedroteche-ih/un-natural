-- un-natural
-- Erv Wilson Combination Product Sets
-- as an isomorphic grid keyboard -> Crow
--
-- grid : isomorphic CPS keyboard (JI lattice projection)
--        leftmost column = rotation strip: slides the visible slice so every
--        note in the set is reachable (chord shapes stay constant)
-- E1   : root volts (transpose the whole board)
-- K1   : panic (all notes off)
-- K2   : toggle scale-builder / play
-- K3   : cycle view (lattice / ring / list)
-- builder: E2 cursor, E3 value (factors, k, factor-count)
--
-- output: Monome Crow -- out1 CV (1V/oct, exact JI), out2 gate/env
--         (2-voice mode adds out3 CV / out4 gate)

local util = require("util")

local ji         = include("un-natural/lib/ji")
local cps        = include("un-natural/lib/cps")
local layout_lib = include("un-natural/lib/layout")
local grid_ui    = include("un-natural/lib/grid_ui")
local crow_out   = include("un-natural/lib/crow_out")
local display    = include("un-natural/lib/display")
local params_setup = include("un-natural/lib/params_setup")

-- ---- state ----
local scale, current_layout
local active = { freq = {}, class = {} }
local freq_count, class_count = {}, {}
local nonmembers_playable = false
local z_offset = 0             -- rotation-strip offset along the CPS rotation axis
local builder = { factors = { 1, 3, 5, 7 }, k = 2, cursor = 1 }
local view = 1                 -- 1 lattice, 2 ring, 3 list
local focus = "keyboard"       -- "keyboard" | "builder"
local scroll = 0
local redraw_metro

-- ---- helpers ----
local function parse_factors(s)
  local t = {}
  for tok in string.gmatch(s or "", "[^,%s]+") do
    local v = tonumber(tok)
    if v and v >= 1 then t[#t + 1] = math.floor(v) end
  end
  if #t == 0 then t = { 1 } end
  return t
end

local function grid_redraw()
  grid_ui.redraw(active)
end

local function panic()
  crow_out.all_off()
  freq_count, class_count = {}, {}
  active.freq, active.class = {}, {}
  grid_redraw()
end

-- rebuild scale + layout from params; the single funnel for structural change
local function rebuild()
  local factors = parse_factors(params:get("un_factors"))
  local k = params:get("un_k")
  scale = cps.build(factors, k)

  nonmembers_playable = params:get("un_nonmembers") == 2

  local mode = (params:get("un_layout") == 2) and "lattice" or "scale"
  local opts = {
    mode = mode,
    grid_w = grid_ui.playing_width(), grid_h = grid_ui.height(),
    origin_x = params:get("un_origin_x"), origin_y = params:get("un_origin_y"),
    root_freq = params:get("un_root_hz"),
  }

  if mode == "lattice" then
    local anchor_i = util.clamp(params:get("un_anchor"), 1, scale.count)
    -- gz (rotation axis) is always auto-derived; gx/gy may be manual
    local agx, agy, gz = cps.default_generators(scale, anchor_i)
    if params:get("un_gen_mode") == 1 then       -- auto: derive from CPS graph
      opts.gen_x, opts.gen_y = agx, agy
    else                                         -- manual
      opts.gen_x = params:get("un_gx_num") / params:get("un_gx_den")
      opts.gen_y = params:get("un_gy_num") / params:get("un_gy_den")
    end
    -- rotation strip shifts the anchor along gz, sliding the visible slice
    opts.anchor_ratio = ji.octave_reduce(scale.notes[anchor_i].ratio * (gz ^ z_offset))
    opts.nonmember_level = nonmembers_playable and 2 or 0
  else
    -- scale mode: rotation strip transposes the whole board by octaves
    opts.z_offset = z_offset
  end

  current_layout = layout_lib.build(scale, opts)
  grid_ui.set_layout(current_layout)
  grid_ui.set_rotation(z_offset)

  -- keep the builder view in sync with the source-of-truth params
  builder.factors = factors
  builder.k = scale.k
  builder.cursor = util.clamp(builder.cursor, 1, #factors + 2)
  scroll = util.clamp(scroll, 0, math.max(0, #scale.notes - 6))

  panic()
end

-- ---- note routing (single fan-out point) ----
local function note_on_cell(cell)
  if not cell.member and not nonmembers_playable then return end
  local f, ck = cell.freq, cell.class_key
  freq_count[f] = (freq_count[f] or 0) + 1
  active.freq[f] = true
  class_count[ck] = (class_count[ck] or 0) + 1
  active.class[ck] = true
  crow_out.note_on(f, cell.mult)
  grid_redraw()
end

local function note_off_cell(cell)
  local f, ck = cell.freq, cell.class_key
  local fc = (freq_count[f] or 1) - 1
  if fc <= 0 then freq_count[f] = nil; active.freq[f] = nil else freq_count[f] = fc end
  local cc = (class_count[ck] or 1) - 1
  if cc <= 0 then class_count[ck] = nil; active.class[ck] = nil else class_count[ck] = cc end
  crow_out.note_off(f)
  grid_redraw()
end

-- rotation strip: shift the visible lattice slice along the CPS rotation axis
local function rotate(offset)
  z_offset = offset
  rebuild()
  redraw()
end

-- ---- builder editing ----
local function commit_factors()
  params:set("un_factors", table.concat(builder.factors, ","))
end

local function builder_edit(d)
  local nf = #builder.factors
  if builder.cursor <= nf then
    builder.factors[builder.cursor] = math.max(1, builder.factors[builder.cursor] + d)
    commit_factors()
  elseif builder.cursor == nf + 1 then          -- k
    params:set("un_k", util.clamp(builder.k + d, 1, nf))
  else                                           -- factor count (n)
    if d > 0 then
      builder.factors[nf + 1] = (builder.factors[nf] or 1) + 2
      commit_factors()
    elseif d < 0 and nf > 2 then
      builder.factors[nf] = nil
      commit_factors()
    end
  end
end

-- ---- lifecycle ----
function init()
  crow_out.setup()
  grid_ui.set_handlers(note_on_cell, note_off_cell, rotate)
  params_setup.init(rebuild, crow_out)
  params:bang()                                  -- fires actions incl. rebuild()

  redraw_metro = metro.init(function() redraw() end, 1 / 15, -1)
  redraw_metro:start()
  grid_redraw()
  redraw()
end

function enc(n, d)
  if n == 1 then
    params:delta("un_base_volts", d)
  elseif focus == "builder" then
    if n == 2 then
      builder.cursor = util.clamp(builder.cursor + d, 1, #builder.factors + 2)
    elseif n == 3 then
      builder_edit(d)
    end
  else
    if n == 2 then
      rotate(util.clamp(z_offset + d, -12, 12))  -- rotate the slice via encoder
    elseif n == 3 and view == 3 then
      scroll = util.clamp(scroll + d, 0, math.max(0, #scale.notes - 6))
    end
  end
  redraw()
end

function key(n, z)
  if z == 1 then
    if n == 1 then
      panic()
    elseif n == 2 then
      focus = (focus == "builder") and "keyboard" or "builder"
    elseif n == 3 then
      view = (view % 3) + 1
    end
    redraw()
  end
end

function redraw()
  if not scale then
    screen.clear(); screen.update(); return
  end
  display.redraw({
    view = view, focus = focus, scale = scale,
    active = active, scroll = scroll, builder = builder,
    z_offset = z_offset,
  })
end

function cleanup()
  if redraw_metro then redraw_metro:stop() end
  crow_out.all_off()
  crow_out.reset()
end
