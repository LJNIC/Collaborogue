local CityGen = require "cityGen"

local function City(level)
  local map = CityGen(40, 40)
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
  spawnActor(game.Player, map._markers["player"][1].x,map._markers["player"][1].y)
  spawnActor(actors.Stairs(), map._markers["stair"][1].x,map._markers["stair"][1].y)

  return map
end

return City
