local Gen = require "genUtil"

local New = Gen:extend()

function New:__new(width, height)
  self._width = width
  self._height = height

end

function New:_create()
  math.randomseed(os.time())
  self._map = self:_fillMap(1)

  self._zoneMap = self:_newZoneMap()
  self._rooms = {}
  self._markedMap = self:_newMarkedMap()
  self._markers = {}

  self:_imposeMap()
  
  return self
end


function New:_miniMaps()

  local map = {}
  for x = 1, 10 do
    map[x] = {}
    for y = 1, 10 do
      map[x][y] = math.random(0,1)
    end
  end

  for i = 1, 1 do
  
    self:_automata(map)
  end

  return map
end

function New:_imposeMap()
  local map = self:_miniMaps()
  for x = 1, #map do
    for y = 1, #map[x] do
      self._map[x][y] = map[x][y]
    end
  end
end

function New:_isOverlap(x1, y1, x2, y2)
  local bit = false

  for x = x1, x2 do
    for y = y1, y2 do
      if self._zoneMap[x][y] ~= nil then
        bit = true
        break
      end
    end
  end
  return bit
end

function New:_generateHall(room1, room2)
  self:_guidedDrunkWalk(
    self._rooms[room1].centerX, self._rooms[room1].centerY,
    self._rooms[room2].centerX, self._rooms[room2].centerY,
    self._zoneMap, room2
  )
end

function New:_generateRooms()
  self:_defineRoom(8,8, 10,10, "clearing", "Box")

  self:_defineRoom(1,1, 3,3, "entrance", "Player")
  self:_defineRoom(1,1, 3,3, "exit", "Stairs")
  self:_defineRoom(1,1, 3,3, "prism", "Prism")
  self:_defineRoom(1,1, 3,3, "boss", "Webweaver")
  self:_defineRoom(1,1, 3,3, "treasure", "Shard")

  
  self:_generateHall("entrance", "clearing")
  self:_generateHall("exit", "clearing")
  self:_generateHall("boss", "clearing")
  self:_generateHall("prism", "clearing")
  self:_generateHall("boss", "treasure")
  

  for i = 1, 100 do
    self:_DLA()
  end

end

function New:_defineRoom(wMin,wMax, hMin,hMax, identifier, actor)
  local width, height = math.random(wMin, wMax),math.random(hMin, hMax)
  local x, y = nil
  repeat
    x,y = math.random(2+width,39-width),math.random(2+height,39-height)
  until self:_isOverlap(x,y, x+width,y+height) == false

  self:_markSpace(x,y, actor)
  self:_designateZoning(x,y, width,height, identifier)

  self:_clearArea(x,y, x+width-1,y+height-1)
end

function New:_DLA()
  local x1,y1 = nil,nil
  repeat
    x1 = math.random(2, 39)
    y1 = math.random(2, 39)
  until self._map[x1][y1] == 1

  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end
  local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
  local x2, y2 = nil, nil
  repeat
    x2,y2 = x1,y1

    local vec = math.random(1, 4)
    x1 = clamp(x1 + neighbors[vec][1], 2, 39)
    y1 = clamp(y1 + neighbors[vec][2], 2, 39)
  until self._map[x1][y1] == 0

  self:_clearSpace(x2, y2)
end

function New:_drunkWalk(x, y, map, limit)
  local x, y = x, y
  local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end

  repeat
    local vec = math.random(1, 4)
    x = clamp(x + neighbors[vec][1], 2, 39)
    y = clamp(y + neighbors[vec][2], 2, 39)

    self:_clearSpace(x, y)
  until map[x][y] == limit
end

function New:_guidedDrunkWalk(x1, y1, x2, y2, map, limit)
  local x, y = x1, y1

  local neighbors = {}
  if math.max(x1, x2) == x2 then
    table.insert(neighbors, {1,0})
  else
    table.insert(neighbors, {-1,0})
  end
  if math.max(y1, y2) == y2 then
    table.insert(neighbors, {0,1})
  else
    table.insert(neighbors, {0,-1})
  end


  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end

  repeat
    self:_clearSpace(x, y)
    local vec = math.random(1, 2)
    x = clamp(x + neighbors[vec][1], math.min(x1, x2), math.max(x1, x2))
    y = clamp(y + neighbors[vec][2], math.min(y1, y2), math.max(y1, y2))
  until map[x][y] == limit

end


return New
