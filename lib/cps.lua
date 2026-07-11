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

return cps
