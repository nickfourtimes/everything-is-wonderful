-- Commonly-used functions/definitions
-------------------------------------------------------------------------------

-- CONSTANTS
-------------------------------------------------------------------------------
-- Linux or Windows? Love2D seems to behave differently depending. =\
--LINUX_VERSION = {}
WINDOWS_VERSION = {}

-- colours we want to save
GLOBALR = 255
GLOBALG = 255
GLOBALB = 255
GLOBALA = 255

-- the types of items available to the player
ItemTypes = {GASCAN = 1, POWDER = 2, DEBRIS = 3, TIMER = 4, BOMB = 5}


-- GLOBAL FUNCTIONS
-------------------------------------------------------------------------------

function ResetGlobalColour()
	love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)
end

