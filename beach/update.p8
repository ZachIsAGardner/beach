pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
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
		bomb.frame=106
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