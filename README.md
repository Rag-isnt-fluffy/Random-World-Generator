# Random World Generator (draft)
A Lua-based procedural world generator that creates randomly generated maps from configurable settings

## to run
```sh
lua cli.lua --seed 12345 --width 100 --height 40 --preview --stats --no-export

# Export a 200x120 world as an image and JSON
lua cli.lua --seed 12345 --width 200 --height 120 --format ppm,json --out myworld
# scale
lua cli.lua --seed hello --layer elevation --scale 6 --out heightmap
```

Run `lua cli.lua --help` for every option. Seeds can be numbers or any text (`--seed "my world"`).

```lua
local rwg = require("rwg")
local world = rwg.generate({ seed = 42, width = 200, height = 120, sea_level = 0.5 })

local biomeId = rwg.biomes.list[world.biome[10][20]].id  -- layers are [y][x], 1-based
print(world.elevation[10][20], biomeId, world.water[10][20], world.trees[10][20])
```

##  settings
# run with ```--[setting] [value]
width, height        128    world size in tiles
frequency            0.02   higher = smaller landmasses
octaves              5      noise detail layers
persistence          0.5    contribution of higher octaves
lacunarity           2.0    frequency multiplier per octave
redistribution       1.3    elevation exponent (flatter lowlands, sharper peaks)
sea_level            0.45   ocean threshold (0-1)
island               0.0    0 = continents, 1 = single island
temperature_offset   0.0    colder (-) or hotter (+)
moisture_offset      0.0    drier (-) or wetter (+)
moisture_frequency   0.03   frequency of moisture noise
river_count          8      rivers to attempt
river_meander        0.02   random wobble of rivers
river_min_length     8      shorter rivers are discarded
lake_count           6      lakes to attempt
tree_density         1.0    tree coverage multiplier

## Love2D viewer

```sh
love .
```
Space = new seed, Left/Right = seed -/+ 1, 1-4 = layer, Up/Down = sea level, `[`/`]` = rivers, E = export PNG/JSON/PPM to the Love save folder.
## Status
This is a **draft**.
