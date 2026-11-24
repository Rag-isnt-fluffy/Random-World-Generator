local Noise = require("rwg.noise")
local Biomes = require("rwg.biomes")
local Terrain = require("rwg.terrain")
local Features = {}
local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
function Features.lakes(world, cfg, rng)
  local w, h, elev, water = cfg.width, cfg.height, world.elevation, world.water
  local sea = cfg.sea_level
  local made = 0
  for _ = 1, cfg.lake_count do
    for _ = 1, 60 do -- attempts per lake
      local sx, sy = rng:int(2, w - 1), rng:int(2, h - 1)
      local base = elev[sy][sx]
      if not water[sy][sx] and base > sea + 0.03 and base < sea + 0.2 then
        local target = rng:int(6, 30)
        local cells, seen, queue = {}, {}, { { sx, sy } }
        seen[(sy - 1) * w + sx] = true
        local head = 1
        while head <= #queue and #cells < target do
          local c = queue[head]
          head = head + 1
          cells[#cells + 1] = c
          for _, d in ipairs(DIRS) do
            local nx, ny = c[1] + d[1], c[2] + d[2]
            if nx >= 1 and nx <= w and ny >= 1 and ny <= h then
              local k = (ny - 1) * w + nx
              if not seen[k] and not water[ny][nx]
                  and elev[ny][nx] > sea and elev[ny][nx] <= base + 0.04 then
                seen[k] = true
                queue[#queue + 1] = { nx, ny }
              end
            end
          end
        end
        if #cells >= 4 then
          for _, c in ipairs(cells) do water[c[2]][c[1]] = "lake" end
          made = made + 1
          break
        end
      end
    end
  end
  return made
end
function Features.rivers(world, cfg, rng)
  local w, h, elev, water = cfg.width, cfg.height, world.elevation, world.water
  local sea = cfg.sea_level
  local minSource = math.max(sea + 0.15, 0.6)
  local sources = {}
  for y = 2, h - 1 do
    for x = 2, w - 1 do
      if elev[y][x] >= minSource and not water[y][x] then
        sources[#sources + 1] = { x, y }
      end
    end
  end
  rng:shuffle(sources)
  local made, tries = 0, 0
  local maxTries = cfg.river_count * 20
  local si = 1
  while made < cfg.river_count and tries < maxTries and si <= #sources do
    tries = tries + 1
    local src = sources[si]
    si = si + 1
    local x, y = src[1], src[2]
    local path, visited, uphill, outcome = {}, {}, 0, "stuck"
    for _ = 1, w * h do
      visited[(y - 1) * w + x] = true
      if elev[y][x] < sea then outcome = "sea"; break end
      if water[y][x] then outcome = "merge"; break end
      path[#path + 1] = { x, y }
      if x <= 1 or y <= 1 or x >= w or y >= h then outcome = "edge"; break end
      local bx, by, bscore
      for _, d in ipairs(DIRS) do
        local nx, ny = x + d[1], y + d[2]
        if not visited[(ny - 1) * w + nx] then
          local score = elev[ny][nx] + rng:float() * cfg.river_meander
          if not bscore or score < bscore then bx, by, bscore = nx, ny, score end
        end
      end
      if not bx then outcome = "stuck"; break end
      if elev[by][bx] > elev[y][x] then
        uphill = uphill + 1
        if uphill > 6 then outcome = "pit"; break end
      end
      x, y = bx, by
    end
    if #path >= cfg.river_min_length then
      for _, c in ipairs(path) do water[c[2]][c[1]] = "river" end
      if outcome == "pit" or outcome == "stuck" then
        local end_ = path[#path]
        local ex, ey = end_[1], end_[2]
        water[ey][ex] = "lake"
        for _, d in ipairs(DIRS) do
          local nx, ny = ex + d[1], ey + d[2]
          if nx >= 1 and nx <= w and ny >= 1 and ny <= h
              and elev[ny][nx] >= sea then
            water[ny][nx] = "lake"
          end
        end
      end
      made = made + 1
    end
  end
  return made
end
-- Probably comes from the biome
function Features.trees(world, cfg, rng)
  local w, h = cfg.width, cfg.height
  local clump = Noise.new(rng)
  local count = 0
  for y = 1, h do
    for x = 1, w do
      if not world.water[y][x] then
        local id = Biomes.list[world.biome[y][x]].id
        local base = Biomes.tree_density[id]
        if base then
          local c = clump:fbm(x * 0.12, y * 0.12, 3, 0.5, 2.0)
          local p = base * cfg.tree_density * (0.3 + 1.4 * c)
          if rng:float() < p then
            world.trees[y][x] = true
            count = count + 1
          end
        end
      end
    end
  end
  return count
end
return Features
