-- TITLE SCREEN OBJECT
-------------------------------------------------------------------------------
title = {}


-- CONSTANTS
-------------------------------------------------------------------------------
local IMG_TITLECARD = "assets/images/title.png"
local IMG_CREDITS = "assets/images/credits.png"
local IMG_POINTER = "assets/images/pointright.png"
local SND_RECORD = "assets/sounds/recordend.mp3"


-- BASE GAME LOOP FUNCTIONS
-------------------------------------------------------------------------------

-- load title screen resources
function title.init()
  title.title = love.graphics.newImage(IMG_TITLECARD)
  title.credit = love.graphics.newImage(IMG_CREDITS)
  title.point = love.graphics.newImage(IMG_POINTER)
  title.snd = love.audio.newSource(SND_RECORD)
  title.snd:setLooping(true)
end


function title.start()
  -- screen setup
  GLOBALR = 255
  GLOBALG = 255
  GLOBALB = 255
  GLOBALA = 255
  love.graphics.setBackgroundColor(255, 255, 255)
  love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)

  -- default values
  title.dir = 1
  title.alpha = 0
  title.gotoNewstate = false
  
  -- start looping the audio
  love.audio.play(title.snd)
end


function title.stop()
  love.audio.stop(title.snd)
end


function title.update(dt)
  -- make the right-arrow fade in and out
  title.alpha = title.alpha + dt * title.dir * 200
  if title.alpha > 255 then
    title.alpha = 255
    title.dir = -1
  elseif title.alpha < 0 then
    title.alpha = 0
    title.dir = 1
  end

  -- check if the player can move on
  if love.keyboard.isDown("right") then
    title.gotoNewstate = true
  end
end


function title.newstate()
  if title.gotoNewstate then
    return game
  else
    return nil
  end
end


function title.draw()
  love.graphics.draw(title.title, 0, 0)
  love.graphics.draw(title.credit, 5, 495)
  
  love.graphics.setColor(255, 255, 255, title.alpha)
  love.graphics.draw(title.point, 470, 492)
  love.graphics.setColor(GLOBALR, GLOBALG, GLOBALB, GLOBALA)
end

