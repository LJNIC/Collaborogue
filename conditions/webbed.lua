local Condition = require "condition"
local Vector2 = require "vector"

local Webbed = Condition:extend()
Webbed.name = "Webbed"
Webbed.description = "You cannot move!"

Webbed:onAction(actions.Move,
  function(self, level, actor, action)
    if not actor:is(actors.Webweaver) then
       action.cancelled = true
       level:addMessage("You break free from the webs!", actor)
    end
    actor:removeCondition(self)
  end
)

Webbed:onAction(actions.Attack,
  function(self, level, actor, action)
    if actor:is(actors.Webweaver) then
      actor:removeCondition(self)
    end
    action.time = action.time + 25
  end
)

return Webbed
