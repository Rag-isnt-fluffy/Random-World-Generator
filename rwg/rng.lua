local RNG = {}
RNG.__index = RNG
local M = 2147483647
local A = 48271
RNG.MODULUS = M
function RNG.normalizeSeed(seed)
  if type(seed) == "string" then
    local h = 5381
    for i = 1, #seed do
      h = (h * 33 + seed:byte(i)) % M
    end
    seed = h
  end
  seed = tonumber(seed) or 0
  seed = math.floor(math.abs(seed)) % (M - 1)
  return seed + 1
end
function RNG.new(seed)
  local self = setmetatable({}, RNG)
  self.seed = RNG.normalizeSeed(seed)
  self.state = self.seed
  for _ = 1, 8 do self:next() end
  return self
end
function RNG:next()
  self.state = (self.state * A) % M
  return self.state
end
function RNG:float()
  return (self:next() - 1) / (M - 1)
end
function RNG:int(a, b)
  return a + math.floor(self:float() * (b - a + 1))
end
function RNG:chance(p)
  return self:float() < p
end
function RNG:shuffle(t)
  for i = #t, 2, -1 do
    local j = self:int(1, i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end
function RNG:child()
  return RNG.new(self:int(1, M - 1))
end
return RNG
