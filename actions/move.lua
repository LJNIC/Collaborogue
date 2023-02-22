local Action = require "action"

local MoveAction = Action:extend()
MoveAction.name = "move"

function MoveAction:__new(owner, direction)
  Action.__new(self, owner)
  self.direction = direction
end

function MoveAction:perform(level)
  local newPosition = self.owner.position + self.direction
  local passable, atPosition = level:getCellPassable(newPosition.x, newPosition.y) 

  if passable then
    level:moveActor(self.owner, newPosition)

    for _, actor in ipairs(atPosition) do
      if actor:hasComponent(components.Contact) then
        level:performAction(actor:getReaction(reactions.Contact)(actor, self.owner))
      end
    end
  end
end

return MoveAction
