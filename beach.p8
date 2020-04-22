pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- beach
-- zachary gardner

-- lifecycle

actors = {}
actor_iteration = 0

logs = {}
log_count = 0
d_draw = {x=0,y=0,frame=15}

p_prompt="🅾️"
s_prompt="❎"

f_en_atk=0
f_col=1
f_pl_atk=2

c_black=0
c_dark_blue=1
c_dark_purple=2
c_dark_green=3
c_brown=4
c_dark_gray=5
c_light_gray=6
c_white=7
c_red=8
c_orange=9
c_yellow=10
c_green=11
c_blue=12
c_indigo=13
c_pink=14
c_peach=15

started=false

--init
function _init()
	init_actors()

	music(63)
end

--update
function _update()
    for a in all(actors) do
		a:update()
	end

	if (started) then
		camera(
			get_room().x,
			get_room().y
		)
	else
		camera(0,128)

		if (btn(4)) then
			started=true
		end
	end
end

--draw
function _draw()
	-- clear screen
	cls(1)
	
	-- draw map
	map()

	-- draw actors
	for i=0,2 do
		for a in all(actors) do
			if (a.z==i) a:draw()
		end
	end

	night_mode()

	local r = get_room()

	print("beach", 0+52, 128+52, c_white)
	print("- press " .. p_prompt .. " -", 0-12+52, 128+8+52, c_white)

	-- debug
    draw_log()
	-- draw_actor(d_draw)
	-- d_draw = { x=-10,y=-10,frame=15 }
end

-->8
-- init

function init_actors()
	-- create player
	replace_with_actor(
		1,
		33,
		function(a)
			pl = a
		end,
		define_player
	)
	
	-- waves
	replace_with_actor(
		51,
		nil,
		function(a) 
			a.anims={
				idle={s=51,e=56,l=true}
			}
			a.anim_duration=1.5
			a.z=0
		end
	)

	-- seagulls
	replace_with_actor(80,33,function(a)
		if (flr(rnd(2)) == 0) a.flip=true
		
		a.update=function(a) 
			update_actor(a)

			local pl_close = false

			if (abs(pl.x - a.x) < 2.25 and abs(pl.y - a.y) < 2.25) then
				pl_close=true
			end
			
			if (pl_close and not a.escape) then
				a.escape=true

				a.vy=-0.25
				if (a.flip) then
					a.vx=-0.125
				else
					a.vx=0.125
				end
				a.collidible=false
				a.friction=-0.1
				a.max_v=0.35
				a.frame=81

				sfx(12)
			end
		end
	end)

	-- barrels
	replace_with_actor(38,33,function(a) a.w=0.5 a.h=0.5 end)

	-- squids
	replace_with_actor(
		64,
		33,
		function(a) 
			a.update=update_follower 
			a.anims={
				idle={s=64,e=64,l=true},
				walk={s=64,e=65,l=true}
			}
			a.max_health=3
			a.health=3
		end
	)
end

-->8
-- update

