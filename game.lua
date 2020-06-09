-- GAME CONTROLLER OBJECT
-------------------------------------------------------------------------------

require("assets")
require("guards")
require("hideyhole")
require("inspector")
require("platform")
require("player")

game = {}


-- CONSTANTS
-------------------------------------------------------------------------------
-- timing values (in seconds)
local TIME_VIOLATION_WHISTLE = 1	-- how long we whistle when there's a violation
local TIME_BEFORE_BUZZ_MIN = 15 -- wait before buzzing the next movement
local TIME_BEFORE_BUZZ_MAX = 25
local TIME_BUZZ_BUFFER = 1	-- time after buzz before we start checking player out of bounds
local TIME_BEFORE_ITEM_MIN = 8 -- wait for next item
local TIME_BEFORE_ITEM_MAX = 20 
local TIME_FORCEMOVE_PAUSE = 4	-- time to wait once force rect has shrunk
local TIME_REVEAL = 1 -- time to revel in the player's reveal

-- force-move constants
local EXPAND_TIME = 0.04
local EXPAND_STEP = 40


-- LOCAL DATA
-------------------------------------------------------------------------------
-- game state
local GameStates = {WANDER = 1, VIOLATION = 2, INSPECT = 3, FORCEMOVE = 4, FIRING = 10, REVEAL = 50, EXPLODE = 100}
local gamestate

-- particle system
local particles = {}
local deadparticles = {}
local bloodsprite = nil
local particlestart = nil
local particletostop = 0

-- clock for "animations"
local clockAnim = nil
local animFlash = false
local animSteps = 0

-- buzz clock
local clockBuzz = nil
local buzzTime = nil
local buzzStart = nil

-- items
local clockItem = nil
local currentItem = nil
local itemSprite = nil
local holdingItem = false
local hideyholeVisible = false
local ix, iy


-- HELPER FUNCTIONS
-------------------------------------------------------------------------------

-- create a spray of blood wherever the player is
local function _spawnPlayerBlood()
	if (nil == particles[0]) then
		particlestart = love.timer.getTime()
		particletostop = 0
		particles[0] = love.graphics.newParticleSystem(sprBloodParticle, 200)
		particles[0]:setSpread(2.0 * math.pi)
		particles[0]:setEmissionRate(150)
		particles[0]:setSpeed(100)
		particles[0]:setSize(1, 3)
		particles[0]:setColor(255, 0, 0, 255, 255, 0, 0, 255)
		particles[0]:setLifetime(-1)
		particles[0]:setParticleLife(0.5)
		particles[0]:setDirection(0)
		particles[0]:setTangentialAcceleration(0)
		particles[0]:setRadialAcceleration(-150)
		
		local x, y = player.getpos()
		particles[0]:setPosition(x+4, y + 5)

		particles[0]:start()
	end
end


-- create a spray of blood for everyone!
local function _spawnEveryoneBlood()
	_spawnPlayerBlood()
	for i=1,guardmgr.getNumGuards() do
		particles[i] = love.graphics.newParticleSystem(sprBloodParticle, 200)
		particles[i]:setSpread(2.0 * math.pi)
		particles[i]:setEmissionRate(150)
		particles[i]:setSpeed(100)
		particles[i]:setSize(1, 3)
		particles[i]:setColor(255, 0, 0, 255, 255, 0, 0, 255)
		particles[i]:setLifetime(-1)
		particles[i]:setParticleLife(0.5)
		particles[i]:setDirection(0)
		particles[i]:setTangentialAcceleration(0)
		particles[i]:setRadialAcceleration(-150)
		
		local x, y = guardmgr.getpos(i)
		particles[i]:setPosition(x+4, y + 5)

		particles[i]:start()
	end
end


-- reset the time before the next buzzer
local function _resetBuzzTime()
	buzzTime = TIME_BEFORE_BUZZ_MIN + math.floor(math.random() * (TIME_BEFORE_BUZZ_MAX - TIME_BEFORE_BUZZ_MIN))
	clockBuzz = love.timer.getTime()
