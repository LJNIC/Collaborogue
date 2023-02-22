local Object = require "object"

local Gen = Object:extend()

function Gen:fillMap(value)
  local map = {}
  for x = 1, self.width do
    map[x] = {}
    for y = 1, self.height do
      map[x][y] = value
    end
  end
  return map
end

--Checks
function Gen:posIsInArea(x,y, xMin,yMin, xMax,yMax)
  if x >= xMin and x <= xMax and y >= yMin and y <= yMax then
    return true
  else
    return false
  end
end
function Gen:posIsInMap(x,y)
  return Gen:posIsInArea(x,y, 1,1, self.width,self.height)
end


--Space
function Gen:clearSpace(x,y)
  self.map[x][y] = 0
end
function Gen:fillSpace(x,y)
  self.map[x][y] = 1
end


--Area
function Gen:targetArea(x1,y1, x2,y2, func)
  for x = x1, x2 do
    for y = y1, y2 do
      func(x, y)
    end
  end
end
function Gen:clearArea(x1,y1, x2,y2)
  self:targetArea(
    x1,y1, x2,y2,
    function(x,y)
      self:clearSpace(x,y)
    end
  )
end
function Gen:fillArea(x1,y1, x2,y2)
  self:targetArea(
    x1,y1, x2,y2,
    function(x,y)
      self:fillSpace(x,y)
    end
  )
end

--Perimeter
function Gen:targetPerimeter(x1,y1, x2,y2, func)
  Gen:targetArea(
    x1,y1, x2,y2,
    function(x,y)
      if x==x1 or x==x2 or y==y1 or y==y2 then
        func(x, y)
      end
    end
  )
end
function Gen:clearPerimeter(x1,y1, x2,y2)
  Gen:targetPerimeter(
    x1,y1, x2,y2,
    function(x,y)
      self:clearSpace(x, y)
    end
  )
end
function Gen:fillPerimeter(x1,y1, x2,y2)
  Gen:targetPerimeter(
    x1,y1, x2,y2,
    function(x,y)
      self:fillSpace(x, y)
    end
  )
end

--Designation
function Gen:newZoneMap()
  local map = self:fillMap(nil)
  return map
end

function Gen:designateZoning(x, y, width, height, identifier)
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

function Gen:newMarkedMap()
  local map = {}
  for x = 1, self.width do
    map[x] = {}
    for y = 1, self.height do
      map[x][y] = "blank"
    end
  end
  return map
end
function Gen:markSpace(x, y, thingStr)
  local markers = self.markers
  markers[thingStr] = markers[thingStr] or {}

  self.markedMap[x][y] = thingStr
  table.insert(markers[thingStr], {x=x, y=y})
end


--ProcGen

function Gen:rollGrowthPotential(cell, probability, max, min)
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

function Gen:getNeighborhood(choice)
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

function Gen:spacePropogation(value, neighborhood, cell, size)
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

function Gen:dijkstra(set, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = self:getNeighborhood(neighborhood)
  local map = self:fillMap(999)
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


function Gen:aStar(x1,y1, x2,y2)

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

function Gen:automata(map)
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

function Gen:automata2()
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

function Gen:DLAInOut(map)
  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end

  while true do
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local x1,y1 = nil,nil
    local x2,y2 = nil,nil

    repeat
      x1 = math.random(3, map.width - 3)
      y1 = math.random(3, map.height - 3)
    until map[x1][y1] == 0


    local n = 0
    while n ~= 4 do
      local vec = math.random(1, 4-n)
      x2 = x1 + neighbors[vec][1]
      y2 = y1 + neighbors[vec][2]

      if map[x2][y2] == 1 then
        break
      else
        n = n + 1
        table.remove(neighbors, vec)
      end
    end

    if n ~= 4 then
      map[x2][y2] = 0
      break
    end
  end
end

return Gen
