local Map = require "maps.map"
local Object = require "object"

local Level = Object:extend()

function Level:__new()
end

function Level:create()
  local map = Map:new(100, 100, 0)

  local room_1 = Map:new(6, 11, 1)
  room_1
  :clearArea(2,2, room_1.width-2, room_1.height-2)
  local room_1_outline = room_1:new_from_outline()

  local room_2 = Map:new(6, 9, 1)
  room_2
  :clearArea(2,2, room_2.width-2, room_2.height-2)
  local room_2_outline = room_2:new_from_outline()

  local room_3 = Map:merge_maps(room_1_outline, room_2_outline)


  -- I'll likely need a function to fill "holes": air tiles surrounded by wall times

  -- -------------------------------------------------------------------------- --


  map:copy_map_onto_self_at_position(room_3, 0, 0)

  return map
end




return Level
