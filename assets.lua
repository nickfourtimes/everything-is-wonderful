-- All art assets for the game
-------------------------------------------------------------------------------

-- CONSTANTS
-------------------------------------------------------------------------------
local MUS_ADAGIO_FILE = "assets/music/AdagioSostenuto-processed.ogg"

local SND_ALARM_FILE = "assets/sounds/alarm.mp3"
local SND_BUZZ_FILE = "assets/sounds/buzzer.mp3"
local SND_ITEM_FILE = "assets/sounds/item.mp3"
local SND_CLEAR_FILE = "assets/sounds/clear.mp3"
local SND_DEPOSIT_FILE = "assets/sounds/deposit.mp3"
local SND_EXPLODE_FILE = "assets/sounds/explode.mp3"
local SND_GETBOMB_FILE = "assets/sounds/getbomb.mp3"
local SND_GUNSHOT_FILE = "assets/sounds/gunshot.mp3"
local SND_PICKUP_FILE = "assets/sounds/pickup.mp3"
local SND_STATIC_FILE = "assets/sounds/static.mp3"

local SPR_BKGD_FILE = "assets/images/prison.png"
local SPR_BLOODPARTICLE_FILE = "assets/images/blood.png"
local SPR_GLASS_FILE = "assets/images/glass.png"
local SPR_ANGRY_FILE = "assets/images/angry.png"
local SPR_HAPPY_FILE = "assets/images/happy.png"
local SPR_QUIET_FILE = "assets/images/prisoner.png"
local SPR_SHOCK_FILE = "assets/images/shock.png"
local SPR_HHOLE_FILE = "assets/images/hideyhole.png"
local SPR_GASCAN_FILE = "assets/images/gascan.png"
local SPR_POWDER_FILE = "assets/images/powder.png"
local SPR_DEBRIS_FILE = "assets/images/debris.png"
local SPR_TIMER_FILE = "assets/images/timer.png"
local SPR_BOMB_FILE = "assets/images/bomb.png"


-- GLOBAL VARIABLES
-------------------------------------------------------------------------------

-- music mans
musAdagio = love.audio.newSource(MUS_ADAGIO_FILE)

-- sound mans
sndAlarm = love.audio.newSource(SND_ALARM_FILE, "static")
sndBuzz = love.audio.newSource(SND_BUZZ_FILE, "static")
sndItem = love.audio.newSource(SND_ITEM_FILE, "static")
sndClear = love.audio.newSource(SND_CLEAR_FILE, "static")
sndDeposit = love.audio.newSource(SND_DEPOSIT_FILE, "static")
sndExplode = love.audio.newSource(SND_EXPLODE_FILE, "static")
sndGetbomb = love.audio.newSource(SND_GETBOMB_FILE, "static")
sndGunshot = love.audio.newSource(SND_GUNSHOT_FILE, "static")
sndPickup = love.audio.newSource(SND_PICKUP_FILE, "static")
sndStatic = love.audio.newSource(SND_STATIC_FILE, "static")

-- sprite mans
sprBkgd = love.graphics.newImage(SPR_BKGD_FILE)
sprBloodParticle = love.graphics.newImage(SPR_BLOODPARTICLE_FILE)
sprGlass = love.graphics.newImage(SPR_GLASS_FILE)
sprAngry = love.graphics.newImage(SPR_ANGRY_FILE)
sprHappy = love.graphics.newImage(SPR_HAPPY_FILE)
sprQuiet = love.graphics.newImage(SPR_QUIET_FILE)
sprShock = love.graphics.newImage(SPR_SHOCK_FILE)
sprHhole = love.graphics.newImage(SPR_HHOLE_FILE)
sprGascan = love.graphics.newImage(SPR_GASCAN_FILE)
sprPowder = love.graphics.newImage(SPR_POWDER_FILE)
sprDebris = love.graphics.newImage(SPR_DEBRIS_FILE)
sprTimer = love.graphics.newImage(SPR_TIMER_FILE)
sprBomb = love.graphics.newImage(SPR_BOMB_FILE)