end


-- reset the time before the next item
local function _resetItemTime()
	itemTime = TIME_BEFORE_ITEM_MIN + math.floor(math.random() * (TIME_BEFORE_ITEM_MAX - TIME_BEFORE_ITEM_MIN))
	clockItem = love.timer.getTime()
end


-- figure out what/where the next item should be
local function _nextItem()
	if not hideyholeVisible then	-- must show hidey-hole first
		hideyholeVisible = true
		hideyhole.place()
		love.audio.play(sndItem)
	else
		if (nil == currentItem) then	-- no item in play, so place one
			local i = hideyhole.nextItem()
			if not (nil == i) then	-- figure out which item
				currentItem = i
				holdingItem = false
				ix = 49 + math.floor(math.random() * 398) -- give the item a random position
				iy = 50 + math.floor(math.random() * 396)

				if ItemTypes.GASCAN == currentItem then
					itemSprite = sprGascan
				elseif ItemTypes.POWDER == currentItem then
					itemSprite = sprPowder
				elseif ItemTypes.DEBRIS == currentItem then
					itemSprite = sprDebris
				elseif ItemTypes.TIMER == currentItem then
					itemSprite = sprTimer
				else
					assert(false, "Hidey-hole returned wrong type of item!")
				end
				love.audio.play(sndItem)
			end -- not (nextitem == nil)
		end
	end
end


-- see if they player should get a new item
local function _checkNewItem()
	if (nil == currentItem) then
		local now = love.timer.getTime()
		if now - clockItem > itemTime then
			_nextItem()
			_resetItemTime()
		end
	end
end


-- see if the player picks up the item
local function _checkPlayerGetItem()
	local px, py = player.getpos()
	local hoverlap = (py > iy and py < iy + 16) or (py+11 > iy and py+11 < iy+16)
	local voverlap = (px > ix and px < ix + 16) or (px+8 > ix and px+8 < ix+16)
	if (hoverlap and voverlap and not holdingItem) then
		holdingItem = true
		love.audio.play(sndPickup)
	end
end


-- called whenever the player commits a violation
local function _playerViolation()
	--love.audio.play(sndBuzz)
	gamestate = GameStates.VIOLATION
	guardmgr.violationSpotted()
	clockAnim = love.timer.getTime()
end


-- called when the player has the bomb, and has been inspected
local function _playerReveal()
	gamestate = GameStates.REVEAL
	player.reveal()
	guardmgr.bombSpotted()
	clockAnim = love.timer.getTime()
	love.audio.play(sndAlarm)
end


-- called when the player actually detonates
local function _playerExplode()
	gamestate = GameStates.EXPLODE
	clockAnim = love.timer.getTime()
	love.audio.play(sndExplode)
	
	--TODO spawn all blood
	clockAnim = love.timer.getTime()
	animFlash = false
	animSteps = 0
end


-- see if the player is off the platform
-- doGuardCheck: (optional) true if we're testing against the guards' field of vision,
--							 just testing globally
local function _checkPlayerOutOfBounds(doGuardCheck)
	local guards = doGuardCheck or false

	-- first see if player is actually out of bounds
	if platform.playerOutOfBounds() then

		-- if we're checking the guards, they must see the player
		if guards then
			local px, py = player.getfloorpos()
			if not guardmgr.playerIsVisible(px, py) then
				return false
			else
				_playerViolation()
			end
		else	-- we're not checking the guards, so we need some buffer time after the buzzer before detecting
			local now = love.timer.getTime()
			if now - buzzStart > TIME_BUZZ_BUFFER then
				-- enough time has passed, spot the player
				_playerViolation()
			end
		end
	end
end


-- see if the player got the bomb
local function _checkPlayerGetBomb()
	-- SOMEONE SET UP US THE BOMB
	if hideyholeVisible then
		if (hideyhole.bombComplete() and not (ItemTypes.BOMB == currentItem)) then
			currentItem = ItemTypes.BOMB
			itemSprite = sprBomb
			holdingItem = true
			hideyholeVisible = false
			love.audio.play(sndPickup)
		end
	end
