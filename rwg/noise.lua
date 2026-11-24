local Noise = {}
Noise.__index = Noise
local GRADIENTS = {
  { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
  { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
}
local floor = math.floor

local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end
local function lerp(a, b, t) return a + (b - a) * t end

local function grad(h, x, y)
  local g = GRADIENTS[h % 8 + 1]
  return g[1] * x + g[2] * y
end
function Noise.new(rng)
  local p = {}
  for i = 1, 256 do p[i] = i - 1 end
  rng:shuffle(p)
  local perm = {}
  for i = 1, 512 do perm[i] = p[(i - 1) % 256 + 1] end
  return setmetatable({
    perm = perm,
    ox = rng:float() * 1000
    oy = rng:float() * 1000,
  }, Noise)
end
function Noise:perlin(x, y)
  x, y = x + self.ox, y + self.oy
  local xf, yf = floor(x), floor(y)
  local fx, fy = x - xf, y - yf
  local xi, yi = xf % 256, yf % 256
  local perm = self.perm
  local aa = perm[perm[xi + 1] + yi + 1]
  local ab = perm[perm[xi + 1] + yi + 2]
  local ba = perm[perm[xi + 2] + yi + 1]
  local bb = perm[perm[xi + 2] + yi + 2]
  local u, v = fade(fx), fade(fy)
  local x1 = lerp(grad(aa, fx, fy), grad(ba, fx - 1, fy), u)
  local x2 = lerp(grad(ab, fx, fy - 1), grad(bb, fx - 1, fy - 1), u)
  return lerp(x1, x2, v)
end
function Noise:fbm(x, y, octaves, persistence, lacunarity)
  local amp, freq, sum, norm = 1, 1, 0, 0
  for _ = 1, octaves do
    sum = sum + self:perlin(x * freq, y * freq) * amp
    norm = norm + amp
    amp = amp * persistence
    freq = freq * lacunarity
  end
  local v = (sum / norm + 1) / 2
  if v < 0 then v = 0 elseif v > 1 then v = 1 end
  return v
end
return Noise
