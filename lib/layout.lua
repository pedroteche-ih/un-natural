-- layout.lua -- isomorphic lattice projection of a CPS onto the grid.
-- The grid is a 2D window into the JI lattice: two axis generators (gen_x per
-- column, gen_y per row). Cell(x,y) sounds root_freq * gen_x^dx * gen_y^dy.
-- Octaves are preserved so it plays like a real isomorphic keyboard; CPS
-- membership is tested octave-reduced.

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

-- opts = { gen_x, gen_y, anchor_ratio, grid_w, grid_h, origin_x, origin_y,
--          root_freq, nonmember_level }
-- The origin cell sits on anchor_ratio (a CPS member), NOT 1/1 -- CPS sets have
-- no 1/1, and level-preserving generators reach members only from a member.
function layout.build(scale, opts)
  local gx = opts.gen_x or 5 / 3
  local gy = opts.gen_y or 7 / 5
  local anchor = opts.anchor_ratio or 1
  local w = opts.grid_w
  local h = opts.grid_h
  local ox = opts.origin_x or 1
  local oy = opts.origin_y or 1
  local root_freq = opts.root_freq or 130.81

  local cells = {}        -- cells[x][y] = cell
  local class_xy = {}     -- class_key -> list of {x,y}

  for x = 1, w do
    cells[x] = {}
    for y = 1, h do
      -- physical y=1 is the top row; make "up" raise pitch
      local dx = x - ox
      local dy = (h - y + 1) - oy
      local mult = anchor * (gx ^ dx) * (gy ^ dy)
      local freq = root_freq * mult
      local reduced = ji.octave_reduce(mult)
      local member = cps.contains(scale, reduced)

      local level
      if member and math.abs(reduced - anchor) < 0.002 then
        level = 12                              -- the anchor member
      elseif member then
        level = 6                               -- an in-scale note
      else
        level = opts.nonmember_level or 0       -- off the CPS (dim if playable)
      end

      local ck = class_key(member, reduced)
      local cell = {
        x = x, y = y, dx = dx, dy = dy,
        mult = mult, freq = freq, reduced = reduced,
        class_key = ck, member = member, base_level = level,
      }
      cells[x][y] = cell
      class_xy[ck] = class_xy[ck] or {}
      table.insert(class_xy[ck], { x, y })
    end
  end

  return {
    cells = cells, class_xy = class_xy,
    gen_x = gx, gen_y = gy, root_freq = root_freq,
    grid_w = w, grid_h = h,
  }
end

return layout