end


-- choose what form of movement the player is subjected to
local function _chooseForcedMove()
	if currentItem then -- if they have the bomb, it WILL be an inspection
		if ItemTypes.BOMB == currentItem then
			gamestate = GameStates.INSPECT
			return
		end
	end

	local v = math.floor(math.random() * 2)
	if 0 == v then
		gamestate = GameStates.INSPECT	-- will inspect player for inventory
	else
		gamestate = GameStates.FORCEMOVE	-- will just move the player around
	end
end


-- STATE-SPECIFIC UPDATE FUNCTIONS
-------------------------------------------------------------------------------
-- update when the player is simply walking around
local function _updateWander(dt)
	-- update stuff
	platform.update(dt)
	player.update(dt)
	guardmgr.update(dt)

	-- check if the player picks up an item
	if not (nil == currentItem) then
		_checkPlayerGetItem()
	end
	
	-- see if the player is out of bounds ("true" == must be visible to guards)
	_checkPlayerOutOfBounds(true)

	-- update the hidey-hole if necessary
	if hideyholeVisible then
		hideyhole.update(dt)
		
		-- does the player deposit an item?
		if hideyhole.playerOverlaps() then
			if (not (nil == currentItem)) and holdingItem then
				love.audio.play(sndDeposit)
				hideyhole.depositItem(currentItem)
				currentItem = nil
				holdingItem = false
				_resetItemTime()
			end
		end
	end

	-- time to do a force-move?
	local now = love.timer.getTime()
	if now - clockBuzz > buzzTime then
		love.audio.play(sndBuzz)
		_chooseForcedMove()
		buzzStart = now
		platform.shrink(0.1, 10, 1)
	end

	-- check if we should place another item
	_checkNewItem()
	
	-- check if they got the bomb
	_checkPlayerGetBomb()
end


-- update the game when the player has been caught in a violation
local function _updateViolation(dt)
	local now = love.timer.getTime()
	if now - clockAnim > TIME_VIOLATION_WHISTLE then	-- if we've whistled long enough, open fire
		gamestate = GameStates.FIRING
		guardmgr.fireOnPlayer()
		love.audio.play(sndGunshot)
		_spawnPlayerBlood()
		clockAnim = now
		animFlash = false
		animSteps = 0
	end
end


-- update when we're inspecting the player
local function _updateInspect(dt)
	-- update the elements
	platform.update(dt)
	player.update(dt)
	guardmgr.update(dt)
	if hideyholeVisible then
		hideyhole.update(dt)
	end
	
	-- see if movement makes our player outside and visible
	_checkPlayerOutOfBounds()
	
	-- player can still (unluckily) pick up an item at this stage
	if not (nil == currentItem) then
		_checkPlayerGetItem()
	end
	
	-- see how that inspection's going
	if platform.minimised() then
		if platform.minimisedThisFrame() then -- start the inspection!
			inspector.start()
		end
		inspector.update(dt)

		-- check if the inspection is finished
		if inspector.finished() then
			if (not (nil == currentItem)) and holdingItem then	-- player is carrying an item IN VIOLATION OF CODE
				if ItemTypes.BOMB == currentItem then
					_playerReveal()
				else
					_playerViolation()
				end
				return
			else	-- go back to wandering
				gamestate = GameStates.WANDER
				platform.expand(EXPAND_TIME, EXPAND_STEP)
				love.audio.play(sndClear)
				_resetBuzzTime()
			end
		end
	end

	-- check if we should place another item
	_checkNewItem()
	
	-- check if they got the bomb
	_checkPlayerGetBomb()
end


