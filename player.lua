-- the main player character
-------------------------------------------------------------------------------

player = {}

-- PLAYER CONSTANTS
-------------------------------------------------------------------------------
local MOVESPEED = 60  -- pixels per second
local XMIN = 0
local XMAX = 504
local YMIN = 0
local YMAX = 501


-- PLAYER VARIABLES
-------------------------------------------------------------------------------
-- player sprite
local sprite

-- position and velocity
local px = 0
local py = 0
local vx = 0
local vy = 0


-- PLAYER METHODS
-------------------------------------------------------------------------------

function player.init()
  sprite = sprQuiet
end


function player.start()
end


function player.getpos()
  return px, py
end


function player.getfloorpos()
  return math.floor(px), math.floor(py)
end


function player.setpos(x, y)
  px = x
  py = y
end


function player.reveal()
  sprite = sprHappy
end


-- BASE GAME LOOP FUNCTIONS
-------------------------------------------------------------------------------

function player.update(dt)
  -- enforce vertical constraints
  if love.keyboard.isDown("down") then
    py = py + MOVESPEED * dt
    if py > YMAX then
      py = YMAX
    end
  elseif love.keyboard.isDown("up") then
    py = py - MOVESPEED * dt
    if py < YMIN then
      py = YMIN
    end
  end

  -- enforce horizontal constraints
  if love.keyboard.isDown("left") then
    px = px - MOVESPEED * dt
    if px < XMIN then
      px = XMIN
    end
  elseif love.keyboard.isDown("right") then
    px = px + MOVESPEED * dt
    if px > XMAX then
      px = XMAX
    end
  end

  
end


function player.draw()
  love.graphics.draw(sprite, math.floor(px), math.floor(py))
end

