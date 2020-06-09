-- An invisible "inspector agent" who does the inspecting for us.
-------------------------------------------------------------------------------

inspector = {}


-- CONSTANTS
-------------------------------------------------------------------------------
local START_YOFFSET = 20
local MAX_YOFFSET = -20
local XOFFSET = 5

local STEP_TIME = 0.25
local STEP_SIZE = 4

local PAUSE_TIME = 1.5



-- LOCAL DATA
-------------------------------------------------------------------------------
local x, y, offsety
local inspectPause
local clockMove
local inspectionFinished


-- INSPECTOR METHODS
-------------------------------------------------------------------------------

-- start the inspection
function inspector.start()
  clockMove = love.timer.getTime()
  offsety = START_YOFFSET
  inspectPause = false
  inspectionFinished = false
end


-- is the inspection finished?
function inspector.finished()
  return inspectionFinished
end


-- BASE GAME LOOP FUNCTIONS
-------------------------------------------------------------------------------

function inspector.update(dt)
  local now = love.timer.getTime()

  -- move the magnifying glass so long as we're not in a pause state
  if not inspectPause then
    if now - clockMove > STEP_TIME then
      clockMove = now
      offsety = offsety - STEP_SIZE
      if MAX_YOFFSET > offsety then
        offsety = MAX_YOFFSET
        inspectPause = true
      end
    end
  else  -- we're waiting for the "pause" period to expire
    if now - clockMove > PAUSE_TIME then
      inspectionFinished = true
    end
  end

  local px, py = player.getfloorpos()
  x = px - XOFFSET
  y = py + offsety
end


function inspector.draw()
  love.graphics.draw(sprGlass, x, y)
end

