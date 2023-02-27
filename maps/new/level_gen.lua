--love.math.setRandomSeed(0)

-- TODO: create a actor list of name and location separate from the map so they don't collide
-- Actors can be a part of the map, and the actor list can be combined in the usual way

local Map = require "maps.map"
local Object = require "object"
local vec2 = require "vector"

local Level = Object:extend()

function Level:__new()
end

local function start()
  local room = Map:new(4, 4, 1)
  room:clearArea(1,1, room.width-1, room.height-1)

  room.map[2][2] = 'Player'

  return room
end

local function clearing()
  local width, height

  local room = Map:new(20, 20, 1)

  for x = 8, 12 do
    for y = 8, 12 do
      local cx, cy = 10, 10
      local rad = 2
      local dx = (x - cx)^2
      local dy = (y - cy)^2
      if (dx + dy) <= rad^2 then
        room.map[x][y] = 0
      end
    end
  end

  for i = 1, 100 do
    room:DLAInOut()
  end
  return room
end

local function limestone(width, height, number_of_particles)
  local room = Map:new(width, height, 100)

  local center = {x = math.floor(width/2), y = math.floor(height/2)}

  room:clearPoint(center.x, center.y)

  for i = 1, number_of_particles do
    room:DLAInOut()
  end

  return room
end

local function rect(min_width, min_height, max_width, max_height)
  local room = Map:new(love.math.random(min_width, max_width), love.math.random(min_height, max_height), 1)
  room:clearArea(1,1, room.width-1, room.height-1)
  return room
end

function Level:create()
  local map = Map:new(1000, 1000, 0)
  local rooms = {
    maps = {},
    insert = function (self, map, offset_1, offset_2)
      for k, v in pairs(self.maps) do
        v.offset = v.offset + offset_1
      end
      
      table.insert(self.maps, {map = map, offset = offset_2})
    end
  }

  local merged_room

  local room = start()
  room, offset = room:new_from_outline()
  if merged_room == nil then
    merged_room = room
    rooms:insert(room, vec2(0, 0), offset)
  else
    merged_room, offset_1, offset_2 = Map:merge_maps(merged_room, room)
    offset_2 = offset_2 + offset
    rooms:insert(merged_room, offset_1, offset_2)
  end


  for i = 1, 10 do
    local room = clearing()--rect(5, 5, 15, 15)
    room, offset = room:new_from_outline()

    if merged_room == nil then
      merged_room = room
    else
      merged_room, offset_1, offset_2 = Map:merge_maps(merged_room, room)
      offset_2 = offset_2 + offset
      rooms:insert(merged_room, offset_1, offset_2)
    end
  end

  map:copy_map_onto_self_at_position(merged_room, 0, 0)
  local heat_map = Map:new(1000, 1000, 0)
  heat_map:copy_map_onto_self_at_position(map, 0, 0)


  heat_map = heat_map:dijkstra({{x = 2+rooms.maps[1].offset.x, y = 2+rooms.maps[1].offset.y}}, 'moore')

  for i, v in ipairs(heat_map.map) do
    for i2, v2 in ipairs(v) do
      if v2 == 999 then
        --map.map[i][i2] = 1
      end
    end
  end

  do
    local room = rooms.maps[1].map.map
    local offset = rooms.maps[1].offset
    --map.map[1+offset.x][1+offset.y] = 'Glowshroom'
    for i, v in ipairs(map) do
      for i2, v2 in ipairs(v) do
        --map.map[i+offset.x][i2+offset.y] = 'Coloredtile'
      end
    end
  end

  return map, heat_map, rooms
end




return Level