function update_player(a)
	update_actor(a)

	create_dust(a,3)
	execute_on_frame(a,3,"sfx_10",function() sfx(10) end)
	
	
	if (a.current_anim != "attack") then
		if (btn(0)) a.vx -= a.acc
		if (btn(1)) a.vx += a.acc
		if (btn(2)) a.vy -= a.acc
		if (btn(3)) a.vy += a.acc

		if (btn(0) or btn (1) 
		or btn(2) or btn(3)) then
			a.current_anim="walk"
		else
			a.current_anim="idle"
		end
	end

	-- attack
	if (btn(4) and a.current_anim != "attack") then
		a.current_anim="attack"
		sfx(9)
		a.atk_timestamp=time()
	end	

	if (a.atk_timestamp and time() - a.atk_timestamp > 0.15 and a.current_anim=="attack" and not a.atk_instance) then
		local circle = define_circle()

		circle.update=function(a)
			a.x = pl.x
			a.y = pl.y
		end
		circle.z=0
		circle.r=1.6
		circle.w=1.6
		circle.h=1.6
		circle.flags[f_pl_atk]=true
		circle.color=c_red

		a.atk_instance = create_actor(circle)
	end

	if (a.atk_timestamp and time() - a.atk_timestamp > 0.275 and a.current_anim=="attack") then
		del(actors, a.atk_instance)
		a.atk_instance = nil
	end

	if (a.atk_timestamp and time() - a.atk_timestamp > 0.4 and a.current_anim=="attack") then
		a.current_anim="idle"
	end

	local hit_atk = is_solid_area(a.x, a.y, a.w, a.h, f_en_atk)


	if (hit_atk.hit and not actor_is_invincible(a)) then
		local continue = true

		if (hit_atk.hit) then
			if (hit_atk.a) then

				if (actor_is_invincible(hit_atk.a)) then
					continue = false
				else
					a.vx = hit_atk.a.vx * 5
					a.vy = hit_atk.a.vy * 5
				end
			end
		end

		if (continue) then
			sfx(6)
			a.health -= 1
			a.invi_timestamp = time()

			del(actors, a.atk_instance)
			a.atk_instance = nil
			a.current_anim="idle"
		end
	end

	if (a.health <= 0) then
		sfx(7)
		a.health = a.max_health
		a.x = a.start_x
		a.y = a.start_y
	end
end

function update_follower(a)
	update_actor(a)

	create_dust(a,65)
	execute_on_frame(a,65,"sfx_10",function() sfx(10) end)
	
	if (not actor_is_invincible(a)) then
		a.current_anim="walk"
		
		if (pl.x < a.x) a.vx -= a.acc
		if (pl.x > a.x) a.vx += a.acc
		if (pl.y < a.y) a.vy -= a.acc
		if (pl.y > a.y) a.vy += a.acc
	else
		a.current_anim="idle"
	end

	local hit_atk = is_solid_area(a.x, a.y, a.w, a.h, f_pl_atk)

	if (hit_atk.hit and not actor_is_invincible(a)) then
		sfx(8)
		a.health -= 1
		a.invi_timestamp = time()

		if (a.health > 0) then
			-- create particles
			for i=0,rnd(2)+3 do
				local p = define_particle(160,161)

				p.x = a.x
				p.y = a.y
				p.vx = (rnd(2)-1)
				p.vy = (rnd(2)-1)
				p.z = 0

				create_actor(p)
			end
		end
	end

	if (a.health <= 0) then
		-- create particles
		for i=0,rnd(2)+3 do
			local p = define_particle(176,178)

			p.x = a.x
			p.y = a.y
			p.vx = (rnd(2)-1)*1.25
			p.vy = (rnd(2)-1)*1.25

			create_actor(p)
		end
		
		sfx(7)
		del(actors, a)	
	end
end

function update_actor(a) 
	if (a.anims) then
		local anim_changed = false
		if (a.old_current_anim and a.old_current_anim != a.current_anim) then 
			anim_changed = true
		end
		a.old_current_anim = a.current_anim

		if (anim_changed) then
			a.frame=a.anims[a.current_anim].s
			anim_timestamp = time()
		end

		if ((time() - a.anim_timestamp) > a.anim_duration) then
			a.frame += 1
			a.anim_timestamp = time()
		end

		if (a.frame > a.anims[a.current_anim].e) then 
			if (a.anims[a.current_anim].d) then
				del(actors, a)
				return
			end

			if (a.anims[a.current_anim].l) then
				a.frame = a.anims[a.current_anim].s
			else
				a.frame = a.anims[a.current_anim].e
			end
		end
	end

	move_actor(a)
end

function create_dust(a,f)
	if (a.frame==f and not a.created_p) then
		local p = define_particle(144,145)

		p.x = a.x
		p.y = a.y+.4
		p.z=0
		p.vy=-0.045
		p.vx=-0
		p.max_v=100
		p.friction=0
		p.collidible=false
		p.anim_duration=0.25

		a.created_p=true

		create_actor(p)
	else
		if (a.frame!=f) a.created_p=false
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

