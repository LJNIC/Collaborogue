local Map = require "maps.map"
local Object = require "object"

local Level = Object:extend()

function Level:__new()
end

function Level:create()
  local map = Map:new(1000, 1000, 0)

  --[[
  local function clearing()
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

  local room_3 = clearing():new_from_outline()

  --]]

  local merged_room
  for i = 1, 20 do
    local room = Map:new(math.random(5, 10), math.random(5, 10), 1)
    room:clearArea(2,2, room.width-1, room.height-1)
    local room_outline = room:new_from_outline()

    if merged_room == nil then
      merged_room = room_outline
    else
      merged_room = Map:merge_maps(merged_room, room_outline)
    end

  end


  -- I'll likely need a function to fill "holes": air tiles surrounded by wall times

  map:copy_map_onto_self_at_position(merged_room, 0, 0)

  return map
end




return Level
