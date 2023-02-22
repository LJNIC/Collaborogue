local Actor = require "actor"
local Action = require "action"
local Tiles = require "tiles"
local Condition = require "condition"

local Read = actions.Read:extend()
Read.name = "read"
Read.targets = {targets.Item}

local Scrying = Condition:extend()
Scrying.name = "Scrying"
Scrying.damage = 1

Scrying:onScry(
  function(self, level, actor)
    local scryed = {}
    for actor in level:eachActor() do
      table.insert(scryed, actor)
    end

    return scryed
  end
)

function Read:perform(level)
  actions.Read.perform(self, level)

  self.owner:applyCondition(Scrying())

  for x = 1, level.width do
    for y = 1, level.height do
      if not self.owner.explored[x] then self.owner.explored[x] = {} end
      self.owner.explored[x][y] = level.map[x][y]
    end
  end
end

local Scroll = Actor:extend()
Scroll.name = "Scroll of Allsight"
Scroll.color = {0.8, 0.8, 0.8, 1}
Scroll.char = Tiles["scroll"]

Scroll.components = {
  components.Item(),
  components.Usable(),
  components.Readable{read = Read},
  components.Cost()
}

return Scroll