-->8
-- draw

function draw_actor(a)
	a:draw_health()

	if actor_is_invincible(a) then
		for i=0,15 do
			pal(i,c_white,0)
		end
	end

	local sx = (a.x * 8) - 4
	local sy = (a.y * 8) - 4
	spr(a.frame, sx, sy, 1, 1, a.flip)
	pal()
end

function draw_circle(a)
	circfill(a.x * 8,a.y * 8, a.r * 8, a.color)
end

function draw_fixed_health()
	local r = get_room()

	rectfill(1+r.x,2+r.y,8*(pl.max_health)+r.x,6+r.y,c_dark_blue)

	for i=0,pl.max_health-1 do
		local color=c_red
		if (i>pl.health-1) color=c_white
		pal(c_red,color)
		spr(128,i*8+1+r.x,1+r.y)
	end
end

function draw_floating_health(a)
	if (not actor_is_invincible(a)) return
	
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
			129,
			start+(j*4),
			a.y*8-4-4
		)
	end
end

-->8
-- definitions

function define_actor()
	return {
		x = 0, -- position x
		y = 0, -- position y
		frame = 0, -- frame of animation
		w = 0.4, -- half width
		h = 0.4, -- half height
		z = 1, -- draw order

		vx = 0, -- velocity x
		vy = 0, -- velocity y
		max_v = 0.055, -- max velocity
		acc = 0.015, -- movement acceleration
		friction = 0.25, -- friction
		collidible = true, -- will collide with walls

		flags = {},

		start_x = 0,
		start_y = 0,

		health = 1,
		max_health = 1,
		invi_length = 0.25,
		invi_timestamp = -10,

		update=update_actor,
		draw=draw_actor,
		draw_health=draw_floating_health,

		anim_timestamp=0, -- timestamp since last frame change
		anim_duration=0.095, -- duration to show one frame in an animation
		anims=nil, -- define animations
		current_anim="idle" -- current animation
	}
end

function define_circle()
	local a = define_actor()

	a.draw = draw_circle
	a.frame = nil
	a.r = 1

	return a
end

function define_player()
	local a = define_actor()

	a.x = 9
	a.y = 4
	a.frame = 1

    a.w = 0.3
    a.h = 0.4

    a.vx = 0
    a.vy = 0
    a.max_v = 0.085
    a.acc = 0.085
    a.friction = 0.185

	a.health = 6
	a.max_health = 6

	a.invi_length = 0.7

	a.update = update_player
	a.draw_health = draw_fixed_health

	a.anims={
		idle={s=1,e=1,l=true},
		walk={s=2,e=3,l=true},
		attack={s=4,e=7,l=false}
	}

	return a
end

function define_particle(s,e)
	local a = define_actor()

	a.frame = s
	a.anims={idle={s=s,e=e,l=false,d=true}}
	a.anim_duration=0.15

	return a
end

-->8
-- collision

function move_actor(a)
	if (a.collidible) then
		local skin = 0.02

		if (abs(a.vx) > 0) then
			local left = sgn(a.vx) == -1

			local h_hit = is_solid_area_h(a.x + a.vx, a.y, a.w, a.h, left, skin, f_col)
			if (h_hit.hit) then
				-- snap to wall
				a.x = (h_hit.rx + ((a.w + 0.5) * (sgn(a.vx) * -1)))
				if (left) then
					a.x = a.x + skin
				else
					a.x = a.x - skin
				end
				a.vx=0
			else
				a.x += a.vx
			end
		end

		if (abs(a.vy) > 0) then
			local top = sgn(a.vy) == -1

			local v_hit = is_solid_area_v(a.x, a.y + a.vy, a.w, a.h, top, skin, f_col)

			if (v_hit.hit) then
				-- snap to wall
				a.y = (v_hit.ry + ((a.h + 0.5) * (sgn(a.vy) * -1)))
				if (top) then
					a.y = a.y + skin
				else
					a.y = a.y - skin
				end
				a.vy=0
			else
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

		local bottom_left = is_solid(x-w-skin,y+h,flag) 
		if (bottom_left.hit) return bottom_left
	else
		local top_right = is_solid(x+w+skin,y-h,flag) 
		if (top_right.hit) return top_right

		local bottom_right = is_solid(x+w+skin,y+h,flag) 
		if (bottom_right.hit) return bottom_right
	end

	return { hit=false }
