local NewGen = require "maps.level_gen"

local function New(level)
  local Gen = NewGen(100, 100)
  local map = Gen:create()

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  for k, v in pairs(map.markers) do
    for _, w in ipairs(v) do
      if k ~= "Player" then
        spawnActor(actors[k](), w.x, w.y)
      end
    end
  end

  for k, v in pairs(map.markers) do
    for _, w in ipairs(v) do
      if k == "Player" then
        spawnActor(game.Player, w.x, w.y)
        break
      end
    end
  end

  spawnActor(game.Player, 15, 15)
  return map
end

return New
