pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-->8
-- utilities

function log(m)
	log_count += 1
	add(logs, { m=m,c=log_count })
end

function draw_log()	
	o = {x=2,y=36}

	local j = 0
	local i = #logs
	while i > 0 and j < 10 do
		rectfill(
			camera_pos.x + o.x,
			camera_pos.y + (j * 8) + o.y,
			camera_pos.x + o.x+64,
			camera_pos.y + (j * 8) + o.y + 5,
			c_dark_blue
		)
		print(logs[i].c .. ": " .. logs[i].m, camera_pos.x + o.x, camera_pos.y + (j * 8) + o.y, c_white)
		i-=1
		j+=1
	end
end

function length(x,y)
	local d = max(abs(x),abs(y))
  	local n = min(abs(x),abs(y)) / d
  	return sqrt(n*n + 1) * d
end

function distance(o1, o2)
	return {
		x = o1.x - o2.x,
		y = o1.y - o2.y
	}
end

function pal_all(c)
	for i=0,15 do
		pal(i,c,0)
	end
end

function get_room()
	local t = nil
	if (pl != nil) then
		t = pl
	else
		if (debug_mode) t = find_tile(112)
	end

	if (t == nil) return {x=0,y=0}

	return {
		x=flr(t.x/16)*128,
		y=flr(t.y/16)*128
	}
end

function get_room_grid()
	local t = nil
	if (pl != nil) then
		t = pl
	else
		if (debug_mode) t = find_tile(112)
	end

	if (t == nil) return {x=0,y=0}

	return {
		x=flr(t.x/16)*16,
		y=flr(t.y/16)*16
	}
end

function night_mode()
	for i=0,15 do
		pal(i,i+128,1)
	end
end

function draw_text(t,x,y,p) 
	p = p or 1
	rectfill(
		camera_pos.x+x-p,
		camera_pos.y+y-p,
		camera_pos.x+x+(#t*4)-2+p,
		camera_pos.y+y+4+p,
		c_dark_blue
	)

	print(t, camera_pos.x+x, camera_pos.y+y, c_white)
end