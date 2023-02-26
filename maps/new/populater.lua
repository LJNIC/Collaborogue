local NewGen = require "maps.new.level_gen"

local function New(level)
  local Gen = NewGen()
  local map, heat_map = Gen:create()

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

  local function draw_heat_map()
    for i, v in ipairs(heat_map.map) do
      for i2, v2 in ipairs(v) do
        if v2 ~= 999 then
          local custom = {
            color = {
              love.math.random(0,255)/255,
              love.math.random(0,255)/255,
              love.math.random(0,255)/255,
              1
            }
          }
          local coloredtile = actors.Coloredtile(custom)
          spawn_actor(coloredtile, i, i2)
        end
      end
    end
  end

  --local coloredtile = actors.Coloredtile()
  --coloredtile.color[1] = 1
  --spawn_actor(coloredtile, 3, 3)

  draw_heat_map()
  spawn_actor(game.Player, 3, 3)


  spawn_actors()

  return map
end

return New
