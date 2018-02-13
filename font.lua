font = {}
local img, quads

function font.init()
	img = love.graphics.newImage("font.png")
	img:setFilter("nearest", "nearest")
	quads = {}

	for i = 32, 127 do
		local c = string.char(i)
		local x = (i % 8) * 8
		local y = math.floor(i / 8) * 8 - 32
		quads[c] = love.graphics.newQuad(x, y, 8, 8, 64, 96)
	end
end

function font.print_centered(text, x, y, s)
	s = s or 2
	font.print(text, x - #text * 4 * s, y, s)
end

function font.print(text, x, y, s)
	s = s or 2
	love.graphics.push()
	for c in text:gmatch(".") do
		local q = quads[c]
		if q then
			love.graphics.draw(img, q, x, y, 0, s)
		end
		love.graphics.translate(8 * s, 0)
	end
	love.graphics.pop()
end

-- python-like modulo operator for strings
getmetatable("").__mod = function(s, a)
	if not a then
		return s
	elseif type(a) == "table" then
		return s:format(unpack(a))
	else
		return s:format(a)
	end
end

