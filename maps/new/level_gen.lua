local Map = require "maps.map"
local Object = require "object"

local Level = Object:extend()

function Level:__new()
end

function Level:create()
  local map = Map:new(100, 100, 0)

  local room = Map:new(5, 5, 1)
  room
  :clearArea(1,1, room.width-1, room.height-1)
  :clearSpace(math.floor(room.width/2), 0)
  

  map:mergeRoomIntoMapAtPosition(room, 5, 5)

  return map
end

function Map:createRoom()
  local room = self:new(5, 5, 1)
  room:clearArea(1,1, room.width-1, room.height-1)

  return room
end

function Map:copyRoomIntoMap(room)
  self.map = room
end

function Map:mergeRoomIntoMapAtPosition(room, x, y)
  for i = x, x+room.width do
    for i2 = y, y+room.height do
      self.map[i][i2] = room.map[i-x][i2-y]
    end
  end
end

return Level
