pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-->8
-- update

function update_player(a)
	if (a.is_dead) then 
		a.i+=1

		if (a.i < 10) a.frame=120
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
		if (a.i == 40) then 
			a.x += 0.2
			a.frame=119
			sfx(24)
		end

		if (a.i == 60) then
			a.is_dead = false
			a.health = a.max_health

			local x = 0
			local y = 0

			if (a.checkpoint) then
				x = a.checkpoint.x
				y = a.checkpoint.y
			else
				x = a.start_x
				y = a.start_y
			end

			transition = { 
				x = x, 
				y = y, 
				start_timestamp = time(), 
				length = 1.5, 
				camera_pos_s=camera_pos.s,
				progress=0,
				opaque_callback=function() 
					for ac in all(actors) do
					if (ac.id != pl.id) del(actors, ac)
					end
					for dac in all(disabled_actors) do
						if (dac.id != pl.id) del(disabled_actors, dac)
					end
					visited_rooms={}
					current_room=nil
				end
			}
		end

		return
	end

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
		circle.x=pl.x
		circle.y=pl.y
		circle.z=0
		circle.r=1.7
		circle.w=1.7
		circle.h=1.7
		circle.flags[f_pl_atk]=true
		circle.color=c_red
		circle.damage=1

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
	if (btn(5) and a.five_released and a.bombs > 0) then
		a.bombs -= 1

		local bomb = define_actor()

		bomb.z=0
		bomb.x=a.x
		bomb.y=a.y
		bomb.frame=101
		bomb.w=0.25
		bomb.h=0.25
		bomb.color=c_red
		bomb.i=0

		bomb.draw=function(ba) 
			if (ceil(bomb.i) % 2 == 0 and time() - bomb.birth_timestamp > 0.5) then
				pal_all(c_red)
			else
				pal()
			end

			draw_actor(ba)
		end

		bomb.update=function(ba)
			bomb.i+=0.5

			if (time() - ba.birth_timestamp > 1) then
				local circle = define_circle()

				circle.x = ba.x
				circle.y = ba.y
				circle.z=0
				circle.r=1.7
				circle.w=1.7
				circle.h=1.7
				circle.flags[f_pl_atk]=true
				circle.color=c_red
				circle.max_lifetime = 0.1
				circle.damage=2

				ba.atk_instance = create_actor(circle)
				sfx(17)
				del(actors, ba)
			else
				sfx(16)
			end
		end

		create_actor(bomb)

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

	-- bomb pickup
	local hit_bomb_drop = is_solid_area(a.x, a.y, a.w, a.h, f_bomb_drop)
	if (hit_bomb_drop.hit) then
		a.bombs+=1
		if (a.bombs > a.max_bombs) a.bombs = a.max_bombs
		del(actors, hit_bomb_drop.a)
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
					a.vx = hit_atk.a.vx * 2
					a.vy = hit_atk.a.vy * 2
				end
			end
		end

		if (continue) then
			sfx(6)
			a.health -= hit_atk.a.damage
			a.invi_timestamp = time()

			del(actors, a.atk_instance)
			a.atk_instance = nil
			a.current_anim="idle"
		end
	end

	if (a.health <= 0) then
		sfx(7)
		a.is_dead=true
		a.i=0
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
		pl.draw=function(a) end
		pl.update=function(a) end

		hit_boat.a.i=0

		hit_boat.a.frame=43
		sfx(13)
		hit_boat.a.vx=-0.03
		hit_boat.a.friction=-0.025
		hit_boat.a.max_v=100
		hit_boat.a.collidible=false
		hit_boat.a.update=function(a) 
			hit_boat.a.i+=1
			update_actor(a)

			if (hit_boat.a.i % 4 == 0) then
				local p = define_particle(93,94)
				p.x=hit_boat.a.x+a.w+0.35
				p.y=hit_boat.a.y+a.h+0.35
				p.lifetime=0.25
				create_actor(p)
			end

			if (time() - game_ended_timestamp > 3) then
				del(actors, hit_boat.a)
			end
		end

		game_ended_timestamp=time()
		game_ended=true
	end

	local hit_trap = is_solid_area(a.x,a.y,a.w,a.h,nil,function(c) return c.tag=="trap" end)

	if (hit_trap.hit) then
		hit_trap.a.activated=true
	end

	local hit_door = is_solid_area(a.x,a.y,a.w,a.h,nil,function(c) return c.tag=="door" end)

	if (hit_door.hit) then
		local r = get_room()

		local doors={
			{enter={x=128,y=128},exit={x=121,y=5}}, 
			{enter={x=896,y=0},exit={x=29,y=28}}, 
			{enter={x=768,y=128},exit={x=119,y=19}}
		}

		local target = nil
		for door in all(doors) do
			if (door.enter.x == r.x and door.enter.y == r.y) then 
				target = door 
				break 
			end
		end

		if (target) then
			transition = { 
				x = target.exit.x, 
				y = target.exit.y, 
				start_timestamp = time(), 
				length = 1.5, 
				camera_pos_s=camera_pos.s,
				progress=0
			}
		end
	end
