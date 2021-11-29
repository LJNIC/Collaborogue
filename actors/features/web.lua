local Actor = require "actor"
local Tiles = require "tiles"

local Web = Actor:extend()
Web.char = Tiles["web"]
Web.name = "Web"
Web.color = { 1, 1, 1, 1}

return Web
