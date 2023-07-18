pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--[[

 todo:
	 - nicer screens
  - separate enemies and
    waves methods into new tab
    
  - wave logic
  - music
  - multiple enemies
  - big enemies
  - enemy bullets

--]]

function _init()
 cls(0)
 
 -- globals
 g_speed = 2
 g_max_lives = 3
 g_max_bombs = 3
 g_num_stars = 100
 g_wave_duration = 80
 
 -- generate stars db
 stars = {}
 for i=1,g_num_stars do
  add(stars,create_random_star())
 end
 
 mode='start'
 blink_time=1
 t=0
end

function _update()
 t+=1
 blink_time+=1

 if mode=='start' then
  update_start()
 elseif mode=='wave_text' then
  update_wave_text()
 elseif mode =='game' then
  update_game()
 elseif mode=='over' then
  update_over()
 elseif mode=='win' then
  update_win()
 end
end

function _draw()
 if mode=='start' then
  draw_start()
 elseif mode=='wave_text' then
  draw_wave_text()
 elseif mode=='game' then
  draw_game()
 elseif mode=='over' then
  draw_over()
 elseif mode=='win' then
  draw_win()
 end
end

function start_game()
 mode='wave_text'
 t=0
 wave=0
 
 -- sprites
 ship_spr = 3
 thrust_spr = 6 
 bullet_spr = 17
 
 -- ship
 ship = {
  x = 64,
  y = 64,
  x_speed = 0,
  y_speed = 0,
  spr_id = ship_spr,
  move_left_dur = 0,
  move_right_dur = 0,
 }
 bullets = {}
 muzzle = 0
 invul=0
 bullet_t=0
 
 enemies =    {}
 explosions = {}
 particles =  {}
 shockwaves = {}
 
 -- counters
 score = 0
 lives = 3
 
 -- 
 -- start
 --
 next_wave()
end

-->8
--update funcs

function update_game()
 ship.x_speed = 0
 ship.y_speed = 0
 ship.spr_id = ship_spr
 
 listen_to_ship_controls()
 animate_starfield()
 
 -- animate thrust
 thrust_spr += 1
 if thrust_spr > 10 then
  thrust_spr = 6
 end
 
 -- animate muzzle flash
 if muzzle > 0 then
  muzzle -= 1
 end 
 
 -- move the bullets
 for bullet in all(bullets) do
  bullet.y -= 4
  bullet.spr_id+=1
 end
 
 -- move the enemies
 for en in all(enemies) do
  en.y+=1
  en.spr_id+=0.4
  
  if en.spr_id>37 then
   en.spr_id=33
  end
  
  if en.y>128 then
   del(enemies,en)
   spawn_enemy()
  end
 end
 
 -- collision bullets x enemies
 for bul in all(bullets) do
		for en in all(enemies) do
		 if collide(bul,en) then
		  -- hit
		  sfx(3)
		  small_shockwave(bul.x+4,bul.y+4)
		  small_spark(bul.x+4,bul.y+4)
		  del(bullets,bul)
		  en.hp-=1
		  en.flash=3
		  
		  -- dies
		  if en.hp<=0 then
			  sfx(2)
			  explode(en.x,en.y)
			  score+=10
		  	del(enemies,en)
		  	
		  	-- if no more enemies
		  	if #enemies==0 then
		  	 next_wave()
		  	end
		  end
		 end
		end
 end
 
  -- update particles
 for p in all(particles) do
  p.x+=p.speed_x
  p.y+=p.speed_y
  
  -- friction
  p.speed_x=p.speed_x*0.85
  p.speed_y=p.speed_y*0.85
  
  p.age+=1
  
  if p.age>p.max_age then
   p.size-=0.5
   if p.size<0 then
    del(particles,p)
   end
  end
 end
 
 -- update shockwaves
 for sw in all(shockwaves) do
  sw.r+=sw.speed
  if sw.r>sw.max_r then
   del(shockwaves,sw)
  end
 end
 
 -- collision ship x enemies
 if invul==0 then
	 for en in all(enemies) do
	  if collide(ship,en) then
			 explode(ship.x,ship.y,'green')
	   lives-=1
	   sfx(1)
	   invul=60
	  end
	 end
 else
  invul-=1
 end
 
 -- monitor lives
 if lives<=0 then
  mode='over'
  return
 end
