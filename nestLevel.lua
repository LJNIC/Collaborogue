local NestGen = require "nestGen"

local function Nest(level)
  local map = NestGen(40, 40)
  local map = map:_create()

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function popDoors()
    for i, v in ipairs(map._markers["door"]) do
      spawnActor(actors.Door(), v.x,v.y)
    end
  end

  popDoors()
  spawnActor(game.Player, 20,27)
  return map
end

return Nest
