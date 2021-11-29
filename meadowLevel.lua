local MeadowGen = require "meadowGen"

local function Meadow(level)
  local map = MeadowGen(80, 40)
  local map = map:_create()
  local rooms = map._rooms

  local function getRandomEmptySpace()

    local x = nil
    local y = nil

    repeat
      x = love.math.random(1, map._width - 1)
      y = love.math.random(1, map._height - 1)
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

  spawnActor(game.Player, getRandomEmptySpace())
  spawnActor(actors.Webweaver(), getRandomEmptySpace())
  populateStairRoom(rooms[1])
  return map
end

return Meadow
