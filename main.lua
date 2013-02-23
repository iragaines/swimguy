require "camera"

function love.load()

	function love.graphics.newDraw(image, x, y)
		return love.graphics.draw(image, math.floor(x), math.floor(y))
	end
	-- standard tile size
	tile_size = 24

	window_width = 24 * tile_size
	window_height = 16 * tile_size
	love.graphics.setMode(window_width, window_height)
	is_looking = false


	-- load tiles
	tileset = {
		-- background
		[1] = love.graphics.newImage("/resources/blocks/black.png"),

		-- water
		[2] = love.graphics.newImage("/resources/blocks/water.png"),
		[3] = love.graphics.newImage("/resources/blocks/deep_water.png"),
		[4] = love.graphics.newImage("/resources/blocks/deeper_water.png"),

		-- ground tiles
		[5] = love.graphics.newImage("/resources/blocks/dirt.png"),
		[6] = love.graphics.newImage("/resources/blocks/grass.png"),

		[7] = love.graphics.newImage("/resources/blocks/ladder.png"),

		-- crates
		[8] = love.graphics.newImage("/resources/blocks/crate.png"),
		[9] = love.graphics.newImage("/resources/blocks/stone.png"),

		-- sky
		[10] = love.graphics.newImage("/resources/blocks/sky.png"),
		[11] = love.graphics.newImage("/resources/blocks/glass.png")
	}

	current_editor_selection=1

	-- load map
	load_map_from_file = love.filesystem.load("/resources/maps/olympic_pool.lua")
	map = load_map_from_file()
	map.tiles_tall = #map.tiles
	map.tiles_wide = #map.tiles[1]
	map.pixels_tall = map.tiles_tall*tile_size
	map.pixels_wide = map.tiles_wide*tile_size


	-- player sprites
	player_sprites = {
		stand_left = love.graphics.newImage("/resources/player/flareon_stand_left.png"),
		stand_right = love.graphics.newImage("/resources/player/flareon_stand_right.png"),
		crouch_left = love.graphics.newImage("/resources/player/flareon_crouch_left.png"),
		crouch_right = love.graphics.newImage("/resources/player/flareon_crouch_right.png"),
		bounding_box = love.graphics.newImage("/resources/player/bounding_box.png"),
		bounding_box_crouch = love.graphics.newImage("/resources/player/bounding_box_crouch.png")
	}

	player_bounding_box_sprites = {
		top_left = love.graphics.newImage("/resources/player/bounding_box_top_left.png"),
		top_right = love.graphics.newImage("/resources/player/bounding_box_top_right.png"),
		bottom_left = love.graphics.newImage("/resources/player/bounding_box_bottom_left.png"),
		bottom_right = love.graphics.newImage("/resources/player/bounding_box_bottom_right.png")
	}

	-- gravity
	gravity = 500

	-- player setup
	player = {
		face_right = map.player_start_face_right,
		crouching = false,
		pixel_location_x = map.player_start_x*tile_size,
		pixel_location_y = map.player_start_y*tile_size,
		pixels_wide = 24,
		pixels_tall = 36,
		speed = 0,
		acceleration = gravity
	}
	player.tiles_tall=math.ceil(player.pixels_tall/tile_size)
	player.tiles_wide=math.ceil(player.pixels_wide/tile_size)
	update_player_sprite()

	random_seed_int = 1

	-- show debug flag
	show_debug = true

	show_editor = false
	editor_width = tile_size*5

	mouse_x=0
	mouse_y=0

end


