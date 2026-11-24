#!/usr/bin/env lua

local script_dir = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
package.path = script_dir .. "/?.lua;" .. script_dir .. "/?/init.lua;" .. package.path

local rwg = require("rwg")
local Export = require("rwg.export")
local Render = require("rwg.render")
local Biomes = require("rwg.biomes")

local function usage()
  print(([[
Random World Generator

Usage: lua cli.lua [options]

Output options:
  --seed N|text          Seed (number or any text). Default: current time.
  --format LIST          Comma list of: %s   (default: ppm)
  --out PREFIX           Output file prefix (default: world)
  --scale N              Pixels per tile in ppm/pgm images (default: 4)
  --layer NAME           Image layer: %s (default: biome)
  --preview              Print an ASCII preview to the terminal
  --no-export            Generate only (use with --preview / --stats)
  --stats                Print biome statistics
  --list-biomes          List biomes and exit
  --version, --help

Generation settings:
%s]]):format(rwg.VERSION, table.concat(Export.formats, ", "),
   table.concat(Render.LAYERS, ", "), rwg.config.describe()))
end

local FLAGS = { preview = true, stats = true, help = true, version = true,
 ["no-export"] = true, ["list-biomes"] = true }
local opts, settings = {}, {}
local special = { format = true, out = true, scale = true, layer = true }

local i = 1
while i <= #arg do
 local a = arg[i]
 local key, val = a:match("^%-%-([%w%-_]+)=(.*)$")
 if not key then key = a:match("^%-%-([%w%-_]+)$") end
 if not key then
   io.stderr:write("Unexpected argument: " .. a .. "\n")
   os.exit(2)
 end
  if FLAGS[key] then
  opts[key] = true
 else
   if val == nil then
     i = i + 1
     val = arg[i]
     if val == nil then
      io.stderr:write("Missing value for --" .. key .. "\n")
       os.exit(2)
      end
    end
    if special[key] then
     opts[key] = val
    else
     settings[(key:gsub("%-", "_"))] = (key == "seed") and (tonumber(val) or val) or val
    end
  end
 i = i + 1
end

if opts.help then usage() os.exit(0) end
if opts.version then print("Random World Generator v" .. rwg.VERSION) os.exit(0) end
if opts["list-biomes"] then
 for n, b in ipairs(Biomes.list) do
   print(string.format("%2d  %-11s  glyph '%s'  rgb(%d,%d,%d)", n, b.id, b.glyph,
     b.color[1], b.color[2], b.color[3]))
 end
 os.exit(0)
end

local world, err = rwg.generate(settings)
if not world then
  io.stderr:write("Error: " .. err .. "\n")
  os.exit(1)
end

print(string.format("Random World Generator v%s", rwg.VERSION))
print(string.format("Seed: %d  (re-use with --seed %d)  Size: %dx%d",
  world.seed_value, world.seed_value, world.width, world.height))

if opts.preview then
  io.write(Export.textString(world))
end

if opts.stats or opts.preview then
  local s = world.stats
  print(string.format("Land: %.1f%%  Rivers: %d  Lakes: %d  Trees: %d",
    s.land_fraction * 100, s.rivers, s.lakes, s.trees))
  if opts.stats then
    for _, b in ipairs(Biomes.list) do
      local c = s.biome_counts[b.id]
      if c > 0 then
        print(string.format("  %-11s %6d  %5.1f%%", b.id, c,
          c / (world.width * world.height) * 100))
      end
    end
  end
end

if not opts["no-export"] then
  local prefix = opts.out or "world"
  local scale = tonumber(opts.scale) or 4
  local layer = opts.layer or "biome"
  local valid = false
  for _, l in ipairs(Render.LAYERS) do if l == layer then valid = true end end
  if not valid then
    io.stderr:write("Unknown layer '" .. layer .. "'\n")
    os.exit(1)
  end
  for fmt in (opts.format or "ppm"):gmatch("[^,%s]+") do
    local path, e = Export.save(world, prefix, fmt:lower(), { scale = scale, layer = layer })
    if path then
      print("Wrote " .. path)
    else
      io.stderr:write("Export failed: " .. tostring(e) .. "\n")
      os.exit(1)
    end
  end
end
