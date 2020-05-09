pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-->8
-- draw

function draw_player(a)
	draw_actor(a)

	rectfill(camera_pos.x+2,camera_pos.y+10,camera_pos.x+14,camera_pos.y+17,c_dark_blue)
	local color = c_white
	if (a.bomb_pickup_timestamp and time() - a.bomb_pickup_timestamp < 0.25) color = c_green
	if (a.bomb_timestamp and time() - a.bomb_timestamp < 0.25) color = c_pink
	print(a.bombs, camera_pos.x+11, camera_pos.y+12, color)
	spr(101,camera_pos.x+2, camera_pos.y+10)

	-- spr(95,camera_pos.x+2, camera_pos.y+17)
	-- print(a.coins, camera_pos.x+9, camera_pos.y+17, c_white)
end

function draw_actor(a)
	a:draw_health()

	if actor_is_invincible(a) then
		for i=0,15 do
			pal(i,c_white,0)
		end
	end

	local sx = (a.x * 8) - 4
	local sy = (a.y * 8) - 4
	spr(a.frame, sx, sy, a.s, a.s, a.flip)
	pal()
end

function draw_circle(a)
	circfill(a.x * 8,a.y * 8, a.r * 8, a.color)
end

function draw_fixed_health()
	rectfill(
		2+camera_pos.x,
		2+camera_pos.y,
		8*(pl.max_health)+camera_pos.x,
		8+camera_pos.y,
		c_dark_blue
	)

	for i=0,pl.max_health-1 do
		local color=c_red
		if (pl.health_pickup_timestamp and time() - pl.health_pickup_timestamp < 0.25) color=c_green
		if (pl.invi_timestamp and time() - pl.invi_timestamp < 0.25) color=c_pink
		if (i>pl.health-1) color=c_white
		pal(c_red,color)
		spr(78,i*8+3+camera_pos.x,3+camera_pos.y)
	end
end

function draw_floating_health(a)
	if (not a.invi_timestamp or time() - a.invi_timestamp > 2.5) return

	local rows = ceil(a.max_health/10)
	
	local length = ((a.max_health - 1) * 4) / rows
	local start = (a.x*8-4) - (length/3.5)
	
	rectfill(
		start-1,
		a.y*8-4-4-1,
		start + length + 3,
		((a.y*8-4-4)+2)+(4 * (rows - 1))+1,
		c_dark_blue
	)

	local l = 0
	local r = 0
	for j=0,a.max_health-1 do
		local color=c_red
		if (j>a.health-1) color=c_white
		pal(c_red,color)

		spr(
			79,
			start+(l*4),
			(a.y*8-4-4)+(4*r)
		)

		l+=1
		if (l > 9) then 
			l = 0
			r+=1
		end
	end

	pal()
end