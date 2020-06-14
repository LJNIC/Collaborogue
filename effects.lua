local Tiles = require "tiles"

local effects = {}

effects.HealEffect = function(actor, heal)
  local t = 0
  local lastflip = 9
  return function(dt, interface)
    t = t + dt

    local color = {.1, 1, .1, 1}
    interface:write(Tiles["heal"], actor.position.x, actor.position.y, color)
    interface:write(tostring(heal), actor.position.x + 1, actor.position.y, color)
    if t > .4 then return true end
  end
end

effects.PoisonEffect = function(actor, damage)
  local t = 0
  return function(dt, interface)
    t = t + dt

    local color = {.1, .7, .1, 1}
    interface:write(Tiles["pointy_poof"], actor.position.x, actor.position.y, color)
    interface:write(tostring(damage), actor.position.x + 1, actor.position.y, color)
    if t > .2 then return true end
  end
end

local function cmul(c1, s)
  return {c1[1] * s, c1[2] * s, c1[3] * s}
end

effects.OpenEffect = function(actor)
  local t = 0
  local lastflip = 9
  return function(dt, interface)
    t = t + dt

    local color = {1, 1, .1, 1}
    if t < .5 then
      local c = cmul(color, t / 0.5)
      interface:write(Tiles["pointy_poof"], actor.position.x, actor.position.y, c)
    elseif t < .8 then
      interface:write(Tiles["chest_open"], actor.position.x, actor.position.y, actor.color)
    else
      return true
    end
  end
end

return effects
