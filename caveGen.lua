local Gen = require "genUtil"

local Cave = Gen:extend()

function Cave:__new(width, height)
	self._width = width
	self._height = height
end

function Cave:_create()
	self._map = self:_fillMap(1)
	self._rooms = {}
	self._markedMap = self:_newMarkedMap()
	self._markers = {}

	self:_carveTunnels()
	self:_allocateRooms()
	return self
end

function Cave:_carveTunnels()
	local function clamp(n, min, max)
		return math.min(math.max(n, min), max)
	end


	local function carveVertical()
		local cells = {}
		cells.cultureThreshold = .5
		cells.maxPopulation = 100000

		local x = love.math.random(10, 30)
		for y = 2, self._height - 2 do
			if love.math.random() >= .50 then
				x = x + 2
			else
				x = x - 2
			end

			x = clamp(x, 1, 40)
			table.insert(cells, {x = x, y = y})
		end

		for i, v in ipairs(cells) do
			v.size = self:_rollGrowthPotential(v, .1, 3, 1)
			self:_spacePropogation(0, "vonNeuman", v, v.size)
			self:_designateZoning(v.x, v.y, v.size, v.size)
		end
	end

	local function carveHorizontal()
		local cells = {}
		cells.cultureThreshold = .5
		cells.maxPopulation = 100000

		local y = love.math.random(10, 30)
		for x = 2, self._width - 2 do
			if love.math.random() >= .50 then
				y = y + 2
			else
				y = y - 2
			end
			y = clamp(y, 1, 40)
			table.insert(cells, {x = x, y = y})
		end

		for i, v in ipairs(cells) do
			v.size = self:_rollGrowthPotential(v, .1, 3, 1)
			self:_spacePropogation(0, "vonNeuman", v, v.size)
			self:_designateZoning(v.x, v.y, v.size, v.size)
		end
	end

	carveVertical()
	carveHorizontal()
end

function Cave:_allocateRooms()
	local playerRoom =
		self._rooms[1]
	local playerPos =
		{x = love.math.random(playerRoom.x1, playerRoom.x2),
		 y = love.math.random(playerRoom.y1, playerRoom.y2)}
	self:_markSpace(playerPos.x, playerPos.y, "player")

	local stairRoom =
		self._rooms[love.math.random(2, #self._rooms)]
	local stairPos =
		{x = love.math.random(stairRoom.x1, stairRoom.x2),
		 y = love.math.random(stairRoom.y1, stairRoom.y2)}
	self:_markSpace(stairPos.x, stairPos.y, "stair")

	for x = stairRoom.x1 - 2, stairRoom.x2 + 2 do
		for y = stairRoom.y1 - 2, stairRoom.y2 + 2 do
			if love.math.random() <= .50 then
				self:_markSpace(x, y, "web")
			end
		end
	end

	for i, v in ipairs(self._rooms) do
		local function clamp(n, min, max)
			return math.min(math.max(n, min), max)
		end

		local x = clamp(love.math.random(v.x1 - 2, v.x2 + 2), 2, 39)
		local y = clamp(love.math.random(v.y1 - 2, v.y2 + 2), 2, 39)

		if love.math.random() <= .25 then
			self:_markSpace(x, y, "web")
		end
	end

end

return Cave
