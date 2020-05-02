pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-->8
-- game

actors = {}
actor_iteration = 0
disabled_actors = {}
actors_to_respawn = {}

camera_pos = { x = 0, y = 0, s = 0.025}

transition = nil

door_timestamp=nil

current_room=nil
visited_rooms={}

debug_mode=true

started=false
started_timestamp=nil

game_ended=false
game_ended_timestamp=nil
game_ended_process={}

logs = {}
log_count = 0

--init
function _init()
    if (debug_mode) then
        start()
        camera_pos.s=0.25
    end
    
	music(63)
end

--update
function _update()
	if (started) then
		-- move camera normally
		destination = {
			x = get_room().x,
			y = get_room().y
		}

		local xf = (camera_pos.s * (destination.x - camera_pos.x))
		local yf = (camera_pos.s * (destination.y - camera_pos.y))

		camera_pos.x = camera_pos.x + (ceil(abs(xf)) * sgn(xf))
		camera_pos.y = camera_pos.y + (ceil(abs(yf)) * sgn(yf))
	else
		-- title screen
		camera_pos.x = 0
		camera_pos.y = 128

		if (btn(4)) then
			start()
		end
	end

	-- update camera
	camera(camera_pos.x, camera_pos.y)

	cleanup_rooms()

	if (transition != nil) then 
		return
	end

	-- update actors
	for a in all(actors) do
		a:update()
	end
end

function cleanup_rooms()
	local r = get_room()

	local new_room = false
	if (current_room == nil or not (r.x == current_room.x and r.y == current_room.y)) then
		new_room = true
	end
	current_room = r

	if (new_room) then
		local first_visit = true
		for visited_room in all(visited_rooms) do
			if visited_room.x == current_room.x and visited_room.y == current_room.y then
				first_visit = false
				break
			end
		end

		if (first_visit) then
			local r_grid = get_room_grid()
			for ra in all(actors_to_respawn) do
				if (ra.room.x==r_grid.x and ra.room.y==r_grid.y) respawn_actor(ra)
			end
			init_actors()
			add(visited_rooms,current_room)
		end
		
		for da in all(disabled_actors) do
			add(actors,da)
		end

		disabled_actors={}

		for a in all(actors) do
			if (not is_in_room(a)) then 
				if (a.destroy_offscreen) then
					del(actors,a)
				else
					add(disabled_actors,a)
					del(actors,a)
				end
			end
		end

		-- log("a= " .. #actors .. ", da= " .. #disabled_actors)
	end
end

--draw
function _draw()
	-- clear screen
    cls(13)
    
    -- draw map
	map()

	-- draw actors
	for i=0,2 do
		for a in all(actors) do
			if (a.z==i) a:draw()
		end
	end

    if (not started) then
        -- title
        print("beach", 0+52, 128+52, c_white)
        print("- press " .. p_prompt .. " -", 0-12+52, 128+8+52, c_white)
    end

	if (game_ended) then
		if (time() - game_ended_timestamp > 1) then
			draw_text("you escaped", 30, 50, 2)

			if (not game_ended_process.sfx_1) then
				sfx(3)
				game_ended_process.sfx_1 = true
			end
		end

		if (time() - game_ended_timestamp > 1.5) then
			draw_text(
				"time: " .. flr(game_ended_timestamp / 60) .. " m " 
					.. ceil(game_ended_timestamp % 60) .. " s", 
				30, 60, 2
			)

			if (not game_ended_process.sfx_2) then
				sfx(3)
				game_ended_process.sfx_2 = true
			end
		end

		if (time() - game_ended_timestamp > 3) then
			draw_text("thanks for playing", 30, 80, 2)

			if (not game_ended_process.sfx_3) then
				sfx(3)
				game_ended_process.sfx_3 = true
			end
		end
    end

    night_mode()

	if (transition) then
		transition_screen()
	end
	
    if (debug_mode) debug()
end

function debug()
	rectfill(camera_pos.x,camera_pos.y+119,camera_pos.x+40,camera_pos.y+125,c_dark_blue)
	local color = c_white
	if (stat(7) != 30) color = c_red
	print("fps: " .. stat(7), camera_pos.x+1, camera_pos.y+120, color)
	
    draw_log()
end