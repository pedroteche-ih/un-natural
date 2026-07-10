-- layout.lua -- maps a CPS onto the grid as an isomorphic keyboard.
--
-- Two modes:
--   "scale"   -- dense scale-degree isomorphic layout (like pitfalls' MOS grid):
--                every cell is a CPS note, all notes present at once, the scale
--                repeats across the whole grid spanning octaves. Columns step +1
--                scale degree; rows step by a "fifth" (nearest CPS note to 3/2).
--   "lattice" -- geometric JI-lattice projection: two axis generators, chord
--                shapes = lattice shapes, factor-swaps = directions. Faithful to
--                CPS geometry but sparse (a 2D slice of a higher-D set), so use
--                the rotation strip to reach notes outside the current slice.

local ji = include('un-natural/lib/ji')
local cps = include('un-natural/lib/cps')

local layout = {}

-- Class key groups cells that share a pitch identity for LED highlighting.
-- Members key by note index (tolerance-matched, robust to float error);
-- off-scale cells key by their reduced ratio.
local function class_key(member, reduced)
  if member then return "m" .. member end
  return string.format("f%.4f", reduced)
end

-- how many scale degrees reach the CPS note nearest a 3/2 fifth (the row step)
local function fifth_degrees(scale)
  local best, bestdiff = 1, math.huge
  for i, note in ipairs(scale.notes) do
    local d = math.abs(note.ratio - 3 / 2)
    if d < bestdiff then bestdiff = d; best = i end
  end
  local offset = best - 1
  if offset == 0 then offset = math.max(1, math.floor(#scale.notes / 2)) end
  return offset
end

-- DENSE scale-degree isomorphic layout ------------------------------------
-- z_offset transposes the whole board by octaves (the rotation strip).
local function build_scale(scale, opts, cells, class_xy)
  local w, h = opts.grid_w, opts.grid_h
  local ox = opts.origin_x or 1
  local oy = opts.origin_y or 1
  local root_freq = opts.root_freq or 130.81
  local z = opts.z_offset or 0
  local N = #scale.notes
  local offset = fifth_degrees(scale)

  for x = 1, w do
    cells[x] = {}
    for y = 1, h do
      local n = (x - ox) + ((h - y + 1) - oy) * offset   -- degree index from root
      local oct = math.floor(n / N) + z
      local deg = n - math.floor(n / N) * N               -- 0 .. N-1
      local note = scale.notes[deg + 1]
      local mult = (2 ^ oct) * note.ratio
      local freq = root_freq * mult
      local member = deg + 1

      local level = (deg == 0) and 12 or 6                -- tonic brighter
      local ck = class_key(member, note.ratio)
      local cell = {
        x = x, y = y, mult = mult, freq = freq, reduced = note.ratio,
        class_key = ck, member = member, base_level = level,
      }
      cells[x][y] = cell
      class_xy[ck] = class_xy[ck] or {}
      table.insert(class_xy[ck], { x, y })
    end
  end
end

-- GEOMETRIC JI-lattice projection -----------------------------------------
-- The origin cell sits on anchor_ratio (a CPS member), NOT 1/1 -- CPS sets have
-- no 1/1, and level-preserving generators reach members only from a member.
local function build_lattice(scale, opts, cells, class_xy)
  local gx = opts.gen_x or 5 / 3
  local gy = opts.gen_y or 7 / 5
  local anchor = opts.anchor_ratio or 1
  local w, h = opts.grid_w, opts.grid_h
  local ox = opts.origin_x or 1
  local oy = opts.origin_y or 1
  local root_freq = opts.root_freq or 130.81

  for x = 1, w do
    cells[x] = {}
    for y = 1, h do
      local dx = x - ox
      local dy = (h - y + 1) - oy
      local mult = anchor * (gx ^ dx) * (gy ^ dy)
      local freq = root_freq * mult
      local reduced = ji.octave_reduce(mult)
      local member = cps.contains(scale, reduced)

      local level
      if member and math.abs(reduced - anchor) < 0.002 then
        level = 12
      elseif member then
        level = 6
      else
        level = opts.nonmember_level or 0
      end

      local ck = class_key(member, reduced)
      local cell = {
        x = x, y = y, mult = mult, freq = freq, reduced = reduced,
        class_key = ck, member = member, base_level = level,
      }
      cells[x][y] = cell
      class_xy[ck] = class_xy[ck] or {}
      table.insert(class_xy[ck], { x, y })
    end
  end
end

function layout.build(scale, opts)
  local cells, class_xy = {}, {}
  if (opts.mode or "scale") == "lattice" then
    build_lattice(scale, opts, cells, class_xy)
  else
    build_scale(scale, opts, cells, class_xy)
  end
  return {
    cells = cells, class_xy = class_xy,
    root_freq = opts.root_freq or 130.81,
    grid_w = opts.grid_w, grid_h = opts.grid_h,
  }
end

return layout
