local Noise = require("rwg.noise")
local Biomes = require("rwg.biomes")
local Terrain = {}
local function newGrid(w, h, fill)
  local g = {}
  for y = 1, h do
    local row = {}
    for x = 1, w do row[x] = fill end
    g[y] = row
  end
  return g
end
Terrain.newGrid = newGrid
local function clamp01(v)
  if v < 0 then return 0 elseif v > 1 then return 1 end
  return v
end
local function normalise(grid, w, h)
  local lo, hi = math.huge, -math.huge
  for y = 1, h do
    local row = grid[y]
    for x = 1, w do
      local v = row[x]
      if v < lo then lo = v end
      if v > hi then hi = v end
    end
  end
  local span = hi - lo
  if span <= 0 then span = 1 end
  for y = 1, h do
    local row = grid[y]
    for x = 1, w do row[x] = (row[x] - lo) / span end
  end
end
function Terrain.generate(cfg, rng)
  local w, h = cfg.width, cfg.height
  local elevNoise = Noise.new(rng)
  local moistNoise = Noise.new(rng)
  local tempNoise = Noise.new(rng)
  local elev = newGrid(w, h, 0)
  for y = 1, h do
    local ny = (y - 1) / (h - 1) * 2 - 1
    for x = 1, w do
      local nx = (x - 1) / (w - 1) * 2 - 1
      local e = elevNoise:fbm(x * cfg.frequency, y * cfg.frequency,
        cfg.octaves, cfg.persistence, cfg.lacunarity)
      if cfg.island > 0 then
        local d = math.min(1, math.sqrt(nx * nx + ny * ny))
        e = e - cfg.island * d * d * d
      end
      elev[y][x] = e
    end
  end
  normalise(elev, w, h)
  for y = 1, h do
    local row = elev[y]
    for x = 1, w do row[x] = row[x] ^ cfg.redistribution end
  end
  local moist = newGrid(w, h, 0)
  for y = 1, h do
    for x = 1, w do
      moist[y][x] = moistNoise:fbm(x * cfg.moisture_frequency,
        y * cfg.moisture_frequency, 4, 0.5, 2.0)
    end
  end
  normalise(moist, w, h)
  local temp = newGrid(w, h, 0)
  for y = 1, h do
    local lat = math.abs((y - 1) / (h - 1) - 0.5) * 2
    local base = 1 - lat ^ 1.4
    for x = 1, w do
      local wobble = tempNoise:fbm(x * cfg.moisture_frequency,
        y * cfg.moisture_frequency, 3, 0.5, 2.0) - 0.5
      local e = elev[y][x]
      local lapse = math.max(0, e - cfg.sea_level) * 0.55
      temp[y][x] = clamp01(base * 0.85 + 0.1 + wobble * 0.3 - lapse
        + cfg.temperature_offset)
    end
  end
  local biome = newGrid(w, h, 1)
  for y = 1, h do
    for x = 1, w do
      local e = elev[y][x]
      local m = clamp01(moist[y][x] + cfg.moisture_offset
        - math.max(0, e - 0.7) * 0.5)
      moist[y][x] = m
      local id = Biomes.classify(e, temp[y][x], m, cfg.sea_level)
      biome[y][x] = Biomes.index[id]
    end
  end
  return elev, moist, temp, biome
end
return Terrain
