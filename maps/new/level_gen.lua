local Map = require "maps.map"
local Object = require "object"

local Level = Object:extend()

function Level:__new()
end

function Level:create()
  local map = Map:new(100, 100, 0)

  local room_1 = Map:new(6, 6, 1)
  room_1
  :clearArea(1,1, room_1.width-1, room_1.height-1)
  :clearPoint(0,math.floor(room_1.height/2))

  local room_2 = Map:new(6, 6, 1)
  room_2
  :clearArea(1,1, room_2.width-1, room_2.height-1)
  :clearPoint(0,math.floor(room_2.height/2))
  
  local room_3 = Map:merge_maps(room_1, room_2)

  map:copy_map_onto_self_at_position(room_3, 5, 5)

  return map
end

function Map:copy_map_onto_self_at_position(map, x, y)
  for i = x, x+map.width do
    for i2 = y, y+map.height do
      self.map[i][i2] = map.map[i-x][i2-y]
    end
  end
end

function Map:merge_maps(map_1, map_2)
  local map_1_max_length = math.max(map_1.width, map_1.height)
  local map_2_max_length = math.max(map_2.width, map_2.height)
  local map_length = map_1_max_length + map_2_max_length
  local map = Map:new(map_length, map_length, 0)


  local merge_point_x = map_1.width
  local merge_point_y = 0
  map:copy_map_onto_self_at_position(map_1, 0, 0)
  map:copy_map_onto_self_at_position(map_2, merge_point_x, merge_point_y)

  return map
end

return Level
