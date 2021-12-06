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

  self._aPath = self:_aStar(self._markers["player"].x,self._markers["player"].y,
                            self._markers["stairs"].x,self._markers["stairs"].y
  )

  --self._aPath = self:_generateHeatMap(self._markers["player"].x,self._markers["player"].y,
  --                                    self._markers["stairs"].x,self._markers["stairs"].y
  --)

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


--

function Meadow:_aStar(x1,y1, x2,y2)

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

function Meadow:_generateHeatMap()

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
