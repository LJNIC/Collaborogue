local Object = require "object"

local Meadow = Object:extend()


function Meadow:__new(width, height)
  self._width = width
  self._height = height
end

function Meadow:_create()
  self._map = self:_fillMap(0)

  self:_bordersToWalls()
  self:_shapeEdges()
  self:_blobs()
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
  for x = 1, self._width do
    for y = 1, self._height do
      if x == 1 or x == self._width or y == 1 or y == self._height then
        self._map[x][y] = 1
      end
    end
  end
end


function Meadow:_shapeEdges()
  local growths = {}
  growths.motherCells = {}
  growths.sizes = {}

  local cardinals = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  local function vonNeumanNeighborhood(motherCell, size)

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


  local function generateMotherCellOrigins()
    for x = 2, self._width - 1 do
      for y = 2, self._height - 1 do
        if love.math.random() > .6 then
          if x == 2 or x == self._width - 1 or y == 2 or y == self._height - 1 then
            table.insert(growths.motherCells, {x,y})
          end
        end
      end
    end
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
    vonNeumanNeighborhood(v, growths.sizes[i])
  end

end








function Meadow:_blobs()

  local growths = {}
  growths.motherCells = {}
  growths.sizes = {}

  local cardinals = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  local function vonNeumanNeighborhood(motherCell, size)

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
    vonNeumanNeighborhood(v, growths.sizes[i])
  end



end

return Meadow
