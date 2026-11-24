-- layers on the returned world (all indexed [y][x], 1-based):
--   elevation, moisture, temperature  numbers 0..1
--   biome                             index into rwg.biomes.list
--   water                             false | "river" | "lake"
--   trees                             boolean
local RNG = require("rwg.rng")
local Config = require("rwg.config")
local Biomes = require("rwg.biomes")
local Terrain = require("rwg.terrain")
local Features = require("rwg.features")
local rwg = {
  VERSION = "0.5.0",
  rng = RNG,
  config = Config,
  biomes = Biomes,
}
function rwg.generate(options)
  options = options or {}
  local cfg, err = Config.resolve(options)
  if not cfg then return nil, err end
  if cfg.seed == nil then cfg.seed = os.time() end

  local master = RNG.new(cfg.seed)
  cfg.seed_value = master.seed
  local terrainRng = master:child()
  local lakeRng = master:child()
  local riverRng = master:child()
  local treeRng = master:child()
  local w, h = cfg.width, cfg.height
  local elev, moist, temp, biome = Terrain.generate(cfg, terrainRng)
  local world = {
    version = rwg.VERSION,
    seed = cfg.seed,
    seed_value = cfg.seed_value,
    width = w,
    height = h,
    config = cfg,
    elevation = elev,
    moisture = moist,
    temperature = temp,
    biome = biome,
    water = Terrain.newGrid(w, h, false),
    trees = Terrain.newGrid(w, h, false),
  }
  local stats = {}
  stats.lakes = Features.lakes(world, cfg, lakeRng)
  stats.rivers = Features.rivers(world, cfg, riverRng)
  stats.trees = Features.trees(world, cfg, treeRng)
  local counts, land = {}, 0
  for _, b in ipairs(Biomes.list) do counts[b.id] = 0 end
  for y = 1, h do
    for x = 1, w do
      local id = Biomes.list[world.biome[y][x]].id
      counts[id] = counts[id] + 1
      if world.elevation[y][x] >= cfg.sea_level then land = land + 1 end
    end
  end
  stats.biome_counts = counts
  stats.land_fraction = land / (w * h)
  world.stats = stats
  return world
end

function rwg.checksum(world)
  local sum = 0
  for y = 1, world.height do
    for x = 1, world.width do
      sum = (sum * 31 + world.biome[y][x]
        + (world.water[y][x] and 7 or 0)
        + (world.trees[y][x] and 3 or 0)
        + math.floor(world.elevation[y][x] * 1000)) % 2147483629
    end
  end
  return sum
end
return rwg
