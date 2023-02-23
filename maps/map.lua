local Object = require "object"

local Map = Object:extend()

function Map:new(width, height, value)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o:init(width, height, value)
	return o
end

function Map:init(width, height, value)
    local map = {}

    for x = 0, width do
      map[x] = {}
      for y = 0, height do
        map[x][y] = value
      end
    end

    self.map = map
    self.width = width
    self.height = height
end

-- Merging
function Map:copy_map_onto_self_at_position(map, x, y, is_destructive)
  for i = x, x+map.width do
    for i2 = y, y+map.height do
      if (is_destructive) or (self.map[i][i2] ~= 1) then
        self.map[i][i2] = map.map[i-x][i2-y]
      end
    end
  end

  return self
end

function Map:find_merge_point_between_maps(map_1, map_2)

  local function getMatches(lines1, lines2)
    -- This is strict for testing purposes
    local matches = {}
    for i, v in ipairs(lines1) do
      for i2, v2 in ipairs(lines2) do
        if ( (v.vec[1] == v2.vec[1]*-1) and (v.vec[2] == v2.vec[2]*-1 )) then
          if (#v > 2) and (#v2 > 2) then
            table.insert(matches, {v, v2})
          end
        end
      end
    end
  
    return matches
  end

  local edges_1 = map_1:find_edges()
  local edges_2 = map_2:find_edges()

  local matches = getMatches(edges_1, edges_2)

  --odd
  --same size
  --same shape

  -- Get a list of room edges
  -- compare two rooms for any matching "jigsaws": two edges with opposite velocities
  -- check for collisions?
  -- if you run out of matches rotate a room
  -- if you run out of rotations make a new map

  --print(#matches)
  local match_index = math.random(1, #matches)
  local match = matches[match_index]

  --print(matches[2])

  local x1, y1 = match[1][2].x, match[1][2].y
  local x2, y2 = (match[1][2].x - match[2][2].x), (match[1][2].y - match[2][2].y)

  return x1, y1, x2, y2
end

function Map:merge_maps(map_1, map_2)
  -- Only works for convex
  -- Requires additional tunneling to make a path

  local map_1_strict = map_1:new_from_outline_strict()
  local map_2_strict = map_2:new_from_outline_strict()

  local x1, y1, x2, y2 = Map:find_merge_point_between_maps(map_1_strict, map_2_strict)

  local map_1_max_length = math.max(map_1.width, map_1.height)
  local map_2_max_length = math.max(map_2.width, map_2.height)
  local map_length = map_1_max_length + map_2_max_length
  local map = Map:new(map_length*2, map_length*2, 0)

  local offset_x, offset_y = map_2.width, map_2.height

  map:copy_map_onto_self_at_position(map_1, offset_x, offset_y, false)
  map:copy_map_onto_self_at_position(map_2, x2+offset_x, y2+offset_y, false)
  :clearPoint(x1+offset_x, y1+offset_y)

  -- there needs to be an overlap check here

  return map
end

function Map:getPadding()
  local padding_x, padding_y = 0, 0

  for x = 0, self.width do
    local binary = false
    for y = 0, self.height do
      if self.map[x][y] == 1 then
        binary = true
        break
      end
    end
    if binary == true then
      break
    end
    padding_x = padding_x + 1
  end

  for y = 0, self.height do
    local binary = false
    for x = 0, self.width do
      if self.map[x][y] == 1 then
        binary = true
        break
      end
    end
    if binary == true then
      break
    end
    padding_y = padding_y + 1
  end

  return padding_x, padding_y
end

function Map:new_from_outline()
  local padding = 1
  local outline_map = Map:new(self.width+padding*2, self.height+padding*2, 1)
  :copy_map_onto_self_at_position(self, padding, padding, true)
  
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

function Map:new_from_outline_strict()
  local outline_map = Map:new(self.width, self.height, 0)

  local to_check = {{0,0}}
  local checked = {}
  while true do

    local current_tile = table.remove(to_check)
    local x, y = current_tile[1], current_tile[2]
    
    for k, v in pairs(Map:getNeighborhood('vonNeuman')) do
      local x, y = x+v[1], y+v[2]

      if self.map[x] then

        if not checked[tostring(x)..','..tostring(y)] then
          if self.map[x][y] == 0 then
            table.insert(to_check, {x, y})
          elseif self.map[x][y] == 1 then
            outline_map.map[x][y] = 1
          end
        end


      end
    end

    checked[tostring(x)..','..tostring(y)] = true


    if #to_check == 0 then
      break
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
        not ( (v[1] == edges[#edges-1].vec[1] * -1) and (v[2] == edges[#edges-1].vec[2] * -1)) -- if not the direction we came from
      then

        local x, y = start.x+v[1], start.y+v[2] -- Check from the starting point + a neighbor
        if self.map[x] and self.map[x][y] == 1 then -- If that pos is a wall
          edge.vec = {v[1],v[2]} -- Define the edges vector as the neighbor direction
          table.insert(edge, {x=x,y=y}) -- insert the position
          break
        end
      end
    end

    repeat -- keep going until you run out of map or reach an empty space
      local x = edge[#edge].x + edge.vec[1]
      local y = edge[#edge].y + edge.vec[2]

      if self.map[x] and self.map[x][y] == 1 then
        table.insert(edge, {x=x,y=y})
      end
    until (not self.map[x]) or (self.map[x][y] ~= 1)

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

-- -------------------------------------------------------------------------- --

-- Checks
function Map:posIsInArea(x,y, xMin,yMin, xMax,yMax)
  if x >= xMin and x <= xMax and y >= yMin and y <= yMax then
    return true
  else
    return false
  end
end
function Map:posIsInMap(x,y)
  return Map:posIsInArea(x,y, 1,1, self.width,self.height)
end


--Space
function Map:clearPoint(x,y)
  self.map[x][y] = 0

  return self
end
function Map:fillPoint(x,y)
  self.map[x][y] = 1

  return self
end


--Area
function Map:targetArea(x1,y1, x2,y2, func)
  for x = x1, x2 do
    for y = y1, y2 do
      func(x, y)
    end
  end

  return self
end
function Map:clearArea(x1,y1, x2,y2)
  self:targetArea(
    x1,y1, x2,y2,
    function(x,y)
      self:clearPoint(x,y)
    end
  )

  return self
end
function Map:fillArea(x1,y1, x2,y2)
  self:targetArea(
    x1,y1, x2,y2,
    function(x,y)
      self:fillPoint(x,y)
    end
  )

  return self
end

--Perimeter
function Map:targetPerimeter(x1,y1, x2,y2, func)
  Map:targetArea(
    x1,y1, x2,y2,
    function(x,y)
      if x==x1 or x==x2 or y==y1 or y==y2 then
        func(x, y)
      end
    end
  )
end
function Map:clearPerimeter(x1,y1, x2,y2)
  Map:targetPerimeter(
    x1,y1, x2,y2,
    function(x,y)
      self:clearPoint(x, y)
    end
  )
end
function Map:fillPerimeter(x1,y1, x2,y2)
  Map:targetPerimeter(
    x1,y1, x2,y2,
    function(x,y)
      self:fillPoint(x, y)
    end
  )
end

--Designation
function Map:newZoneMap()
  local map = self:newMap(nil)
  return map
end

function Map:designateZoning(x, y, width, height, identifier)
  local width, height = width, height
  local centerX = x + math.floor(width/2)
  local centerY = y + math.floor(height/2)
  local x1, y1 = x, y
  local x2, y2 = x1 + width - 1, y1 + height - 1
  local identifier = identifier or (#self.rooms + 1)

  self.rooms[identifier] = {
    width = width, height = height,
    centerX = centerX, centerY = centerY,
    x1 = x1, y1 = y1,
    x2 = x2, y2 = y2,
  }

  for x = x1, x2 do
    for y = y1, y2 do
      self.zoneMap[x][y] = identifier
    end
  end
end

function Map:newMarkedMap()
  local map = {}
  for x = 1, self.width do
    map[x] = {}
    for y = 1, self.height do
      map[x][y] = "blank"
    end
  end
  return map
end
function Map:markSpace(x, y, thingStr)
  local markers = self.markers
  markers[thingStr] = markers[thingStr] or {}

  self.markedMap[x][y] = thingStr
  table.insert(markers[thingStr], {x=x, y=y})
end


--ProcMap

function Map:rollGrowthPotential(cell, probability, max, min)
  local size = min or 1

  while size < max do
    if love.math.random() <= probability then
      size = size + 1
    else
      break
    end
  end

  return size
end

function Map:getNeighborhood(choice)
  local neighborhood = {}

  neighborhood.vonNeuman = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  neighborhood.moore = {
    n = {0, -1},
    ne = {1, -1},
    e = {1, 0},
    se = {1, 1},
    s = {0, 1},
    sw = {-1, 1},
    w = {-1, 0},
    nw = {-1, -1}
  }

  return neighborhood[choice]
end

function Map:spacePropogation(value, neighborhood, cell, size)
  local neighborhood = self:getNeighborhood(neighborhood)
 
  self.map[cell.x][cell.y] = value

  local function recurse(cell, size)
    if size > 0 then
      for _, v in pairs(neighborhood) do
        local x = cell.x + v[1]
        local y = cell.y + v[2]
        if self:posIsInMap(x, y) then
          self.map[x][y] = value
          recurse({x=x,y=y}, size - 1)
        end
      end
    end
  end

  recurse(cell, size)
end

function Map:dijkstra(set, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = self:getNeighborhood(neighborhood)
  local map = self:newMap(999)
  local traveled = {}

  for i, v in ipairs(set) do
    map[v.x][v.y] = 0
  end

  local function isWall(x, y)
    return self.map[x][y] == 1
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


    for x = 1, self.width do
      for y = 1, self.height do
        if not isWall(x, y) then
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
      if self:posIsInMap(newPos.x, newPos.y) then
        if not isWall(newPos.x, newPos.y) then
          map[newPos.x][newPos.y] = math.min(mdp.v + 1, map[newPos.x][newPos.y])
        end
      end
    end

  end

  return map, traveled
end


function Map:aStar(x1,y1, x2,y2)

  local vonNeuman = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  local aMap = {}
  for x = 1, self.width do
    aMap[x] = {}
    for y = 1, self.height do
      aMap[x][y] = 0
    end
  end

  local toTravel = {}
  local travelled = {}
  local function MDistance(x1,y1, x2,y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
  end

  local SEMDistance = MDistance(x1,y1, x2,y2)
  local startNode = {x = x1, y = y1, s = 0, e = SEMDistance, t = SEMDistance}
  table.insert(toTravel, startNode)

  while true do
    local nextNode = nil
    local nodeIndex = nil

    for i, v in ipairs(toTravel) do
      if aMap[v.x][v.y] == 0 then

        if nextNode == nil then
          nextNode = v
          nodeIndex = i
        elseif  v.t < nextNode.t then
          nextNode = v
          nodeIndex = i
        elseif v.t == nextNode.t and v.e < nextNode.e then
          nextNode = v
          nodeIndex = i
        end

      end
    end

    table.remove(toTravel, nodeIndex)
    table.insert(travelled, nextNode)
    aMap[nextNode.x][nextNode.y] = nextNode.s

    if nextNode.x == x2 and nextNode.y == y2 then
      break
    end

    for k, v in pairs(vonNeuman) do
      if self:posIsInMap(nextNode.x + v[1], nextNode.y + v[2]) then
        if self.map[nextNode.x + v[1]][nextNode.y + v[2]] ~= 1 then
          local newNode = {}
          newNode.x = nextNode.x + v[1]
          newNode.y = nextNode.y + v[2]
          newNode.s = nextNode.s + 1
          newNode.e = MDistance(newNode.x,newNode.y, x2,y2)
          newNode.t = newNode.s + newNode.e

          local match = nil
          for i, v in ipairs(toTravel) do
            if v.x == newNode.x and v.y == newNode.y then
              match = {s = v.s, i = i}
            end
          end

          if match ~= nil then
            if match.s > newNode.s then
              table.remove(toTravel, match.i)
              table.insert(toTravel, newNode)
            end
          else
            table.insert(toTravel, newNode)
          end

        end
      end
    end
  end


  local aPath = {}

  local furthestS = -1
  for i, v in ipairs(travelled) do
    if v.s > furthestS then
      furthestS = v.s
    end
  end

  local endNode = {x = x2, y = y2, s = furthestS, e = 0, t = furthestS}
  table.insert(aPath, endNode)

  while #aPath ~= furthestS + 1  do
    for i, v in ipairs(travelled) do
      if v.s == aPath[#aPath].s - 1 then
        if MDistance(v.x, v.y, aPath[#aPath].x, aPath[#aPath].y) == 1  then
          table.insert(aPath, v)
        end
      end
    end
  end

  return aPath
end

function Map:automata(map)
  local neighbors = {
    {-1,1},{0,1},{1,1},
    {-1,0},      {1,0},
    {-1,-1},{0,-1},{1,-1}
  }

  local copy = {}
  for x = 1, #map do
    copy[x] = {}
    for y = 1, #map[x] do
      copy[x][y] = 0
    end
  end

  for x = 1, #map do
    for y = 1, #map[x] do
      local numOfNeighbors = 0
      for i, v in ipairs(neighbors) do
        if self:posIsInArea(x+v[1], y+v[2], 1,1,#map,#map[x]) then
          if map[x+v[1]][y+v[2]] == 1 then
            numOfNeighbors = numOfNeighbors + 1
          end
        else
          numOfNeighbors = numOfNeighbors + 1
        end
      end

      if map[x][y] == 0 then
        if numOfNeighbors > 4 then
          copy[x][y] = 1
        end
      elseif map[x][y] == 1 then
        if numOfNeighbors >= 3 then
          copy[x][y] = 1
        else
          copy[x][y] = 0
        end
      end

    end
  end

  
  for x = 1, #copy do
    for y = 1, #copy[x] do
      map[x][y] = copy[x][y]
    end
  end

end

function Map:automata2()
  local perms = {}
  local square = {1,1,1, 0,0, 0,0,0}

  table.insert(perms, square)
  local function mirrorX(t)
    local new = {}
    for i = 1,3 do
      new[i] = t[i+5]
    end
    for i = 4,5 do
      new[i] = t[i]
    end
    for i = 6,8 do
      new[i] = t[i-5]
    end

    return new
  end

  table.insert(perms, mirrorX(square))

  local function match(x,y, comp)
    local map = self.map
    local neighbors = {
      {-1,1},{0,1},{1,1},
      {-1,0},      {1,0},
      {-1,-1},{0,-1},{1,-1}
    }

    local bit = true

    for i, v in ipairs(neighbors) do
      local x,y = x+v[1],y+v[2]
      if map[x][y] ~= comp[i] then
        bit = false
        break
      end
    end

    return bit
  end

  for x = 2, self.width-1 do
    for y = 2, self.height-1 do
      for i, v in ipairs(perms) do
        if match(x,y, v) then
          self.map[x][y] = 1
        end
      end
    end
  end
end

function Map:DLAInOut()
  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end

  while true do
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local x1,y1 = nil,nil
    local x2,y2 = nil,nil

    repeat
      x1 = math.random(3, self.width - 3)
      y1 = math.random(3, self.height - 3)
    until self.map[x1][y1] == 0


    local n = 0
    while n ~= 4 do
      local vec = math.random(1, 4-n)
      x2 = x1 + neighbors[vec][1]
      y2 = y1 + neighbors[vec][2]

      if self.map[x2][y2] == 1 then
        break
      else
        n = n + 1
        table.remove(neighbors, vec)
      end
    end

    if n ~= 4 then
      self.map[x2][y2] = 0
      break
    end
  end
end

return Map
