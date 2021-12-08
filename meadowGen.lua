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


  self:_designateActorSpawns()
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


function Meadow:_generateHeatMaps(x1,y1, x2,y2)
  local aPath = self:_aStar(x1,y1, x2,y2)

  local pathMap = self:_dijkstra(aPath)

  return pathMap
end















function Meadow:_designateActorSpawns()
  local function getFloorNearArea(x, y)
    local x,y = x,y

    if self._map[x][y] == 0 then
      return {x=x, y=y}
    else
      repeat
        x = math.max(math.min(x + love.math.random(-5, 5), self._width), 1)
        y = math.max(math.min(y + love.math.random(-5, 5), self._height), 1)
      until self._map[x][y] == 0
      return {x=x, y=y}
    end
  end


  local dMap, sptSet = self:_dijkstra({getFloorNearArea(20,20)})

  for x = 1, self._width do
    for y = 1, self._height do
      if dMap[x][y] == 999 then
        self._map[x][y] = 1
      end
    end
  end



  local dMapOrigin = nil
  for i, v in ipairs(sptSet) do
    if dMapOrigin == nil or v.v > dMapOrigin.v and v.v ~= 999 then
      dMapOrigin = v
    end
  end

  local dMap, sptSet = self:_dijkstra({dMapOrigin})

  local dMapFarPos = nil
  for i, v in ipairs(sptSet) do
    if dMapFarPos == nil or v.v > dMapFarPos.v and v.v ~= 999 then
      dMapFarPos = v
    end
  end

  self:_markSpace(dMapOrigin.x, dMapOrigin.y, "Player")
  self:_markSpace(dMapFarPos.x, dMapFarPos.y, "Stairs")





  local pathMap = self:_generateHeatMaps(dMapOrigin.x,dMapOrigin.y, dMapFarPos.x,dMapFarPos.y)


  for x = 1, self._width do
    for y = 1, self._width do
      if pathMap[x][y] ~= 999 then
        if pathMap.max == nil or pathMap[x][y] > pathMap.max then
          pathMap.max = pathMap[x][y]
        end
      end
    end
  end

  for x = 1, self._width do
    for y = 1, self._height do
      local path = pathMap[x][y]

      local edge = pathMap.max

      local function notWall(v)
        if not (v >= 999) then
          return true
        end
      end

      if path >= 0 and path <= 1 then
        self:_markSpace(x, y, "Glowshroom")
      end

      if path > 1 and path <= edge/3 and notWall(path) then
          self:_markSpace(x, y, "Shard")
      end

      if path > edge/3 and path <= 2*edge/3 and notWall(path) then
        self:_markSpace(x, y, "Web")
      end

      if path > 2*edge/3 and path <= edge and notWall(path) then
        self:_markSpace(x, y, "Arrow")
      end



      --if path <= 5 and notWall(path) then
        --if love.math.random() <= .02 then
          --self:_markSpace(x, y, "Glowshroom")
        --end
      --end



      
    end
  end

end

return Meadow
