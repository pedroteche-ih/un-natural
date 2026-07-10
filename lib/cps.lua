-- cps.lua -- Combination Product Set engine (generic k-of-n)
-- Erv Wilson CPS: take a set of n factors, multiply every k-element subset,
-- octave-reduce the products. e.g. Hexany = 2-of-4 {1,3,5,7} -> 6 notes.

local ji = include('un-natural/lib/ji')

local cps = {}

-- names keyed on "n,k"; falls back to a generic descriptor
local NAMES = {
  ["3,1"] = "Triad",       ["4,2"] = "Hexany",
  ["5,2"] = "Dekany",      ["5,3"] = "Dekany",
  ["6,2"] = "Pentadekany", ["6,4"] = "Pentadekany",
  ["6,3"] = "Eikosany",    ["7,3"] = "Hebdomekontany",
}

-- all k-element subsets of indices 1..n, as lists of indices
function cps.combinations(n, k)
  local out = {}
  local combo = {}
  local function recurse(start, depth)
    if depth > k then
      local c = {}
      for i = 1, k do c[i] = combo[i] end
      out[#out + 1] = c
      return
    end
    for i = start, n - (k - depth) do
      combo[depth] = i
      recurse(i + 1, depth + 1)
    end
  end
  if k >= 1 and k <= n then recurse(1, 1) end
  return out
end

function cps.name(n, k)
  local base = NAMES[n .. "," .. k]
  local count = #cps.combinations(n, k)
  if base then return base end
  return string.format("%d)%d CPS", k, n)
end

-- build a scale from a factor list and k.
-- returns { factors, k, name, count, notes = { sorted by pitch:
--   { ratio, num, den, subset={indices}, factors={values}, cents, label } } }
function cps.build(factors, k)
  local n = #factors
  k = math.max(1, math.min(k, n))
  local combos = cps.combinations(n, k)
  local notes = {}
  for _, subset in ipairs(combos) do
    local product = 1
    local vals = {}
    for _, idx in ipairs(subset) do
      product = product * factors[idx]
      vals[#vals + 1] = factors[idx]
    end
    local num, den, ratio = ji.reduce_product(product)
    notes[#notes + 1] = {
      ratio = ratio, num = num, den = den,
      subset = subset, factors = vals,
      cents = ji.cents(ratio),
      label = ji.nearest_label(ratio, num, den),
    }
  end
  table.sort(notes, function(a, b) return a.ratio < b.ratio end)

  return {
    factors = factors, k = k, n = n,
    name = cps.name(n, k), count = #notes, notes = notes,
  }
end

-- do two notes' subsets differ by exactly one factor? (a CPS lattice edge)
function cps.adjacent(a, b, k)
  local shared = 0
  for _, i in ipairs(a.subset) do
    for _, j in ipairs(b.subset) do
      if i == j then shared = shared + 1 end
    end
  end
  return shared == k - 1
end

-- Derive isomorphic axis generators from the CPS graph: from the anchor note,
-- the smallest ascending factor-swap intervals. The first two are the grid
-- axes (gx, gy) -- they keep neighbouring cells on CPS members, so chords sit
-- in compact movable clusters. The third (gz) is the ROTATION axis: shifting
-- the anchor by gz slides the visible 2D slice to a parallel one, which is how
-- the rotation column reaches notes outside the current projection.
-- Returns gx, gy, gz (float ratios).
function cps.default_generators(scale, anchor_index)
  local anchor = scale.notes[anchor_index or 1]
  if not anchor then return 3 / 2, 5 / 4 end
  local cands = {}
  for _, m in ipairs(scale.notes) do
    if m ~= anchor and cps.adjacent(anchor, m, scale.k) then
      local g = m.ratio / anchor.ratio
      while g < 1 do g = g * 2 end            -- ascending within the octave
      cands[#cands + 1] = g
    end
  end
  table.sort(cands)
  local uniq = {}
  for _, g in ipairs(cands) do
    local dup = false
    for _, u in ipairs(uniq) do
      if math.abs(u - g) / g < 0.001 then dup = true end
    end
    if not dup then uniq[#uniq + 1] = g end
  end
  local gx = uniq[1] or 3 / 2
  local gy = uniq[2] or uniq[1] or 5 / 4
  local gz = uniq[3] or uniq[2] or uniq[1] or 2   -- rotation axis (octave fallback)
  return gx, gy, gz
end

-- is an octave-reduced ratio a member of the scale? returns note index or nil
function cps.contains(scale, reduced_ratio, tol)
  tol = tol or 0.002
  for i, note in ipairs(scale.notes) do
    if math.abs(note.ratio - reduced_ratio) / note.ratio < tol then
      return i
    end
  end
  return nil
end

return cps
