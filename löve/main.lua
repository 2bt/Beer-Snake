require("font")

function love.keypressed(key)
	-- quit with escape
	if key == "escape" then
		love.event.push("q")
	elseif key == "f" then
		love.graphics.toggleFullscreen()
	elseif key == " " then
		space = true
	end
end

function love.keyreleased(key)
	if key == " " then
		space = nil
	end
end


function love.quit()
	print("Remember: don't drink and drive.")
end

function love.load()
	love.mouse.setVisible(false)
	love.graphics.setBackgroundColor(50, 50, 50)
	font.init()

	bottle = {
		tick = 0,
		img = love.graphics.newImage("bottle.png")
	}
	function bottle:set()
		-- find a place not already occupied by the snake
		for i = 1, 20 do
			self.x = math.random(-360, 360)
			self.y = math.random(-260, 260)

			local collision = false
			for j, s in pairs(snake.tail) do
				local dx = s.x - self.x
				local dy = s.y - self.y
				if dx * dx + dy * dy < 900 then
					collision = true
					break
				end
			end
			if not collision then return end
		end
	end

	state.current = state.start
end

function love.draw()
	-- camera setup
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	love.graphics.scale(width / 800, height / 600)
	love.graphics.translate(400, 300)

	state.current:draw()
end

function love.update(dt)
	state.current:update()
	love.timer.sleep(25 - (dt * 1000))
	print(25 - (dt * 1000))
end


state = { start = {}, ingame = {}, over = {} }

function state.start:update()
	self.tick = (self.tick or 0) + 1

	if space then
		space = nil
		state.current = state.ingame

		snake = {
			tick = 0,
			x = 0,
			y = 0,
			dir = 0,
			tail = {},
			speed = 4,
			length = 18,
			score = 0,
		}
		bottle:set()

	end
end


function state.start:draw()
	love.graphics.setColor(127, 127 + 127 * math.sin(self.tick * 0.1), 127)
	font.print_centered("Beer Snake", math.floor(math.sin(self.tick * 0.05) * 30), -160, 8)

	love.graphics.setColor(255, 255, 255)
	font.print_centered("Collect as many bottles as you can!", 0, 0)
	font.print_centered("Get hammered but don't hurt your head.", 0, 40)
	font.print_centered("Press SPACE to start.", 0, 100)
	font.print_centered("Press ESC to exit.", 0, 140)
end

function state.over:update()
	bottle.tick = bottle.tick + 1
	if space then
		space = nil
		state.current = state.start
	end
end


function state.over:draw()

	state.ingame:draw()

	love.graphics.setColor(255, 255, 255)
	font.print_centered("Game Over", 0, -160, 8)

	love.graphics.setColor(255, 255, 255)
	font.print_centered("You collected %d bottle%s!" %
		{ snake.score, snake.score == 1 and "" or "s" }, 0, 0)

	if snake.score >= 30 then
		font.print_centered("Not too bad.", 0, 40)
	end
	font.print_centered("Press SPACE.", 0, 100)
end


function state.ingame:update()

	snake.tick = snake.tick + 1
	bottle.tick = bottle.tick + 1

	-- collision
	local collision = math.abs(snake.x) > 385 or math.abs(snake.y) > 285

	for i = 30, #snake.tail do
		local dx = snake.tail[i].x - snake.x
		local dy = snake.tail[i].y - snake.y
		if dx * dx + dy * dy < 760 then
			collision = true
			break
		end
	end

	if collision then
		print("Ouch!")
		state.current = state.over
		return
	end

	local dx = bottle.x - snake.x
	local dy = bottle.y - snake.y
	if dx * dx + dy * dy < 1200 then
		snake.score = snake.score + 1
		snake.length = snake.length + 10
		bottle:set()
	end


	-- movement

	local dd = math.sin(snake.tick * 0.16) * 0.004 * snake.score
	if love.keyboard.isDown("left") then
		dd = dd - 0.1
	end
	if love.keyboard.isDown("right") then
		dd = dd + 0.1
	end
	if math.abs(dd) > 0.2 then
		dd = 0.2 * dd / math.abs(dd)
	end
	snake.dir = snake.dir + dd

	snake.x = snake.x + math.sin(snake.dir) * snake.speed
	snake.y = snake.y - math.cos(snake.dir) * snake.speed

	table.insert(snake.tail, 1, {x = snake.x, y = snake.y})
	snake.tail[snake.length + 1] = nil

end

function state.ingame:draw()

	-- draw bottle
	love.graphics.setColor(255, 255, 0)
	love.graphics.draw(bottle.img, bottle.x, bottle.y, math.sin(bottle.tick * 0.05) * 0.8,
			1, 1, bottle.img:getWidth() / 2, bottle.img:getHeight() / 2)

	-- draw tail
	love.graphics.setColor(0, 160, 0)
	for i = 4, #snake.tail do
		love.graphics.circle("fill", snake.tail[i].x, snake.tail[i].y,
				10 + math.abs(math.cos(i * 0.2 + 0.8)) * 3, 16)
--				12, 16)
	end

	-- draw head
	local poly = { snake.x, snake.y }
	local f = math.pi / 180 * (0.86 + math.sin(snake.tick * 0.2) * 0.12)
	for i = -180, 180, 20 do
		table.insert(poly, snake.x + math.sin(i * f - snake.dir) * 15)
		table.insert(poly, snake.y + math.cos(i * f - snake.dir) * 15)
	end
	love.graphics.polygon("fill", poly)


	-- score
	love.graphics.setColor(255, 255, 255, 150)
	font.print("Score: %2d" % snake.score, -390, 290 - 16)
end