end



function update_start()
 animate_starfield()
 
 if btnp(4) or btnp(5) then
  start_game()
 end
end


function update_wave_text()
 update_game()
 wave_text_time-=1
 
 if wave_text_time<=0 then
  mode='game'
  spawn_wave()
 end
end


function update_over()
 animate_starfield()
 
 if btn(4)==false and btn(5)==false then
  button_released=true
 end
 
 if (button_released) then
  if btnp(4) or btnp(5) then
	  mode='start'
	  button_released=false
	 end
 end
end


function update_win()
 animate_starfield()
 
 if btn(4)==false and btn(5)==false then
  button_released=true
 end
 
 if (button_released) then
  if btnp(4) or btnp(5) then
	  mode='start'
	  button_released=false
	 end
 end
end
-->8
-- draw funcs

function draw_game()
 cls(0)
 render_starfield()
 
 -- render ship
	if invul<=0 then
	 draw_sprite(ship)
	 spr(thrust_spr,ship.x,ship.y+8)
 else
  -- invulnerable
	 if sin(t/5)<0.1 then
	  draw_sprite(ship)
	  spr(thrust_spr,ship.x,ship.y+8)
	 end
 end
 
 -- render bullets
 for bullet in all(bullets) do
  if (bullet.y < -10) then
   del(bullets, bullet)
  else
   if bullet.spr_id>19 then
    bullet.spr_id=bullet_spr
   end
   draw_sprite(bullet)
  end
 end
 
 -- render muzzle
 if muzzle > 0 then
  circfill(ship.x+2,ship.y-2,muzzle,7)
  circfill(ship.x+5,ship.y-2,muzzle,7)
 end
 
 -- render shock waves
 for sw in all(shockwaves) do
  circ(sw.x,sw.y,sw.r,sw.clr)
 end
 
 -- render particles
 for p in all(particles) do
  local p_color=7
  
  if p.color_mode=='green' then
   p_color=get_green_p_color(p)
  else
   p_color=get_red_p_color(p)
  end
  
  if p.is_spark then
   pset(p.x,p.y,7)
  else
   circfill(p.x,p.y,p.size,p_color)
  end
 end
 
 -- render enemies
 for en in all(enemies) do
  if en.flash>0 then
   en.flash-=1
   for i=1,15 do
    pal(i,7)
   end
  end
  
  draw_sprite(en)
  pal()
 end
 
 -- ui
 -- render score
 print('score: '..score,40,1,12)
 
 -- lives
 for i = 1,g_max_lives do
 	if lives >= i then
   spr(11,(i * 9)-9)
 	else
   spr(12,(i * 9)-9)
 	end
 end
end




function draw_start()
 cls(1)
 
 render_starfield()
 print('most amazing shmup',27,40,12)
 print('press any key to start',20,80,blink())
end



function draw_wave_text()
 draw_game()
 print('wave '..wave,56,40,blink())
end



function draw_over()
 cls(8)
 
 render_starfield()
 print('game over',44,40,2)
 print('press any key to continue',15,80,blink())
end



function draw_win()
 cls(11)
 
 render_starfield()
 print('congrats!',40,40,2)
end
-->8
-- private methods

