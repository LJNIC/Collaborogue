local Map = require "maps.map"
local Object = require "object"

local Level = Object:extend()

function Level:__new()
end

function Level:create()
  local map = Map:new(100, 100, 0)

  local room_1 = Map:new(5, 5, 1)
  room_1
  :clearArea(1,1, room_1.width-1, room_1.height-1)

  local room_2 = Map:new(5, 5, 1)
  room_2
  :clearArea(1,1, room_2.width-1, room_2.height-1)
  
  local room_3 = Map:merge_maps(room_1, room_2)

  map:merge_room_into_map_at_position(room_3, 5, 5)

  return map
end

function Map:createRoom()
  local room = self:new(5, 5, 1)
  room:clearArea(1,1, room.width-1, room.height-1)

  return room
end

function Map:merge_room_into_map_at_position(room, x, y)
  for i = x, x+room.width do
    for i2 = y, y+room.height do
      self.map[i][i2] = room.map[i-x][i2-y]
    end
  end
end

function Map:merge_maps(map_1, map_2)
  local map_1_max_length = math.max(map_1.width, map_1.height)
  local map_2_max_length = math.max(map_2.width, map_2.height)
  local map_length = map_1_max_length + map_2_max_length

  local map = Map:new(map_length, map_length, 0)

  local min_x, max_x = 0, map_1.width
  local min_y, max_y = 0, map_1.height
  for i = min_x, max_x do
    for i2 = min_y, max_y do
      map.map[i][i2] = map_1.map[i][i2]
    end
  end

  local min_x, max_x = map_1.width, map_1.width+map_2.width
  local min_y, max_y = map_1.height, map_1.height+map_2.height
  for i = min_x, max_x do
    for i2 = min_y, max_y do
      map.map[i][i2] = map_2.map[i-min_x][i2-min_y]
    end
  end

  return map
end

return Level
