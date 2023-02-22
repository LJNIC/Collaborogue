local Gen = require "genUtil"

local Nest = Gen:extend()

function Nest:__new(width, height)
  self._width = width
  self._height = height
end

function Nest:_create()
  self._map = self:_fillMap(1)
  self._rooms = {}
  self._markedMap = self:_newMarkedMap()
  self._markers = {}

  self:_buildRooms()
  return self
end

function Nest:_buildRooms()
  --center
  self:_clearArea(15,15, 25,25)

  --doorPassage
  --self:_clearArea(20,10, 20,15)

  --spawnPassage
  self:_clearArea(20,25, 20,27)
  self:_markSpace(20,26, "door")

  --leftUp
  self:_clearArea(10,17, 15,17)
  self:_clearArea(10,14, 10,17)
  --rightUp
  self:_clearArea(25,17, 30,17)
  self:_clearArea(30,14, 30,17)


  --leftDown
  self:_clearArea(10,23, 15,23)
  self:_clearArea(10,23, 10,27)
  --rightDown
  self:_clearArea(25,23, 30,23)
  self:_clearArea(30,23, 30,27)

  --leftMidUp
  self:_clearArea(5,19, 15,19)
  --leftMidDown
  self:_clearArea(7,21, 15,21)


  --rightMidUp
  self:_clearArea(25,19, 34,19)
  --rightMidDown
  self:_clearArea(25,21, 32,21)


end

return Nest