end

function is_solid_area_v(x,y,w,h,top,skin,flag)
	if (top) then
		local top_left = is_solid(x-w,y-h-skin,flag) 
		if (top_left.hit) return top_left

		local top_right = is_solid(x+w,y-h-skin,flag) 
		if (top_right.hit) return top_right
	else
		local bottom_left = is_solid(x-w,y+h+skin,flag) 
		if (bottom_left.hit) return bottom_left

		local bottom_right = is_solid(x+w,y+h+skin,flag) 
		if (bottom_right.hit) return bottom_right
	end

	return { hit=false }
end

function is_solid_area(x,y,w,h,flag)
	local top_left = is_solid(x-w,y-h,flag) 
	if (top_left.hit) return top_left
		
	local top_right = is_solid(x+w,y-h,flag) 
	if (top_right.hit) return top_right

	local bottom_left = is_solid(x-w,y+h,flag) 
	if (bottom_left.hit) return bottom_left

	local bottom_right = is_solid(x+w,y+h,flag) 
	if (bottom_right.hit) return bottom_right

	return { hit=false }
end

function is_solid(x,y,flag)
	local rx=ceil(x)-.5	
	local ry=ceil(y)-.5	

	-- check map
    if fget(mget(x, y), flag) then
		-- d_draw = {x=rx,y=ry,frame=15}
		return { hit=true,rx=rx,ry=ry,x=x,y=y }
	end

	-- check collidible actors
	for a in all(actors) do
		if (a.flags[flag]) then
			if (x < a.x + a.w 
				and x > a.x - a.w
				and y < a.y + a.h
				and y > a.y - a.h
			) then
				return { hit=true,rx=rx,ry=ry,x=x,y=y,a=a }
			end
		end
	end

	-- no hits
	return { hit=false }
end

-->8
-- other

function draw_text(m)
	r = get_room()
	o = 4
	
	for i=0,14 do
		spr(9,r.x+(i*8)+o,r.y+o)	
	end
	
	print(
		m,
		r.x+1+o,
		r.y+1+o
	)
end

function draw_sign()
	if (mget(pl.x,pl.y)==8) then
		draw_text("hi!")
	end
end

-->8
-- utility

function actor_is_invincible(a)
	if (not a.invi_timestamp) return false

	return (time() - a.invi_timestamp) <= a.invi_length
end

function create_actor(a)
	a.anim_timestamp = time()

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

function log(m)
	log_count += 1
	add(logs, { m=m,c=log_count })
end

function draw_log()	
	r = get_room()
	o = {x=2,y=36}

	local j = 0
	local i = #logs
	while i > 0 and j < 10 do
		print(logs[i].c .. ": " .. logs[i].m, r.x + o.x, r.y + (j * 8) + o.y, c_white)
		i-=1
		j+=1
	end
end

function distance(o1, o2)
	return {
		x = o1.x - o2.x,
		y = o1.y - o2.y
	}
end