function love.update(dt)
	-- quit game if start button pressed
	if love.joystick.isDown(1, 8) or love.keyboard.isDown("escape") or love.keyboard.isDown("q") then
		love.event.push("quit")
	end

	-- toggle display of debug info
	if love.keyboard.isDown("lshift") and love.keyboard.isDown("`") then
		show_debug = false
	elseif love.keyboard.isDown("`") then
		show_debug = true
	end


	-- toggle display of debug info
	if love.keyboard.isDown("lshift") and love.keyboard.isDown("e") then
		show_editor = false
		love.graphics.setMode(window_width, window_height)
	elseif love.keyboard.isDown("e") then
		show_editor = true
		love.graphics.setMode(window_width + editor_width, window_height)
	end



	-- look around (keyboard)
	if love.keyboard.isDown("a") then
		camera:move(-100*dt, 0)
		is_looking = true
	elseif love.keyboard.isDown("d") then
		camera:move(100*dt, 0)
		is_looking = true
	end
	if love.keyboard.isDown("w") then
		camera:move(0, -100*dt)
		is_looking = true
	elseif love.keyboard.isDown("s") then
		camera:move(0, 100*dt)
		is_looking = true
	end

	-- look around (controller)
	if love.joystick.getAxis(1, 5) < -0.25 then
		camera:move(-10*dt + 5*love.joystick.getAxis(1, 5), 0)
		is_looking = true
	elseif love.joystick.getAxis(1, 5) > 0.25 then
		camera:move(10*dt + 5*love.joystick.getAxis(1, 5), 0)
		is_looking = true
	end
	if love.joystick.getAxis(1, 4) < -0.25 then
		camera:move(0, -10*dt + 5*love.joystick.getAxis(1, 4))
		is_looking = true
	elseif love.joystick.getAxis(1, 4) > 0.25 then
		camera:move(0, 10*dt + 5*love.joystick.getAxis(1, 4))
		is_looking = true
	end

	-- reset look
	if (is_looking == true) and ((not love.keyboard.isDown("w","a","s","d")) and ((math.abs(love.joystick.getAxis(1, 5))<0.25) and (math.abs(love.joystick.getAxis(1, 4))<0.25))) then
		center_camera()
		is_looking = false
	end

	-- crouch
	if (not ((max_move_down == 0) and (max_move_up == 0))) or love.keyboard.isDown(" ") then
		previous_crouching = player.crouching
		player.crouching=(love.joystick.isDown(1, 1) or love.keyboard.isDown(" "))
		if player.crouching then
			player.pixels_tall=24
		else
			player.pixels_tall=36
		end
		if (max_move_down == 0) then
			if previous_crouching and (not player.crouching) then
				player.pixel_location_y = player.pixel_location_y - 12
				center_camera()
			elseif player.crouching and (not previous_crouching) then
				player.pixel_location_y = player.pixel_location_y + 12
				center_camera()
			end
		end
		update_player_sprite()
	end


	player_left = 1+math.floor((player.pixel_location_x)/tile_size)
	player_right = 1+math.floor((player.pixel_location_x+player.pixels_wide-1)/tile_size)
	player_top = 1+math.floor((player.pixel_location_y)/tile_size)
	player_bottom = 1+math.floor((player.pixel_location_y+player.pixels_tall-1)/tile_size)



	max_move_up = tile_size
	max_move_left = tile_size
	max_move_right = tile_size
	max_move_down = tile_size

	on_ladder = false
	for i=player_top, player_bottom, 1 do
		for j=player_left, player_right, 1 do
			if (map.midground[i][j] == 7) then
				on_ladder = true
				if love.keyboard.isDown("up","down") then
					player.pixel_location_x = (j-1)*tile_size
				end
			end
		end
	end

	in_water = false
	player.acceleration=gravity
	i=player_bottom
	for j=player_left, player_right, 1 do
		if (map.collision[i][j] == 2) then
			in_water = true
			player.acceleration=0.25*gravity
		end
	end


	above_ladder = false
	i = math.min(player_bottom+1, map.tiles_tall)
	for j=player_left, player_right, 1 do
		if (map.midground[i][j] == 7) then
			above_ladder = true
		end
	end


	if not (above_ladder and (love.keyboard.isDown("down") or love.joystick.getAxis(1, 2) > 0.25)) then
		for i=player_bottom, math.min(player_bottom+1,map.tiles_tall), 1 do
			for j=player_left, player_right, 1 do
				if (map.collision[i][j] == 1 or map.collision[i][j] == 4) then
					max_move_down = math.min((i-1)*tile_size - (player.pixel_location_y + player.pixels_tall), max_move_down)
				end
			end
		end
	end


	for i=math.max(player_top-1,1), player_top do
		for j=player_left, player_right, 1 do
			if (map.collision[i][j] == 1) then
				max_move_up = math.min(player.pixel_location_y - i*tile_size, max_move_up)
			end
		end
	end

	for i=player_top, player_bottom, 1 do
		for j=math.max(player_left-1,1),player_left,1 do
			if (map.collision[i][j] == 1) then
				max_move_left = math.min(player.pixel_location_x - j*tile_size, max_move_left)
			end
		end
	end

	for i=player_top, player_bottom, 1 do
		for j=player_right, math.min(player_right+1,map.tiles_wide),1 do
			if (map.collision[i][j] == 1) then
				max_move_right = math.min((j-1)*tile_size - (player.pixel_location_x + player.pixels_wide), max_move_right)
			end
		end
	end

	-- spawn to random location if back button pressed
	if (max_move_down == 0 or on_ladder) and (love.joystick.isDown(1, 7) or love.keyboard.isDown("r")) then
		random_seed_int = random_seed_int + 1000*math.random()
		math.randomseed(random_seed_int)
		valid_location = false
		while not valid_location do
			this_x = math.random(1, map.tiles_wide)
			this_y = math.random(1, map.tiles_tall)
			player_fits = true
			for i=this_y, math.min(this_y+player.tiles_tall, map.tiles_tall), 1 do
				for j=this_x, math.min(this_x+player.tiles_wide, map.tiles_wide), 1 do
					if (map.collision[i][j] == 1) then
						player_fits = false
					end
				end
			end
			valid_location = player_fits
		end

		player.speed=0
		player.pixel_location_x = this_x*tile_size
		player.pixel_location_y = this_y*tile_size
	end


	if not (((player.pixel_location_x % tile_size == 0) and (player.pixel_location_y % tile_size == 0)) and (love.keyboard.isDown("up", "down") and love.keyboard.isDown("left","right"))) then
		-- move player
		if love.keyboard.isDown("left") or (love.joystick.getAxis(1, 1) < -0.25) then
			player.face_right = false
			if (on_ladder) then
				player.pixel_location_x = player.pixel_location_x - 100*dt
			else
				player.pixel_location_x = player.pixel_location_x - math.min(100*dt, max_move_left)
			end
			center_camera()
		elseif love.keyboard.isDown("right") or (love.joystick.getAxis(1, 1) > 0.25) then
			player.face_right = true
			if (on_ladder) then
				player.pixel_location_x = player.pixel_location_x + 100*dt
			else
				player.pixel_location_x = player.pixel_location_x + math.min(100*dt, max_move_right)
			end
			center_camera()
		end
		if love.keyboard.isDown("up") or (love.joystick.getAxis(1, 2) < -0.25) then
			if (on_ladder) then
				player.pixel_location_y = player.pixel_location_y - 100*dt
			elseif (in_water and max_move_up ~= 0) then
				player.speed = math.min(-100, player.speed)
			end
			center_camera()
		elseif love.keyboard.isDown("down") or (love.joystick.getAxis(1, 2) > 0.25) then
			if (on_ladder) then
				player.pixel_location_y = player.pixel_location_y + math.min(100*dt, max_move_down)
			elseif in_water then
				player.speed = math.max(100, player.speed)
			end

			center_camera()
		end
	end

	-- jump
	if love.keyboard.isDown("z") and (max_move_down == 0) then
		if in_water then
			player.speed = -100
		else
			player.speed = -200
		end
	end

	-- gravity
	if ((max_move_down == 0 and (not love.keyboard.isDown("z")) and not (in_water and love.keyboard.isDown("up"))) or (on_ladder and max_move_down ~= 0)) then
		player.speed = 0
	else
		if max_move_up == 0 then
			player.speed = math.max(0, player.speed)
		end
		player.speed = player.speed + player.acceleration*dt
		player.pixel_location_y = player.pixel_location_y + math.max(math.min(player.speed*dt+(player.acceleration*(dt^2))/2, max_move_down), -max_move_up)
		center_camera()
	end

	-- on leftclick of mouse
	if love.mouse.isDown("l") then
		if love.mouse.getX() > window_width then
			tile_selector_for_editor()
		else
			editor_tile_stamp()
		end
	end



	-- keep camera on map
	camera:constrain(window_width, window_height, map.pixels_wide, map.pixels_tall)

	-- keep player on map
	if player.pixel_location_x < 0 then
		player.pixel_location_x = 0
	elseif player.pixel_location_x + player.pixels_wide > map.pixels_wide then
		player.pixel_location_x = map.pixels_wide - player.pixels_wide
	end
	if player.pixel_location_y < 0 then
		player.pixel_location_y = 0
	elseif player.pixel_location_y + player.pixels_tall > map.pixels_tall then
		player.pixel_location_y = map.pixels_tall - player.pixels_tall
	end

	-- mouse tracking for tile selection in and out of editor
	mouse_tracker()
	player.speed = math.min(player.speed, 300)

