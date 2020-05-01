pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-->8
-- collision

function move_actor(a)
	if (a.collidible) then
		local skin = 0.02
		local o = (0.5 * (-1 + a.s))

		if (abs(a.vx) > 0) then
			local left = sgn(a.vx) == -1

			local h_hit = is_solid_area_h(a.x + a.vx + o, a.y + o, a.w, a.h, left, skin, f_col)
			if (h_hit.hit) then
				-- snap to wall
				a.x = (h_hit.rx + ((a.w + 0.5) * (sgn(a.vx) * -1))) - o
				if (left) then
					a.x = a.x + skin
				else
					a.x = a.x - skin
				end

				a.vx=0

				if (left) then 
					a.col.left=true
					a.col.right=false
				else
					a.col.left=false
					a.col.right=true
				end
			else
				a.col.left = false
				a.col.right = false

				a.x += a.vx
			end
		end

		if (abs(a.vy) > 0) then
			local top = sgn(a.vy) == -1

			local v_hit = is_solid_area_v(a.x + o, a.y + a.vy + o, a.w, a.h, top, skin, f_col)

			if (v_hit.hit) then
				-- snap to wall
				a.y = (v_hit.ry + ((a.h + 0.5) * (sgn(a.vy) * -1))) - o
				if (top) then
					a.y = a.y + skin
				else
					a.y = a.y - skin
				end

				a.vy=0

				if (top) then 
					a.col.top=true
					a.col.bottom=false
				else
					a.col.top=false
					a.col.bottom=true
				end
			else
				a.col.top = false
				a.col.bottom = false

				a.y += a.vy
			end
		end
	else
		a.x += a.vx
		a.y += a.vy
    end

    a.vx *= (1-a.friction)
    a.vy *= (1-a.friction)

    if (a.vx > a.max_v) a.vx = a.max_v
    if (a.vx < a.max_v * -1) a.vx = a.max_v * -1
    if (a.vy > a.max_v) a.vy = a.max_v
    if (a.vy < a.max_v * -1) a.vy = a.max_v * -1
end

function is_solid_area_h(x,y,w,h,left,skin,flag)
	if (left) then
		local top_left = is_solid(x-w-skin,y-h,flag) 
		if (top_left.hit) return top_left

		local middle_left = is_solid(x-w-skin,y,flag) 
		if (middle_left.hit) return middle_left

		local bottom_left = is_solid(x-w-skin,y+h,flag) 
		if (bottom_left.hit) return bottom_left
	else
		local top_right = is_solid(x+w+skin,y-h,flag) 
		if (top_right.hit) return top_right

		local middle_right = is_solid(x+w+skin,y,flag) 
		if (middle_right.hit) return middle_right

		local bottom_right = is_solid(x+w+skin,y+h,flag) 
		if (bottom_right.hit) return bottom_right
	end

	return { hit=false }
end

function is_solid_area_v(x,y,w,h,top,skin,flag)
	if (top) then
		local top_left = is_solid(x-w,y-h-skin,flag) 
		if (top_left.hit) return top_left

		local top_middle = is_solid(x,y-h-skin,flag) 
		if (top_middle.hit) return top_middle

		local top_right = is_solid(x+w,y-h-skin,flag) 
		if (top_right.hit) return top_right
	else
		local bottom_left = is_solid(x-w,y+h+skin,flag) 
		if (bottom_left.hit) return bottom_left

		local bottom_middle = is_solid(x,y+h+skin,flag) 
		if (bottom_middle.hit) return bottom_middle

		local bottom_right = is_solid(x+w,y+h+skin,flag) 
		if (bottom_right.hit) return bottom_right
	end

	return { hit=false }
end

function is_solid_area(x,y,w,h,flag,c)
	local top_left = is_solid(x-w,y-h,flag,c) 
	if (top_left.hit) return top_left
		
	local top_right = is_solid(x+w,y-h,flag,c) 
	if (top_right.hit) return top_right

	local bottom_left = is_solid(x-w,y+h,flag,c) 
	if (bottom_left.hit) return bottom_left

	local bottom_right = is_solid(x+w,y+h,flag,c) 
	if (bottom_right.hit) return bottom_right

	return { hit=false }
end

function is_solid(x,y,flag,c)
	local rx=ceil(x)-.5	
	local ry=ceil(y)-.5	

	-- check map
    if fget(mget(x, y), flag) then
		return { hit=true,rx=rx,ry=ry,x=x,y=y }
	end

	-- check collidible actors
	for a in all(actors) do
		if (a.flags[flag] or c and c(a)) then
			local o = 0

			if (a.s == 2) o = 0.5

			if (x < a.x + a.w + o
				and x > a.x - a.w + o
				and y < a.y + a.h + o
				and y > a.y - a.h + o
			) then
				return { hit=true,rx=rx,ry=ry,x=x,y=y,a=a }
			end
		end
	end

	-- no hits
	return { hit=false }
end