function get_room()
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
__gfx__
0000000000000000000000000000000000000000000000000007270000000000ffffffff11111111000000000000000000000000000000000000000000000000
0000000000111110001111100011111000000000000000000007270000727770ffffffff11111111000000000000000000000000000000000000000000000000
0070070001727770017277700172777000000000001111100007210000727170f444444211111111000000000000000000000000000000000000000000000000
0007700011727170117271701172717010111110011111100012770001277770f411141411111111000000000000000000000000000000000000000000088000
0007700000277770002777700027777011111110117277700111d10011777770f444444411111111000000000000000000000000000000000000000000088000
00700700000ddd00010ddd01010ddd0111277777007271700001d100001ddd10f411211411111111000000000000000000000000000000000000000000000000
00000000001ddd100001dd00000dd100072777170027777000010100000ddd00f224444411111111000000000000000000000000000000000000000000000000
0000000000010100000001000001000002777777001101100001010000010100ffff2fff11111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffffffff4ffffffccccccccccccccccf4ffffff00555500000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff4f4fffffcccccccccccccccc4f4fffff05555550000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffffffffff6666fccccccccccccccccffffffff01555510000880000000000000000000000000000000000000000000000000000000000000000000
00000000fffffffff666666dccccccccccccddccffffffff04111140008998000000000000000000000000000000000000000000000000000000000000000000
00000000fffffffff6666666cccccccccc7ddd7cfffff4ff01444410008998000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffdd666666ccccccccccc777ccffff4f4f04111140000880000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffdddd6666ccccccccccccccccffffffff01444410000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff44444444ccccccccccccccccffffffff00111100000000000000000000000000000000000000000000000000000000000000000000000000
444444442222222244444444ffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000
444444442222222244444444ffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000
44444444222222224444444477777777ccccccccccccccccffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000
4444444422222222444444447777777777777777ccccccccffffffffffffffff7777777700000000000000000000000000000000000000000000000000000000
444444442222222244444444cccccccc7777777777777777cccccccc777777777777777700000000000000000000000000000000000000000000000000000000
444444442222222244444444cccccccccccccccccccccccc77777777cccccccccccccccc00000000000000000000000000000000000000000000000000000000
444444442222222277777777cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
4444444422222222cccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
00101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07717700001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07181700077177000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000071817000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00818000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000008180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080800088888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080800800800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dd079000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007770000ddd17000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07dd1990000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88008800808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888800888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888800080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00909000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0900090000a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900000900a000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0900090000a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00909000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007777000700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007777000700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
28822882288228822882288228822882288228822882288222222222222222222222222222222222222222222222222222222222222222222222222222222222
28888881188888811888888118888881188888811888888112222222222222222222222222222222222222222222222222222222222222222222222222222222
28888881188888811888888118888881188888811888888112222222222222222222222222222222222222222222222222222222222222222222222222222222
21888811118888111188881111888811118888111188881112222222222222222222222222222222222222222222222222222222222222222222222222222222
21188111111881111118811111188111111881111118811112222222222222222222222222222222222222222222222222222222222222222222222222222222
21111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222f4fffffffffffffffffffffffffffffffffffffffffffffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
222222224f4fffffffffffffffffffffffffffffffffffffffffffff4f4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffffffffffffffffffffffffffffffffffffffffffffffffff6666fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffffffffffffffffffffffffffffffffffffffffffffffff666666dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffff4ffffffffffffffffffffffffffffffffffff1f1ffff6666666ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffff4f4ffffffffffffffffffffffffffffffffff77177ffdd666666ffffff11111fffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffffffffffffffffffffffffffffffffffffffff71817ffdddd6666fffff172777fffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffff888fff44444444ffff1172717fffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffffffffffffffff4ffffffffffffffffffffffff818fffffffffffffffff27777fffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffff4f4ffffffffffffffffffffff88888fffffffffffffffffdddffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffff8ff8ff8fffffffffffffff1ddd1fffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222fffffffffffffffffffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffff4f4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
22222222ff5555ffff5555fffffffffffffffffff4fffffffffffffffffffffff4ffffffffffffffffffffff2222222222222222222222222222222222222222
22222222f555555ff555555fffffffffffffffff4f4fffffffffffffffffffff4f4fffffffffffffffffffff2222222222222222222222222222222222222222
22222222f155551ff155551fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
22222222f411114ff411114fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
22222222f144441ff144441ffffffffffffffffffffff4fffffffffffffffffffffff4ffffffffffffffffff2222222222222222222222222222222222222222
22222222f411114ff411114fffffffffffffffffffff4f4fffffffffffffffffffff4f4fffffffffffffffff2222222222222222222222222222222222222222
22222222f144441ff144441fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
22222222ff1111ffff1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffff777777772222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc2222222222222222222222222222222222222222
222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc2222222222222222222222222222222222222222
222222224444444444444444f4ffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc4444444444444444444444442222222222222222
2222222244444444444444444f4fffffffffffffffffffffffffffffffffffffffffffffffffffffcccccccc4444444444444444444444442222222222222222
222222224444444444444444ffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4444444444444444444444442222222222222222
222222224444444444444444ffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4444444444444444444444442222222222222222
222222224444444444444444fffff4ffffffffffffffffff77777777777777777777777777777777cccccccc4444444444444444444444442222222222222222
222222224444444444444444ffff4f4fffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4444444444444444444444442222222222222222
222222224444444444444444ffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4444444444444444444444442222222222222222
222222224444444444444444ffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccc4444444444444444444444442222222222222222
22222222ff5555ffffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccfffffffffffffffff4ffffff2222222222222222
22222222f555555fffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffff4f4fffff2222222222222222
22222222f155551fffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccfffffffffffffffffff6666f2222222222222222
22222222f411114fffffffffffffffffffffffffffffffffccccccccccccccccccccddccccccccccccccccccfffffffffffffffff666666d2222222222222222
22222222f144441fffffffffffffffffffffffffffffffffcccccccccccccccccc7ddd7cccccccccccccccccfffffffffffffffff66666662222222222222222
22222222f411114fffffffffffffffffffffffffffffffffccccccccccccccccccc777ccccccccccccccccccffffffffffffffffdd6666662222222222222222
22222222f144441fffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffffdddd66662222222222222222
22222222ff1111ffffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffff444444442222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffffffffffff2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffccccccccccccccccccccccccccccccccccccccccffffffffffffffffffffffff2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccc7777777777777777777777772222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222ffffffffffffffffffffffffffffffffffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
222222227777777777777777777777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
22222222cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444ccccccccccccccccccccccccccccccccccccddcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444cccccccccccccccccccccccccccccccccc7ddd7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444ccccccccccccccccccccccccccccccccccc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
ffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
ffffffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
77777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222222222222222

