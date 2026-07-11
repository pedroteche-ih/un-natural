-- display.lua -- 128x64 screen for the Hexany chord-trigger.
-- Shows the hexany's factors + 6 ratios (selected ones highlighted), the octave,
-- and the last-triggered envelope (attack/release) with a small AR sketch.

local display = {}

local function fmt_time(t)
  if not t then return "-" end
  if t < 1 then return string.format("%dms", math.floor(t * 1000 + 0.5)) end
  return string.format("%.2fs", t)
end

-- state = { scale, selected_set = {[i]=true}, octave, last_env = {atk,rel}, amp }
function display.redraw(state)
  screen.clear()
  local scale = state.scale
  if not scale then screen.update(); return end

  -- header: name + factors
  screen.level(15)
  screen.move(0, 8)
  screen.text("un-natural")
  screen.level(4)
  screen.move(127, 8)
  screen.text_right(table.concat(scale.factors, "\183"))   -- middle dot

  screen.level(6)
  screen.move(0, 18)
  screen.text(scale.name)
  screen.move(127, 18)
  screen.text_right(string.format("oct %+d", state.octave or 0))

  -- 6 ratios, 3 per row; selected highlighted
  local sel = state.selected_set or {}
  local cols = { 0, 44, 86 }
  for i, note in ipairs(scale.notes) do
    local row = (i <= 3) and 0 or 1
    local x = cols[((i - 1) % 3) + 1]
    local y = 32 + row * 12
    local on = sel[i]
    screen.level(on and 15 or 3)
    screen.move(x, y)
    screen.text(note.num .. "/" .. note.den)
    if on then
      screen.move(x, y + 2)
      screen.line(x + screen.text_extents(note.num .. "/" .. note.den), y + 2)
      screen.stroke()
    end
  end

  -- last envelope + level
  local e = state.last_env
  screen.level(6)
  screen.move(0, 62)
  if e then
    screen.text("A " .. fmt_time(e.atk) .. "  R " .. fmt_time(e.rel))
  else
    screen.text("select notes, tap pad")
  end
  screen.move(127, 62)
  screen.text_right(string.format("amp %.2f", state.amp or 0))

  screen.update()
end

return display