function listen_to_ship_controls()
  -- move left
  if btn(0) then
    ship.x_speed = -g_speed
    ship.spr_id = ship_spr-1

    if ship.move_left_dur < 10 then
      ship.move_left_dur += 1
    end
  else
    if ship.move_left_dur > 0 then
      ship.move_left_dur-=1
    end
  end
   
  --move right
  if btn(1) then
    ship.x_speed = g_speed
    ship.spr_id = ship_spr+1

    if ship.move_right_dur < 10 then
      ship.move_right_dur += 1
    end
  else
    if ship.move_right_dur > 0 then
      ship.move_right_dur-=1
    end
  end
  
  -- move up
  if btn(2) then
    ship.y_speed = -g_speed
    if ship.move_left_dur > 0 then
      ship.move_left_dur-=1
    end
    if ship.move_right_dur > 0 then
      ship.move_right_dur-=1
    end
  end
  
  --move down
  if btn(3) then
    ship.y_speed = g_speed
    if ship.move_left_dur > 0 then
      ship.move_left_dur-=1
    end
    if ship.move_right_dur > 0 then
      ship.move_right_dur-=1
    end
  end

  -- adapt ship sprite to movement
  if ship.move_left_dur >= 5 then
    ship.spr_id-=1
  end
  if ship.move_right_dur >= 5 then
    ship.spr_id+=1
  end
 
 -- shoot bullet
 if btn(5) then
	 if bullet_t<=0 then
	  local new_bullet = {
	   x = ship.x,
	   y = ship.y,
	   spr_id = bullet_spr,
	  }
	  add(bullets,new_bullet)
	  sfx(0)
	  muzzle = 5
	  bullet_t = 4
  end
 end
 bullet_t-=1
 
 ship.x += ship.x_speed
 ship.y += ship.y_speed
 
 -- check if we hit the edge
 if ship.x > 119 then
  ship.x = 119
 end
 
 if ship.x < 0 then
  ship.x = 0
 end
 
 if ship.y > 119 then
  ship.y = 119
 end
 
 if ship.y < 0 then
  ship.y = 0
 end
end

function render_starfield()
 for star in all(stars) do
  if (star.clr==6) then
   line(star.x,star.y,star.x,star.y+1,6)
  else
   pset(star.x,star.y,star.clr)
  end
 end
end

function animate_starfield()
 for i=1,#stars do
  local star = stars[i]
  if star.y > 128 then
   del(stars, star)
   add(stars,create_random_star(true))
  end
  star.y += star.speed
 end
end

function create_random_star(at_top)
 at_top = at_top or false
 
 local x = flr(rnd(128))
 local y = 0
 local spd = rnd(1.5) + 0.5
 local clr = 6
 
 if (not at_top) then
  y = flr(rnd(128))
 end
 
 if spd < 1 then
  clr=1
 elseif spd < 1.5 then
  clr=13
 end
 
 return {
  x=x,
  y=y,
  speed=spd,
  clr=clr,
 }
end

function blink()
 local blink_anim={
  5,5,5,5,5,5,6,6,7,7,6,6
 }
 
 if blink_time>count(blink_anim) then
  blink_time=1 
 end
 
 return blink_anim[blink_time]
end

function draw_sprite(sp)
 spr(sp.spr_id,sp.x,sp.y)
end

function collide(a,b)
 -- math
 local a_left=a.x
 local a_top=a.y
 local a_right=a.x+7
 local a_bottom=a.y+7
 
 local b_left=b.x
 local b_top=b.y
 local b_right=b.x+7
 local b_bottom=b.y+7
 
 
 if a_top>b_bottom then return false end
 if b_top>a_bottom then return false end
 if a_left>b_right then return false end
 if b_left>a_right then return false end
 
 return true
end

function spawn_enemy()
 add(enemies,{
  x=rnd(120),
  y=-8,
  spr_id=33,
  hp=5,
  flash=0,
 })
end

function explode(x,y,color_mode)
 color_mode=color_mode or 'red'
 
 add(particles,{
  x=x+4,
  y=y+4,
  speed_x=0,
  speed_y=0,
  max_age=0,
  age=0,
  size=10,
 })
 
 -- particles
 for i=1,30 do
	 add(particles,{
	  x=x+4,
	  y=y+4,
	  color_mode=color_mode,
	  speed_x=(rnd()-0.5)*7,
	  speed_y=(rnd()-0.5)*7,
	  max_age=10+rnd(10),
	  age=rnd(2),
	  size=rnd(4)+1,
	 })
 end
 
 -- sparks
 for i=1,20 do
	 add(particles,{
	  x=x+4,
	  y=y+4,
	  color_mode=color_mode,
	  speed_x=(rnd()-0.5)*12,
	  speed_y=(rnd()-0.5)*12,
	  max_age=10+rnd(10),
	  age=rnd(2),
	  size=rnd(4)+1,
	  is_spark=true,
	 })
 end
 
 big_shockwave(x,y)
