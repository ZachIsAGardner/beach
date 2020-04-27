-->8
-- game

actors = {}
actor_iteration = 0

camera_pos = { x = 0, y = 0, s = 0.025}

debug_mode=true

started=false
started_timestamp=nil

game_ended=false
game_ended_timestamp=nil

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
	if (game_ended) then
		music(-1)
		return
	end

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

	-- update actors
	for a in all(actors) do
		if (is_in_room(a) or pl and a.id == pl.id) a:update()
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
			if (a.z==i and is_in_room(a)) a:draw()
		end
	end

    if (not started) then
        -- title
        print("beach", 0+52, 128+52, c_white)
        print("- press " .. p_prompt .. " -", 0-12+52, 128+8+52, c_white)
    end

	if (game_ended) then
		print("thanks for playing", camera_pos.x + 30, camera_pos.y + 50, c_white)
		print("coins: " .. pl.coins, camera_pos.x + 30, camera_pos.y + 58, c_white)
		print("time: " .. flr(game_ended_timestamp / 60) .. " m " .. ceil(game_ended_timestamp % 60) .. " s", camera_pos.x + 30, camera_pos.y + 66, c_white)
		return
    end

    night_mode()
    
    debug()
end

function debug()
	rectfill(camera_pos.x,camera_pos.y+119,camera_pos.x+40,camera_pos.y+125,c_dark_blue)
	local color = c_white
	if (stat(7) != 30) color = c_red
	print("fps: " .. stat(7), camera_pos.x+1, camera_pos.y+120, color)
	
    draw_log()
end