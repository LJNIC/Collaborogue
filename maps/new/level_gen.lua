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
  --:clearPoint(0,math.floor(room_2.height/2))

  local room_3 = Map:merge_maps(room_1, room_2)
  
  -- -------------------------------------------------------------------------- --

  local room_1 = Map:new(10, 10, 1)
  room_1
  :clearArea(4,4, room_1.width-4, room_1.height-4)
  
  room_outline = room_1:new_from_outline()
  local edges = room_outline:find_edges()
  -- I'll likely need a function to fill holes, air tiles surrounded by wall times
  --:clearPoint(0,math.floor(room_1.height/2))

  -- -------------------------------------------------------------------------- --


  map:copy_map_onto_self_at_position(room_outline, 1, 1)



  return map
end

function Map:copy_map_onto_self_at_position(map, x, y)
  for i = x, x+map.width do
    for i2 = y, y+map.height do
      self.map[i][i2] = map.map[i-x][i2-y]
    end
  end

  return self
end

function Map:merge_maps(map_1, map_2)
  Map:find_merge_point_between_maps(map_1, map_2)

  local map_1_max_length = math.max(map_1.width, map_1.height)
  local map_2_max_length = math.max(map_2.width, map_2.height)
  local map_length = map_1_max_length + map_2_max_length
  local map = Map:new(map_length, map_length, 0)

  local merge_point_x, merge_point_y = map_1.width, map_1.height/2
  local offset_x, offset_y = 0, map_1.height/2
  local position_x, position_y = merge_point_x-offset_x, merge_point_y-offset_y

  map:copy_map_onto_self_at_position(map_1, 0, 0)
  map:copy_map_onto_self_at_position(map_2, position_x, position_y)
  :clearPoint(merge_point_x, merge_point_y)

  return map
end



function Map:new_from_outline()
  local padding = 1
  local outline_map = Map
  :new(self.width+padding*2, self.height+padding*2, 1)
  :copy_map_onto_self_at_position(self, padding, padding)
  
  for x = 0, outline_map.width do
    for y = 0, outline_map.height do
      local is_adjacent_to_air = false

      for k, v in pairs(Map:getNeighborhood('vonNeuman')) do
        if outline_map.map[x+v[1]] and outline_map.map[x+v[1]][y+v[2]] == 0 then
          is_adjacent_to_air = true
          break
        end
      end

      if not is_adjacent_to_air then -- if not adjacent to air
        outline_map.map[x][y] = 999 -- dummy value
      end
    end
  end

  for x = 0, outline_map.width do
    for y = 0, outline_map.height do
      if outline_map.map[x][y] == 999 then
        outline_map.map[x][y] = 0
      end
    end
  end

  return outline_map
end

function Map:find_edges()

  local startPos
  for x = 0, self.width do
    for y = 0, self.height do
      if self.map[x][y] == 1 then
        startPos = {x=x, y=y}
      end
    end
  end

  

  local edges = {{startPos}}

  while true do
    local edge = edges[#edges] -- Current edge is the last element
    local start = edge[1] -- Starting position is the first element
    for k, v in pairs(Map:getNeighborhood('moore')) do
      if #edges == 1 or -- If there's only one edge
        not (v[1] == edges[#edges-1].vec[1] * -1 and v[2] == edges[#edges-1].vec[2] * -1) --?
      then

        local x, y = start.x+v[1], start.y+v[2] -- Check from the starting point + a neighbor
        if self:posIsInArea(x,y, 0,0, #self.map,#self.map[1]) then -- If that pos is in the map
          if self.map[x][y] == 1 then -- If that pos is a wall
            edge.vec = {v[1],v[2]} -- Define the edges vector as the neighbor direction
            table.insert(edge, {x=x,y=y}) -- insert the position
            break
          end
        end
      end
    end

    repeat -- keep going until you run out of map or reach an empty space
      local x = edge[#edge].x + edge.vec[1]
      local y = edge[#edge].y + edge.vec[2]

      if self:posIsInArea(x,y, 0,0, #self.map,#self.map[1]) then
        if self.map[x][y] == 1 then
          table.insert(edge, {x=x,y=y})
        end
      end
    until self.map[x][y] ~= 1

    if -- if you reach the starting position you've done a full loop
      edge[#edge].x == startPos.x and
      edge[#edge].y == startPos.y
    then
      break
    end

    table.insert(edges, {edge[#edge]})

  end


  return edges
end

function Map:find_merge_point_between_maps(map_1, map_2)
  local edges_1 = map_1:find_edges()
  -- Get a list of room edges
  -- compare two rooms for any matching "jigsaws": two edges with opposite velocities
  -- check for collisions?
  -- if you run out of matches rotate a room
  -- if you run out of rotations make a new map
end

local function getMatches(lines1, lines2)
  local matches = {}
  for i, v in ipairs(lines1) do
    for i2, v2 in ipairs(lines2) do
      if #v == #v2 and v.vec[1] == v2.vec[1] and v.vec[2] == v2.vec[2] then
        if #v > 2 and #v2 > 2 then
          table.insert(matches, {v, v2})
        end
      end
    end
  end

  return matches
end

local function getLines(map)

  -- iterate until you find a wall
  local startPos
  for x = 0, #map do
    for y = 0, #map[x] do
      if map[x][y] == 1 then
        startPos = {x=x,y=y}
      end
    end
  end

  local lines = {{startPos}}
  local neighbors = {
    {-1,1},{0,1},{1,1},
    {-1,0},      {1,0},
    {-1,-1},{0,-1},{1,-1}
  }

  while true do
    local line = lines[#lines] -- Current line is the last element
    local start = line[1] -- Starting position is the first element
    for i, v in ipairs(neighbors) do
      if #lines == 1 or -- If there's only one line
        not (v[1] == lines[#lines-1].vec[1] * -1 and v[2] == lines[#lines-1].vec[2] * -1) --?
      then

        local x, y = start.x+v[1], start.y+v[2] -- Check from the starting point + a neighbor
        if self:posIsInArea(x,y, 0,0, #map,#map[1]) then -- If that pos is in the map
          if map[x][y] == 1 then -- If that pos is a wall
            line.vec = {v[1],v[2]} -- Define the lines vector as the neighbor direction
            table.insert(line, {x=x,y=y}) -- insert the position
            break
          end
        end
      end
    end

    repeat -- keep going until you run out of map or reach an empty space
      local x = line[#line].x + line.vec[1]
      local y = line[#line].y + line.vec[2]

      if self:posIsInArea(x,y, 0,0, #map,#map[1]) then
        if map[x][y] == 1 then
          table.insert(line, {x=x,y=y})
        end
      end
    until map[x][y] ~= 1

    if -- if you reach the starting position you've done a full loop
      line[#line].x == startPos.x and
      line[#line].y == startPos.y
    then
      break
    end

    table.insert(lines, {line[#line]})

  end


  return lines
end

return Level
