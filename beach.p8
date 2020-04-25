pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- beach
-- zachary gardner

-- lifecycle

actors = {}
actor_iteration = 0

camera_pos = { x = 0, y = 0, s = 0.025}

logs = {}
log_count = 0
d_draw = {x=0,y=0,frame=15}

p_prompt="🅾️"
s_prompt="❎"

f_en_atk=0
f_col=1
f_pl_atk=2
f_health=3
f_checkpoint=4
f_coin=5
f_something=6
f_boat=7

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
started_timestamp=nil
game_ended=false
game_ended_timestamp=nil

--init
function _init()
	start()
	camera_pos.s=0.25
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
		a:update()
	end
end

--draw
function _draw()
	-- clear screen
	cls(13)

	if (game_ended) then
		print("thanks for playing", camera_pos.x + 30, camera_pos.y + 50, c_white)
		print("coins: " .. pl.coins, camera_pos.x + 30, camera_pos.y + 58, c_white)
		print("time: " .. flr(game_ended_timestamp / 60) .. " m " .. ceil(game_ended_timestamp % 60) .. " s", camera_pos.x + 30, camera_pos.y + 66, c_white)
		return
	end
	
	-- draw map
	map()

	-- draw actors
	for i=0,2 do
		for a in all(actors) do
			if (a.z==i) a:draw()
		end
	end

	-- fps
	print("fps: " .. stat(7), camera_pos.x+1, camera_pos.y+120, c_white)

	night_mode()

	-- title
	print("beach", 0+52, 128+52, c_white)
	print("- press " .. p_prompt .. " -", 0-12+52, 128+8+52, c_white)

	-- debug
    draw_log()
	-- draw_actor(d_draw)
	-- d_draw = { x=-10,y=-10,frame=15 }
end

-->8
-- init

function start() 
	started=true
	started_timestamp=time()
	init_actors()
end

function init_actors()
	-- create player
	replace_with_actor(
		112,
		33,
		function(a)
			pl = a
		end,
		define_player
	)

	-- beached player, which creates player
	replace_with_actor(
		119,
		33,
		function(a)
			a.update=function(a)
				if (time() - started_timestamp > 2.5 and not a.go) then
					a.i=0
					a.go=true
				end

				if (not a.go) return
				a.i+=1

				if (a.i == 1) then 
					a.frame = 120
					sfx(13)
				end
				if (a.i == 15) then 
					a.x -= 0.1
					sfx(13)
				end
				if (a.i == 20) then 
					a.x += 0.2
					sfx(13)
				end
				if (a.i == 25) then 
					a.x -= 0.2
					sfx(13)
				end
				if (a.i == 30) then 
					a.x += 0.2
					sfx(13)
				end

				if (a.i == 45) then
					sfx(14)
					camera_pos.s=0.25

					pl = define_player()
					pl.x = a.x
					pl.y = a.y
					create_actor(pl)

					del(actors, a)
				end
			end
		end
	)

	-- boat
	replace_with_actor(41,33,function(a)
		a.w=1
		a.h=1
		a.s=2
	end)

	-- crab
	replace_with_actor(73,33,function(a)
		a.w=0.8
		a.h=0.8
		a.s=2
		a.max_health=12
		a.health=12
		a.anims={
			idle={s=73,e=73,l=true},
			walk={s=73,e=75,l=true}
		}
		a.update=update_follower
	end)

	-- checkpoint
	replace_with_actor(123,33,function(a) 
		a.z = 0
		a.update=function(a) 
			if (pl and pl.checkpoint and pl.checkpoint.id == a.id) then
				a.frame = 124
			else
				a.frame = 123
			end
		end
	end)

	-- coin
	replace_with_actor(107,33,function(a)
		a.z=0
	end)

	-- spike block
	replace_with_actor(61,33)

	-- heart
	replace_with_actor(77,33)
	
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

			if (pl and abs(pl.x - a.x) < 2.25 and abs(pl.y - a.y) < 2.25) then
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
	replace_with_actor(38,33,function(a) 
		a.w=0.5 
		a.h=0.5 
		a.update=function(a)
			local hit_atk = is_solid_area(a.x,a.y,a.w,a.h,f_pl_atk)
			if (hit_atk.hit) then
				sfx(3)
				create_dust_cloud(a)
				del(actors,a)
			end
		end
	end)

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
			a.max_v=0.06
			a.max_health=3
			a.health=3
		end
	)

	-- barnacle
	replace_with_actor(
		96,
		33,
		function(a) 
			a.w=0.5
			a.h=0.5
			a.max_v=100
			a.friction=0
			a.update=update_bouncer 
			a.anims={
				idle={s=96,e=99,l=true}
			}
			a.anim_duration=0.25
			a.max_health=2
			a.health=2
		end
	)
