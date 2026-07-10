-- display.lua -- 128x64 screen views for un-natural.
-- Views cycled with K3: lattice graph, pitch ring, ratio list.
-- Builder screen (K2 focus) edits the factor set + k.

local display = {}

local CX, CY, R = 82, 36, 24   -- graph/ring centre and radius (left area for text)

-- a scale note (index i) is sounding if its member key is in the active set
local function is_on(active, i) return active["m" .. i] end

local function node_pos(note)
  local a = -math.pi / 2 + 2 * math.pi * (note.cents / 1200)
  return CX + R * math.cos(a), CY + R * math.sin(a)
end

-- two CPS notes are adjacent iff their subsets differ by exactly one factor
local function adjacent(a, b, k)
  local shared = 0
  for _, i in ipairs(a.subset) do
    for _, j in ipairs(b.subset) do
      if i == j then shared = shared + 1 end
    end
  end
  return shared == k - 1
end

local function header(scale)
  screen.level(15)
  screen.move(0, 8)
  screen.text(scale.name)
  screen.level(4)
  screen.move(0, 17)
  screen.text(scale.count .. " notes")
  if display._rot and display._rot ~= 0 then
    screen.level(6)
    screen.move(127, 8)
    screen.text_right(string.format("rot %+d", display._rot))
  end
end

-- LATTICE GRAPH -------------------------------------------------------------
function display.lattice(scale, active)
  header(scale)
  local pos = {}
  for i, note in ipairs(scale.notes) do
    pos[i] = { node_pos(note) }
  end
  -- edges first
  screen.level(2)
  for i = 1, #scale.notes do
    for j = i + 1, #scale.notes do
      if adjacent(scale.notes[i], scale.notes[j], scale.k) then
        screen.move(pos[i][1], pos[i][2])
        screen.line(pos[j][1], pos[j][2])
        screen.stroke()
      end
    end
  end
  -- nodes
  for i, note in ipairs(scale.notes) do
    local on = is_on(active, i)
    screen.level(on and 15 or 6)
    screen.circle(pos[i][1], pos[i][2], on and 2.5 or 1.5)
    screen.fill()
    screen.level(on and 15 or 3)
    screen.move(pos[i][1] + 4, pos[i][2] + 2)
    screen.text(note.label)
  end
end

-- PITCH RING ----------------------------------------------------------------
function display.ring(scale, active)
  header(scale)
  screen.level(2)
  screen.circle(CX, CY, R)
  screen.stroke()
  for i, note in ipairs(scale.notes) do
    local x, y = node_pos(note)
    local on = is_on(active, i)
    screen.level(on and 15 or 6)
    screen.circle(x, y, on and 2.5 or 1.5)
    screen.fill()
  end
  screen.level(4)
  screen.move(0, 30)
  screen.text("ring")
  screen.move(0, 40)
  screen.text("cents")
end

-- RATIO LIST ----------------------------------------------------------------
function display.list(scale, active, scroll)
  scroll = scroll or 0
  screen.level(15)
  screen.move(0, 8)
  screen.text(scale.name)
  local rows = 6
  for row = 1, rows do
    local i = row + scroll
    local note = scale.notes[i]
    if note then
      local y = 8 + row * 8
      local on = is_on(active, i)
      screen.level(on and 15 or 4)
      screen.move(0, y)
      screen.text(note.num .. "/" .. note.den)
      screen.move(48, y)
      screen.text(note.label)
      screen.move(88, y)
      screen.text(string.format("%dc", math.floor(note.cents + 0.5)))
    end
  end
end

-- BUILDER -------------------------------------------------------------------
-- b = { factors = {..}, k = n, cursor = i }  (cursor #factors+1 edits k)
function display.builder(b, scale)
  screen.level(15)
  screen.move(0, 8)
  screen.text("build: " .. scale.name)
  screen.level(4)
  screen.move(0, 17)
  screen.text(scale.count .. " notes   " .. b.k .. ")" .. #b.factors)

  local x = 0
  for i, f in ipairs(b.factors) do
    local sel = (b.cursor == i)
    local s = tostring(f)
    screen.level(sel and 15 or 5)
    screen.move(x, 36)
    screen.text(s)
    if sel then
      screen.level(15)
      screen.move(x - 1, 40)
      screen.line(x + screen.text_extents(s) + 1, 40)
      screen.stroke()
    end
    x = x + screen.text_extents(s) + 8
  end

  local ksel = (b.cursor == #b.factors + 1)
  screen.level(ksel and 15 or 5)
  screen.move(0, 54)
  screen.text("k = " .. b.k)
  if ksel then
    screen.move(0, 58)
    screen.line(screen.text_extents("k = " .. b.k), 58)
    screen.stroke()
  end

  screen.level(2)
  screen.move(0, 63)
  screen.text("E2 cursor  E3 value  K2 play")
end

-- DISPATCH ------------------------------------------------------------------
-- state = { view, focus, scale, active, scroll, builder }
function display.redraw(state)
  display._rot = state.z_offset or 0
  screen.clear()
  if state.focus == "builder" then
    display.builder(state.builder, state.scale)
  elseif state.view == 1 then
    display.lattice(state.scale, state.active)
  elseif state.view == 2 then
    display.ring(state.scale, state.active)
  else
    display.list(state.scale, state.active, state.scroll)
  end
  screen.update()
end

return display
