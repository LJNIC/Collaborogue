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

function Meadow:_dijkstra(x, y)
  local vonNeuman = {
    n = {0, -1},
    e = {1, 0},
    s = {0, 1},
    w = {-1, 0},
  }

  local sptSet = {}
  local dMap = {}
  for x = 1, self._width do
    dMap[x] = {}
    for y = 1, self._height do
      dMap[x][y] = 999
    end
  end

  local centerX, centerY = self._width-20, self._height-20
  local startX, startY = x or centerX, y or centerY

  if self._map[startX][startY] == 0 then
    dMap[startX][startY] = 0
  else
    repeat
      startX = startX + love.math.random(-5, 5)
      startY = startY + love.math.random(-5, 5)
    until self._map[startX][startY] == 0
    dMap[startX][startY] = 0
  end


  local function hell()
    local function updateMDV(mdv, x, y)
      mdv.v = dMap[x][y]
      mdv.x = x
      mdv.y = y

      return mdv
    end

    while true do
      local mdv = {}

      for x = 1, self._width do
        for y = 1, self._height do

          if self._map[x][y] ~= 1 then
            local skip = false

            if #sptSet ~= 0 then
              for i, v in ipairs(sptSet) do
                if v.x == x and v.y == y then
                  skip = true
                end
              end
            end

            if skip == false then
              if
                mdv.v == nil or mdv.v > dMap[x][y]
              then
                mdv = updateMDV(mdv, x, y)
              end
            end

          end
        end
      end

      if mdv.x == nil then
        break
      end

      table.insert(sptSet, mdv)
      for i, v in pairs(vonNeuman) do
        if self:_posIsInMap(mdv.x + v[1], mdv.y + v[2]) then
          if self._map[mdv.x+v[1]][mdv.y+v[2]] ~= 1 then
            dMap[mdv.x + v[1]][mdv.y + v[2]] = math.min(mdv.v + 1, dMap[mdv.x+v[1]][mdv.y+v[2]])
          end
        end
      end

    end
  end

  hell()

  for x, v in ipairs(dMap) do
    for y, w in ipairs(v) do
      if w == 999 then
        self._map[x][y] = 1
      end
    end
  end

  return dMap, sptSet
end


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

  local less = math.random(stairs.v - 3, stairs.v)
  for i, v in ipairs(sptSet) do
    if v.v == less then
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
