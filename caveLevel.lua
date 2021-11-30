local CaveGen = require "caveGen"

local function Cave(level)
  local map = CaveGen(40, 40)
  local map = map:_create()

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function popWebs()
    for i, v in ipairs(map._markers["web"]) do
      spawnActor(actors.Web(), v.x,v.y)
    end
  end

  popWebs()


  spawnActor(game.Player, map._markers["player"][1].x,map._markers["player"][1].y)
  spawnActor(actors.Stairs(), map._markers["stair"][1].x,map._markers["stair"][1].y)
  return map
end

return Cave
