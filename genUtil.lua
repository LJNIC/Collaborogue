local Object = require "object"

local Gen = Object:extend()

function Gen:_fillMap(value)
  local map = {}
  for x = 1, self._width do
    map[x] = {}
    for y = 1, self._height do
      map[x][y] = value
    end
  end
  return map
end

--Checks
function Gen:_posIsInArea(x,y, xMin,yMin, xMax,yMax)
  if x > xMin and x < xMax and y > yMin and y < yMax then
    return true
  else
    return false
  end
end
function Gen:_posIsInMap(x,y)
  return Gen:_posIsInArea(x,y, 1,1, self._width,self._height)
end


--Space
function Gen:_clearSpace(x,y)
  self._map[x][y] = 0
end
function Gen:_fillSpace(x,y)
  self._map[x][y] = 1
end


--Area
function Gen:_targetArea(x1,y1, x2,y2, func)
  for x = x1, x2 do
    for y = y1, y2 do
      func(x, y)
    end
  end
end
function Gen:_clearArea(x1,y1, x2,y2)
  self:_targetArea(
    x1,y1, x2,y2,
    function(x,y)
      self:_clearSpace(x,y)
    end
  )
end
function Gen:_fillArea(x1,y1, x2,y2)
  self:_targetArea(
    x1,y1, x2,y2,
    function(x,y)
      self:_fillSpace(x,y)
    end
  )
end

--Perimeter
function Gen:_targetPerimeter(x1,y1, x2,y2, func)
  Gen:_targetArea(
    x1,y1, x2,y2,
    function(x,y)
      if x==x1 or x==x2 or y==y1 or y==y2 then
        func(x, y)
      end
    end
  )
end
function Gen:_clearPerimeter(x1,y1, x2,y2)
  Gen:_targetPerimeter(
    x1,y1, x2,y2,
    function(x,y)
      self:_clearSpace(x, y)
    end
  )
end
function Gen:_fillPerimeter(x1,y1, x2,y2)
  Gen:_targetPerimeter(
    x1,y1, x2,y2,
    function(x,y)
      self:_fillSpace(x, y)
    end
  )
end

--Designation
function Gen:_designateZoning(x, y, width, height, identifier)
  local width, height = width, height
  local x1, y1 = x, y
  local x2, y2 = x1 + width - 1, y1 + height - 1
  local identifier = identifier or (#self._rooms + 1)

  self._rooms[identifier] = {
    width = width, height = height,
    x1 = x1, y1 = y1,
    x2 = x2, y2 = y2,
  }

end
function Gen:_newMarkedMap()
  local map = {}
  for x = 1, self._width do
    map[x] = {}
    for y = 1, self._height do
      map[x][y] = "blank"
    end
  end
  return map
end
function Gen:_markSpace(x, y, thingStr)
  local markers = self._markers
  markers[thingStr] = markers[thingStr] or {}

  self._markedMap[x][y] = thingStr
  table.insert(markers[thingStr], {x=x, y=y})
end


--ProcGen

function Gen:_rollGrowthPotential(cell, probability, max, min)
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

function Gen:_getNeighborhood(choice)
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

function Gen:_spacePropogation(value, neighborhood, cell, size)
  local neighborhood = self:_getNeighborhood(neighborhood)
 
  self._map[cell.x][cell.y] = value

  local function recurse(cell, size)
    if size > 0 then
      for _, v in pairs(neighborhood) do
        local x = cell.x + v[1]
        local y = cell.y + v[2]
        if self:_posIsInMap(x, y) then
          self._map[x][y] = value
          recurse({x=x,y=y}, size - 1)
        end
      end
    end
  end

  recurse(cell, size)
end

function Gen:_dijkstra(set, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = self:_getNeighborhood(neighborhood)
  local map = self:_fillMap(999)
  local traveled = {}

  for i, v in ipairs(set) do
    map[v.x][v.y] = 0
  end

  local function isWall(x, y)
    return self._map[x][y] == 1
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


    for x = 1, self._width do
      for y = 1, self._height do
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
      if self:_posIsInMap(newPos.x, newPos.y) then
        if not isWall(newPos.x, newPos.y) then
          map[newPos.x][newPos.y] = math.min(mdp.v + 1, map[newPos.x][newPos.y])
        end
      end
    end

  end

  return map, traveled
end


function Gen:_aStar(x1,y1, x2,y2)

  local vonNeuman = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  local aMap = {}
  for x = 1, self._width do
    aMap[x] = {}
    for y = 1, self._height do
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
      if self:_posIsInMap(nextNode.x + v[1], nextNode.y + v[2]) then
        if self._map[nextNode.x + v[1]][nextNode.y + v[2]] ~= 1 then
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

return Gen
