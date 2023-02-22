local Component = require "component"

local Contact = Component:extend()
Contact.name = "Contact"

function Contact:__new(options)
   self.effects = options.effects
end

function Contact:initialize(actor)
   actor.contactEffects = self.effects
   actor:addReaction(reactions.Contact)
end

return Contact
