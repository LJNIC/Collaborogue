local MeadowGen = require "meadowGen"

local function Meadow(level)
  local map = MeadowGen(20, 20)
  local map = map:_create()

  local function spawnActor(room, actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function populateStartRoom(room)
    spawnActor(room, game.Player, 5, 5)
  end

  populateStartRoom(startRoom)

  return map
end

return Meadow