end


function love.draw()
	camera:set()

	draw_background_layer()

	draw_midground_layer()

	draw_crates()

	draw_player()

	draw_mousebox()

	camera:unset()

	if show_debug then
		draw_debug()

	end

	if show_editor then
		draw_editor()
		draw_editor_selectbox()
	end
end


function update_player_sprite()
	if player.crouching then
		if player.face_right then
			player.current_sprite = player_sprites.crouch_right
		else
			player.current_sprite = player_sprites.crouch_left
		end
	else
		if player.face_right then
			player.current_sprite = player_sprites.stand_right
		else
			player.current_sprite = player_sprites.stand_left
		end
	end
end

function center_camera()
	camera:setPosition(player.pixel_location_x - window_width/2,
					   player.pixel_location_y - window_height/2)
end

function mouse_tracker()
	local x, y = camera:mousePosition();
	mouse_x, mouse_y = math.floor(x / tile_size), math.floor(y / tile_size)
end

function tile_selector_for_editor()
	findx = 1+math.floor((love.mouse.getY())/tile_size)*math.floor(editor_width/tile_size)+math.floor((love.mouse.getX()-window_width)/tile_size)
	if findx > 0 and findx < #tileset+1 then
		current_editor_selection = findx
	end
end

function editor_tile_stamp()
	if current_editor_selection == 7 then
		if map.midground[mouse_y+1][mouse_x+1] == 0 then
			map.midground[mouse_y+1][mouse_x+1] = current_editor_selection
		elseif map.midground[mouse_y+1][mouse_x+1] == 7 then
			map.midground[mouse_y+1][mouse_x+1] = 0
		end
	elseif current_editor_selection == 1 or current_editor_selection == 10 then
		map.tiles[mouse_y+1][mouse_x+1] = current_editor_selection
		map.collision[mouse_y+1][mouse_x+1] = 0
	elseif current_editor_selection == 2 or current_editor_selection == 3 or current_editor_selection == 4 then
		map.tiles[mouse_y+1][mouse_x+1] = current_editor_selection
		map.collision[mouse_y+1][mouse_x+1] = 2
	else
		map.tiles[mouse_y+1][mouse_x+1] = current_editor_selection
		map.collision[mouse_y+1][mouse_x+1] = 1
	end
