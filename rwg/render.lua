local Biomes = require("rwg.biomes")
local Render = {}
Render.LAYERS = { "biome", "elevation", "moisture", "temperature" }
local floor = math.floor
local function lerp(a, b, t) return a + (b - a) * t end
local function ramp(stops, t)
  if t <= stops[1][1] then
    local c = stops[1][2]
    return c[1], c[2], c[3]
  end
  for i = 2, #stops do
    local a, b = stops[i - 1], stops[i]
    if t <= b[1] then
      local k = (t - a[1]) / (b[1] - a[1])
      return lerp(a[2][1], b[2][1], k), lerp(a[2][2], b[2][2], k), lerp(a[2][3], b[2][3], k)
    end
  end
  local last = stops[#stops][2]
  return last[1], last[2], last[3]
end
local ELEV_RAMP = {
  { 0.0, { 15, 30, 80 } }, { 0.45, { 60, 110, 170 } }, { 0.46, { 90, 160, 80 } },
  { 0.65, { 160, 150, 90 } }, { 0.8, { 120, 100, 85 } }, { 1.0, { 250, 250, 250 } },
}
local MOIST_RAMP = { { 0, { 230, 215, 160 } }, { 0.5, { 110, 170, 110 } }, { 1, { 30, 80, 170 } } }
local TEMP_RAMP = { { 0, { 60, 90, 200 } }, { 0.5, { 240, 235, 140 } }, { 1, { 210, 50, 40 } } }
function Render.colorAt(world, x, y, layer)
  layer = layer or "biome"
  local r, g, b
  if layer == "elevation" then
    r, g, b = ramp(ELEV_RAMP, world.elevation[y][x])
  elseif layer == "moisture" then
    r, g, b = ramp(MOIST_RAMP, world.moisture[y][x])
  elseif layer == "temperature" then
    r, g, b = ramp(TEMP_RAMP, world.temperature[y][x])
  else
    local water = world.water[y][x]
    if water then
      local c = Biomes.water[water].color
      r, g, b = c[1], c[2], c[3]
    else
      local c = Biomes.list[world.biome[y][x]].color
      r, g, b = c[1], c[2], c[3]
      local e = world.elevation[y][x]
      if e >= world.config.sea_level then
        if world.trees[y][x] then
          r, g, b = lerp(r, 25, 0.55), lerp(g, 85, 0.55), lerp(b, 35, 0.55)
        end
        -- cheap hillshade: compare with the north-west neighbour
        local nw = world.elevation[math.max(1, y - 1)][math.max(1, x - 1)]
        local shade = 1 + math.max(-0.22, math.min(0.22, (e - nw) * 9))
        r, g, b = r * shade, g * shade, b * shade
      end
    end
  end
  r = math.max(0, math.min(255, floor(r + 0.5)))
  g = math.max(0, math.min(255, floor(g + 0.5)))
  b = math.max(0, math.min(255, floor(b + 0.5)))
  return r, g, b
end

function Render.glyphAt(world, x, y)
  local water = world.water[y][x]
  if water then return Biomes.water[water].glyph end
  if world.trees[y][x] then return "T" end
  return Biomes.list[world.biome[y][x]].glyph
end
return Render
