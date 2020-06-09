-- The platform on which the player can walk
-------------------------------------------------------------------------------

platform = {}


-- CONSTANTS
-------------------------------------------------------------------------------
-- the base configuration
local XMIN = 45
local YMIN = 45
local MAXSZ = 420 -- biggest it gets
local MINSZ = 30  -- smallest it gets


-- LOCAL DATA
-------------------------------------------------------------------------------
local x, y, size
local changingSize, stepSize, stepTime, clockLastSize
local minimisedThisFrame


-- PLATFORM METHODS
-------------------------------------------------------------------------------

-- check if the player's gone out of bounds
function platform.playerOutOfBounds()
  local px, py = player.getfloorpos()
  if px < x or py < y or px+8 > x+size or py+11 > y+size then
    return true
  else
    return false
  end
end


-- signal the platform that it should shrink
-- speed: the time (in seconds) between shrinking steps
-- sz: how much it should shrink by each step
-- delay: (optional) how long to delay if necessary
function platform.shrink(speed, sz, delay)
  local d = delay or 0
  changingSize = true
  stepTime = speed
  stepSize = -sz
  clockLastSize = love.timer.getTime() + d
  minimisedThisFrame = false
end


-- signal the platform that it should expand
-- speed: the time (in seconds) between expanding steps
-- sz: how much it should expand by each step
-- delay: (optional) how long to delay if necessary
function platform.expand(speed, sz, delay)
  local d = delay or 0
  changingSize = true
  stepTime = speed
  stepSize = sz
  clockLastSize = love.timer.getTime() + d
  minimisedThisFrame = false
end


-- return true if the platform is as small as it's going to get, false otherwise
function platform.minimised()
  return (size == MINSZ)
end


-- return true if the platform is as big as it's going to get, false otherwise
function platform.maximised()
  return (size == MAXSZ)
end


-- return true ONLY IF the platform minimised this frame
function platform.minimisedThisFrame()
  return minimisedThisFrame
end


-- BASE GAME LOOP FUNCTIONS
-------------------------------------------------------------------------------

function platform.start()
  -- defaults
  x = XMIN
  y = YMIN
  size = MAXSZ
  changingSize = false
end


function platform.update(dt)
  minimisedThisFrame = false

  -- see if we should change size
  if changingSize then
    local now = love.timer.getTime()
    if (now - clockLastSize > stepTime) then  -- time to shrink/expand again
      clockLastSize = now
      size = size + stepSize
      
      -- check boundaries
      if size <= MINSZ then
        changingSize = false
        size = MINSZ
        minimisedThisFrame = true
      elseif size >= MAXSZ then
        changingSize = false
        size = MAXSZ
        x = XMIN
        y = YMIN
      end

      -- centre the square
      if not (MAXSZ == size) then
        x = math.floor(512/2 - size/2)
        y = x
      end
    end
  end --if(changingSize)
end


function platform.draw()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.rectangle("fill", x, y, size, size)
  ResetGlobalColour()
end

