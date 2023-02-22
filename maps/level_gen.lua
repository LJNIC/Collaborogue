local Gen = require "maps.procgen"

function Gen:fillMap(value)
  local map = {}
  for x = 0, self.width do
    map[x] = {}
    for y = 0, self.height do
      map[x][y] = value
    end
  end
  return map
end


local New = Gen:extend()

function New:__new(width, height)
  self.width = width
  self.height = height

end

function New:create()
  --math.randomseed(os.time())
  self.map = self:fillMap(0)

  self.zoneMap = self:newZoneMap()
  self.rooms = {}
  self.markedMap = self:newMarkedMap()
  self.markers = {}

  self:woooork()
  
  return self
end

function New:woooork()

  local function nest()
    local map = self:miniMaps(30,30)
    for i = 1, 2 do
      self:drunkWalk(15,15, map,
                      function(x, y)
                        if not self:posIsInArea(x,y, 10,10, 20,20) then
                          return true
                        end
                      end
      )
    end
    for i = 1, 200 do
      self:DLA(map)
    end
    return map
  end


  local function clearing()
    local map = self:miniMaps(20,20)

    for x = 8, 12 do
      for y = 8, 12 do
        local cx, cy = 10, 10
        local rad = 2
        local dx = (x - cx)^2
        local dy = (y - cy)^2
        if (dx + dy) <= rad^2 then
          map[x][y] = 0
        end
      end
    end

    for i = 1, 100 do
      self:DLAInOut(map)
    end
    return map
  end


  local function entrance()
    local map = self:miniMaps(6,6)
    for i = 1, 1 do
      self:drunkWalk(3,3, map,
                      function(x, y)
                        if not self:posIsInArea(x,y, 0,0, 6,6) then
                          return true
                        end
                      end
      )
    end
    return map
  end

  local function exit()
    local map = self:miniMaps(6,6)
    for i = 1, 1 do
      self:drunkWalk(3,3, map,
                      function(x, y)
                        if not self:posIsInArea(x,y, 0,0, 6,6) then
                          return true
                        end
                      end
      )
    end

    return map
  end


  local function outlineTransformations(map)
    local map = map
    local map1 = self:outline(map, {{x=0,y=0}})

    local function isClearAdjacent(map, x, y)
      local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
      local bit = false

      for i, v in ipairs(neighbors) do
        local x, y = x+v[1], y+v[2]
        if self:posIsInArea(x, y, 0,0, map.width,map.height) then
          if map[x][y] == 0 then
            bit = true
          end
        end
      end

      return bit
    end

    local map2 = {width = map.width, height = map.height}
    for x = 0, #map do
      map2[x] = {}
      for y = 0, #map[x] do
        if map1[x][y] == 999 then
          map2[x][y] = 0
        else
          map2[x][y] = 1
        end
      end
    end

    for x = 0, #map do
      for y = 0, #map[x] do
        if map1[x][y] == 999 then
          map[x][y] = 0
        end
      end
    end

    for x = 0, #map do
      for y = 0, #map[x] do
        if map[x][y] == 1 then
          if isClearAdjacent(map,x,y) then
            map2[x][y] = 1
          else
            map2[x][y] = 0
          end
        end
      end
    end

    return map2
  end

  local function outlineTransformations2(map)
    local map = map
    local map1 = self:outline(map, {{x=0,y=0}})

    local function isClearAdjacent(map, x, y)
      local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
      local bit = false

      for i, v in ipairs(neighbors) do
        local x, y = x+v[1], y+v[2]
        if self:posIsInArea(x, y, 0,0, map.width,map.height) then
          if map[x][y] == 0 then
            bit = true
          end
        end
      end

      return bit
    end

    local map2 = {width = map.width, height = map.height}
    for x = 0, #map do
      map2[x] = {}
      for y = 0, #map[x] do
        if map1[x][y] == 999 then
          map2[x][y] = 0
        else
          map2[x][y] = 1
        end
      end
    end


    local map3 = {}
    for x = 0, #map do
      map3[x] = {}
      for y = 0, #map[x] do
        map3[x][y] = map[x][y]
      end
    end


    for x = 0, #map do
      for y = 0, #map[x] do
        if map1[x][y] == 999 then
          map[x][y] = 0
        end
      end
    end

    for x = 0, #map do
      for y = 0, #map[x] do
        if map[x][y] == 1 then
          if isClearAdjacent(map,x,y) then
            map2[x][y] = 1
          else
            map2[x][y] = 0
          end
        end
      end
    end

    for x = 0, #map do
      for y = 0, #map[x] do
        if map3[x][y] == 1 and map1[x][y] == 999 then
          map2[x][y] = 1
        end
      end
    end

    return map2
  end



  local function getLines(map)

    local startPos = {}
    for x = 0, #map do
      for y = 0, #map[x] do
        if map[x][y] == 1 then
          startPos = {x=x,y=y}
        end
      end
    end

    local lines = {{startPos}}
    local neighbors = {
      {-1,1},{0,1},{1,1},
      {-1,0},      {1,0},
      {-1,-1},{0,-1},{1,-1}
    }

    while true do
      local line = lines[#lines]
      local start = line[1]
      for i, v in ipairs(neighbors) do
        if #lines == 1 or
          not (v[1] == lines[#lines-1].vec[1] * -1 and v[2] == lines[#lines-1].vec[2] * -1)
        then

          local x, y = start.x+v[1], start.y+v[2]
          if self:posIsInArea(x,y, 0,0, #map,#map[1]) then
            if map[x][y] == 1 then
              line.vec = {v[1],v[2]}
              table.insert(line, {x=x,y=y})
              break
            end
          end
        end
      end

      repeat
        local x = line[#line].x + line.vec[1]
        local y = line[#line].y + line.vec[2]

        if self:posIsInArea(x,y, 0,0, #map,#map[1]) then
          if map[x][y] == 1 then
            table.insert(line, {x=x,y=y})
          end
        end
      until map[x][y] ~= 1

      if
        line[#line].x == startPos.x and
        line[#line].y == startPos.y
      then
        break
      end

      table.insert(lines, {line[#line]})

    end


    return lines
  end


  local function combineMaps(map1, map2)

    local bmap1 = outlineTransformations2(map1)
    local bmap2 = outlineTransformations2(map2)

    local map1 = outlineTransformations(map1)
    local map2 = outlineTransformations(map2)

    local lines1 = getLines(map1)
    local lines2 = getLines(map2)

    local matches = {}
    for i, v in ipairs(lines1) do
      for i2, v2 in ipairs(lines2) do
        if #v == #v2 and v.vec[1] == v2.vec[1] and v.vec[2] == v2.vec[2] then
          if #v > 2 and #v2 > 2 then
            table.insert(matches, {v, v2})
          end
        end
      end
    end

    local center = {x=30,y=30}


    local function constructMap(match)
      local result = self:miniMaps(80, 80, 0)

      local diff1 = {x = center.x - match[1][1].x, y = center.y - match[1][1].y}
      for x = 0, #map1 do
        for y = 0, #map1[x] do
          if map1[x][y] == 1 then
            result[x+diff1.x][y+diff1.y] = 1
          end
        end
      end

      local diff2 = {x = center.x - match[2][1].x, y = center.y - match[2][1].y}
      for x = 0, #map2 do
        for y = 0, #map2[x] do
          if map2[x][y] == 1 then
            result[x+diff2.x][y+diff2.y] = 1
          end
        end
      end

      for i = 1, #match[1] do
        if
          result[center.x + match[1][i].x][center.y + match[1][i].y] == 0
        then
          --error("whaaa?")
        end
      end

      return result
    end

    local function testMapShape()
      local app = 0
      while true do

        local result = constructMap(matches[1])

        local neighbors = {
          {-1,1},{0,1},{1,1},
          {-1,0},      {1,0},
          {-1,-1},{0,-1},{1,-1}
        }


        local lastPoint = {x = center.x, y = center.y}
        local point = {}

        if result[lastPoint.x][lastPoint.y] ~= 1 then
          error("Miss")
        end

        while true do
          local hits = 0
          local broken = false

          for i, v in ipairs(neighbors) do
            local x, y = lastPoint.x + v[1], lastPoint.y + v[2]
            if x ~= lastPoint.x and y ~= lastPoint.y then

              if hits > 0 then
                broken = true
                break
              end

              if result[x][y] == 1 then
                point.x, point.y = x, y
                hits = hits + 1
              end

            end
          end

          if broken == true then
            break
          end

          if point.x == center.x and point.y == center.y then
            error("yay")
          end

          lastPoint.x, lastPoint.y = point.x, point.y
        end

        table.remove(matches, 1)
        if app == 1 then
          return result
        end
        app = app + 1
      end

    end


    local result = testMapShape()
    return result
  end


  local map = combineMaps(nest(), clearing())
  self:imposeMap(map, 1, 1)

end

function New:outline(map1, set, neighborhood)
  local neighborhood = neighborhood or "vonNeuman"
  local neighbors = self:getNeighborhood(neighborhood)
  local map = self:miniMaps(map1.width, map1.height, 999)
  local traveled = {}

  for i, v in ipairs(set) do
    map[v.x][v.y] = 0
  end

  local function isClear(x, y)
    return map1[x][y] == 0
  end
  local function isClearAdjacent(map, x, y)
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local bit = false

    for i, v in ipairs(neighbors) do
      local x, y = x+v[1], y+v[2]
      if self:posIsInArea(x, y, 0,0, map.width,map.height) then
        if map[x][y] == 0 then
          bit = true
        end
      end
    end

    return bit
  end

  local function isTraveled(x, y)
    local bit = false
    for _, v in ipairs(traveled) do
      if v.x == x and v.y == y then
        bit = true
        break
      end
    end

    return bit
  end

  local function getLeast(mdp, x, y)
    if mdp.v > map[x][y] then
      return {v = map[x][y], x=x,y=y}
    else
      return mdp
    end
  end

  while true do
    local minimumDistancePos = {v = 999}
    local mdp = minimumDistancePos


    for x = 0, map1.width do
      for y = 0, map1.height do
        if not isClear(x, y) then
          if not isTraveled(x, y) then
            mdp = getLeast(mdp, x, y)
          end
        end
      end
    end
    

    if mdp.x == nil then
      break
    end


    table.insert(traveled, mdp)


    for _, v in pairs(neighbors) do
      local newPos = {x = mdp.x + v[1], y = mdp.y + v[2]}
      if self:posIsInArea(newPos.x, newPos.y, 0,0, map1.width,map1.height) then
        if not isClear(newPos.x, newPos.y) then
          if not isClearAdjacent(map1, mdp.x, mdp.y) then
            map[newPos.x][newPos.y] = math.min(mdp.v + 1, map[newPos.x][newPos.y])
          end
        end
      end
    end

  end

  return map, traveled
end


function New:miniMaps(width, height, value)
  local map = {}
  map.width = width
  map.height = height
  for x = 0, map.width do
    map[x] = {}
    for y = 0, map.height do
      map[x][y] = value or 1
    end
  end
  return map
end

function New:imposeMap(map, tx, ty)
  local tx,ty = tx or 0, ty or 0
  for x = 0, #map do
    for y = 0, #map[x] do
      self.map[x+tx][y+ty] = map[x][y]
    end
  end
end

function New:combineMaps(map1, map2)
  local map = {}
  map.width = map1.width + map2.width
  map.height = map1.height + map2.height

  local function isClearAdjcent(map, x, y)
    local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
    local bit = false

    for i, v in ipairs(neighbors) do
      local x, y = x+v[1], y+v[2]
      if self:posIsInArea(x, y, 0,0, map.width,map.height) then
        if map[x][y] == 0 then
          bit = true
        end
      end
    end

    return bit
  end

  for x = 0, map1.width do
    map[x] = {}
    for y = 0, map1.height do
      if map1[x][y] == 1 then
        if isClearAdjcent(map1, x, y) then
          map[x][y] = map1[x][y]
        else
          map[x][y] = 0
        end
      else
        map[x][y] = 0
      end
    end
  end

  for x = 0, map2.width do
    map[x+map1.width] = {}
    for y = 0, map2.height do
      if map2[x][y] == 1 then
        if isClearAdjcent(map2, x, y) then
          map[x+map1.width][y] = map2[x][y]
        else
          map[x+map1.width][y] = 0
        end
      else
        map[x+map1.width][y] = 0
      end
    end
  end


  return map
end

function New:isOverlap(x1, y1, x2, y2)
  local bit = false

  for x = x1, x2 do
    for y = y1, y2 do
      if self.zoneMap[x][y] ~= nil then
        bit = true
        break
      end
    end
  end
  return bit
end

function New:generateHall(room1, room2)
  self:guidedDrunkWalk(
    self.rooms[room1].centerX, self.rooms[room1].centerY,
    self.rooms[room2].centerX, self.rooms[room2].centerY,
    self.zoneMap, room2
  )
end

function New:generateRooms()
  self:defineRoom(8,8, 10,10, "clearing", "Box")

  self:defineRoom(1,1, 3,3, "entrance", "Player")
  self:defineRoom(1,1, 3,3, "exit", "Stairs")
  self:defineRoom(1,1, 3,3, "prism", "Prism")
  self:defineRoom(1,1, 3,3, "boss", "Webweaver")
  self:defineRoom(1,1, 3,3, "treasure", "Shard")

  self:generateHall("entrance", "clearing")
  self:generateHall("exit", "clearing")
  self:generateHall("boss", "clearing")
  self:generateHall("prism", "clearing")
  self:generateHall("boss", "treasure")

  for i = 1, 100 do
    self:DLA()
  end

end

function New:defineRoom(wMin,wMax, hMin,hMax, identifier, actor)
  local width, height = math.random(wMin, wMax),math.random(hMin, hMax)
  local x, y = nil
  repeat
    x,y = math.random(1+width,39-width),math.random(1+height,39-height)
  until self:isOverlap(x,y, x+width,y+height) == false

  self:markSpace(x,y, actor)
  self:designateZoning(x,y, width,height, identifier)

  self:clearArea(x,y, x+width-1,y+height-1)
end

function New:DLA(map)
  local x1,y1 = nil,nil
  repeat
    x1 = math.random(2, map.width-2)
    y1 = math.random(2, map.height-2)
  until map[x1][y1] == 1

  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end
  local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
  local x2, y2 = nil, nil
  repeat
    x2,y2 = x1,y1

    local vec = math.random(1, 4)
    x1 = clamp(x1 + neighbors[vec][1], 2, map.width-2)
    y1 = clamp(y1 + neighbors[vec][2], 2, map.height-2)
  until map[x1][y1] == 0

  map[x2][y2] = 0
end

function New:drunkWalk(x, y, map, exitFunc)
  local x, y = x, y
  local neighbors = {{1,0},{-1,0},{0,1},{0,-1}}
  local function clamp(n, min, max)
    local n = math.max(math.min(n, max), min)
    return n
  end

  repeat
    local vec = math.random(1, 4)
    x = clamp(x + neighbors[vec][1], 1, map.width-1)
    y = clamp(y + neighbors[vec][2], 1, map.height-1)

    map[x][y] = 0
  until exitFunc(x,y) == true
end

function New:guidedDrunkWalk(x1, y1, x2, y2, map, limit)
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
    self:clearSpace(x, y)
    local vec = math.random(1, 2)
    x = clamp(x + neighbors[vec][1], math.min(x1, x2), math.max(x1, x2))
    y = clamp(y + neighbors[vec][2], math.min(y1, y2), math.max(y1, y2))
  until map[x][y] == limit

end


return New
