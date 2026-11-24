local dir = (arg[0] or ""):match("^(.*)[/\\]tests[/\\][^/\\]*$") or "."
package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path
local rwg = require("rwg")
local RNG = require("rwg.rng")
local Export = require("rwg.export")
local passed, failed = 0, 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then passed = passed + 1; print("ok    " .. name)
  else failed = failed + 1; print("FAIL  " .. name .. ": " .. tostring(err)) end
end
local function check(cond, msg) if not cond then error(msg or "assertion failed", 2) end end
test("rng is deterministic", function()
  local a, b = RNG.new(42), RNG.new(42)
  for _ = 1, 100 do check(a:next() == b:next()) end
end)
test("rng floats stay in [0,1)", function()
  local r = RNG.new(7)
  for _ = 1, 10000 do local f = r:float(); check(f >= 0 and f < 1, "out of range") end
end)
test("rng int respects bounds", function()
  local r = RNG.new(99)
  for _ = 1, 10000 do local n = r:int(3, 9); check(n >= 3 and n <= 9) end
end)
test("string seeds work", function()
  check(RNG.new("hello").seed == RNG.new("hello").seed)
 check(RNG.new("hello").seed ~= RNG.new("world").seed)
end)
test("same seed gives identical world", function()
  local a = rwg.generate({ seed = 1234, width = 64, height = 48 })
  local b = rwg.generate({ seed = 1234, width = 64, height = 48 })
  check(rwg.checksum(a) == rwg.checksum(b))
end)
test("different seeds give different worlds", function()
  local a = rwg.generate({ seed = 1, width = 64, height = 48 })
  local b = rwg.generate({ seed = 2, width = 64, height = 48 })
  check(rwg.checksum(a) ~= rwg.checksum(b))
end)
test("layers stay in range", function()
  local w = rwg.generate({ seed = 5, width = 64, height = 64 })
  for y = 1, w.height do
    for x = 1, w.width do
      for _, layer in ipairs({ "elevation", "moisture", "temperature" }) do
        local v = w[layer][y][x]
        check(v >= 0 and v <= 1, layer .. " out of range")
      end
      check(w.biome[y][x] >= 1 and w.biome[y][x] <= #rwg.biomes.list)
    end
  end
end)

test("world has both land and sea", function()
  local w = rwg.generate({ seed = 77, width = 96, height = 96 })
  check(w.stats.land_fraction > 0.05 and w.stats.land_fraction < 0.95,
    "land fraction " .. w.stats.land_fraction)
end)
test("invalid settings are rejected", function()
  local w, err = rwg.generate({ bogus = 1 })
  check(w == nil and err:find("unknown setting"))
end)
test("exports produce expected shapes", function()
  local w = rwg.generate({ seed = 3, width = 16, height = 10 })
  local ppm = Export.ppmString(w, 2)
  check(ppm:sub(1, 2) == "P6")
  local header = "P6\n32 20\n255\n"
  check(#ppm == #header + 32 * 20 * 3, "ppm size " .. #ppm)
  local txt = Export.textString(w)
  local lines = 0
  for _ in txt:gmatch("[^\n]+") do lines = lines + 1 end
  check(lines == 10)
  check(Export.jsonString(w):find('"version": "0.5.0"'))
end)
print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
