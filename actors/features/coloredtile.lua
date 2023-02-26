local Actor = require "actor"
local Tiles = require "tiles"

local ColoredTile = Actor:extend()

ColoredTile.char = Tiles["floor"]
ColoredTile.name = "ColoredTile"

return ColoredTile