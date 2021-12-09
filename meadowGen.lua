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


function Meadow:_spiderZone(x,y)
  local size = self:_rollGrowthPotential({x, y}, .9, 7, 4)
  local spiderChance = .10
  local spiderLimit = size / 2

  local cells = self:_dijkstra({{x=x, y=y}})

  for x, v in ipairs(cells) do
    for y, w in ipairs(v) do
      if w <= size then
        if love.math.random() <= .5 then
          self:_markSpace(x, y, "Web")
        end

        if spiderLimit > 0 then
          if love.math.random() <= spiderChance then
            spiderChance = spiderChance - .50
            spiderLimit = spiderLimit - 1
            self:_markSpace(x, y, "Webweaver")
          end
        else
          spiderChance = spiderChance + .10
        end
      end
    end
  end
end

function Meadow:_sqeetoZone(x, y)
  local sqeetoLimit = 6
  local size = self:_rollGrowthPotential({x, y}, .9, 7, 4)

  local cells = self:_dijkstra({{x=x, y=y}})

  for x, v in ipairs(cells) do
    for y, w in ipairs(v) do
      if w <= size then
        if love.math.random() <= .2 then
          if sqeetoLimit ~= 0 then
            sqeetoLimit = sqeetoLimit - 1
            self:_markSpace(x, y, "Sqeeto")
          end
        end
      end
    end
  end
end

function Meadow:_crystalZone(x,y)
  local size = self:_rollGrowthPotential({x, y}, .3, 5, 2)

  local cells = self:_dijkstra({{x=x, y=y}})

  for x, v in ipairs(cells) do
    for y, w in ipairs(v) do
      if w <= size then
        self:_markSpace(x, y, "Shard")
      end
    end
  end
end

function Meadow:_farmZone(x,y)
  local size = self:_rollGrowthPotential({x, y}, .3, 5, 2)

  local cells = self:_dijkstra({{x=x, y=y}}, "moore")

  self:_markSpace(x, y, "Shopkeep")

  for x, v in ipairs(cells) do
    for y, w in ipairs(v) do
      if w <= size then
        self:_markSpace(x, y, "Snip")
      end
    end
  end

end

function Meadow:_pondZone(x,y)
  local size = self:_rollGrowthPotential({x, y}, .3, 5, 2)

  local cells = self:_dijkstra({{x=x, y=y}})

  for x, v in ipairs(cells) do
    for y, w in ipairs(v) do
      if w <= size then
        self:_markSpace(x, y, "Box")
      end
    end
  end
end

function Meadow:_treasureZone(x,y)
  self:_markSpace(x, y, "Chest")
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


  local testCells = {}
  for x = 1, self._width do
    for y = 1, self._height do
      local path = pathMap[x][y]
      local edge = pathMap.max

      if path >= 1 and path <= edge then
        table.insert(testCells, {x=x,y=y, v=path})
      end

    end
  end

  local uniques = {}
  for i, v in ipairs(testCells) do
    for j, w in ipairs(testCells) do
      local d = math.abs(v.x - w.x)+math.abs(v.y - w.y)

      if d <= 8 then
        testCells[j] = v
        uniques[tostring(v.x)..","..tostring(v.y)] = {x=v.x,y=v.y}
      end
    end
  end

  local sortie = {}
  for k, v in pairs(uniques) do
    local a = pathMap[v.x][v.y]
    local d = dMap[v.x][v.y]

    table.insert(sortie, {a=a,d=d,x=v.x,y=v.y})
  end


  ----
  --FarFar
  do
  local eSpace = {}
  for i,v in ipairs(sortie) do
    local rank = v.a + v.d
    if eSpace.v == nil or eSpace.v < rank then
      eSpace.v = rank
      eSpace.x = v.x
      eSpace.y = v.y
    end
  end

    local seed = {x = eSpace.x, y = eSpace.y}
    local map = self:_dijkstra({seed})
    for x = 1, self._height do
      for y = 1, self._width do
        if map[x][y] <= 4 then
         -- self:_markSpace(x,y, "Web")
        end
      end
    end
  end


  do
    local paths = {}
    for i, v in ipairs(sortie) do
      local rank = v.a
      if rank <= 6 then
        table.insert(paths, v)
      end
    end

    local map = self:_dijkstra(paths)
    for x = 1, self._height do
      for y = 1, self._width do
        if map[x][y] <= 1 then
          self:_markSpace(x,y, "Web")
        end
      end
    end
  end

  for k, v in pairs(uniques) do
    self:_markSpace(v.x,v.y, "Box")
  end

--[[
  local bignum = -1

  for x = 1, self._width do
    for y = 1, self._height do
      if pathMap[x][y] + dMap[x][y] < 998 then
        bignum = math.max(pathMap[x][y] + dMap[x][y], bignum)
      end
    end
  end

  local zones = {}
  local farms = 0
  local crystals = 0
  local sqeetos = 0
  for x = 1, self._width do
    for y = 1, self._height do
      local path = pathMap[x][y] + dMap[x][y]
      local edge = bignum

      local path2 = pathMap[x][y]
      local edge2 = pathMap.max

      local function notWall(v)
        if not (v >= 999) then
          return true
        end
      end

      if path2 <= 5 then
        if love.math.random() <= .02 then
          self:_markSpace(x, y, "Glowshroom")
        end
      end

      if path2 <= 3 then
        if path >= 5 and path <= 1*edge/3 then
          zones.ponds = zones.ponds or 0
          if zones.ponds == 0 then
            self:_pondZone(x,y)
            zones.ponds = zones.ponds + 1
          end
        end
      end

      if path >= 3 and path <= edge/3 then
        if farms == 0 then
          self:_farmZone(x,y)
          farms = farms + 1
        end
      end

      if path >= edge/3 and path <= 2*edge/3 then
        if crystals == 0 then
          self:_crystalZone(x,y)
          crystals = crystals + 1
        end
      end

      if path2 >= edge2/3 and path2 <= 2*edge2/3 then
        if path >= 2*edge/3 and path <= 3*edge/3 then
          if sqeetos == 0 then
            self:_sqeetoZone(x,y)
            sqeetos = sqeetos + 1
          end
        end
      end

      if path2 >= 2*edge2/3 and path2 <= edge2 then
        zones.spiders = zones.spiders or 0
        if zones.spiders == 0 then
          self:_spiderZone(x,y)
          zones.spiders = zones.spiders + 1
        end
      end

      if path2 >= 2*edge2/3 and path2 <= edge2 then
        zones.treasure = zones.treasure or 0
        if zones.treasure < 2 then
          self:_treasureZone(x,y)
          zones.treasure = zones.treasure + 1
        end
      end

    end
  end
]]--
  
end

return Meadow
