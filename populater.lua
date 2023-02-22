local function Populater(level)
  local map = ROT.Map.Brogue(100 - 11, 44)
  local map = map:create()

  local spawnedPrism = false
  local treasureRoom = false
  local store = false
  local toSpawn = {}
  local roomsLeft = #map._rooms - 1 -- subtract the starting room
  local doors = {}

  local function hash(x, y)
    return x and y * 0x4000000 + x or false --  26-bit x and y
  end

  local function spawnActor(room, actor, x, y)
    local _x, _y = room:getRandomWalkableTile()
    local x, y = x or _x, y or _y
    actor.position.x = x
    actor.position.y = y
    level:addActor(actor)
  end

  local function moveActorToRoom(room, actor)
    local x, y = room:getRandomWalkableTile()
    actor.position.x = x
    actor.position.y = y
  end

  local function spawnDoors(room)
    for _, x, y in room._doors:each() do
      if not doors[hash(x, y)] and math.random() > 0.50 then
        local door = actors.Door()
        door.position.x = x
        door.position.y = y

        level:addActor(door)
        doors[hash(x,y)] = true
      end
    end
  end

  local function spawnShards(room, i, j)
    for i = 1, love.math.random(i, j) do
      spawnActor(room, actors.Shard())
    end
  end

  local function spawnShrooms(room, i, j)
    for i = 1, love.math.random(i, j) do
      spawnActor(room, actors.Glowshroom())
    end
  end

  local function populateStartRoom(room)
    spawnDoors(room)
    spawnActor(room, game.Player)
    spawnActor(room, actors.Box())
    spawnActor(room, actors.Snip())
  --  spawnActor(room, actors.Gazer())
  end

  local chestContents = {
    actors.Ring_of_protection,
    actors.Ring_of_vitality,
    actors.Armor,
    actors.Cloak_of_invisibility,
    actors.Slippers_of_swiftness,
    actors.Wand_of_lethargy,
    actors.Wand_of_swapping,
    actors.Wand_of_fireball,
    actors.Wand_of_displacement,
    actors.Dagger_of_venom
  }

  local function populateShopRoom(room)
    local shop = actors.Shopkeep()
    shop.position.x, shop.position.y = room:getCenterTile()
    shop.position.x = shop.position.x - 3
    level:addActor(shop)

    local torch = actors.Stationarytorch()
    torch.position.x, torch.position.y = shop.position.x, shop.position.y
    torch.position.x = shop.position.x - 1
    level:addActor(torch)

    local shopItems = {
      {
        components.Weapon,
        components.Wand
      },
      {
        components.Equipment
      },
      {
        components.Edible,
        components.Drinkable,
        components.Readable
      }
    }
    for i = 1, 3 do
      local itemTable =shopItems[i]
      local item = Loot.generateLoot(itemTable[love.math.random(1, #itemTable)])
      local product = actors.Product()
      product.position.x = shop.position.x + i*2
      product.position.y = shop.position.y

      product:setItem(item)
      product:setPrice(actors.Shard, item.cost)
      product:setShopkeep(shop)
      level:addActor(product)
    end
  end

  local function populateTreasureRoom(room)
    treasureRoom = true
    local locked = false

    if roomsLeft <= #toSpawn then
      locked = false
    elseif love.math.random() > .5 then
      locked = true
    end

    local chest = actors.Chest()
    local key = actors.Key()

    table.insert(chest.inventory, chestContents[math.random(#chestContents)]())

    chest:setKey(key)
    spawnActor(room, chest)
    table.insert(toSpawn, key)

    spawnShards(room, 3, 10)
  end

  local function populateSpiderRoom(room)
    spawnActor(room, actors.Webweaver())
  end

  local function populateRoom(room)

    if #room._doors == 2 and not treasureRoom then
      populateTreasureRoom(room)
      return
    end

    if not store and love.math.random(1, roomsLeft)/roomsLeft > 0.6 then
      store = true
      populateShopRoom(room)
      return
    end

    if roomsLeft <= #toSpawn and not (#toSpawn == 0) then
      local actor = table.remove(toSpawn, 1)
      spawnActor(room, actor)
      room.actors = room.actors or {}
      table.insert(room.actors, actor)

      if math.random() > 0.50 then
        populateSpiderRoom(room)
      end
      return
    end

    if false then
      spawnShards(room, 2, 4)
      spawnShrooms(room, 0, 2)
      spawnActor(room, actors.Snip())
      spawnActor(room, actors.Snip())
      spawnActor(room, actors.Snip())
      return
    end

    spawnShards(room, 0, 2)
    spawnShrooms(room, 0, 2)
    spawnActor(room, actors.Sqeeto())
    spawnActor(room, actors.Gloop())
  end

  table.insert(toSpawn, actors.Prism())
  table.insert(toSpawn, actors.Stairs())

  local startRoom = table.remove(map._rooms, love.math.random(1, #map._rooms))

  for _, room in ipairs(map._rooms) do
    roomsLeft = roomsLeft - 1
    populateRoom(room)
  end

  populateStartRoom(startRoom)

  return map
end

return Populater
