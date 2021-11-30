local Object = require "object"
local Gen = require "genUtil"

local City = Gen:extend()

function City:__new(width, height)
  self._width = width
  self._height = height
end

function City:_create()
  self._map = self:_fillMap(1)
  self._rooms = {}
  self._markedMap = self:_newMarkedMap()
  self._markers = {}


  self:_carveMap()
  self:_allocateRooms()
  return self
end

function City:_calcArea(x,y, size)
  local room = {}
  local width,height = size, size
  local x1,y1 =
    math.max(math.floor(x - width/2), 1),
    math.max(math.floor(y - height/2), 1)
  local x2,y2 =
    math.min(math.floor(x + width/2), self._width-1),
    math.min(math.floor(y + height/2), self._height-1)

  room = {
    width = width, height = height,
    x1 = x1, y1 = y1,
    x2 = x2, y2 = y2,
  }

  return room
end

function City:_carveMap()
  local cells = {}
  cells.cultureThreshold = .02
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
    v.size = self:_rollGrowthPotential(v, .5, 8, 3)
    self:_spacePropogation(0, "moore", v, v.size)
  end

  for i, v in ipairs(cells) do
    local room = self:_calcArea(v.x,v.y, v.size)
    self:_designateZoning(room.x1, room.y1, room.width, room.height)

    self:_fillPerimeter(
      math.max(room.x1, 1), math.max(room.y1, 1),
      math.min(room.x2, self._width-1), math.min(room.y2, self._height-1)
      )


    local pick = love.math.random()

    if pick >= 0 and pick <= .24 then
      self:_clearSpace(
        math.max(math.min(room.x1+math.floor(room.width/2), self._width-1), 1),
        math.max(math.min(room.y1, self._height-1), 1)
      )
      self:_markSpace(
        math.max(math.min(room.x1+math.floor(room.width/2), self._width-1), 1),
        math.max(math.min(room.y1, self._height-1), 1),
        "door"
      )
    end

    if pick >= .25 and pick <= .49 then
    self:_clearSpace(
      math.max(math.min(room.x1+math.floor(room.width/2), self._width-1), 1),
      math.max(math.min(room.y2, self._height-1), 1)
    )
    self:_markSpace(
      math.max(math.min(room.x1+math.floor(room.width/2), self._width-1), 1),
      math.max(math.min(room.y2, self._height-1), 1),
      "door"
    )
    end

    if pick >= .50 and pick <= .74 then
    self:_clearSpace(
      math.max(math.min(room.x1, self._width-1), 1),
      math.max(math.min(room.y1+math.floor(room.height/2), self._height-1), 1)
    )
    self:_markSpace(
      math.max(math.min(room.x1, self._width-1), 1),
      math.max(math.min(room.y1+math.floor(room.height/2), self._height-1), 1),
      "door"
    )
    end

    if pick >= .75 and pick <= .99 then
    self:_clearSpace(
      math.max(math.min(room.x2, self._width-1), 1),
      math.max(math.min(room.y1+math.floor(room.height/2), self._height-1), 1)
    )
    self:_markSpace(
      math.max(math.min(room.x2, self._width-1), 1),
      math.max(math.min(room.y1+math.floor(room.height/2), self._height-1), 1),
      "door"
    )
    end

  end
end


function City:_allocateRooms()
  local playerRoom =
    self._rooms[love.math.random(1, #self._rooms)]
  local playerPos =
    {x = love.math.random(playerRoom.x1, playerRoom.x2),
     y = love.math.random(playerRoom.y1, playerRoom.y2)}
  self:_markSpace(playerPos.x, playerPos.y, "player")

  local stairRoom =
    self._rooms[love.math.random(1, #self._rooms)]
  local stairPos =
    {x = love.math.random(stairRoom.x1, stairRoom.x2),
     y = love.math.random(stairRoom.y1, stairRoom.y2)}
  self:_markSpace(stairPos.x, stairPos.y, "stair")

end

return City
