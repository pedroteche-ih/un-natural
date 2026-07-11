-- params_setup.lua -- PARAMETERS for the Hexany chord-trigger.
-- Grouped into sections (hexany / envelope / crow / engine) for a clean menu.
-- Structural params (factors, root) call rebuild(); envelope + output params are
-- read live at trigger time.

local params_setup = {}

function params_setup.init(rebuild, crow_out)
  -- ---- hexany ----
  params:add_group("un-natural: hexany", 5)
  params:add_number("un_factor_a", "factor 1", 1, 64, 1)
  params:add_number("un_factor_b", "factor 2", 1, 64, 3)
  params:add_number("un_factor_c", "factor 3", 1, 64, 5)
  params:add_number("un_factor_d", "factor 4", 1, 64, 7)
  for _, id in ipairs({ "un_factor_a", "un_factor_b", "un_factor_c", "un_factor_d" }) do
    params:set_action(id, function() rebuild() end)
  end
  params:add_control("un_root_hz", "root (1/1)",
    controlspec.new(20, 2000, "exp", 0, 130.81, "Hz"))
  params:set_action("un_root_hz", function() rebuild() end)

  -- ---- envelope (AR pad ranges) ----
  params:add_group("un-natural: envelope", 4)
  params:add_control("un_atk_min", "attack min",
    controlspec.new(0.001, 1, "exp", 0, 0.002, "s"))
  params:add_control("un_atk_max", "attack max",
    controlspec.new(0.01, 4, "exp", 0, 1.0, "s"))
  params:add_control("un_rel_min", "release min",
    controlspec.new(0.001, 1, "exp", 0, 0.01, "s"))
  params:add_control("un_rel_max", "release max",
    controlspec.new(0.05, 12, "exp", 0, 6.0, "s"))

  -- ---- crow ----
  params:add_group("un-natural: crow", 3)
  params:add_control("un_base_volts", "root volts",
    controlspec.new(-5, 10, "lin", 0.01, 0, "V"))
  params:set_action("un_base_volts", function(v) crow_out.cfg.base_volts = v end)
  params:add_control("un_peak_volts", "env peak",
    controlspec.new(0, 10, "lin", 0.1, 5, "V"))
  params:set_action("un_peak_volts", function(v) crow_out.cfg.peak_volts = v end)
  params:add_control("un_cv_slew", "cv slew",
    controlspec.new(0, 1, "lin", 0.001, 0, "s"))
  params:set_action("un_cv_slew", function(v) crow_out.cfg.slew = v end)

  -- ---- engine ----
  params:add_group("un-natural: engine", 1)
  params:add_control("un_amp", "sine level",
    controlspec.new(0, 1, "lin", 0.01, 0.2))
end

return params_setup
