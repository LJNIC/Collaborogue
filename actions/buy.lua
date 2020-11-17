local Action = require "action"

local Buy = Action:extend()
Buy.name = "buy"
Buy.targets = {targetProduct}

function Buy:__new(owner, targets)
  Action.__new(self, owner, targets)
  local product = self.targetActors[1]
  self.price = product.price
end

function Buy:perform(level)
  local product = self.targetActors[1]
  if self.owner:withdraw(product.currency, self.price) then
    level:performAction(self.owner:getAction(actions.Pickup)(self.owner, product.item), true)
    level:removeActor(product)
    if product.shopkeep then
      level:addEffect(product.soldEffect())
    end
  elseif product.shopkeep then
    level:addEffect(product.notSoldEffect())
  end
end

return Buy