end

-->8
-- update

function update_player(a)
	update_actor(a)

	create_dust(a,114)
	execute_on_frame(a,114,"sfx_10",function() sfx(10) end)

	a.dir = {x=0,y=0}
	if (btn(0)) a.dir.x = -1
	if (btn(1)) a.dir.x = 1
	if (btn(2)) a.dir.y = -1
	if (btn(3)) a.dir.y = 1

	if (not (a.dir.x == 0 and a.dir.y == 0)) then
		a.last_dir=a.dir
	end
	
	if (a.current_anim != "attack") then
		a.vx += a.acc * a.dir.x
		a.vy += a.acc * a.dir.y

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
		circle.r=1.7
		circle.w=1.7
		circle.h=1.7
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

	-- bomb
	if (btn(5) and a.five_released) then
		a.five_released = false
	end

	if (not btn(5)) then
		a.five_released = true
	end

	-- health pickup
	local hit_health = is_solid_area(a.x, a.y, a.w, a.h, f_health)
	if (hit_health.hit) then
		a.health+=1
		if (a.health > a.max_health) a.health = a.max_health
		del(actors, hit_health.a)
		sfx(14)
	end

	-- enemy attack
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
		if (a.checkpoint) then
			a.x = a.checkpoint.x
			a.y = a.checkpoint.y
		else
			a.x = a.start_x
			a.y = a.start_y
		end
	end

	local hit_checkpoint = is_solid_area(a.x,a.y,a.w,a.h,f_checkpoint)

	if (hit_checkpoint.hit) then
		if (pl.checkpoint == nil or hit_checkpoint.a.id != pl.checkpoint.id) then
			a.checkpoint=hit_checkpoint.a
			sfx(4)
		end
	end

	local hit_coin = is_solid_area(a.x,a.y,a.w,a.h,f_coin)

	if (hit_coin.hit) then
		pl.coins+=1
		sfx(15)
		del(actors,hit_coin.a)
	end

	local hit_boat = is_solid_area(a.x,a.y,a.w,a.h,f_boat)

	if (hit_boat.hit and not game_ended) then
		game_ended=true
		game_ended_timestamp=time()
	end
end

function update_follower(a)
	if (not is_on_screen(a)) return

	update_actor(a)
	update_enemy_health(a)

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
end

function update_bouncer(a) 
	if (not is_on_screen(a)) return

	local s = 0.09

	if (not a.start) then
		a.vx = s
		a.vy = s
	end

	if (a.col.top) a.vy=s
	if (a.col.bottom) a.vy=-s
	if (a.col.left) a.vx=s
	if (a.col.right) a.vx=-s

	update_actor(a)
	update_enemy_health(a)

	a.start = true
end

function update_enemy_health(a) 
	local hit_atk = is_solid_area(a.x, a.y, a.w, a.h, f_pl_atk)

	if (hit_atk.hit and not actor_is_invincible(a)) then
		a.health -= 1
		a.invi_timestamp = time()

		if (a.health > 0) then
			sfx(8)
			create_hit_effect(a)
		end
	end

	if (a.health <= 0) then
		create_dust_cloud(a)
		create_coins(a)
		
		sfx(7)
		del(actors, a)	
	end
