-- ji.lua -- just-intonation helpers
-- Pure functions, no state. Ratios are plain numbers (e.g. 1.5 for 3/2).

local ji = {}

local LOG2 = math.log(2)

-- fold a ratio into the octave [1, 2)
function ji.octave_reduce(r)
  while r >= 2 do r = r / 2 end
  while r < 1 do r = r * 2 end
  return r
end

-- cents of a ratio (relative to 1/1)
function ji.cents(r)
  return 1200 * math.log(r) / LOG2
end

-- volts per octave: how far (in octaves = volts) a multiplier is from the root
function ji.mult_to_volts(mult, base_volts)
  return (base_volts or 0) + math.log(mult) / LOG2
end

function ji.clamp(x, lo, hi)
  if x < lo then return lo elseif x > hi then return hi else return x end
end

function ji.gcd(a, b)
  a, b = math.floor(a), math.floor(b)
  while b ~= 0 do a, b = b, a % b end
  return math.abs(a)
end

-- reduce integer fraction to lowest terms; returns num, den
function ji.reduce_fraction(num, den)
  local g = ji.gcd(num, den)
  if g == 0 then return num, den end
  return num // g, den // g
end

-- given a product of integers, octave-reduce it into a fraction num/den in [1,2)
-- returns num, den (integers), and the float ratio
function ji.reduce_product(product)
  local num, den = product, 1
  while num / den >= 2 do den = den * 2 end
  while num / den < 1 do num = num * 2 end
  num, den = ji.reduce_fraction(num, den)
  return num, den, num / den
end

-- compact table of common just intervals for labelling (7- and 11-limit friendly).
-- subset adapted from pitfalls/lib/ratios.lua
ji.labels = {
  {1/1,    "1/1"},   {16/15, "m2"},  {12/11, "N2"},  {10/9,  "T2"},
  {9/8,    "M2"},    {8/7,   "S2"},  {7/6,   "s3"},  {6/5,   "m3"},
  {11/9,   "n3"},    {5/4,   "M3"},  {9/7,   "S3"},  {21/16, "s4"},
  {4/3,    "P4"},    {11/8,  "n4"},  {7/5,   "sT"},  {45/32, "A4"},
  {10/7,   "ST"},    {16/11, "N5"},  {3/2,   "P5"},  {14/9,  "s6"},
  {8/5,    "m6"},    {13/8,  "N6"},  {5/3,   "M6"},  {12/7,  "S6"},
  {7/4,    "s7"},    {16/9,  "m7"},  {9/5,   "g7"},  {11/6,  "n7"},
  {15/8,   "M7"},    {35/18, "d8"},  {2/1,   "P8"},
}

-- nearest interval label within tolerance, else formatted fraction
function ji.nearest_label(r, num, den)
  local best, bestdiff = nil, 0.01
  for _, pair in ipairs(ji.labels) do
    local diff = math.abs((pair[1] - r) / pair[1])
    if diff < bestdiff then bestdiff = diff; best = pair[2] end
  end
  if best then return best end
  if num and den then return num .. "/" .. den end
  return string.format("%.3f", r)
end

return ji
