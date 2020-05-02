pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-->8
-- draw

function draw_player(a)
	draw_actor(a)

	spr(101,camera_pos.x+1, camera_pos.y+8)
	print(a.bombs, camera_pos.x+9, camera_pos.y+9, c_white)

	spr(95,camera_pos.x+2, camera_pos.y+17)
	print(a.coins, camera_pos.x+9, camera_pos.y+17, c_white)
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
		3+camera_pos.y,
		8*(pl.max_health)+camera_pos.x,
		6+camera_pos.y,
		c_dark_blue
	)

	for i=0,pl.max_health-1 do
		local color=c_red
		if (i>pl.health-1) color=c_white
		pal(c_red,color)
		spr(78,i*8+2+camera_pos.x,2+camera_pos.y)
	end
end

function draw_floating_health(a)
	if (not a.invi_timestamp or time() - a.invi_timestamp > 1.5) return
	
	local length = (a.max_health - 1) * 4
	local start = (a.x*8-4) - (length/3.5)
	rectfill(
		start,
		a.y*8-4-4,
		start + length,
		(a.y*8-4-4)+2,
		c_dark_blue
	)

	for j=0,a.max_health-1 do
		local color=c_red
		if (j>a.health-1) color=c_white
		pal(c_red,color)
		spr(
			79,
			start+(j*4),
			a.y*8-4-4
		)
	end

	pal()
end