end

function draw_background_layer()
	for i=1, map.tiles_tall, 1 do
		for j=1, map.tiles_wide, 1 do
			love.graphics.newDraw(tileset[map.tiles[i][j]], (j-1)*tile_size, (i-1)*tile_size)
		end
	end
end

function draw_midground_layer()
	for i=1, map.tiles_tall, 1 do
		for j=1, map.tiles_wide, 1 do
			if map.midground[i][j] ~= 0 then
				love.graphics.newDraw(tileset[map.midground[i][j]], (j-1)*tile_size, (i-1)*tile_size)
			end
		end
	end
end

function draw_crates()

	-- optimize so you only draw crates on screen

	for i=1,#map.crates,1 do
		love.graphics.newDraw(tileset[8], map.crates[i].pixel_location_x, map.crates[i].pixel_location_y)
	end
end


function draw_player()
	love.graphics.newDraw(player.current_sprite, player.pixel_location_x, player.pixel_location_y)

	if player.crouching then
		love.graphics.newDraw(player_sprites.bounding_box_crouch, player.pixel_location_x, player.pixel_location_y)
	else
		love.graphics.newDraw(player_sprites.bounding_box, player.pixel_location_x, player.pixel_location_y)
	end
	love.graphics.newDraw(player_bounding_box_sprites.top_left, (player_left-1)*tile_size, (player_top-1)*tile_size)
	love.graphics.newDraw(player_bounding_box_sprites.top_right, (player_right-1)*tile_size, (player_top-1)*tile_size)
	love.graphics.newDraw(player_bounding_box_sprites.bottom_left, (player_left-1)*tile_size, (player_bottom-1)*tile_size)
	love.graphics.newDraw(player_bounding_box_sprites.bottom_right, (player_right-1)*tile_size, (player_bottom-1)*tile_size)
