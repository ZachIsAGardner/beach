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
	if (pl == nil) return { x=0,y=0 }

	return {
		x=flr(pl.x/16)*128,
		y=flr(pl.y/16)*128
	}
end

function night_mode()
	for i=0,15 do
		pal(i,i+128,1)
	end
end