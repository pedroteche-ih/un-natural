-- crow_out.lua -- CV/gate output to Monome Crow with simple voice allocation.
-- CV is 1V/oct and continuous, so just-intonation ratios are exact: a note's
-- voltage is base_volts + log2(multiplier-from-root). Each voice = one CV output
-- + one gate/envelope output. Gate is an AR shape (rise on note-on, fall on off).

local ji = include('un-natural/lib/ji')

local crow_out = {}

crow_out.cfg = {
  mode = 1,          -- 1 = one voice (cv1/gate2), 2 = two voices (cv1/gate2, cv3/gate4)
  base_volts = 0.0,  -- root (1/1) voltage
  out_lo = -5.0,
  out_hi = 10.0,
  slew = 0.0,        -- CV glide seconds
  attack = 0.005,    -- gate rise seconds
  release = 0.05,    -- gate fall seconds
  gate_high = 5.0,
}

local voices = {}    -- { {cv, gate, id, order}, ... }
local counter = 0    -- for round-robin / oldest-steal

local function build_voices()
  voices = {}
  if crow_out.cfg.mode >= 2 then
    voices[1] = { cv = 1, gate = 2, id = nil, order = 0 }
    voices[2] = { cv = 3, gate = 4, id = nil, order = 0 }
  else
    voices[1] = { cv = 1, gate = 2, id = nil, order = 0 }
  end
end

-- configure crow outputs for the current mode
local function configure_outputs()
  for _, v in ipairs(voices) do
    crow.output[v.cv].slew = crow_out.cfg.slew
    crow.output[v.gate].volts = 0
  end
end

function crow_out.setup()
  -- reconfigure whenever Crow (re)connects; also configure now in case it is
  -- already present. crow autoconnects on norns, so no explicit clear/init needed.
  crow.add = function() build_voices(); configure_outputs() end
  crow.remove = function() end
  build_voices()
  configure_outputs()
end

function crow_out.set_mode(m)
  crow_out.cfg.mode = m
  crow_out.all_off()
  build_voices()
  configure_outputs()
end

local function free_voice()
  -- prefer an idle voice, else steal the oldest
  local pick, oldest = nil, math.huge
  for _, v in ipairs(voices) do
    if v.id == nil then return v end
    if v.order < oldest then oldest = v.order; pick = v end
  end
  return pick
end

local function open_gate(v)
  crow.output[v.gate].action =
    string.format("to(%f,%f)", crow_out.cfg.gate_high, crow_out.cfg.attack)
  crow.output[v.gate]()
end

local function close_gate(v)
  crow.output[v.gate].action = string.format("to(0,%f)", crow_out.cfg.release)
  crow.output[v.gate]()
end

-- id is the note identity (its frequency); mult is the ratio-from-root
function crow_out.note_on(id, mult)
  if #voices == 0 then return end
  local v = free_voice()
  if v.id ~= nil then close_gate(v) end   -- steal: retrigger cleanly
  counter = counter + 1
  v.id = id
  v.order = counter
  local volts = ji.clamp(
    ji.mult_to_volts(mult, crow_out.cfg.base_volts),
    crow_out.cfg.out_lo, crow_out.cfg.out_hi)
  crow.output[v.cv].slew = crow_out.cfg.slew
  crow.output[v.cv].volts = volts
  open_gate(v)
end

function crow_out.note_off(id)
  for _, v in ipairs(voices) do
    if v.id == id then
      close_gate(v)
      v.id = nil
      return
    end
  end
end

function crow_out.all_off()
  for _, v in ipairs(voices) do
    if v.id ~= nil then close_gate(v) end
    v.id = nil
  end
end

function crow_out.reset()
  crow.send("crow.reset()")
end

return crow_out
