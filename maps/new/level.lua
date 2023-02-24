local NewGen = require "maps.new.level_gen"

local function New(level)
  local Gen = NewGen()
  local map = Gen:create()

  local function spawn_actor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function spawn_actors()
    for i, v in ipairs(map.map) do
      for i2, v2 in ipairs(v) do
        if type(v2) == 'string' then
          spawn_actor(actors[v2](), i, i2)
        end
      end
    end
  end

  spawn_actor(game.Player, 16, 16)
  spawn_actors()
  --spawnActor(game.Player, 6, 6)
  return map
end

return New
