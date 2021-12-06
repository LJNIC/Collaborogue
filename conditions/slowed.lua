local Condition = require "condition"

local Slowed = Condition:extend()
Slowed.name = "Slowed"
Slowed.description = "Your movement is 100 slower. Your attacks are 25 slower."

Slowed:onAction(actions.Move,
  function(self, level, actor, action)
    if actor:rollCheck("PR") >= 13 then
      actor:removeCondition(self)
    else
      action.time = action.time + 125
    end
  end
)

Slowed:onAction(actions.Attack,
  function(self, level, actor, action)
    action.time = action.time + 25
  end
)

return Slowed