end

function update_actor(a) 
	-- animate actor
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
			a.frame += 1 * a.s
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

function create_coins(a)
	for i=0,0 do
		local a2 = define_actor()

		a2.x = a.x
		a2.y = a.y
		a2.vx = (rnd(2)-1)*0.75
		a2.vy = (rnd(2)-1)*0.75
		a2.frame=107

		create_actor(a2)
	end
end

function create_dust_cloud(a)
	for i=0,rnd(2)+3 do
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

function draw_player(a)
	draw_actor(a)

	spr(108,camera_pos.x+1, camera_pos.y+8)
	print(a.coins, camera_pos.x + 8, camera_pos.y+8, c_white)
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
		1+camera_pos.x,
		2+camera_pos.y,
		8*(pl.max_health)+camera_pos.x,
		6+camera_pos.y,
		c_dark_blue
	)

	for i=0,pl.max_health-1 do
		local color=c_red
		if (i>pl.health-1) color=c_white
		pal(c_red,color)
		spr(78,i*8+1+camera_pos.x,1+camera_pos.y)
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
		s = 1, -- sprite size

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
		invi_timestamp = nil,

		update=update_actor,
		draw=draw_actor,
		draw_health=draw_floating_health,

		anim_timestamp=0, -- timestamp since last frame change
		anim_duration=0.095, -- duration to show one frame in an animation
		anims=nil, -- define animations
		current_anim="idle", -- current animation

		col={}
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
	a.frame = 112

    a.w = 0.3
    a.h = 0.4

    a.vx = 0
    a.vy = 0
    a.max_v = 0.04125
    a.acc = 0.085
    a.friction = 0.185

	a.coins=0

	a.health = 4
	a.max_health = 4

	a.invi_length = 0.8

	a.update = update_player
	a.draw = draw_player
	a.draw_health = draw_fixed_health

	a.anims={
		idle={s=112,e=112,l=true},
		walk={s=113,e=114,l=true},
		attack={s=115,e=118,l=false},
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

-->8
-- other

function draw_text(m)
	local o = 4
	
	for i=0,14 do
		spr(9,camera_pos.x+(i*8)+o,camera_pos.y+o)	
	end
	
	print(
		m,
		camera_pos.x+1+o,
		camera_pos.y+1+o
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
	o = {x=2,y=36}

	local j = 0
	local i = #logs
	while i > 0 and j < 10 do
		print(logs[i].c .. ": " .. logs[i].m, camera_pos.x + o.x, camera_pos.y + (j * 8) + o.y, c_white)
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000fffffffff4ffffffccccccccccccccccf4ffffff00555500000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff4f4fffffcccccccccccccccc4f4fffff05555550000000000000000000000048000000000000000000000000000000000000000000000000
00000000fffffffffff6666fccccccccccccccccffffffff01555510044444400000000000000048000000000000000000000000000000000000000000000000
00000000fffffffff666666dccccccccccccddccffffffff04111140044444400000000000000448800000000000000000000000000000000000000000000000
00000000fffffffff6666666cccccccccc7ddd7cfffff4ff014444100aa99aa00000000000000488888000000000000000000000000000000000000000000000
00000000ffffffffdd666666ccccccccccc777ccffff4f4f04111140044994400000000000000488888000000000000000000000000000000000000000000000
00000000ffffffffdddd6666ccccccccccccccccffffffff01444410044444400000000000000400000000000000000000000000000000000000000000000000
00000000ffffffff44444444ccccccccccccccccffffffff00111100044444400000000000004444444440000000000000000000000000000000000000000000
444444442222222200000000ffffffffffffffffffffffffffffffffffffffffffffffff04444555555554400000000000000000000660000000000011111111
444444442222222200000000ffffffffffffffffffffffffffffffffffffffffffffffff94554555554455540000000000000000006666000000000011111111
44444444222222220000000077777777ccccccccccccccccffffffffffffffffffffffff0495555555445554000000000000000006dddd600444444211111111
4444444422222222000000007777777777777777ccccccccffffffffffffffff777777777449555555445594000000000000000066dddd660411141411111111
444444442222222200000000cccccccc7777777777777777cccccccc77777777777777770744999999999944000000000000000066dddd660444444411111111
444444442222222200000000cccccccccccccccccccccccc77777777cccccccccccccccc0074444444444477000000000000000006dddd600411211411111111
444444442222222200000000cccccccccccccccccccccccccccccccccccccccccccccccc00077444444447000000000000000000006666000224444411111111
444444442222222200000000cccccccccccccccccccccccccccccccccccccccccccccccc00000777777770000000000000000000000660000000200011111111
00101000000000000000000000000000000000000000000000000000997000009970000000000000000000000000000000000000000000008808800080800000
0771770000101000000000000000000000404000000000000000000099900000999000000000000000ee00000000000000000000000000008888800088800000
07181700077177000000000000000000009990000040400000000000999011109991110000000000077e00000000000000ee0000007070008888800008000000
0088800007181700000000000000000000949440009990000000000004017171041717100000000eeeeee00000000000077e0000078787000888000000000000
008180000088800000000000000000000099944400949440000000000400000104000010000007777eeee0000000000eeeeee000078887000080000000000000
00888000008180000000000000000000009994440099944400000000040111114011111088000eeeeeeee000000007777eeee000007870000000000000000000
0808080008888800000000000000000009999940009994440000000001011110101111100880ee888888ee0088000eeeeeeee000000700000000000000000000
0808080080080080000000000000000009000900999999900000000004011111400111110088e81888818e000880ee888888ee00000000000000000000000000
000000000000000000000000000000000000000000000000000ee000000000000000000000887771881777000088e81888818e00000000000000000000000000
00000000000000000000000000000000000ee0000000000000eeee00000000000000000000887178888717000088777188177700000000000000000000000000
0000000000000000000000000000000000eeee00000ee000007ee700000000000000000090987779889777000088717888871700000000000000000000000000
00000000000000900000000000000000007ee70000eeee0020eeee02000000000000000098881889889881089098777988977700000770000000000000000000
000000000dd07900000000000000000000eeee00007ee700202ee202000000000000000009990e888888e0809888188988988108000770000000700000000000
007770000ddd17000000000000000000002ee20000eeee00020000200000000000000000000008990099800809990e888888e080000000000000000000000000
07dd199000077000000000000000000002000020022ee22000000000000000000000000000008908008098000000889900998808000000000000000000000000
00090000000009000000000000000000220000222200002200000000000000000000000000008008008008000008000800800080000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000000000000000000000
0027720000222200002277000077220000000000000000000000000000000000000000000000000000000000000000009aa90000000000000000000000077000
0227722002221220022277200277277000000000000000000000000000000000000000000000000000000000000900009aa90000000000000007700000000000
0222222002221120022222200222277000000000000000000000000000000000000000000000000000000000009a90009aa90000000770000077770007000070
0772112007722220021127700211222000000000000000000000000000000000000000000000000000000000009a900009900000000770000077770007000070
07721220077277200221277002212220000000000000000000000000000000000000000000000000000000000009000000000000000000000007700000000000
00222200002277000022220000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007270000000000000000000000000000111110000000000000000000000000000000000000000000000000
00111110001111100011111000000000000000000007270000727770011111000000000001727770000000000000000000400000000900000000000000000000
0172777001727770017277700000000000111110000721000072717017277700011111001172717000000000004000000048800000909000000a000000000000
117271701172717011727170101111100111111000127700012777701277770001111110002777700000000000400000004888000900090000a0a00000000000
00277770002777700027777011111110117277700111d100117777701777770007777700001ddd10000000000040000000488000900000900a000a0000000000
000ddd00010ddd01010ddd0111277777007271700001d100001ddd10100ddd100777ddd0000ddd000000000000400000004000000900090000a0a00000000000
001ddd100001dd00000dd100072777170027777000010100000ddd00001ddd000001ddd00001010000000000004000000040000000909000000a000000000000
00010100000001000001000002777777001101100001010000010100000010100001101101111111000000000040000000400000000900000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000002020200020000808000000000000202000000000000008080000001000001010000000000000001000000080000000000000000000000000000000000000100000000000000000000202000000000000000000000000000001000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31313131303030303030303030303030303030303030303030303030303030303000000000000031313131313131000000000000000000000000000000003d3131000000000000000000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131303021212121212121212121212621212121212121212121212121212121210000000000000000313131313d00000000007b003100000000000000003d3131000000400000000000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31312121212121222121212121212126252121212150212121212540212121212100000000004000003d31313100000000000000003100000000000000003d3131000000000000000000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3130505021212121212121215021212621212121212121212121212121212221210000000000000000003131310000000000313131313d3d3d3d3d0000003d3131000000000000000000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31222121212121215021212131313131313131212121212121212121212121212100005000000000000031313100000000003100003100000000000060003d3131000000003131313131000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31262621212521212521213131313131313131212121212121213131313131312100000000000000000000313100000000003100000000000000000000003d3131000000003131313131000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31313121212121212121213131313131303030212121212121313131313131313131000000000000000000000000003131313100003100000000000000003d3131000000003131313131000000006031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131312121212121212133313131313133333325212121213131313131313131313131310000000000000000000000313131310031313131313131313131313131000000003131313131000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3130302521213333333323303030313123242326502125213131313131313131313131310000000000000000000000313131310000000031313131313131313131000000003131313131000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3126212121212323242323502122313123232333333333333131313131313131313131310000000000004000000000313131000000000000000000003131313131000000003131313131000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31502121702123232323233333333131232323232323233131313131313131313131313100000000000000000000003131000000000000000000000050000000000000000000003d0000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3133333333332323232323232323313123232323232323313131313131313131313131313d000000000000000000313131000000000000000060000031313131310000000040003d0000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30232323232423232323232323313131232323232331313131313131313131313131313131310000000000000000313131000000000000000000000031313131310000000000003d0000000000000031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
332323232323232323232323233331312323233131313131313131313131313131313131313131313131313131313131313d3d3d3d3d3d3d3131313131313131310000000000003d0000003126310031310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323313123232331313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131310000003131310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323242323313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000313131313131313131310000003131310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000232923232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2324232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232331313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
__sfx__
0114000019333000003c6153940330623000003c61500000183330c003183153940330623000033c6150000018333000003c6153940330623000003c6130000018333000003c31518053306230c0533c61530613
011400000c15000100101500c1000c1500010010150001000c15000100101500c1000c1500010010150001001315000100171500c100131500010017150001001315000100171500c10013150001001715000100
011400000010000100131500010000100001001315000100001000010013150001000010000100131500010000100001000e1500010000100001000e1500010000100001000e1500010000100001000e15000100
010500001833300000186200c620186200c6200060518613006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605000000000000000
010600001805018055000000000018050180551c0501c0501c0501c05500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000070200702247620070228762007022b76200702007020070200702007020070200702007020070200702007022676200702297620070226762007020070200702007020070200702007020070200702
0106000000330243302f0302e03000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000000000000000000000000000000000000000000
010800002407118071000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000000
01060000003300c130170301603000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000052124521185510050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
010400001801300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01e100001862418625000001a6241a625000001c6241c6250000024624246250c6240c655000001c6241c625000001a6241a62500000196241962500000246242462500000286242862500000196241962500000
01190000300112b011000000000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000000
010700001813300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
010500000c13013131001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010600002405030050300550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

