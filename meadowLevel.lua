local MeadowGen = require "meadowGen"

local function Meadow(level)
  local Gen = MeadowGen(40, 40)
  local map = Gen:_create()
  local rooms = map._rooms

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end


  for k, v in pairs(map._markers) do
    for _, w in ipairs(v) do
      if k ~= "Player" then
        spawnActor(actors[k](), w.x, w.y)
      end
    end
  end

  for k, v in pairs(map._markers) do
    for _, w in ipairs(v) do
      if k == "Player" then
        spawnActor(game.Player, w.x, w.y)
        break
      end
    end
  end


  return map
end

return Meadow
