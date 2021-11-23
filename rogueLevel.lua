local function Populater(level)
  local map = ROT.Map.Rogue(100 - 11, 44)
  local map = map:create()

  local function spawnActor(room, actor, x, y)
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function populateStartRoom(room)
    spawnActor(room, game.Player, 10, 10)
  end

  local startRoom = table.remove(map._rooms, love.math.random(1, #map._rooms))
  populateStartRoom(startRoom)

  return map
end

return Populater