end

function transition_screen()
	if not transition.started then
		camera_pos.s = 1
		sfx(19)
		transition.started = true
	end


	local diff = time() - transition.start_timestamp

	if (time() - transition.start_timestamp > transition.length) then 
		camera_pos.s = transition.camera_pos_s
		transition = nil
		return
	end

	if (diff > transition.length / 2) then
		transition.progress -= 1

		pl.x = transition.x
		pl.y = transition.y
		pl.vx = 0
		pl.vy = 0.2

		if (transition.opaque_callback and not transition.executed_opaque_callback) then
			transition.opaque_callback()
			transition.executed_opaque_callback=true
		end

		if not transition.descended and transition.progress < 8 then
			sfx(20)
			transition.descended = true
		end
	else
		transition.progress += 1
	end

	for y=0,16 do for x=0,16 do
		rectfill(
			camera_pos.x+(x*8),
			camera_pos.y+(y*8),
			camera_pos.x+(x*8)+transition.progress,
			camera_pos.y+(y*8)+transition.progress,
			c_dark_purple
		)
	end end
end

function update_shooter(a)
	update_actor(a)
	update_enemy_health(a)

	create_dust(a,71)
	execute_on_frame(a,71,"sfx_10",function() sfx(10) end)

	if (a.shoot_timestamp == nil or time() - a.shoot_timestamp > 1.75) then
		a.shoot_timestamp = time()
		
		local c = define_projectile(a.x,a.y,8)

		c.max_lifetime=3

		sfx(18)

		create_actor(c)
	end
	
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

function update_follower(a)
	update_actor(a)
	update_enemy_health(a)

	create_dust(a,65)
	execute_on_frame(a,65,"sfx_10",function() sfx(10) end)
	
	if (not a.invi_timestamp or time() - a.invi_timestamp > 0.1) then
		a.current_anim="walk"
		
		if (pl.x < a.x) a.vx -= a.acc
		if (pl.x > a.x) a.vx += a.acc
		if (pl.y < a.y) a.vy -= a.acc
		if (pl.y > a.y) a.vy += a.acc
	else
		a.current_anim="idle"
	end
end

