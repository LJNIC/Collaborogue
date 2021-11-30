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
  return Gen:_posIsInArea(x,y, 2,2, self._width-1,self._height-1)
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


return Gen
