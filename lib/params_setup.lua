-- params_setup.lua -- PARAMETERS menu for un-natural.
-- Params are the source of truth (PSET save/load for free). Structural params
-- (factors/k/generators/root/origin) call rebuild(); output params update crow.

local params_setup = {}

-- preset -> { factors(csv), k }  (generators are auto-derived per set)
local PRESETS = {
  { name = "Hexany 2)4",       factors = "1,3,5,7",      k = 2 },
  { name = "Dekany 2)5",       factors = "1,3,5,7,9",    k = 2 },
  { name = "Dekany 3)5",       factors = "1,3,5,7,9",    k = 3 },
  { name = "Pentadekany 2)6",  factors = "1,3,5,7,9,11", k = 2 },
  { name = "Eikosany 3)6",     factors = "1,3,5,7,9,11", k = 3 },
  { name = "custom",           factors = nil,            k = nil },
}
params_setup.PRESETS = PRESETS

function params_setup.init(rebuild, crow_out)
  params:add_group("un-natural", 19)   -- nests the next 19 params

  local names = {}
  for i, p in ipairs(PRESETS) do names[i] = p.name end
  params:add_option("un_preset", "preset", names, 1)
  params:set_action("un_preset", function(i)
    local p = PRESETS[i]
    if p.factors then
      params:set("un_factors", p.factors)
      params:set("un_k", p.k)
    end
    rebuild()
  end)

  params:add_text("un_factors", "factors", "1,3,5,7")
  params:set_action("un_factors", function() rebuild() end)

  params:add_number("un_k", "k (choose)", 1, 8, 2)
  params:set_action("un_k", function() rebuild() end)

  params:add_option("un_layout", "layout",
    { "scale (dense)", "lattice (geometric)" }, 1)
  params:set_action("un_layout", function() rebuild() end)

  params:add_option("un_gen_mode", "generators", { "auto", "manual" }, 1)
  params:set_action("un_gen_mode", function() rebuild() end)

  params:add_number("un_anchor", "anchor note", 1, 64, 1)
  params:set_action("un_anchor", function() rebuild() end)

  -- manual generators (used only when generators = manual); defaults suit Hexany
  params:add_number("un_gx_num", "gen X num", 1, 64, 8)
  params:add_number("un_gx_den", "gen X den", 1, 64, 7)
  params:add_number("un_gy_num", "gen Y num", 1, 64, 6)
  params:add_number("un_gy_den", "gen Y den", 1, 64, 5)
  for _, id in ipairs({ "un_gx_num", "un_gx_den", "un_gy_num", "un_gy_den" }) do
    params:set_action(id, function() rebuild() end)
  end

  params:add_number("un_origin_x", "origin col", 1, 32, 2)
  params:add_number("un_origin_y", "origin row", 1, 32, 2)
  params:set_action("un_origin_x", function() rebuild() end)
  params:set_action("un_origin_y", function() rebuild() end)

  params:add_control("un_root_hz", "root (1/1)",
    controlspec.new(20, 2000, "exp", 0, 130.81, "Hz"))
  params:set_action("un_root_hz", function() rebuild() end)

  params:add_option("un_nonmembers", "off-scale cells", { "silent", "playable" }, 1)
  params:set_action("un_nonmembers", function() rebuild() end)

  params:add_option("un_mode", "voices", { "1 (out1/2)", "2 (out1-4)" }, 1)
  params:set_action("un_mode", function(i) crow_out.set_mode(i) end)

  params:add_control("un_base_volts", "root volts",
    controlspec.new(-5, 10, "lin", 0.01, 0, "V"))
  params:set_action("un_base_volts", function(v) crow_out.cfg.base_volts = v end)

  params:add_control("un_slew", "cv slew",
    controlspec.new(0, 2, "lin", 0.001, 0, "s"))
  params:set_action("un_slew", function(v) crow_out.cfg.slew = v end)

  params:add_control("un_attack", "gate attack",
    controlspec.new(0, 2, "lin", 0.001, 0.005, "s"))
  params:set_action("un_attack", function(v) crow_out.cfg.attack = v end)

  params:add_control("un_release", "gate release",
    controlspec.new(0, 4, "lin", 0.001, 0.05, "s"))
  params:set_action("un_release", function(v) crow_out.cfg.release = v end)
end

return params_setup
