local MeadowGen = require "meadowGen"

local function Meadow(level)
  local map = MeadowGen(80, 40)
  local map = map:_create()
  local rooms = map._rooms

  local function getRandomEmptySpaceWithinArea(x, y, width, height)

    local x, y = x, y
    local width, height = width, height

    repeat
      x = love.math.random(x, width)
      y = love.math.random(y, height)
    until map._map[x][y] == 0

    return x, y
  end

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function populateStairRoom(room)
    local function spawnStairs()
      local x = room.x + (room.width/2)
      local y = room.y + (room.height/2)
      spawnActor(actors.Stairs(), x, y)
    end

    local function spawnDoors()
      local centerX = room.x + (room.width/2)
      local centerY = room.y + (room.height/2)

      spawnActor(actors.Door(), room.x, centerY)
      spawnActor(actors.Door(), centerX, room.y)
      spawnActor(actors.Door(), room.x + room.width, centerY)
      spawnActor(actors.Door(), centerX, room.y + room.height)
    end

    spawnStairs()
    spawnDoors()
  end

  local function populateSpiderZone()
    local room = rooms["nest"]
    local width, height = room.width, room.height
    local x1, y1 = room.x, room.y
    local x2, y2 = room.x + room.width, room.y + room.height

    for x = x1, x2 do
      for y = y1, y2 do
        if love.math.random() >= .6 then
          spawnActor(actors.Web(), x, y)
        end
      end
    end

    spawnActor(actors.Webweaver(),
               getRandomEmptySpaceWithinArea(x1, y1, x2, y2))
  end

  spawnActor(game.Player, getRandomEmptySpaceWithinArea(1, 1, map._width, map._height))
  populateStairRoom(rooms[1])
  populateSpiderZone()
  return map
end

return Meadow
