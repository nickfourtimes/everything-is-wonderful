-- all the NPC guards
-------------------------------------------------------------------------------

-- GUARD CONSTANTS & DATA
-------------------------------------------------------------------------------
local NUM_GUARDS = 8
local GUARD_SPEED = 60	 -- pixels per second

-- guard states
local GuardStates = {HAPPY = 1, ANGRY = 2, SHOCK = 3}
local guardstate
local guardsprite

-- movement around edge
local XMIN = 4
local XMAX = 500
local YMIN = 2
local YMAX = 499

-- guarding constants
local VISIBLE_RADIUS = 96
local VISIBLE_RADIUS_SQ = VISIBLE_RADIUS * VISIBLE_RADIUS

-- firing variables
local isFiring = false
local fireclock = nil
local FIREFLASHTIME = 0.05
local firegb = 255


-- GUARD CLASS
-------------------------------------------------------------------------------

local Guard = {}
Guard.__index = Guard

-- Guard "constructor"
function Guard:New()
	obj = {}

	setmetatable(obj, self)

	-- place somewhere random on the edge
	local r = math.floor(math.random() * 4)
	if 0 == r then		-- top edge
		obj.x = math.floor(math.random() * 496) + 4
		obj.y = 2
		obj.dx = GUARD_SPEED
		obj.dy = 0
	elseif 1 == r then	-- bottom edge
		obj.x = math.floor(math.random() * 496) + 4
		obj.y = 499
		obj.dx = GUARD_SPEED
		obj.dy = 0
	elseif 2 == r then	-- left edge
		obj.x = 4
		obj.y = math.floor(math.random() * 497) + 2
		obj.dx = 0
		obj.dy = GUARD_SPEED
	else		-- right edge
		obj.x = 500
		obj.y = math.floor(math.random() * 497) + 2
		obj.dx = 0
		obj.dy = GUARD_SPEED
	end

	-- randomly go one direction or the other
	if 0 == math.floor(math.random() * 2) then
		obj.dx = -obj.dx
		obj.dy = -obj.dy
	end

	return obj
end


-- helper function to just move guard in some direction
function Guard:_MoveSelf(dt)
	self.x = self.x + self.dx * dt
	self.y = self.y + self.dy * dt
	
	-- see if horizontally-moving guards should change direction
	if self.x < XMIN then
		self.x = XMIN
		self.dx = 0
		if YMAX == self.y then -- must move "up" screen
			self.dy = -GUARD_SPEED
		else	-- move down
			self.dy = GUARD_SPEED
		end
	elseif self.x > XMAX then
		self.x = XMAX
		self.dx = 0
		if YMAX == self.y then	-- must move "up" screen
			self.dy = -GUARD_SPEED
		else	-- move down
			self.dy = GUARD_SPEED
		end
	end
	
	-- see if vertically-moving guards should change direction
	if self.y < YMIN then
		self.y = YMIN
		self.dy = 0
		if XMAX == self.x then -- must move "left"
			self.dx = -GUARD_SPEED
		else	-- move right
			self.dx = GUARD_SPEED
		end
	elseif self.y > YMAX then
		self.y = YMAX
		self.dy = 0
		if XMAX == self.x then	-- must move "left"
			self.dx = -GUARD_SPEED
		else	-- move right
			self.dx = GUARD_SPEED
		end
	end
end


function Guard:Patrol(dt)
	self:_MoveSelf(dt)
end


function Guard:Draw()
	local x = math.floor(self.x)
	local y = math.floor(self.y)

	--love.graphics.setColor(0, 0, 0, 32)
	--love.graphics.circle("fill", x+4, y+5, VISIBLE_RADIUS+2, 20)
	--ResetGlobalColour()
	love.graphics.draw(guardsprite, x, y)
end


-- GUARD MANAGER
-------------------------------------------------------------------------------

guardmgr = {}
local allguards = {}


-- get the number of guards
function guardmgr.getNumGuards()
	return NUM_GUARDS
end


-- return position of the guard at index 'ind'
function guardmgr.getpos(ind)
	return allguards[ind].x, allguards[ind].y
end


-- see if any of the guards sees the player
-- return true if one of them does, false otherwise
function guardmgr.playerIsVisible(px, py)
	local gx
	local gy

	-- check each guard to see if they see player
	for i=1, NUM_GUARDS do
		gx = allguards[i].x
		gy = allguards[i].y
		gx = gx + 4 -- offset to centre
		gy = gy + 5
		if VISIBLE_RADIUS_SQ >= (gx - px) * (gx - px) + (gy - py) * (gy - py) then
			return true
		end
	end
	
	-- no visibles
	return false
end


-- tell everyone that there's a violation
function guardmgr.violationSpotted()
	guardstate = GuardStates.ANGRY
	guardsprite = sprAngry
	love.audio.play(sndAlarm)
end


-- called when the player shows the bomb
function guardmgr.bombSpotted()
	guardstate = GuardStates.SHOCK
	guardsprite = sprShock
end


-- tell everyone to fire at the player
function guardmgr.fireOnPlayer()
	if not isFiring then
		isFiring = true
		fireclock = love.timer.getTime()
	end
end


function guardmgr.init()
end


function guardmgr.start()
	isFiring = false
	guardstate = GuardStates.HAPPY
	guardsprite = sprHappy
	local i	
	for i=1,NUM_GUARDS do
		allguards[i] = Guard:New()
	end	
end


function guardmgr.update(dt)
	if GuardStates.HAPPY == guardstate then	-- just wander around
		for key, value in pairs(allguards) do
			value:Patrol(dt)
		end
	elseif GuardStates.ANGRY == guardstate then	-- don't move, just modulate ray colour
		if isFiring then
			local now = love.timer.getTime()
			if now - fireclock > FIREFLASHTIME then
				fireclock = now
				if 0 == firegb then
					firegb = 255
				else
					local foo = sndGunshot
					love.audio.play(foo)
					firegb = 0
				end
			end
		end
	else	-- GuardStates.SHOCK
		--
	end -- guardstate switch statement
end


function guardmgr.draw()
	local px, py = player.getfloorpos()

	-- draw each of the guards
	for key, value in pairs(allguards) do
		if isFiring then	-- draw a gunshot line if they're firing
			love.graphics.setColor(255, firegb, firegb, 255)
			love.graphics.line(value.x+4, value.y+5, px+4, py+5)
			love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)
		end
		value:Draw()
	end
end

