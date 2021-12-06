local Actor = require "actor"
local Condition = require "condition"
local Tiles = require "tiles"

local Web = Actor:extend()
Web.char = Tiles["web"]
Web.name = "Web"
Web.color = { 1, 1, 1, 1}

Web.components = {
   components.Contact{ effects = { conditions.Webbed() } }
}

return Web
