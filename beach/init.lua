-->8
-- init

function start() 
	started=true
	started_timestamp=time()
	-- init_actors()
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
				if (started and time() - started_timestamp > 2.5 and not a.go) then
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

	-- trap tile
	replace_with_actor(19,19,function(a) 
		a.w = 0.1
		a.h = 0.1
		a.z = 0
		a.update=function(a) 
			local hit_pl = is_solid_area(a.x,a.y,a.w,a.h,nil,function(c) return pl and c.id == pl.id end)

			if (hit_pl.hit and not a.triggered) then
				for i=0,256 do
					if(mget(a.x,i) == 6) then
						mset(a.x,a.y,1)
						local p = define_projectile(a.x,i,4)
						p.vx=0
						a.frame=1
						a.triggered=true
						sfx(18)
						create_actor(p)
					end
				end	
			end
		end		
	end)

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

	-- heart drop
	replace_with_actor(77,33)

	-- bomb drop
	replace_with_actor(105,33)
	
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
				create_random_drop(a)
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

	-- slug
	replace_with_actor(
		71,
		33,
		function(a) 
			a.update=update_shooter 
			a.anims={
				idle={s=71,e=71,l=true},
				walk={s=71,e=72,l=true}
			}
			a.anim_duration=0.25
			a.max_v=0.002
			a.max_health=1
			a.health=1
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