-- update when we're moving the player
local function _updateForcemove(dt)
	-- update the elements
	platform.update(dt)
	player.update(dt)
	guardmgr.update(dt)
	if hideyholeVisible then
		hideyhole.update(dt)
	end
	
	-- see if movement makes our player outside and visible
	_checkPlayerOutOfBounds()

	-- player can still (unluckily) pick up an item at this stage
	if not (nil == currentItem) then
		_checkPlayerGetItem()
	end

	-- see if it's time to end the forced-move	
	if platform.minimised() then
		local now = love.timer.getTime()
		if platform.minimisedThisFrame() then -- start forced-move
			clockAnim = now
		else
			if now - clockAnim > TIME_FORCEMOVE_PAUSE then	-- go back to wandering
				gamestate = GameStates.WANDER
				platform.expand(EXPAND_TIME, EXPAND_STEP)
				love.audio.play(sndClear)
				_resetBuzzTime()
			end
		end
	end

	-- check if we should place another item
	_checkNewItem()
	
	-- check if they got the bomb
	_checkPlayerGetBomb()
end


-- update the game when the guards are firing
local function _updateFiring(dt)
	-- update the guards, who are firing on the player
	guardmgr.update(dt)

	-- check if a particle system needs to pause
	if particles[0] then
		if particles[0]:isActive() then
			local time = love.timer.getTime()
			if time - particlestart > 0.25 then
				deadparticles[#deadparticles+1] = particles[0]
				particles[0] = nil
			end
		end
	end

	-- update all active particle systems
	for key, value in pairs(particles) do
		particles[key]:update(dt)
	end

	-- see how and when we should flash the screen
	local now = love.timer.getTime()
	if 0 == animSteps % 2 then	-- not flashing
		local length = 0 == animSteps and 0.5 or 0.075		-- length = (0==animSteps) ? 0.5 : 0.1
		if now - clockAnim > length then	-- flash!
			animFlash = true
			animSteps = animSteps + 1
			clockAnim = now
			if 1 == animSteps then
				love.audio.play(sndStatic)
			end
		end
	else	-- flashing
		if now - clockAnim > 0.075 then -- stop flashing
			animFlash = false
			animSteps = animSteps + 1
			clockAnim = now
		end
	end

	-- after a little flashing, go back to menu
	if 10 < animSteps then
		game.gotoNewstate = true
	end
end


local function _updateReveal(dt)
	local now = love.timer.getTime()
	if now - clockAnim > TIME_REVEAL then
		_spawnEveryoneBlood()
		_playerExplode()
	end
end


local function _updateExplode(dt)
	-- check if a particle system needs to pause
	for key, value in pairs(particles) do
		if value:isActive() then
			local time = love.timer.getTime()
			if time - particlestart > 0.25 then
				deadparticles[#deadparticles+1] = value
				value = nil
			end
		end
	end

	-- update all active particle systems
	for key, value in pairs(particles) do
		particles[key]:update(dt)
	end

	-- see how and when we should flash the screen
	local now = love.timer.getTime()
	if 0 == animSteps % 2 then	-- not flashing
		local length = 0 == animSteps and 0.5 or 0.075		-- length = (0==animSteps) ? 0.5 : 0.1
		if now - clockAnim > length then	-- flash!
			animFlash = true
			animSteps = animSteps + 1
			clockAnim = now
			if 1 == animSteps then
				love.audio.play(sndStatic)
			end
		end
	else	-- flashing
		if now - clockAnim > 0.075 then -- stop flashing
			animFlash = false
			animSteps = animSteps + 1
			clockAnim = now
		end
	end

	-- after a little flashing, end the game
	if 10 < animSteps then
		love.event.push("q")
	end
end


-- STATE-SPECIFIC DRAW FUNCTIONS
-------------------------------------------------------------------------------
local function _drawPrison()
	-- render the background
	love.graphics.draw(sprBkgd)

	-- draw the platform
	platform.draw()
end


local function _drawItemsAndActors()
	-- draw all live and dead particle systems
	local mode = love.graphics.getColorMode()
	love.graphics.setColorMode("modulate")
	for key, value in pairs(particles) do
		love.graphics.draw(value)
	end
	for key, value in pairs(deadparticles) do
		love.graphics.draw(value)
	end
	love.graphics.setColorMode(mode)

	-- draw hidey-hole if necessary
	if hideyholeVisible then
		hideyhole.draw()
	end

	-- draw items, if any
	if currentItem then
		if holdingItem then
			local px, py = player.getpos()
			px = math.floor(px)
			py = math.floor(py)
			love.graphics.draw(itemSprite, px-4, py-18)
		else
			love.graphics.draw(itemSprite, ix, iy)
		end
	end

	-- draw NPCs
	guardmgr.draw()

	-- this is where the player is make draw
	player.draw()
end


local function _drawWander()
	_drawPrison()
	_drawItemsAndActors()
end


local function _drawViolation()
	_drawPrison()
	_drawItemsAndActors()
end


local function _drawFiring()
	if not animFlash then
		_drawPrison()
		_drawItemsAndActors()
	else	-- render a flash!
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle("fill", 0, 0, 512, 512)
		love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)
	end
end


local function _drawInspect()
	-- draw stuff
	_drawPrison()
	_drawItemsAndActors()
	
	-- draw the magnifying glass
	if platform.minimised() then
		inspector.draw()
	end
end


local function _drawForcemove()
	-- draw stuff
	_drawPrison()
	_drawItemsAndActors()
end


local function _drawReveal()
	_drawPrison()
	_drawItemsAndActors()
end


local function _drawExplode()
	if not animFlash then
		_drawPrison()
		_drawItemsAndActors()
	else	-- render a flash!
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle("fill", 0, 0, 512, 512)
		love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)
	end
