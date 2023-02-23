local NewGen = require "maps.new.level_gen"

local function New(level)
  local Gen = NewGen()
  local map = Gen:create()

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  spawnActor(game.Player, 8, 8)
  --spawnActor(game.Player, 6, 6)
  return map
end

return New
