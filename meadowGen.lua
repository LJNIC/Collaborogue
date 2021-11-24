local Object = require "object"

local Meadow = Object:extend()


function Meadow:__new(width, height)
  self._width = width
  self._height = height
end

function Meadow:_create()
  self._map = self:_fillMap(0)

  for x = 1, self._width do
    for y = 1, self._height do
      if x == 1 or x == self._width or y == 1 or y == self._height then
        self._map[x][y] = 1
      end
    end
  end

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

function Meadow:_BordersToWalls()

end

return Meadow