end

function get_red_p_color(particle)
	local p_color=7
	
	if particle.age>5 then
	 p_color=10
	end
	if particle.age>7 then
	 p_color=9
	end
	if particle.age>10 then
	 p_color=8
	end
	if particle.age>12 then
	 p_color=2
	end
	if particle.age>15 then
	 p_color=5
	end
	
	return p_color
end

function get_green_p_color(particle)
	local p_color=7
	
	if particle.age>5 then
	 p_color=6
	end
	if particle.age>7 then
	 p_color=11
	end
	if particle.age>10 then
	 p_color=11
	end
	if particle.age>12 then
	 p_color=3
	end
	if particle.age>15 then
	 p_color=3
	end
	
	return p_color
end

function small_shockwave(x,y,clr)
 clr=clr or 12
 
 add(shockwaves,{
  x=x,
  y=y,
  r=3, -- radius
  max_r=6,
  clr=clr,
  speed=1,
 })
end

function big_shockwave(x,y,clr)
 clr=clr or 7
 
 add(shockwaves,{
  x=x,
  y=y,
  r=3, -- radius
  max_r=25,
  clr=clr,
  speed=3.5,
 })
end

function small_spark(x,y)
 add(particles,{
  x=x+4,
  y=y+4,
  color_mode=color_mode,
  speed_x=(rnd()-0.5)*8,
  speed_y=(rnd()-1)*3,
  max_age=10+rnd(10),
  age=rnd(2),
  size=rnd(2)+1,
  is_spark=true,
 })
end
-->8
-- waves and enemies

function spawn_wave()
 spawn_enemy()
end

function next_wave()
 wave+=1

 
 if wave==4 then
  mode='win'
 else
  mode='wave_text'
  wave_text_time=g_wave_duration
 end
