local Object = require "object"

local Meadow = Object:extend()

----------
--Utilities
function Meadow:_targetBorders(effect, offset)
  local offset = offset or 0

  local x1, x2 = 1 + offset, self._width - offset
  local y1, y2 = 1 + offset, self._height - offset

  for x = x1, x2 do
    for y = y1, y2 do
      if x == x1 or x == x2 or y == y1 or y == y2 then
        effect(x, y)
      end
    end
  end
end

function Meadow:_targetArea(effect, area)
end


function Meadow:_vonNeuman(motherCell, size)
  local cardinals = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  local function recurse(motherCell, size)
    if size > 0 then
      for _, cardinal in pairs(cardinals) do
        local x = motherCell[1] + cardinal[1]
        local y = motherCell[2] + cardinal[2]
        if x > 1 and x < self._width and y > 1 and y < self._height then
          self._map[x][y] = 1
          recurse({x, y}, size - 1)
        end
      end
    end
  end

  recurse(motherCell, size)
end

---------

function Meadow:__new(width, height)
  self._width = width
  self._height = height
end

function Meadow:_create()
  self._map = self:_fillMap(0)
  self._rooms = {}

  self:_bordersToWalls()
  self:_shapeEdges()
  self:_blobs()
  self:_randomRoom()
  return self
end

function Meadow:_fillMap(value)
  local map = {}
  for x = 1, self._width do
    map[x] = {}
    for y = 1, self._height do
      map[x][y] = value
    end
  end
  return map
end


function Meadow:_bordersToWalls()
  self:_targetBorders(
    function(x, y)
      self._map[x][y] = 1
    end
  )
end


function Meadow:_shapeEdges()
  local growths = {}
  growths.motherCells = {}
  growths.sizes = {}


  local function generateMotherCellOrigins()
    self:_targetBorders(
      function(x, y)
        if love.math.random() >= .6 then
          table.insert(growths.motherCells, {x,y})
        end
      end, 1
    )
   end

  local function determineSizes()
    for i = 1, #growths.motherCells do
      local size = 1
      while size < 6 do
        if love.math.random() >= .12 then
          size = size + 1
        else
          break
        end
      end
      table.insert(growths.sizes, size)
    end
  end


  generateMotherCellOrigins()
  determineSizes()

  for i, v in ipairs(growths.motherCells) do
    self._map[v[1]][v[2]] = 1
    self:_vonNeuman(v, growths.sizes[i])
  end

end


function Meadow:_blobs()
  local growths = {}
  growths.motherCells = {}
  growths.sizes = {}

  local function generateMotherCellOrigins()
    for x = 2, self._width - 1 do
      for y = 2, self._height - 1 do
        if love.math.random() > .99 then
          table.insert(growths.motherCells, {x,y})
        end
      end
    end
  end

  local function determineSizes()
    for i = 1, #growths.motherCells do
      local size = 3
      while size < 1 do
        if love.math.random() >= .9 then
          size = size + 1
        else
          break
        end
      end
      table.insert(growths.sizes, size)
    end
  end


  generateMotherCellOrigins()
  determineSizes()

  for i, v in ipairs(growths.motherCells) do
    self._map[v[1]][v[2]] = 1
    self:_vonNeuman(v, growths.sizes[i])
  end
end

function Meadow:_room(xPrime, yPrime, width, height)

  for x = xPrime, xPrime + width do
    for y = yPrime, yPrime + width do
      if x == xPrime or x == xPrime + width or y == yPrime or y == yPrime + height then
        self._map[x][y] = 1
      else
        self._map[x][y] = 0
      end
    end
  end


  --Cross Pattern
  for x = xPrime, xPrime + width do
    for y = yPrime, yPrime + height do
      if x == xPrime + (width/2) or y == yPrime + (height/2) then
        self._map[x][y] = 0
      end
    end
  end
end

function Meadow:_randomRoom()

  local x = love.math.random(2, self._width - 8)
  local y = love.math.random(2, self._height - 8)
  local height = 8
  local width = 8

  table.insert(self._rooms, {x = x, y = y, width = width, height = height})

  self:_room(x, y, width, height)
end

return Meadow
