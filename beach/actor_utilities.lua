-->8
-- actors utilities

function is_on_screen(a)
	local x = a.x*8
	local y = a.y*8

	if (x >= camera_pos.x and x <= camera_pos.x + 128 
	and y >= camera_pos.y and y <= camera_pos.y + 128) then
		return true
	else
		return false
	end
end

function is_in_room(a)
	local x = a.x*8
	local y = a.y*8

	local r = get_room()

	if (x >= r.x and x <= r.x + 128 
	and y >= r.y and y <= r.y + 128) then
		return true
	else
		return false
	end
end

function execute_on_frame(a,f,n,c)
	if (a.frame==f and not a[n]) then
		a[n] = true
		c()
	else
		if (a.frame!=f) a[n] = false
	end
end

function actor_is_invincible(a)
	if (not a.invi_timestamp) return false

	return (time() - a.invi_timestamp) <= a.invi_length
end

function create_actor(a)
	a.anim_timestamp = time()
	a.birth_timestamp = time()

	a.start_x = a.x
	a.start_y = a.y

	a.id = actor_iteration

	if (a.frame != nil) then
		for i=0,7 do
			a.flags[i] = fget(a.frame, i)
		end	
	end

	add(actors, a)

	actor_iteration += 1

	return a
end

function replace_with_actor(t, r, callback, define) 
	if (not define) define = define_actor

    for y=0,256 do for x=0,256 do
        if (mget(x,y) == t) then
			if (r) mset(x,y,r)

			local a = define()
			a.x = x+(4/8)
			a.y = y+(4/8)
			a.frame = t
			if (callback) callback(a)
	
			create_actor(a)
		end
    end
end end

--

function create_hit_effect(a)
	for i=0,rnd(2)+3 do
		local p = define_particle(125,126)

		p.x = a.x
		p.y = a.y
		p.vx = (rnd(2)-1)
		p.vy = (rnd(2)-1)
		p.z = 0

		create_actor(p)
	end
end

function create_random_drop(a)
	local r = ceil(rnd(7))

	if (r == 1) create_coins(a)
	if (r == 2) create_hearts(a)
	if (r == 3) create_bombs(a)
end

function create_coins(a)
	create_drop(a,107)
end

function create_hearts(a)
	create_drop(a,77)
end

function create_bombs(a)
	create_drop(a,105)
end

function create_drop(a,f) 
	for i=0,0 do
		local a2 = define_actor()

		a2.x = a.x
		a2.y = a.y
		a2.vx = (rnd(2)-1)*0.75
		a2.vy = (rnd(2)-1)*0.75
		a2.frame=f

		create_actor(a2)
	end
end

function create_dust_cloud(a)
	for i=0,rnd(2)+1 do
		local p = define_particle(109,111)

		p.x = a.x
		p.y = a.y
		p.vx = (rnd(2)-1)*0.75
		p.vy = (rnd(2)-1)*0.75

		create_actor(p)
	end
end

function create_dust(a,f)
	execute_on_frame(a,f,"dust_p", function() 
		local p = define_particle(93,94)

		p.x = a.x
		p.y = a.y+.4
		p.z=0
		p.vy=-0.045
		p.vx=-0
		p.max_v=100
		p.friction=0
		p.collidible=false
		p.anim_duration=0.25

		create_actor(p)
	end)
end