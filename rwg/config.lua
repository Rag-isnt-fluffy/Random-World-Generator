local Config = {}
local SCHEMA = {
  width              = { 128,  8,    2048, "World width in tiles" },
  height             = { 128,  8,    2048, "World height in tiles" },
  frequency          = { 0.02, 0.002, 0.5,  "Terrain feature frequency (higher = smaller landmasses)" },
  octaves            = { 5,    1,    10,   "Noise detail layers" },
  persistence        = { 0.5,  0.1,  0.9,  "How strongly higher octaves contribute" },
  lacunarity         = { 2.0,  1.2,  4.0,  "Frequency multiplier between octaves" },
  redistribution     = { 1.3,  0.4,  4.0,  "Elevation exponent (higher = flatter lowlands, sharper peaks)" },
  sea_level          = { 0.45, 0.05, 0.9,  "Elevation below which tiles are ocean (0-1)" },
  island             = { 0.0,  0.0,  1.0,  "Island falloff strength; 0 = continents, 1 = one island" },
  temperature_offset = { 0.0, -0.5,  0.5,  "Shift climate colder (-) or hotter (+)" },
  moisture_offset    = { 0.0, -0.5,  0.5,  "Shift climate drier (-) or wetter (+)" },
  moisture_frequency = { 0.03, 0.002, 0.5, "Frequency of the moisture noise" },
  river_count        = { 8,    0,    200,  "Number of rivers to attempt" },
  river_meander      = { 0.02, 0.0,  0.2,  "Random wobble applied to river paths" },
  river_min_length   = { 8,    2,    200,  "Rivers shorter than this are discarded" },
  lake_count         = { 6,    0,    200,  "Number of lakes to attempt" },
  tree_density       = { 1.0,  0.0,  3.0,  "Multiplier for tree coverage" },
}
local ORDER = {}
for k in pairs(SCHEMA) do ORDER[#ORDER + 1] = k end
table.sort(ORDER)
Config.SCHEMA = SCHEMA
Config.KEYS = ORDER
function Config.resolve(user)
  local cfg = {}
  for k, def in pairs(SCHEMA) do cfg[k] = def[1] end
  cfg.seed = nil
  for k, v in pairs(user or {}) do
    if k == "seed" then
      cfg.seed = v
    else
      local def = SCHEMA[k]
      if not def then
        return nil, "unknown setting '" .. tostring(k) .. "'"
      end
      v = tonumber(v)
      if not v then
        return nil, "setting '" .. k .. "' must be a number"
      end
      if v < def[2] then v = def[2] elseif v > def[3] then v = def[3] end
      cfg[k] = v
    end
  end
  cfg.width = math.floor(cfg.width)
  cfg.height = math.floor(cfg.height)
  cfg.octaves = math.floor(cfg.octaves)
  cfg.river_count = math.floor(cfg.river_count)
  cfg.lake_count = math.floor(cfg.lake_count)
  cfg.river_min_length = math.floor(cfg.river_min_length)
  return cfg
end
function Config.describe()
  local lines = {}
  for _, k in ipairs(ORDER) do
    local d = SCHEMA[k]
    lines[#lines + 1] = string.format("  --%-20s default %-6s %s",
      (k:gsub("_", "-")), tostring(d[1]), d[4])
  end
  return table.concat(lines, "\n")
end
return Config
