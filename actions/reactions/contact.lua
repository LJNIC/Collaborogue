local Reaction = require "reaction"

local Contact = Reaction:extend()

function Contact:__new(owner, target)
   self.owner = owner
   self.walker = target
end

function Contact:perform(level)
   for _, effect in ipairs(self.owner.contactEffects) do 
      print(effect.name)
      self.walker:applyCondition(effect)
   end
end

return Contact
