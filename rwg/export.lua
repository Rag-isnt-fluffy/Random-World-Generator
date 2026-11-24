local Biomes = require("rwg.biomes")
local Render = require("rwg.render")
local Export = {}
local char = string.char
local concat = table.concat
local function num(v)
  return (string.format("%.4f", v):gsub(",", "."))
end
local function writeFile(path, data)
  local f, err = io.open(path, "wb")
  if not f then return nil, err end
  f:write(data)
  f:close()
  return true
end
function Export.ppmString(world, scale, layer)
  scale = math.max(1, math.floor(scale or 1))
  local w, h = world.width, world.height
  local out = { string.format("P6\n%d %d\n255\n", w * scale, h * scale) }
  for y = 1, h do
    local row = {}
    for x = 1, w do
      local r, g, b = Render.colorAt(world, x, y, layer)
      local px = char(r, g, b)
      for _ = 1, scale do row[#row + 1] = px end
    end
    local line = concat(row)
    for _ = 1, scale do out[#out + 1] = line end
  end
  return concat(out)
end
function Export.pgmString(world, scale)
  scale = math.max(1, math.floor(scale or 1))
  local w, h = world.width, world.height
  local out = { string.format("P5\n%d %d\n255\n", w * scale, h * scale) }
  for y = 1, h do
    local row = {}
    for x = 1, w do
      local v = math.floor(world.elevation[y][x] * 255 + 0.5)
      local px = char(v)
      for _ = 1, scale do row[#row + 1] = px end
    end
    local line = concat(row)
    for _ = 1, scale do out[#out + 1] = line end
  end
  return concat(out)
end
function Export.textString(world)
  local lines = {}
  for y = 1, world.height do
    local row = {}
    for x = 1, world.width do row[x] = Render.glyphAt(world, x, y) end
    lines[y] = concat(row)
  end
  return concat(lines, "\n") .. "\n"
end
function Export.csvString(world)
  local out = { "x,y,elevation,moisture,temperature,biome,water,tree" }
  for y = 1, world.height do
    for x = 1, world.width do
      out[#out + 1] = string.format("%d,%d,%s,%s,%s,%s,%s,%d",
        x - 1, y - 1,
        num(world.elevation[y][x]), num(world.moisture[y][x]),
        num(world.temperature[y][x]),
        Biomes.list[world.biome[y][x]].id,
        world.water[y][x] or "none",
        world.trees[y][x] and 1 or 0)
    end
  end
  return concat(out, "\n") .. "\n"
end
local function jsonGrid(grid, w, h, cell)
  local rows = {}
  for y = 1, h do
    local r = {}
    for x = 1, w do r[x] = cell(grid[y][x]) end
    rows[y] = "[" .. concat(r, ",") .. "]"
  end
  return "[" .. concat(rows, ",\n    ") .. "]"
end
function Export.jsonString(world)
  local cfg = world.config
  local legend = {}
  for i, b in ipairs(Biomes.list) do
    legend[i] = string.format('"%s"', b.id)
  end
  local settings = {}
  for _, k in ipairs(require("rwg.config").KEYS) do
    local v = num(cfg[k]):gsub("%.?0+$", "")
    settings[#settings + 1] = string.format('"%s": %s', k, v)
  end
  local w, h = world.width, world.height
  local function n(v) return num(v) end
  local parts = {
    "{",
    string.format('  "generator": "random-world-generator",\n  "version": "%s",', world.version),
    string.format('  "seed": %d,', world.seed_value),
    string.format('  "width": %d,\n  "height": %d,', w, h),
    '  "settings": {' .. concat(settings, ", ") .. "},",
    '  "biome_legend": [' .. concat(legend, ", ") .. "],",
    '  "elevation": ' .. jsonGrid(world.elevation, w, h, n) .. ",",
    '  "moisture": ' .. jsonGrid(world.moisture, w, h, n) .. ",",
    '  "temperature": ' .. jsonGrid(world.temperature, w, h, n) .. ",",
    '  "biome": ' .. jsonGrid(world.biome, w, h, tostring) .. ",",
    '  "water": ' .. jsonGrid(world.water, w, h, function(v)
      return v and ('"' .. v .. '"') or "null"
    end) .. ",",
    '  "trees": ' .. jsonGrid(world.trees, w, h, function(v) return v and "1" or "0" end),
    "}",
  }
  return concat(parts, "\n") .. "\n"
end
local FORMATS = {
  ppm  = function(world, o) return Export.ppmString(world, o.scale, o.layer) end,
  pgm  = function(world, o) return Export.pgmString(world, o.scale) end,
  txt  = function(world) return Export.textString(world) end,
  csv  = function(world) return Export.csvString(world) end,
  json = function(world) return Export.jsonString(world) end,
}
Export.formats = { "ppm", "pgm", "txt", "csv", "json" }
function Export.save(world, basePath, format, opts)
  local make = FORMATS[format]
  if not make then return nil, "unknown format '" .. tostring(format) .. "'" end
  local path = basePath .. "." .. format
  local ok, err = writeFile(path, make(world, opts or {}))
  if not ok then return nil, err end
  return path
end
return Export
