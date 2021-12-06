local Action = require "action"
local Tiles = require "tiles"
local Vector2 = require "vector"

local Web = Action:extend()
Web.name = "web"
Web.targets = {targets.Creature}

local function spawnWeb(level, position)
  local web = actors.Web()
  web.position.x = position.x
  web.position.y = position.y
  level:addActor(web)
end

function Web:perform(level)
  local creature = self.targetActors[1]
  creature:applyCondition(conditions.Webbed)
  level:addEffect(effects.CharacterDynamic(creature, 0, 0, Tiles["web"], {1, 1, 1}, .5))

  spawnWeb(level, creature.position)
  spawnWeb(level, creature.position + Vector2.UP)
  spawnWeb(level, creature.position + Vector2.DOWN)
  spawnWeb(level, creature.position + Vector2.RIGHT)
  spawnWeb(level, creature.position + Vector2.LEFT)
end

return Web