__gff__
0000000000000000000000000000000000000000000000000000000000000000000002020200020100000000000000000202020000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3131313131313131313131313131313131313131313131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3130303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3121212121212121212121212121212121212140212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3125212121212122212121212121212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3121505021212121212121215021212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3121212121212121212121213131313131313121212121210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3126262121252121252121313131313131313121212221210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131312121212121212121313131313131313121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131312121212121212133313131313132323221212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3130302521213333333323303030313123232321212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3126212121212323242323502122313123232121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3150212121212323232323333333313123232121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3133333333332323232323232323313123232121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3023232323242323232323232323313123232321212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3323232323232323232323232323313123232321212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323313123232321212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323242323313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2324232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0114000019333000003c6153940330623000003c61500000183330c003183153940330623000033c6150000018333000003c6153940330623000003c6130000018333000003c31518053306230c0533c61530613
011400000c15000100101500c1000c1500010010150001000c15000100101500c1000c1500010010150001001315000100171500c100131500010017150001001315000100171500c10013150001001715000100
011400000010000100131500010000100001001315000100001000010013150001000010000100131500010000100001000e1500010000100001000e1500010000100001000e1500010000100001000e15000100
010300003062500600306550060000600006000060000600006000060000600006000060000600006000060000600000000060000600006000060000600006000060000600006000060000600006000060000600
001000001865000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000070200702247620070228762007022b76200702007020070200702007020070200702007020070200702007022676200702297620070226762007020070200702007020070200702007020070200702
0106000000330243302f0302e03000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000000000000000000000000000000000000000000
010800002407118071000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000000
010600000033018330230302203000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000052124521185510050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
010200001801300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01e100001862418625000001a6241a625000001c6241c6250000024624246250c6240c655000001c6241c625000001a6241a62500000196241962500000246242462500000286242862500000196241962500000
01190000300112b011000000000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 41424500
00 01024500
00 01020544
02 01020500
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 0b424344

