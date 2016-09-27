math.randomseed(os.time())
math.clamp = function(val, low, high)
	return math.max(low, math.min(high, val))
end

function love.load()
	frame = 0
	paused = false
	mode = 0
	segment = 1
	totalSegments = 3
	love.window.setMode(1200, 300, {resizable=true, vsync=false, minwidth=400, minheight=300})
	g = love.graphics

	-- Contains all of the source drawings and their image data
	images = {
		g.newImage("img/img100.jpg"),
		g.newImage("img/img101.jpg"),
		g.newImage("img/img102.jpg"),
		g.newImage("img/img103.jpg"),
		g.newImage("img/img104.jpg"),
		g.newImage("img/img105.jpg"),
		g.newImage("img/img106.jpg"),
		g.newImage("img/img107.jpg"),
		g.newImage("img/img108.jpg"),
		g.newImage("img/img109.jpg"),
		g.newImage("img/img110.jpg")
	}
	images.data = {}
	for k, v in ipairs(images) do
		images.data[k] = v:getData()
	end
	images.w, images.h = images[1]:getDimensions()

	-- The output image, drawn at a small scale
	preview = {}
	preview.x = 0
	preview.y = 0
	preview.w = 16384
	preview.h = 4096
	preview.s = 1
	preview.resx = 32
	preview.resy = 1
	preview.values = {}
	for i = 1, preview.resx do
		preview.values[i] = {}
		for j = 1, preview.resy do
			preview.values[i][j] = 1
		end
	end
	preview.canvas = g.newCanvas(preview.w, preview.h, "normal", 0)
	preview.canvas:setWrap("clampzero", "clampzero")
	g.setCanvas(preview.canvas)
	g.rectangle("fill", 0, 0, preview.w, preview.h)
	g.setCanvas();

	-- Quad used to show preview cutout at full scale
	lens = {}
	lens.w = 200
	lens.h = 200
	lens.quad = g.newQuad(0, 0, lens.w, lens.h, preview.w, preview.h)

	-- Quad used to cut out new cells from source images
	clip = {}
	clip.w = math.floor(preview.w / preview.resx)
	clip.h = math.floor(preview.h / preview.resy)
	clip.h = images.h
	clip.quad = g.newQuad(0, 0, clip.w, clip.h, images.w, images.h)

	-- Pattern to determine where images can be drawn to the canvas
	pattern = {}
	pattern.w = preview.resx
	pattern.h = preview.resy
	pattern.s = 1
	pattern.getValue = function(x, y)
		-- return -1
		return (x / preview.resx) * 2 - 1
	end
	pattern.getIndex = function(x, y)
		x = preview.resx * segment + x
		x = x / preview.resx
		x = x / totalSegments
		return math.clamp(math.floor(x * #images + math.random(-0.5, 0.5)), 0, #images - 1) + 1
	end
	pattern.data = love.image.newImageData(pattern.w, pattern.h)
	pattern.data:mapPixel(function (x, y, r, g, b, a)
		value = math.floor(pattern.getValue(x, y) * 255)
		return value, value, value, 255
	end)
	pattern.image = love.graphics.newImage(pattern.data)
	pattern.image:setFilter("nearest", "nearest")

	-- Trigger preview resize
	love.resize(g.getWidth(), g.getHeight())
end

function love.update(dt)
	do
		local mx, my = love.mouse.getPosition()
		local gw = g.getWidth()
		local gh = g.getHeight()
		local lx = ((mx - (gw / 2)) / preview.s) + (preview.w / 2)
		local ly = ((my - (gh / 2)) / preview.s) + (preview.h / 2)
		lens.quad:setViewport(lx, ly, lens.w, lens.h)
	end

	if not paused then
		-- Place clips according to value
		local imi = math.random(1, #images)
		local imx = math.random(images.w - clip.w - 1)
		local imy = math.random(images.h - clip.h - 1)

		local v = 0
		for i = imx, imx + clip.w - 1 do
			for j = imy, imy + clip.h - 1 do
				v = v + (images.data[imi]:getPixel(i, j))
			end
		end
		v = v / (clip.w * clip.h)
		v = v / 255
		v = -v + 1

		local choices = {}
		for i = 1, preview.resx do
			for j = 1, preview.resy do
				if preview.values[i][j] - v > pattern.getValue(i, j) then
					table.insert(choices, i)
				end
			end
		end

		if #choices > 0 then
			local pr = math.random(1, #choices)
			local prx = choices[pr]
			local pry = 1
			preview.values[prx][pry] = preview.values[prx][pry] - v
			clip.quad:setViewport(imx, imy, clip.w, clip.h)
			g.setCanvas(preview.canvas)
			g.setBlendMode("darken", "premultiplied")
			g.draw(images[imi], clip.quad, (prx - 1) * clip.w, (pry - 1) * clip.h + math.random(preview.h - clip.h))
			-- g.draw(images[imi], clip.quad, (prx - 1) * clip.w, (pry - 1) * clip.h + love.math.noise(prx * 0.5) * (preview.h - clip.h))
			g.setBlendMode("alpha")
			g.setCanvas()
		end

		-- -- Place clips according to image index
		-- for pry = 1, preview.resy do
		-- 	local prx = frame % preview.resx + 1
		-- 	local imi = pattern.getIndex(prx - 1, pry - 1)
		-- 	local imx = math.random(images.w - clip.w - 1)
		-- 	local imy = math.random(images.h - clip.h - 1)
		--
		-- 	clip.quad:setViewport(imx, imy, clip.w, clip.h)
		-- 	g.setCanvas(preview.canvas)
		-- 	if math.random() < math.clamp((prx / preview.resx), 0.1, 0.9) then
		-- 		g.setBlendMode("darken", "premultiplied")
		-- 	else
		-- 		g.setBlendMode("lighten", "premultiplied")
		-- 	end
		-- 	-- g.draw(images[imi], clip.quad, (prx - 1) * clip.w, (pry - 1) * clip.h + math.random(preview.h - clip.h))
		-- 	-- g.draw(images[imi], clip.quad, (prx - 1) * clip.w, (pry - 1) * clip.h + love.math.noise(frame * 0.05) * (preview.h - clip.h))
		-- 	g.draw(images[imi], clip.quad, (prx - 1) * clip.w, (pry - 1) * clip.h - clip.h + ((frame * 500) % (preview.h + clip.h)))
		-- 	g.setBlendMode("alpha")
		-- 	g.setCanvas()
		-- end

		-- -- Naive placement of clips
		-- local prx = math.random(1, preview.resx)
		-- local pry = math.random(1, preview.resy)
		-- if math.random() > pattern.get(prx, pry) then
		-- 	clip.quad:setViewport(imx, imy, clip.w, clip.h)
		-- 	g.setCanvas(preview.canvas)
		-- 	g.setBlendMode("darken", "premultiplied")
		-- 	g.draw(images[imi], clip.quad, (prx - 1) * clip.w, (pry - 1) * clip.h)
		-- 	g.setBlendMode("alpha")
		-- 	g.setCanvas()
		-- end
		-- frame = frame + 1
		-- if frame % preview.resx == 0 then
		-- 	paused = true
		-- end
	end
end

function love.draw()
	local gw = g.getWidth()
	local gh = g.getHeight()
	local mx, my = love.mouse.getPosition()
	if mode == 0 then
		g.draw(preview.canvas, gw / 2, gh / 2, 0, preview.s, preview.s, preview.w / 2, preview.h / 2)
	end
	if mode == 1 then
		g.draw(pattern.image, gw / 2, gh / 2, 0, pattern.s, pattern.s, pattern.w / 2, pattern.h / 2)
	end
	if love.mouse.isDown(1) then
		g.draw(preview.canvas, lens.quad, mx - lens.w / 2, my - lens.h / 2)
	end
end

function love.resize(w, h)
	preview.s = math.min(w / preview.w, h / preview.h, 1)
	pattern.s = math.min(w / pattern.w, h / pattern.h)
end

function love.keypressed(key, scancode, isrepeat)
	if key == "p" then
		paused = not paused
	end
	if key == "s" then
		local data = preview.canvas:newImageData()
		data:encode("png", "out.png")
	end
	if key == "space" then
		paused = true
		mode = mode + 1
		if mode >= 2 then
			mode = 0
		end
	end
end