end


-- BASE GAME LOOP FUNCTIONS
-------------------------------------------------------------------------------
function game.init()
	-- screen setup
	GLOBALR = 255
	GLOBALG = 255
	GLOBALB = 255
	GLOBALA = 255

	-- other game elements
	player.init()
	guardmgr.init()
end


function game.start()
	-- initial values
	animFlash = false
	game.gotoNewstate = false
	gamestate = GameStates.WANDER
	hideyholeVisible = false
	currentItem = nil
	holdingItem = false
	
	-- reset all components
	platform.start()
	guardmgr.start()
	player.start()
	player.setpos(255, 255)

	-- start the orchestra
	love.audio.play(musAdagio)

	-- start the clocks
	local now = love.timer.getTime()
	clockBuzz = now
	clockItem = now
	_resetBuzzTime()
	_resetItemTime()
end


function game.stop()
	-- in case it's still playing
	love.audio.stop(sndGunshot)
	love.audio.stop(sndStatic)
	love.audio.stop(musAdagio)
end


function game.update(dt)
	if GameStates.WANDER == gamestate then
		_updateWander(dt)
	elseif GameStates.VIOLATION == gamestate then
		_updateViolation(dt)
	elseif GameStates.INSPECT == gamestate then
		_updateInspect(dt)
	elseif GameStates.FORCEMOVE == gamestate then
		_updateForcemove(dt)
	elseif GameStates.FIRING == gamestate then
		_updateFiring(dt)
	elseif GameStates.REVEAL == gamestate then
		_updateReveal(dt)
	elseif GameStates.EXPLODE == gamestate then
		_updateExplode(dt)
	end
end


function game.newstate()
	if game.gotoNewstate then
		return title
	else
		return nil
	end
end


function game.draw()
	if GameStates.WANDER == gamestate then
		_drawWander()
	elseif GameStates.VIOLATION == gamestate then
		_drawViolation()
	elseif GameStates.INSPECT == gamestate then
		_drawInspect()
	elseif GameStates.FORCEMOVE == gamestate then
		_drawForcemove()
	elseif GameStates.FIRING == gamestate then
		_drawFiring()
	elseif GameStates.REVEAL == gamestate then
		_drawReveal()
	elseif GameStates.EXPLODE == gamestate then
		_drawExplode()
	end
end