function update_crab(a) 
	local d = distance(a,pl)
	if (abs(d.y) < 3 and abs(d.x) < 4 and not a.triggered) then 
		a.triggered = true
		a.i=0
	end

	if (not a.triggered) return

	if (not a.normal) then
		a.i += 1

		if (a.i < 30) then
			if (a.i % 4 == 0) then
				sfx(3)
				create_dust_cloud({x=a.x,y=a.y})
				create_dust_cloud({x=a.x+1,y=a.y+1})
			end
		end

		if (a.i == 30) then
			a.is_active=true
			sfx(21)
		end

		if (a.i > 45) then
			if (a.i % 2 == 0) then
				a.frame=73
			else
				a.frame=75
			end
		end

		if (a.i == 60) then
			sfx(3)
			a.spawn_timestamp = time()
			a.bubble_timestamp = time()
			a.charge_timestamp = time()
			a.normal=true
		end
	end

	if (not a.is_active) return

	if (not a.normal) return

	-- spawn babies
	if (not a.spawn_timestamp or time() - a.spawn_timestamp > a.spawn_wait) then
		local bca = define_actor()

		bca.frame=87
		bca.x=132
		bca.y=flr(rnd(7))+19

		bca.vx=-0.1
		bca.friction=0
		bca.max_v=100
		bca.anims={
			idle={s=87,e=88,l=true},
			water={s=85,e=86,l=true}
		}
		bca.collidible=false
		bca.tag="baby_crab"

		bca.update=function(bca) 
			if (is_on_screen(bca)) bca.destroy_offscreen=true

			local hit_water = is_solid(bca.x,bca.y,f_col)
			if (hit_water.hit) then
				bca.current_anim="water"
			else
				bca.current_anim="idle"
			end

			update_actor(bca)
			update_enemy_health(bca)

			create_dust(bca,88)
			execute_on_frame(bca,88,"sfx_10",function() sfx(10) end)
		end

		create_actor(bca)

		a.spawn_timestamp=time()
		a.spawn_wait=flr(rnd(4))+1
	end

	-- charge
	if (not a.bubbling) then
		if (a.charge_timestamp == nil or time() - a.charge_timestamp > a.charge_wait) then
			a.charging=true

			a.current_anim = "walk"

			if (a.ci == 30) then
				a.friction=0
				local d = direction(pl,{x=a.x+0.5,y=a.y+0.5})
				a.vx= d.x / 3.75
				a.vy= d.y / 3.75
				a.max_v=100
				a.charging_timestamp=time()
				sfx(17)
			else 
				if (a.ci < 30) then
					a.current_anim = "bide"
					a.friction=1
				end
			end

			a.ci+=1
		else
			a.target = {x=pl.x,y=pl.y}
		end

		if (a.charging) then
			if (a.col.top or a.col.bottom) then 
				sfx(18)
				a.vy *= -1 
			end
			if (a.col.left or a.col.right) then 
				sfx(18)
				a.vx *= -1 
			end

			if (a.charging_timestamp and time() - a.charging_timestamp > 1) then
				a.charge_timestamp = time()
				a.charging_timestamp = nil
				a.charge_wait=flr(rnd(7))+1
				a.ci = 0
				a.charging = false

				a.bubble_wait += 2
				a.friction=a.o_friction
			end
		end
	end

	-- blow bubbles
	if (not a.charging) then
		if (a.bubble_timestamp == nil or time() - a.bubble_timestamp > a.bubble_wait) then
			a.bubbling=true

			a.bi += 1

			if (a.bi > 25) then
				a.current_anim="idle"
			else
				a.current_anim="bide"
			end

			if (a.bi > 25 and a.bi % 3 == 0) then
				sfx(25)

				local b = define_actor()
				b.frame=107
				b.anims={idle={s=107,e=108,l=true}}
				b.anim_duration=0.25
				b.collidible=false
				b.x=a.x+0.5
				b.y=a.y+0.5
				local d = direction(pl,{x=a.x+0.5,y=a.y+0.5})
				b.max_v=100
				b.vx = (d.x / 9.25) + ((rnd(3)-1) / 25)
				b.vy = (d.y / 9.25) + ((rnd(3)-1) / 25)
				b.friction=0
				b.max_lifetime=1.2
				create_actor(b)
			end

			if (a.bi > 45) then
				a.bubble_timestamp=time()
				a.bubble_wait=flr(rnd(7))+1
				a.charge_wait += 2
				a.bubbling=false
				a.bi=0
				a.friction=a.o_friction
				return
			end
			
			a.vx=0
			a.vy=0
			a.friction=1
		end
	end
	
	update_actor(a)
	update_enemy_health(a)

	create_dust(a,73)
	execute_on_frame(a,73,"sfx_10",function() sfx(10) end)
	
	if (not a.bubbling and not a.charging) then
		if (not a.invi_timestamp or time() - a.invi_timestamp > 0.1) then
			a.current_anim="walk"
			
			if (pl.x < a.x + 0.5) a.vx -= a.acc
			if (pl.x > a.x + 0.5) a.vx += a.acc
			if (pl.y < a.y + 0.5) a.vy -= a.acc
			if (pl.y > a.y + 0.5) a.vy += a.acc
		else
			a.current_anim="idle"
		end
	end
end

function update_bouncer(a) 
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
	local o = (0.5 * (-1 + a.s))
	local hit_atk = is_solid_area(a.x + o, a.y + o, a.w, a.h, f_pl_atk)

	if (hit_atk.hit and not actor_is_invincible(a)) then
		a.health -= hit_atk.a.damage
		a.invi_timestamp = time()

		if (a.health > 0) then
			sfx(8)
			create_hit_effect(a)
		end
	end

	if (a.health <= 0) then
		create_dust_cloud(a)
		create_random_drop(a)

		if (a.before_destroy != nil) then
			a.before_destroy(a)
		end
		
		sfx(7)
		del(actors, a)	
	end
end

function update_actor(a) 
	-- check lifetime
	if (a.max_lifetime != nil and time() - a.birth_timestamp > a.max_lifetime) then
		del(actors,a)
		return;
	end

	if (a.destroy_offscreen and not is_on_screen(a)) then
		del(actors,a)
		return;
	end

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