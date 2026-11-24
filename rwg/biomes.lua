local Biomes = {}

Biomes.list = {
  { id = "deep_ocean", color = { 20, 40, 95 },     glyph = "~" },
  { id = "ocean",      color = { 35, 75, 140 },    glyph = "-" },
  { id = "beach",      color = { 222, 205, 150 },  glyph = "." },
  { id = "desert",     color = { 219, 190, 120 },  glyph = ":" },
  { id = "steppe",     color = { 170, 170, 100 },  glyph = "," },
  { id = "savanna",    color = { 185, 180, 85 },   glyph = "'" },
  { id = "grassland",  color = { 110, 170, 75 },   glyph = '"' },
  { id = "forest",     color = { 50, 125, 55 },    glyph = "f" },
  { id = "rainforest", color = { 20, 100, 60 },    glyph = "F" },
  { id = "swamp",      color = { 70, 100, 70 },    glyph = "%" },
  { id = "taiga",      color = { 70, 110, 95 },    glyph = "t" },
  { id = "tundra",     color = { 150, 160, 145 },  glyph = "_" },
  { id = "snow",       color = { 240, 244, 250 },  glyph = "*" },
  { id = "mountain",   color = { 120, 115, 110 },  glyph = "^" },
  { id = "snow_peak",  color = { 250, 250, 255 },  glyph = "A" },
}
Biomes.index = {}
Biomes.byId = {}
for i, b in ipairs(Biomes.list) do
  Biomes.index[b.id] = i
  Biomes.byId[b.id] = b
end
Biomes.water = {
  river = { color = { 60, 120, 200 }, glyph = "=" },
  lake  = { color = { 50, 100, 180 }, glyph = "o" },
}
Biomes.tree_density = {
  forest = 0.55, rainforest = 0.80, taiga = 0.45, swamp = 0.25,
  grassland = 0.05, savanna = 0.04, steppe = 0.01, tundra = 0.01,
}
function Biomes.classify(e, t, m, sea)
  if e < sea - 0.12 then return "deep_ocean" end
  if e < sea then return "ocean" end
  if e < sea + 0.025 then return "beach" end
  if e > 0.86 then return "snow_peak" end
  if e > 0.74 then
    if t < 0.45 then return "snow" end
    return "mountain"
  end
  if t < 0.2 then
    if m < 0.4 then return "tundra" end
    return "snow"
  elseif t < 0.4 then
    if m < 0.25 then return "steppe" end
    return "taiga"
  elseif t < 0.7 then
    if m < 0.2 then return "steppe" end
    if m < 0.5 then return "grassland" end
    if m < 0.8 then return "forest" end
    return (e < sea + 0.08) and "swamp" or "forest"
  else
    if m < 0.25 then return "desert" end
    if m < 0.5 then return "savanna" end
    if m < 0.75 then return "forest" end
    return "rainforest"
  end
end
return Biomes
