-- crow_out.lua -- Monome Crow output for the Hexany chord-trigger.
-- Paraphonic: out1/out2/out3 = the three selected note pitches (1V/oct, exact JI),
-- out4 = one shared one-shot AR envelope fired on trigger. CV is continuous so
-- just-intonation is exact: volts = base_volts + log2(mult-from-root).

local ji = include('un-natural/lib/ji')

local crow_out = {}

crow_out.cfg = {
  base_volts = 0.0,   -- root (1/1) voltage
  peak_volts = 5.0,   -- out4 envelope peak
  slew = 0.0,         -- CV glide seconds (0 = instant)
  out_lo = -5.0,
  out_hi = 10.0,
}

local CV = { 1, 2, 3 }   -- pitch outputs
local ENV = 4            -- envelope output

local function configure_outputs()
  for _, o in ipairs(CV) do crow.output[o].slew = crow_out.cfg.slew end
  crow.output[ENV].volts = 0
end

function crow_out.setup()
  -- crow autoconnects on norns; reconfigure on (re)connect and now.
  crow.add = function() configure_outputs() end
  crow.remove = function() end
  configure_outputs()
end

-- set the three pitch CVs from up to three mult-from-root values.
-- empty slots mirror the last supplied note (so a 1- or 2-note chord is coherent).
function crow_out.set_chord(mults)
  local last = nil
  for i = 1, 3 do
    local m = mults[i] or last
    last = mults[i] or last
    if m then
      local volts = ji.clamp(
        ji.mult_to_volts(m, crow_out.cfg.base_volts),
        crow_out.cfg.out_lo, crow_out.cfg.out_hi)
      crow.output[CV[i]].slew = crow_out.cfg.slew
      crow.output[CV[i]].volts = volts
    end
  end
end

-- one-shot AR on out4: rise to peak over atk, fall to 0 over rel
function crow_out.trigger_env(atk, rel)
  crow.output[ENV].action =
    string.format("{ to(%f,%f), to(0,%f) }", crow_out.cfg.peak_volts, atk, rel)
  crow.output[ENV]()
end

function crow_out.all_off()
  crow.output[ENV].action = "to(0,0.01)"
  crow.output[ENV]()
end

function crow_out.reset()
  crow.send("crow.reset()")
end

return crow_out