end
__gfx__
00000000000030000003300000033000000330000003000000000000000000000000000000000000000000000880088008800880000000000000000000000000
000000000003b300003bb300003bb300003bb300003b300000077000008778000007700000877800000770008778888280088002000000000000000000000000
000000000003bb30003bb300003bb300003bb30003bb3000008aa8000887788000877800088aa880008aa8008788888280000002000000000000000000000000
00000000003bbb3003b33b3003b33b3003b33b3003bbb30000088000008aa800008aa800008aa800800880008888888280000002000000000000000000000000
0000000000b7bbb00b7c3bb03b37c3b30bb37cb00bbb7b0000000000008aa8000008800000088000000880000888882008000020000000000000000000000000
0000000000bcbbb00b113bb03b3113b30bb311b00bbbcb0000000000000880008008800000088000000009000088820000800200000000000000000000000000
000000000005b3300355bb3003b55b3003bb5530033b500000000000000880000800008000000000000000000008200000082000000000000000000000000000
00000000000990000099300000b99b0000399b000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000001100001c77c100000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000
0000000001c77c101c7777c1000000000000000000000000000000000000000000000000000000000000000000e8800000000000000000000000000000000000
000000001c7777c1c777777c00000000000000000000000000000000000000000000000000000000000000000ee8880000000000000000000000000000000000
000000001c7777c1c777777c00000000000000000000000000000000000000000000000000000000000000000776660000000000000000000000000000000000
0000000001c77c101c7777c100000000000000000000000000000000000000000000000000000000000000000ee8880000000000000000000000000000000000
00000000001771000c7777c000000000000000000000000000000000000000000000000000000000000000000076600000766000000000000000000000000000
00000000001cc10001c77c1000000000000000000000000000000000000000000000000000000000000000000979690009796900000000000000000000000000
0000000000011000001cc10000000000000000000000000000000000000000000000000000000000000000009979699099796990000000000000000000000000
00000000022002200220022002200220022002200000000000000000000000000000000000000000000000000000000000000000000000000099990000000000
000000002282282222822822228228222282282200000000000000000000000000000000000000000000000000000000000000000000000009aaaa9000000000
00000000288888822888888228888882288888820000000000000000000000000000000000000000000000000000000000000000000000009aa77aa900000000
00000000287717822877178228771782287717820000000000000000000000000000000000000000000000000000000000000000000000009a7777a900000000
00000000087117800871178008711780087117800000000000000000000000000000000000000000000000000000000000000000000000009a7777a900000000
00000000008778000087780000877800008778000000000000000000000000000000000000000000000000000000000000000000000000009aa77aa900000000
000000000808808008088080080880800808808000000000000000000000000000000000000000000000000000000000000000000000000009aaaa9000000000
00000000080000808000000808000080088008800000000000000000000000000000000000000000000000000000000000000000000000000099990000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100001c77c10009a9000000ee000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c77c101c7777c109a7a90000e88e00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c7777c1c77cc77c9a777a900e8778e0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c7777c1c77cc77ca77777a00e8778e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c77c101c7777c19a777a900e8778e0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001771000c7777c009a7a90000e77e00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cc10001c77c10009a900000e88e00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001cc10000000000000ee000
00000000000000000000998200000000000522225550000000000550000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000002999222000000000228822250000000000050500000000000055005555000000000000000000000000000000000000000000000000000
00000000007000000029999999999000052288888225500005500555005550000000555000000500000000000000000000000000000000000000000000000000
000000000000707000999aaaaaaa99000528a8998888550000055555555855000000555000050000000000000000000000000000000000000000000000000000
0007700aaa0000000999aa77777a99005528899a9998825005558885955555500055550000550000000000000000000000000000000000000000000000000000
000000977aa000000999a777777aa9805228a9977998825005585589598555500050050055555500000000000000000000000000000000000000000000000000
000009a777790000099a77777777a990528899a77a99825000559995598552000550000005555500000000000000000000000000000000000000000000000000
0000aa77777a0000099777777777a99052889aa77a99822502559858888585050550000005555550000000000000000000000000000000000000000000000000
0000a77777770000099777777777a990528899777aa9822555288288888555050550005005005505000000000000000000000000000000000000000000000000
0000a77777770000099aa777777aa990528a99aaaa99822555259255855882550050000055000005000000000000000000000000000000000000000000000000
0070077777a907000299a77777aa9990028889999999822555525222888598550055550005000050000000000000000000000000000000000000000000000000
0007779777a000000299a7777aa999900288889a9998825005552552528955500050005005500050000000000000000000000000000000000000000000000000
000070090770000000999aaaaa999800002288899888825000555555255555500000005005550500000000000000000000000000000000000000000000000000
00007770700700000009999999998000505528888822550050055555555005000000055555500000000000000000000000000000000000000000000000000000
00000700070000000000899999990000000522222225500000005500555500000000000005500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055000505000000000000050500000000000000000000000000000000000000000000000000000000000000000000
__label__
60006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000003300000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000003bb30000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000003bb30000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000003b33b3000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003b37c3b300000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003b3113b300000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000003b88b3000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000b99b0000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000037550305502c5502855025550215501a55014550105500b55008550065500355002550035500055000550005500055000550055000450003500025000250002500015000050000500015000150000500
000100001f65025640296402a63028620246201e6301c6101861017650126200e6200962002620006100060000600016000160001600016000160000600006000060000600006000060000600006000060000600
000100003c75006650377502b73025720105200f5200b520186500655001650196500265005650075100f650075100c6400455003610035500360010620055500363004500035000660006600006000060000600
00010000286101f370055600050000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
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
001000001d0501f0501f0501305013050160501b0501b05011050160501d0502405027050290502905027050240501f050160501d0501d0500f0500f050180501b0501805013050130500f0500f0500f0500f050
00100000035500050000500005000a550005000050000500005500050000500005000f550005000050000500165500050000500005000c5501155000500005000755000500005000050003550005000050000500
__music__
00 14154344

