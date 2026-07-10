-- grid_ui.lua -- draws the CPS keyboard and handles grid presses.
-- Two reserved control strips frame the keyboard:
--   * leftmost column (x=1)       -- octave transpose (scale mode) / slice rotation (lattice)
--   * bottom row (x>=2, y=height) -- sets how many columns the keyboard uses
-- The keyboard is everything else. Cells are keyed by frequency (idiom from
-- pitfalls/lib/g.lua); all cells of a held pitch light together.

local grid_ui = {}

local g = grid.connect()
local current_layout = nil
local on_cell, off_cell, on_rotate, on_setcols = nil, nil, nil, nil
local RESERVED = 1            -- leftmost column (control strip)
local RESERVED_ROWS = 1       -- bottom row (column-count selector)
local rot_offset = 0          -- currently selected octave/rotation offset (draw)
local cur_cols = 0            -- currently selected number of keyboard columns (draw)

function grid_ui.width()  return (g.cols and g.cols > 0) and g.cols or 16 end
function grid_ui.height() return (g.rows and g.rows > 0) and g.rows or 8 end
function grid_ui.playing_width()    return grid_ui.width() - RESERVED end
function grid_ui.keyboard_height()  return grid_ui.height() - RESERVED_ROWS end
function grid_ui.device() return g end

-- centre row = offset 0; rows above are positive, below negative
local function rot_center() return math.ceil(grid_ui.height() / 2) end
local function row_to_offset(y) return rot_center() - y end

function grid_ui.set_handlers(on_fn, off_fn, rot_fn, setcols_fn)
  on_cell, off_cell, on_rotate, on_setcols = on_fn, off_fn, rot_fn, setcols_fn
end

function grid_ui.set_layout(layout) current_layout = layout end
function grid_ui.set_rotation(offset) rot_offset = offset end
function grid_ui.set_cols(n) cur_cols = n end

g.key = function(x, y, z)
  if x <= RESERVED then                          -- left column: octave/rotation
    if z > 0 and on_rotate then on_rotate(row_to_offset(y)) end
    return
  end
  if y > grid_ui.keyboard_height() then          -- bottom row: column-count selector
    if z > 0 and on_setcols then on_setcols(x - RESERVED) end
    return
  end
  if not current_layout then return end          -- keyboard
  local col = current_layout.cells[x - RESERVED]
  local cell = col and col[y]
  if not cell then return end
  if z > 0 then
    if on_cell then on_cell(cell) end
  else
    if off_cell then off_cell(cell) end
  end
end

-- active = { freq = {[freq]=true}, class = {[class_key]=true} }
function grid_ui.redraw(active)
  active = active or { freq = {}, class = {} }
  local h = grid_ui.height()

  -- left control strip (x = 1)
  for y = 1, h do
    local o = row_to_offset(y)
    local level
    if o == rot_offset then level = 15
    elseif o == 0 then level = 6
    else level = 2 end
    g:led(1, y, level)
  end

  -- keyboard (physical x = RESERVED+1.., y = 1..keyboard_height)
  if current_layout then
    for lx = 1, current_layout.grid_w do
      for y = 1, current_layout.grid_h do
        local cell = current_layout.cells[lx][y]
        local level = cell.base_level
        if cell.active ~= false then
          if active.freq[cell.freq] then
            level = 15
          elseif active.class[cell.class_key] then
            level = 11
          end
        end
        g:led(lx + RESERVED, y, level)
      end
    end
  end

  -- bottom row: column-count selector (x = RESERVED+1 .. width)
  for x = RESERVED + 1, grid_ui.width() do
    local c = x - RESERVED                        -- this button = c columns
    local level
    if c == cur_cols then level = 12              -- current setting
    elseif c < cur_cols then level = 3            -- within the active span
    else level = 0 end
    g:led(x, h, level)
  end

  g:refresh()
end

return grid_ui
