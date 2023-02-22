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

  map:copy_map_onto_self_at_position(room_3, 5, 5)

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

local function outlineTransformations(map)
  local map = map
  local map1 = self:outline(map, {{x=0,y=0}})

  local function isClearAdjacent(map, x, y)
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local bit = false

    for i, v in ipairs(neighbors) do
      local x, y = x+v[1], y+v[2]
      if self:posIsInArea(x, y, 0,0, map.width,map.height) then
        if map[x][y] == 0 then
          bit = true
        end
      end
    end

    return bit
  end

  local map2 = {width = map.width, height = map.height}
  for x = 0, #map do
    map2[x] = {}
    for y = 0, #map[x] do
      if map1[x][y] == 999 then
        map2[x][y] = 0
      else
        map2[x][y] = 1
      end
    end
  end

  for x = 0, #map do
    for y = 0, #map[x] do
      if map1[x][y] == 999 then
        map[x][y] = 0
      end
    end
  end

  for x = 0, #map do
    for y = 0, #map[x] do
      if map[x][y] == 1 then
        if isClearAdjacent(map,x,y) then
          map2[x][y] = 1
        else
          map2[x][y] = 0
        end
      end
    end
  end

  return map2
end

function Map:outline(set, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = self:getNeighborhood(neighborhood)
  local map = self:miniMaps(map1.width, map1.height, 999)
  local traveled = {}

  for i, v in ipairs(set) do
    map[v.x][v.y] = 0
  end

  local function isClear(x, y)
    return map1[x][y] == 0
  end
  local function isClearAdjacent(map, x, y)
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local bit = false

    for i, v in ipairs(neighbors) do
      local x, y = x+v[1], y+v[2]
      if self:posIsInArea(x, y, 0,0, map.width,map.height) then
        if map[x][y] == 0 then
          bit = true
        end
      end
    end

    return bit
  end

  local function isTraveled(x, y)
    local bit = false
    for _, v in ipairs(traveled) do
      if v.x == x and v.y == y then
        bit = true
        break
      end
    end

    return bit
  end

  local function getLeast(mdp, x, y)
    if mdp.v > map[x][y] then
      return {v = map[x][y], x=x,y=y}
    else
      return mdp
    end
  end

  while true do
    local minimumDistancePos = {v = 999}
    local mdp = minimumDistancePos


    for x = 0, map1.width do
      for y = 0, map1.height do
        if not isClear(x, y) then
          if not isTraveled(x, y) then
            mdp = getLeast(mdp, x, y)
          end
        end
      end
    end
    

    if mdp.x == nil then
      break
    end


    table.insert(traveled, mdp)


    for _, v in pairs(neighbors) do
      local newPos = {x = mdp.x + v[1], y = mdp.y + v[2]}
      if self:posIsInArea(newPos.x, newPos.y, 0,0, map1.width,map1.height) then
        if not isClear(newPos.x, newPos.y) then
          if not isClearAdjacent(map1, mdp.x, mdp.y) then
            map[newPos.x][newPos.y] = math.min(mdp.v + 1, map[newPos.x][newPos.y])
          end
        end
      end
    end

  end

  return map, traveled
end

function Map:outlineTransformations()
  local map = map
  local map1 = self:outline(map, {{x=0,y=0}})

  local function isClearAdjacent(map, x, y)
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local bit = false

    for i, v in ipairs(neighbors) do
      local x, y = x+v[1], y+v[2]
      if self:posIsInArea(x, y, 0,0, map.width,map.height) then
        if map[x][y] == 0 then
          bit = true
        end
      end
    end

    return bit
  end

  local map2 = {width = map.width, height = map.height}
  for x = 0, #map do
    map2[x] = {}
    for y = 0, #map[x] do
      if map1[x][y] == 999 then
        map2[x][y] = 0
      else
        map2[x][y] = 1
      end
    end
  end

  for x = 0, #map do
    for y = 0, #map[x] do
      if map1[x][y] == 999 then
        map[x][y] = 0
      end
    end
  end

  for x = 0, #map do
    for y = 0, #map[x] do
      if map[x][y] == 1 then
        if isClearAdjacent(map,x,y) then
          map2[x][y] = 1
        else
          map2[x][y] = 0
        end
      end
    end
  end

  return map2
end

function Map:find_edges()

  local start_pos
  for x = 0, self.width do
    for y = 0, self.height do
      if self.map[x][y] == 1 then
        start_pos = {x=x, y=y}
      end
    end
  end


  local vectors = {
    {-1,1},{0,1},{1,1},
    {-1,0},      {1,0},
    {-1,-1},{0,-1},{1,-1}
  }

  local edges = {{startPos}}

end

function Map:find_merge_point_between_maps(map_1, map_2)
  local edges_1 = map_1:find_edges()
  -- Get a list of room edges
  -- compare two rooms for any matching "jigsaws": two edges with opposite velocities
  -- check for collisions?
  -- if you run out of matches rotate a room
  -- if you run out of rotations make a new map
end

return Level
