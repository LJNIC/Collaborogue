local MeadowGen = require "meadowGen"

local function Meadow(level)
  local Gen = MeadowGen(40, 40)
  local map = Gen:_create()
  local rooms = map._rooms

  local function spawnActor(actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function populateStairRoom(room)
    local function spawnStairs()
      local x = room.x1 + (room.width/2)
      local y = room.y1 + (room.height/2)
      spawnActor(actors.Stairs(), x, y)
    end

    local function spawnDoors()
      local centerX = room.x1 + (room.width/2)
      local centerY = room.y1 + (room.height/2)

      spawnActor(actors.Door(), room.x1, centerY)
      spawnActor(actors.Door(), centerX, room.y1)
      spawnActor(actors.Door(), room.x1 + room.width, centerY)
      spawnActor(actors.Door(), centerX, room.y1 + room.height)
    end

    spawnStairs()
    spawnDoors()
  end

  local function populateSpiderZone()
    local room = rooms["nest"]
    local width, height = room.width, room.height
    local x1, y1 = room.x1, room.y1
    local x2, y2 = room.x1 + room.width, room.y1 + room.height

    for x = x1, x2 do
      for y = y1, y2 do
        if love.math.random() >= .6 then
          spawnActor(actors.Web(), x, y)
        end
      end
    end

    spawnActor(actors.Webweaver(), 10, 10)
  end

  local function shroomPath()
    for i, v in ipairs(map._aPath) do
      if i ~= 1 then
        spawnActor(actors.Glowshroom(), v.x, v.y)
      end
    end
  end

  for k, v in pairs(map._markers) do
    if k == "player" then
      spawnActor(game.Player, v.x, v.y)
    end
    if k == "stairs" then
      spawnActor(actors.Stairs(), v.x, v.y)
    end
  end


  shroomPath()
  --populateSpiderZone()
  return map
end

return Meadow
