-- grid_ui.lua -- fixed-zone grid for the Hexany chord-trigger (8 rows x 16 cols).
--   column 1  : rows 1-6 = the 6 hexany notes (row 6 = lowest .. row 1 = highest),
--               row 7 = octave up, row 8 = octave down
--   cols 2-9  : 8x8 AR-envelope pad. X (2->9) = attack, Y (bottom->top) = release.
--   cols 10+  : unused (dark)

local grid_ui = {}

local g = grid.connect()
local on_note, on_octave, on_env = nil, nil, nil

local PAD_X0, PAD_X1 = 2, 9

function grid_ui.width()  return (g.cols and g.cols > 0) and g.cols or 16 end
function grid_ui.height() return (g.rows and g.rows > 0) and g.rows or 8 end
function grid_ui.device() return g end

function grid_ui.set_handlers(note_fn, octave_fn, env_fn)
  on_note, on_octave, on_env = note_fn, octave_fn, env_fn
end

-- row (1..6) -> note index; row 6 = lowest note, row 1 = highest
local function row_to_note(y) return 7 - y end

g.key = function(x, y, z)
  if z <= 0 then return end                        -- act on press only
  if x == 1 then                                   -- note selector column
    if y <= 6 then
      if on_note then on_note(row_to_note(y)) end
    elseif y == 7 then
      if on_octave then on_octave(1) end
    elseif y == 8 then
      if on_octave then on_octave(-1) end
    end
  elseif x >= PAD_X0 and x <= PAD_X1 then          -- envelope pad
    local atk = x - PAD_X0 + 1                      -- 1..8 (left = short)
    local rel = grid_ui.height() - y + 1           -- 1..8 (bottom = short)
    if on_env then on_env(atk, rel) end
  end
  -- cols 10+ : unused
end

-- state = { selected = {[note_index]=true}, last_env = {atk=, rel=} }
function grid_ui.redraw(state)
  state = state or {}
  local sel = state.selected or {}
  g:all(0)

  -- column 1: notes + octave buttons
  for y = 1, 6 do
    local ni = row_to_note(y)
    g:led(1, y, sel[ni] and 15 or 3)
  end
  g:led(1, 7, 5)   -- octave up
  g:led(1, 8, 5)   -- octave down

  -- envelope pad: dim field, last-triggered cell lit
  for x = PAD_X0, PAD_X1 do
    for y = 1, 8 do g:led(x, y, 2) end
  end
  if state.last_env then
    local ex = PAD_X0 + state.last_env.atk - 1
    local ey = grid_ui.height() - state.last_env.rel + 1
    g:led(ex, ey, 12)
  end

  g:refresh()
end

return grid_ui
