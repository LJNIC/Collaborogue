local Action = require "action"

local Attack = Action:extend()
Attack.name = "attack"
Attack.targets = {targets.Creature}

function Attack:__new(owner, targets, weapon)
  Action.__new(self, owner, targets)
  self.weapon = weapon or owner.wielded
  self.time = self.weapon.time or 100
  self.damageBonus = 0
  self.attackBonus = 0
  self.criticalOn = 20
end

function Attack:perform(level)
  local weapon = self.weapon
  local target = self:getTarget(1)

  --All attacks now deal stat + dmgMod
  local dmg = weapon.dmgMod + self.owner:getStatBonus(weapon.stat)

  --All attacks now have a 1/20 crit rate
  local critical = love.math.random() <= 0.05

  --All attacks now have a 0.95% hit rate
  if love.math.random() <= 0.95 then
    self.hit = true
    if critical then
      dmg = dmg * 2
    end
    local damage = target:getReaction(reactions.Damage)(target, {self.owner}, dmg)

    level:performAction(damage)
    return
  end

  level:addEffect(effects.DamageEffect(self.owner.position, target, dmg, false))
end

return Attack
