--love.math.setRandomSeed(0)
local Map = require "maps.map"
local Object = require "object"

local Level = Object:extend()

function Level:__new()
end

function Level:create()
  local map = Map:new(1000, 1000, 0)

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

  local merged_room
  
  --[[
  for i = 1, 1 do
    local room = rect(30, 5, 30, 5)
    room = room:new_from_outline()

    if merged_room == nil then
      merged_room = room
    else
      merged_room = Map:merge_maps(merged_room, room)
    end
  end
  --]]

  for i = 1, 20 do
    local room = rect(5, 5, 10, 10)
    room = room:new_from_outline()

    if merged_room == nil then
      merged_room = room
    else
      merged_room = Map:merge_maps(merged_room, room)
    end
  end

  --[[
  for i = 1, 5 do
    local room = clearing()
    room = room:new_from_outline()

    if merged_room == nil then
      merged_room = room
    else
      merged_room = Map:merge_maps(merged_room, room)
    end
  end
  --]]



  -- I'll likely need a function to fill "holes": air tiles surrounded by wall times

  map:copy_map_onto_self_at_position(merged_room, 1, 1)

  return map
end




return Level
