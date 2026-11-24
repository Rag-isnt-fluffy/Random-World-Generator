local rwg = require("rwg")
local Export = require("rwg.export")
local Render = require("rwg.render")
local settings = { width = 192, height = 120, seed = os.time() % 1000000 }
local layer = "biome"
local world, image, imageData, message, messageTimer = nil, nil, nil, "", 0
local function rebuild()
 local w, err = rwg.generate(settings)
 if not w then message, messageTimer = err, 4 return end
 world = w
 local data = love.image.newImageData(world.width, world.height)
 for y = 1, world.height do
    for x = 1, world.width do
     local r, g, b = Render.colorAt(world, x, y, layer)
     data:setPixel(x - 1, y - 1, r / 255, g / 255, b / 255, 1)
   end
  end
 imageData = data
 image = love.graphics.newImage(data)
 image:setFilter("nearest", "nearest")
end
local function bump(key, delta, lo, hi)
 local v = (settings[key] or rwg.config.SCHEMA[key][1]) + delta
 settings[key] = math.max(lo, math.min(hi, v))
end

function love.load()
 love.graphics.setBackgroundColor(0.08, 0.09, 0.11)
 rebuild()
end

function love.keypressed(key)
 if key == "escape" then love.event.quit()
 elseif key == "space" then settings.seed = math.random(1, 2000000000); rebuild()
 elseif key == "left" then settings.seed = settings.seed - 1; rebuild()
 elseif key == "right" then settings.seed = settings.seed + 1; rebuild()
 elseif key == "up" then bump("sea_level", 0.02, 0.05, 0.9); rebuild()
 elseif key == "down" then bump("sea_level", -0.02, 0.05, 0.9); rebuild()
 elseif key == "[" then bump("river_count", -2, 0, 200); rebuild()
 elseif key == "]" then bump("river_count", 2, 0, 200); rebuild()
 elseif key >= "1" and key <= "4" then layer = Render.LAYERS[tonumber(key)]; rebuild()
 elseif key == "e" then
   local base = "world_" .. world.seed_value
   love.filesystem.write(base .. ".json", Export.jsonString(world))
   love.filesystem.write(base .. ".ppm", Export.ppmString(world, 4, layer))
   imageData:encode("png", base .. ".png")
   message = "Exported to " .. love.filesystem.getSaveDirectory() .. "/" .. base .. ".*"
   messageTimer = 5
  end
end

function love.update(dt)
 if messageTimer > 0 then messageTimer = messageTimer - dt end
end

function love.draw()
 local ww, wh = love.graphics.getDimensions()
 if image then
   local scale = math.min(ww / world.width, (wh - 60) / world.height)
   scale = math.max(1, math.floor(scale))
   local ox = math.floor((ww - world.width * scale) / 2)
   love.graphics.setColor(1, 1, 1)
   love.graphics.draw(image, ox, 8, 0, scale, scale)
  end
  love.graphics.setColor(0.9, 0.9, 0.9)
 local s = world and world.stats
 love.graphics.print(string.format(
   "v%s  seed %d  layer %s  sea %.2f  land %.0f%%  rivers %d  lakes %d   [space] new  [</>] seed  [1-4] layer  [up/down] sea  [E] export",
   rwg.VERSION, world.seed_value, layer, world.config.sea_level,
   s.land_fraction * 100, s.rivers, s.lakes), 8, wh - 40)
 if messageTimer > 0 then
   love.graphics.setColor(1, 0.9, 0.5)
   love.graphics.print(message, 8, wh - 22)
 end
end
