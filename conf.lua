function love.conf(t)
	-- game window information
	t.screen.width = 512
	t.screen.height = 512
	t.title = "Everything is Wonderful"
	t.author = "nick nick nick nick"

	-- disable unneeded modules
	t.modules.joystick = false
	t.modules.mouse = false
	t.modules.physics = false
end

