require("font")

function love.keypressed(key, unicode)
	-- quit with escape
	if key == "escape" then
		love.event.push("q")
	elseif key == "f" then
		love.graphics.toggleFullscreen()
	end
end


function love.quit()
	print("Don't drink and drive.")
end

function love.load()
	love.mouse.setVisible(false)
	love.graphics.setBackgroundColor(50, 50, 50)
	font.init()

	snake = {
		x = 0,
		y = 0,
		dir = 0,
		tail = {},
		length = 22 + 500,
		speed = 2,
		score = 0
	}

	bottle = {
		img = love.graphics.newImage("bottle.png"),
	}
	function bottle:set()
		-- find a place not already occupied by the snake
		for i = 1, 20 do
			self.x = math.random(-370, 370)
			self.y = math.random(-270, 270)

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
		print("not")
	end
	bottle:set()


	tick = 0
	death_delay = 30
end


function love.update()

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
		if death_delay == 0 then
			love.event.push("q")
		end
		death_delay = death_delay - 1
		return
	end

	local dx = bottle.x - snake.x
	local dy = bottle.y - snake.y
	if dx * dx + dy * dy < 1200 then
		snake.score = snake.score + 1
		snake.length = snake.length + 20
		bottle:set()
	end


	tick = tick + 1

	-- movement
	if love.keyboard.isDown("left") then
		snake.dir = snake.dir - 0.1
	end
	if love.keyboard.isDown("right") then
		snake.dir = snake.dir + 0.1
	end

	snake.x = snake.x + math.sin(snake.dir) * snake.speed
	snake.y = snake.y - math.cos(snake.dir) * snake.speed

	table.insert(snake.tail, 1, {x = snake.x, y = snake.y})
	snake.tail[snake.length + 1] = nil


end


function love.draw()

	-- camera setup
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	love.graphics.scale(width / 800, height / 600)
	love.graphics.translate(400, 300)


	-- draw bottle
	love.graphics.setColor(255, 255, 0)
	love.graphics.draw(bottle.img, bottle.x, bottle.y, math.sin(tick * 0.05) * 0.8,
			1, 1, bottle.img:getWidth() / 2, bottle.img:getHeight() / 2)


	-- draw tail
	love.graphics.setColor(0, 160, 0)
	for i = 7, #snake.tail do
		love.graphics.circle("fill", snake.tail[i].x, snake.tail[i].y,
				10 + math.abs(math.cos(i * 0.2)) * 3, 16)
	end

	-- draw head
	local poly = { snake.x, snake.y }
	local f = math.pi / 180 * (0.86 + math.sin(tick * 0.2) * 0.12)
	for i = -180, 180, 20 do
		table.insert(poly, snake.x + math.sin(i * f - snake.dir) * 15)
		table.insert(poly, snake.y + math.cos(i * f - snake.dir) * 15)
	end
	love.graphics.polygon("fill", poly)


	-- score
	love.graphics.setColor(255, 255, 255, 150)
	font.print("Score: %2d" % snake.score, -390, 290 - 16)

end


