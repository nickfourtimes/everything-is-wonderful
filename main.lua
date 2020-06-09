-- "EVERYTHING is WONDERFUL"
-- A game by nick nick nick nick
-- http://nicknicknicknick.net
-------------------------------------------------------------------------------

require("common")
require("game")
require("title")

-- the game state we're currently updating/rendering
local cstate = nil


-- BASE APP FUNCTIONS
-------------------------------------------------------------------------------

-- called once at startup
function love.load()
  -- randomness!
  math.randomseed(os.time())

  -- initialise game elements
  game.init()
  title.init()

  -- start the titlescreen
  cstate = title
  title.start()
end


function love.keypressed(key, unicode)
  -- press Escape to quit
  if key == 'escape' then
    notblue = 128
    love.event.push('q')
  end
end


function love.update(dt)
  cstate.update(dt)

  -- see if we move to a new state
  local ns = cstate.newstate()
  if ns then
    cstate.stop()
    cstate = ns
    cstate.start()  -- reset everything in the new state
  end
end


function love.draw()
  cstate.draw()
end
