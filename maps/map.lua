local Object = require "object"
local Map = Object:extend()

local vec2 = require "vector"

local lib_path = love.filesystem.getWorkingDirectory() .. '/maps/clipper'
local extension = jit.os == 'Windows' and 'dll' or jit.os == 'Linux' and 'so' or jit.os == 'OSX' and 'dylib'
package.cpath = string.format('%s;%s/?.%s', package.cpath, lib_path, extension)
local Clipper = require('maps/clipper/clipper')


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

  self.actors = {}
  self.map = map
  self.cells = map
  self.width = width
  self.height = height
end

-- Merging
function Map:copy_map_onto_self_at_position(map, x, y, is_destructive)
  for i = x, x+map.width do
    for i2 = y, y+map.height do
      if (is_destructive) or (self.cells[i][i2] == 0) then
        self.cells[i][i2] = map.cells[i-x][i2-y]
      end
    end
  end

  return self
end

function Map:find_merge_point_between_maps(map_1, map_2)

  local function getMatches(lines1, lines2)

    local function sort_by_closest_to_origin(p, q)
      if p.x < q.x then
        return p, q
      elseif p.x == q.x then
        if p.y < q.y then
          return p, q
        elseif p.y == q.y then
          assert()
        else
          return q, p
        end
      else
        return q, p
      end
    end
    local function orientation(p, q, r)
      local val = (
        (q.y - p.y) * (r.x - q.x) -
        (q.x - p.x) * (r.y - q.y)
      )

      if (val == 0) then return 0 end

      return (val > 0) and 1 or 2
    end
    function sign(n) return n>0 and 1 or n<0 and -1 or 0 end

    -- This is strict for testing purposes
    local matches = {}
    for i, v in ipairs(lines1) do
      local p1, q1 = v[1], v[#v]
      --local p1, q1 = sort_by_closest_to_origin(v[1], v[#v])

      for i2, v2 in ipairs(lines2) do
        local p2, q2 = v2[1], v2[#v2]

        local dx1, dy1 = p1.x-q1.x, p1.y-q1.y
        local dx2, dy2 = p2.x-q2.x, p2.y-q2.y

        --if ( (v.vec[1] == v2.vec[1]*-1) and (v.vec[2] == v2.vec[2]*-1 )) then
        if (sign(dx1) == sign(dx2) * -1) and (sign(dy1) == sign(dy2)*-1) then
          if (#v > 2) and (#v2 > 2) then
            table.insert(matches, {v, v2})
          end
        end
      end
    end
  
    return matches
  end

  local function does_intersect(v, edges_1, edges_2, offset)
    local is_intersects = false

    local subject = edges_1

    local clip = Clipper.Path(1000)
    local i = 0
    for _, v in ipairs(edges_2) do
      for _, v2 in ipairs(v) do
        clip[i] = Clipper.IntPoint(v2.x+offset.x, v2.y+offset.y)
        i = i + 1
      end
    end

    local solution = Clipper.Paths(1)

    local clipper = Clipper.Clipper()
    clipper:AddPath(subject, Clipper.ptSubject, true)
    clipper:AddPath(clip, Clipper.ptClip, true)
    clipper:Execute(Clipper.ctDifference, solution)

    return (Clipper.Area(solution[0]) ~= Clipper.Area(subject))
  end

  local edges_1 = map_1:find_edges()
  local edges_2 = map_2:find_edges()

  local matches = getMatches(edges_1, edges_2)
  local matches_without_intersections = {}

  local subject = Clipper.Path(10000)
  local i = 0
  for _, v in ipairs(edges_1) do
    for _, v2 in ipairs(v) do
      subject[i] = Clipper.IntPoint(v2.x, v2.y)
      i = i + 1
    end
  end
  local offset
  for i, v in ipairs(matches) do
    local segment_index_1 = math.random(2, #v[1]-1)
    local segment_index_2 = math.random(2, #v[2]-1)
    local offset = vec2(v[1][segment_index_1].x - v[2][segment_index_2].x, v[1][segment_index_1].y - v[2][segment_index_2].y)
    if (not does_intersect(v, subject, edges_2, offset)) then
      table.insert(matches_without_intersections, {v, segment_index_1, segment_index_2})
    end
  end

  local matches = matches_without_intersections

  assert(#matches > 0, "no matches found")
  local match_index = math.random(1, #matches)
  local match = matches[match_index]
  local segment_index_1 = match[2]
  local segment_index_2 = match[3]

  local x1, y1 = match[1][1][segment_index_1].x, match[1][1][segment_index_1].y
  local x2, y2 = (match[1][1][segment_index_1].x - match[1][2][segment_index_2].x), (match[1][1][segment_index_1].y - match[1][2][segment_index_2].y)

  return x1, y1, x2, y2
end

function Map:merge_maps(map_1, map_2)
  -- Requires additional tunneling to make a path

  --local map_1 = map_1:new_from_outline()
  --local map_2 = map_2:new_from_outline()

  local map_1_strict = map_1:new_from_outline_strict()
  local map_2_strict = map_2:new_from_outline_strict()

  local x1, y1, x2, y2 = Map:find_merge_point_between_maps(map_1_strict, map_2_strict)

  local map_1_max_length = math.max(map_1.width, map_1.height)
  local map_2_max_length = math.max(map_2.width, map_2.height)
  local map_length = map_1_max_length + map_2_max_length
  local map = Map:new(map_length*2, map_length*2, 0)

  map:copy_map_onto_self_at_position(map_1, map_2.width, map_2.height, false)
  map:copy_map_onto_self_at_position(map_2, x2+map_2.width, y2+map_2.height, false)
  :set_point(x1+map_2.width, y1+map_2.height, 'Door')

  local left, right, top, bottom = map:get_padding()
  
  local map = map:new_from_trim_edges(left-1, right-1, top-1, bottom-1)
  -- there needs to be an overlap check here

  local offset_1 = vec2(map_2.width-(left-1), map_2.height-(top-1))
  local offset_2 = vec2(map_2.width-(left-1), map_2.height-(top-1))

  return map, offset_1, offset_2
end

function Map:get_padding()
  local padding_left, padding_right = 0, 0
  local padding_top, padding_bottom = 0, 0

  for x = 0, self.width do
    local binary = false
    for y = 0, self.height do
      if self.cells[x][y] == 1 then
        binary = true
        break
      end
    end
    if binary == true then
      break
    end
    padding_left = padding_left + 1
  end

  for x = self.width, 0, -1 do
    local binary = false
    for y = 0, self.height do
      if self.cells[x][y] == 1 then
        binary = true
        break
      end
    end
    if binary == true then
      break
    end
    padding_right = padding_right + 1
  end

  for y = 0, self.height do
    local binary = false
    for x = 0, self.width do
      if self.cells[x][y] == 1 then
        binary = true
        break
      end
    end
    if binary == true then
      break
    end
    padding_top = padding_top + 1
  end

  for y = self.height, 0, -1 do
    local binary = false
    for x = 0, self.width do
      if self.cells[x][y] == 1 then
        binary = true
        break
      end
    end
    if binary == true then
      break
    end
    padding_bottom = padding_bottom + 1
  end

  return padding_left, padding_right, padding_top, padding_bottom
end

function Map:new_from_trim_edges(left, right, top, bottom)
  local map = Map:new(self.width-(left+right), self.height-(top+bottom), 0)

  for x = left, self.width-right do
    for y = top, self.height-bottom do
      map.cells[x-left][y-top] = self.cells[x][y]
    end
  end

  return map
end

function Map:new_from_outline()
  local padding = 1
  local offset = vec2(padding, padding)
  local outline_map = Map:new(self.width+padding*2, self.height+padding*2, 1)
  :copy_map_onto_self_at_position(self, padding, padding, true)
  
  for x = 0, outline_map.width do
    for y = 0, outline_map.height do
      local is_adjacent_to_air = false

      for k, v in pairs(Map:getNeighborhood('moore')) do
        if outline_map.cells[x+v[1]] and outline_map.cells[x+v[1]][y+v[2]] == 0 then
          is_adjacent_to_air = true
          break
        end
      end

      if not is_adjacent_to_air then
        outline_map.cells[x][y] = 999 -- dummy value
      end
    end
  end

  for x = 0, outline_map.width do
    for y = 0, outline_map.height do
      if outline_map.cells[x][y] == 999 then
        outline_map.cells[x][y] = 0
      end
    end
  end

  return outline_map, offset
end

function Map:new_from_outline_strict()
  local outline_map = Map:new(self.width, self.height, 0)

  local to_check = {{0,0}}
  local checked = {}
  while true do

    local current_tile = table.remove(to_check)
    local x, y = current_tile[1], current_tile[2]
    
    for k, v in pairs(Map:getNeighborhood('moore')) do
      local x, y = x+v[1], y+v[2]

      if self.cells[x] then

        if not checked[tostring(x)..','..tostring(y)] then
          if self.cells[x][y] == 0 then
            table.insert(to_check, {x, y})
          elseif self.cells[x][y] == 1 then
            outline_map.cells[x][y] = 1
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
      if self.cells[x][y] == 1 then
        startPos = {x=x, y=y}
      end
    end
  end

  local edges = {{startPos}}

  local moore = Map:getNeighborhood('moore')
  local vonNeuman = Map:getNeighborhood('vonNeuman')
  local winding = {vonNeuman.e, vonNeuman.s, vonNeuman.w, vonNeuman.n}
  --local winding = {moore.e, moore.se, moore.s, moore.sw, moore.w, moore.nw, moore.n, moore.ne}

  while true do
    local edge = edges[#edges] -- Current edge is the last element
    local start = edge[1] -- Starting position is the first element
    for i, v in ipairs(winding) do
      if #edges == 1 or -- If there's only one edge
        not ( (v[1] == edges[#edges-1].vec[1] * -1) and (v[2] == edges[#edges-1].vec[2] * -1)) -- if not the direction we came from
      then

        local x, y = start.x+v[1], start.y+v[2] -- Check from the starting point + a neighbor
        if self.cells[x] and self.cells[x][y] == 1 then -- If that pos is a wall
          edge.vec = {v[1],v[2]} -- Define the edges vector as the neighbor direction
          table.insert(edge, {x=x,y=y}) -- insert the position
          break
        end
      end
    end

    repeat -- keep going until you run out of map or reach an empty space
      local x = edge[#edge].x + edge.vec[1]
      local y = edge[#edge].y + edge.vec[2]

      if self.cells[x] and self.cells[x][y] == 1 then
        table.insert(edge, {x=x,y=y})
      end
    until (not self.cells[x]) or (self.cells[x][y] ~= 1)

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
  self.cells[x][y] = 0

  return self
end
function Map:fillPoint(x,y)
  self.cells[x][y] = 1

  return self
end
function Map:set_point(x, y, id)
  self.cells[x][y] = id

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
 
  self.cells[cell.x][cell.y] = value

  local function recurse(cell, size)
    if size > 0 then
      for _, v in pairs(neighborhood) do
        local x = cell.x + v[1]
        local y = cell.y + v[2]
        if self:posIsInMap(x, y) then
          self.cells[x][y] = value
          recurse({x=x,y=y}, size - 1)
        end
      end
    end
  end

  recurse(cell, size)
end

function Map:dijkstra(start, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = Map:getNeighborhood(neighborhood)
  local map = Map:new(self.width, self.height, 999)
  local traveled = {}

  for i, v in ipairs(start) do
    map.cells[v.x][v.y] = 0
  end

  local function isWall(x, y)
    return self.cells[x][y] == 1
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
    if mdp.v > map.cells[x][y] then
      return {v = map.cells[x][y], x=x,y=y}
    else
      return mdp
    end
  end

  local cycles = 0
  while true do
    cycles = cycles+1
    print(cycles)
    local minimumDistancePos = {v = 999}
    local mdp = minimumDistancePos


    for x = 0, self.width do
      for y = 0, self.height do
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
      if self.cells[newPos.x] and self.cells[newPos.x][newPos.y] then
        if not isWall(newPos.x, newPos.y) then
          map.cells[newPos.x][newPos.y] = math.min(mdp.v + 1, map.cells[newPos.x][newPos.y])
        end
      end
    end

  end

  return map, traveled
end

function Map:dijkstra(start, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = Map:getNeighborhood(neighborhood)
  local map = Map:new(self.width, self.height, 999)

  for i, v in ipairs(start) do
    map.cells[v.x][v.y] = 0
  end

  local to_check = start
  local checked = {}

  while true do 
    local current_tile = table.remove(to_check)
    local x, y = current_tile.x, current_tile.y
    local minimum_distance_value = map.cells[x][y]
    
    for k, v in pairs(neighbors) do
      local x, y = x+v[1], y+v[2]

      if self.cells[x] and self.cells[x][y] then

        if not checked[tostring(x)..','..tostring(y)] then
          if self.cells[x][y] ~= 1 then
            table.insert(to_check, {x=x, y=y})
            minimum_distance_value = math.min(minimum_distance_value, map.cells[x][y]+1)
            map.cells[x][y] = math.min(minimum_distance_value + 1, map.cells[x][y])
          end
        end


      end
    end

    --[[
    for k, v in pairs(neighbors) do
      local x, y = x+v[1], y+v[2]

      if self.cells[x] and self.cells[x][y] then
          if self.cells[x][y] ~= 1 then
            map.map[x][y] = math.min(minimum_distance_value + 1, map.map[x][y])
          end
      end
    end
    --]]

    map.cells[x][y] = minimum_distance_value

    checked[tostring(x)..','..tostring(y)] = true


    if #to_check == 0 then
      break
    end 
  end

  return map
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
        if self.cells[nextNode.x + v[1]][nextNode.y + v[2]] ~= 1 then
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
    local map = self.cells
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
          self.cells[x][y] = 1
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
      x1 = love.math.random(3, self.width - 3)
      y1 = love.math.random(3, self.height - 3)
    until self.cells[x1][y1] == 0


    local n = 0
    while n ~= 4 do
      local vec = love.math.random(1, 4-n)
      x2 = x1 + neighbors[vec][1]
      y2 = y1 + neighbors[vec][2]

      if self.cells[x2][y2] == 1 then
        break
      else
        n = n + 1
        table.remove(neighbors, vec)
      end
    end

    if n ~= 4 then
      self.cells[x2][y2] = 0
      break
    end
  end
end

return Map