end

function draw_mousebox()
	love.graphics.newDraw(player_bounding_box_sprites.top_left, mouse_x*tile_size, mouse_y*tile_size)
	love.graphics.newDraw(player_bounding_box_sprites.top_right, mouse_x*tile_size, mouse_y*tile_size)
	love.graphics.newDraw(player_bounding_box_sprites.bottom_left, mouse_x*tile_size, mouse_y*tile_size)
	love.graphics.newDraw(player_bounding_box_sprites.bottom_right, mouse_x*tile_size, mouse_y*tile_size)
end

function draw_editor_selectbox()
	if love.mouse.getX() > window_width then
		love.graphics.newDraw(player_bounding_box_sprites.top_left, love.mouse.getX()-love.mouse.getX()%tile_size, love.mouse.getY()-love.mouse.getY()%tile_size)
		love.graphics.newDraw(player_bounding_box_sprites.top_right, love.mouse.getX()-love.mouse.getX()%tile_size, love.mouse.getY()-love.mouse.getY()%tile_size)
		love.graphics.newDraw(player_bounding_box_sprites.bottom_left, love.mouse.getX()-love.mouse.getX()%tile_size, love.mouse.getY()-love.mouse.getY()%tile_size)
		love.graphics.newDraw(player_bounding_box_sprites.bottom_right, love.mouse.getX()-love.mouse.getX()%tile_size, love.mouse.getY()-love.mouse.getY()%tile_size)
	end
end

function draw_debug()
	love.graphics.setColor(0,0,0,255)

	if love.mouse.getX() > window_width then
		love.graphics.print("selected_tile_ID: " .. current_editor_selection, 10, 10)
	else
		love.graphics.print("mouse over tile: (".. 1+mouse_x .. ", " .. 1+mouse_y .. ")", 10, 10)
	end

	--love.graphics.print("midgr x: " .. i .. " midgr y: " .. j , 10, math.floor(camera.y) +20)
	love.graphics.print("player x: " .. player.pixel_location_x .. " player y: " .. player.pixel_location_y, 10, 30)
	love.graphics.print("max move: down " .. max_move_down .. " up " .. max_move_up .. " left " .. max_move_left .. " right " .. max_move_right , 10, 60)
	love.graphics.print("player bottom " .. player.pixel_location_y+player.pixels_tall .. " " .. player_bottom, 10, 70)
	love.graphics.print("player left " .. player.pixel_location_x .. " " .. player_left, 10, 80)
	love.graphics.print("player right " .. player.pixel_location_x+player.pixels_wide .. " " .. player_right, 10, 90)
	love.graphics.print("player top " .. player.pixel_location_y .. " " .. player_top, 10, 100)

	love.graphics.print("player acceleration " .. player.acceleration .. " speed " .. player.speed, 10, 110)

	fix_color_buffer()
end

function draw_editor()
	love.graphics.setColor(100,100,100,255)
	love.graphics.rectangle("fill", window_width, 0, editor_width, window_height)
	fix_color_buffer()
	love.graphics.print("selected tile", window_width+8, 150)
	love.graphics.newDraw(tileset[current_editor_selection], window_width+tile_size*4, tile_size*6)
	tiles_per_row = math.floor(editor_width/tile_size)
	for i=1,#tileset,1 do
		this_row = math.floor((i-1)/tiles_per_row)
		this_col = (i-1)%tiles_per_row
		love.graphics.newDraw(tileset[i], window_width+this_col*tile_size, this_row*tile_size)
	end
end

function fix_color_buffer()
	love.graphics.setColor(255,255,255,255)
end
