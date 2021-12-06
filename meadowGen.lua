local Object = require "object"
local Gen = require "genUtil"

local Meadow = Gen:extend()

function Meadow:__new(width, height)
  self._width = width
  self._height = height
end

function Meadow:_create()
  self._map = self:_fillMap(0)
  self._rooms = {}
  self._markedMap = self:_newMarkedMap()
  self._markers = {}

  self:_fillPerimeter(1,1, self._width,self._height)
  self:_shapeEdges()
  self:_blobs()

  self:_designateStairsSpawn()

  --self._aPath = self:_aStar(self._markers["player"].x,self._markers["player"].y,
   --                         self._markers["stairs"].x,self._markers["stairs"].y
  --)

  self._heatMap = self:_generateHeatMap(self._markers["player"].x,self._markers["player"].y,
                                      self._markers["stairs"].x,self._markers["stairs"].y
  )

  self:_designateZoning(15, 15, 3, 3, "nest")
  return self
end


function Meadow:_shapeEdges()
  local cells = {}
  cells.cultureThreshold = .4
  cells.maxPopulation = 100000

  self:_targetPerimeter(
    2,2, self._width-1,self._height-1,
    function(x,y)
      if love.math.random() <= cells.cultureThreshold and
        #cells <= cells.maxPopulation then
        table.insert(cells, {x = x, y = y})
      end
    end
  )

  for i, v in ipairs(cells) do
    v.size = self:_rollGrowthPotential(v, .88, 6)
    self:_spacePropogation(1, "vonNeuman", v, v.size)
  end
end


function Meadow:_blobs()
  local cells = {}
  cells.cultureThreshold = .01
  cells.maxPopulation = 100000

  self:_targetArea(
    2,2, self._width-1,self._height-1,
    function(x,y)
      if love.math.random() <= cells.cultureThreshold and
        #cells <= cells.maxPopulation then
        table.insert(cells, {x = x, y = y})
      end
    end
  )

  for i, v in ipairs(cells) do
    v.size = self:_rollGrowthPotential(v, 1, 3)
    self:_spacePropogation(1, "vonNeuman", v, v.size)
  end
end


function Meadow:_generateHeatMap(x1,y1, x2,y2)

  local aPath = self:_aStar(x1,y1, x2,y2)

  local heatMap = self:_dijkstra(_,_, aPath)

  return heatMap
end

--

function Meadow:_designatePlayerSpawn()
  local dMap, sptSet = self:_dijkstra()

  local newStart = nil
  for i, v in ipairs(sptSet) do
    if newStart == nil or v.v > newStart.v and v.v ~= 999 then
      newStart = v
    end
  end

  local less = math.random(newStart.v - 3, newStart.v)
  for i, v in ipairs(sptSet) do
    if v.v == less then
      newStart = v
    end
  end

  local dMap, sptSet = self:_dijkstra(newStart.x, newStart.y)

  self:_markSpace(newStart.x, newStart.y, "player")

  return dMap, sptSet
end

function Meadow:_designateStairsSpawn()
  local dMap, sptSet = self:_designatePlayerSpawn()

  local stairs = nil
  for i, v in ipairs(sptSet) do
    if stairs == nil or v.v > stairs.v and v.v ~= 999 then
      stairs = v
    end
  end


  self:_markSpace(stairs.x, stairs.y, "stairs")
end
  --

function Meadow:_spawnRoom(x1, y1, width, height)

  self:_clearArea(x1,y1, x1+width,y1+height)
  self:_fillPerimeter(x1,y1, x1+width,y1+height)

  --Cross Pattern
  for x = x1, x1 + width do
    for y = y1, y1 + height do
      if x == x1 + (width/2) or y == y1 + (height/2) then
        self._map[x][y] = 0
      end
    end
  end
end

function Meadow:_randomRoom()

  local x = love.math.random(2, self._width - 8)
  local y = love.math.random(2, self._height - 8)
  local height = 4
  local width = 4

  self:_designateZoning(x,y, width,height)

  self:_spawnRoom(x, y, width, height)
end

return Meadow
