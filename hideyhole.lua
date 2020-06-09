-- the hidey hole in which the player hides bomb components
-------------------------------------------------------------------------------

hideyhole = {}


-- CONSTANTS
-------------------------------------------------------------------------------
local HMIN = 0
local HMAX = 476

local BUILD_TICK = 0.25	-- time in seconds between each build tick

-- position of the progress bar
local PROGRESS_X = 227
local PROGRESS_Y = 0

-- system-dependent variables
if LINUX_VERSION then
	HMIN = 29
	PROGRESS_Y = 251
elseif WINDOWS_VERSION then
	HMIN = 27
	PROGRESS_Y = 252
end


-- LOCAL DATA
-------------------------------------------------------------------------------
-- the items in the hideyhole
local items = {}
local hasAllMaterials = false
local playerOverlap = false -- whether the player overlaps the hidey-hole

-- clock to tick while we build bomb
local clockBuild = nil


-- HIDEY-HOLE METHODS
-------------------------------------------------------------------------------

function hideyhole.place()
	-- randomly place the hidey-hole on an edge
	local v = math.floor(math.random() * 4)
	if 0 == v then	-- top
		hideyhole.x = HMIN + math.floor(math.random() * 446)
		hideyhole.y = HMIN
	elseif 1 == v then	-- bottom
		hideyhole.x = HMIN + math.floor(math.random() * 446)
		hideyhole.y = HMAX
	elseif 2 == v then	-- left
		hideyhole.x = HMIN
		hideyhole.y = HMIN + math.floor(math.random() * 446)
	else	-- right
		hideyhole.x = HMAX
		hideyhole.y = HMIN + math.floor(math.random() * 446)
	end
	
	-- bomb progress is nil
	hideyhole.bombprogress = 0

	-- player isn't over it
	hideyhole.playerabove = false

	-- not holding anything
	items[ItemTypes.GASCAN] = false
	items[ItemTypes.POWDER] = false
	items[ItemTypes.DEBRIS] = false
	items[ItemTypes.TIMER] = false
	hasAllMaterials = false
end


function hideyhole.nextItem()
	if not items[ItemTypes.GASCAN] then
		return ItemTypes.GASCAN
	elseif not items[ItemTypes.POWDER] then
		return ItemTypes.POWDER
	elseif not items[ItemTypes.DEBRIS] then
		return ItemTypes.DEBRIS
	elseif not items[ItemTypes.TIMER] then
		return ItemTypes.TIMER
	else
		return nil
	end
end


function hideyhole.playerOverlaps()
	return playerOverlap
end


function hideyhole.depositItem(iType)
	items[iType] = true
	if (true == items[ItemTypes.GASCAN]) and (true == items[ItemTypes.POWDER]) and (true == items[ItemTypes.DEBRIS]) and (true == items[ItemTypes.TIMER]) then
		hasAllMaterials = true
		clockBuild = love.timer.getTime()
	end
end


function hideyhole.hasAllMaterials()
	return hasAllMaterials
end


function hideyhole.bombComplete()
	return hideyhole.bombprogress >= 56
end


-- BASE GAME LOOP FUNCTIONS
-------------------------------------------------------------------------------

function hideyhole.update(dt)
	local px, py = player.getfloorpos()
	
	-- a bit of a complicated check, necessitated by the odd shape of the player and hidey-hole
	local minx, maxx, miny, maxy
	if hideyhole.x < px then
		minx = hideyhole.x
	else
		minx = px
	end
	
	if hideyhole.x + 8 < px + 8 then
		maxx = px + 8
	else
		maxx = hideyhole.x + 8
	end
	
	if hideyhole.y < py then
		miny = hideyhole.y
	else
		miny = py
	end
	
	if hideyhole.y + 8 < py + 11 then
		maxy = py + 11
	else
		maxy = hideyhole.y + 8
	end

	-- see if player overlaps the hidey-hole
	playerOverlap = ((maxx-minx < 16) and (maxy-miny < 19))
	
	-- see if we should increment our clock tick
	if (playerOverlap and hasAllMaterials) then
		local now = love.timer.getTime()
		if now - clockBuild > BUILD_TICK then
			clockBuild = now
			hideyhole.bombprogress = hideyhole.bombprogress + 2
		end
	end
end


function hideyhole.draw()
	-- draw the GUI if the player is over the hidey-hole
	if playerOverlap then		
		-- draw each item
		if items[ItemTypes.GASCAN] then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(255, 255, 255, 64)
		end
		love.graphics.draw(sprGascan, 220, 230)
		
		
		if items[ItemTypes.POWDER] then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(255, 255, 255, 64)
		end
		love.graphics.draw(sprPowder, 238, 230)
		
		if items[ItemTypes.DEBRIS] then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(255, 255, 255, 64)
		end
		love.graphics.draw(sprDebris, 256, 230)
		
		if items[ItemTypes.TIMER] then
			love.graphics.setColor(255, 255, 255, 255)
		else
			love.graphics.setColor(255, 255, 255, 64)
		end
		love.graphics.draw(sprTimer, 274, 230)
		
		-- draw the rectangle and bomb bar
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.setLineStyle("rough")
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", 215, 225, 80, 40)
		if not hasAllMaterials then
			love.graphics.setColor(0, 0, 0, 64)
		end
		love.graphics.rectangle("line", 225, 250, 60, 10)
		
		-- draw progress, if any
		if hasAllMaterials then
			love.graphics.setColor(0, 0, 0, 255)
			love.graphics.rectangle("fill", PROGRESS_X, PROGRESS_Y, hideyhole.bombprogress, 6)
		end
		
		love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)
	end

	-- draw the hidey-hole itself
	love.graphics.draw(sprHhole, hideyhole.x, hideyhole.y)
end

