pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
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

		max_lifetime=nil,

		update=update_actor,
		draw=draw_actor,
		draw_health=draw_floating_health,

		anim_timestamp=0, -- timestamp since last frame change
		anim_duration=0.095, -- duration to show one frame in an animation
		anims=nil, -- define animations
		current_anim="idle", -- current animation

		col={},
		damage=1,

		is_active=true,

		destroy_offscreen=false -- destroy if leaves screen
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
    a.h = 0.3

    a.vx = 0
    a.vy = 0
    a.max_v = 0.04125
    a.acc = 0.085
    a.friction = 0.185

	a.coins = 0
	a.bombs = 1
	a.max_bombs = 3

	a.health = 4
	a.max_health = 6

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

function define_projectile(x,y,damp)
	local c = define_circle()

	local d = distance(pl,{x=x,y=y})
	local l = length(d.x,d.y)
	c.vx = d.x / l / damp
	c.vy = d.y / l / damp
	c.max_v = 100
	c.collidible=false
	c.friction=0
	c.flags[f_en_atk]=true
	c.x = x
	c.y = y
	c.r = 0.3
	c.w = 0.3
	c.h = 0.3
	c.color = c_red
	c.max_lifetime=2
	c.destroy_offscreen=true

	return c
end

function define_particle(s,e)
	local a = define_actor()

	a.frame = s
	a.anims={idle={s=s,e=e,l=false,d=true}}
	a.anim_duration=0.15
	a.destroy_offscreen=true

	return a
end