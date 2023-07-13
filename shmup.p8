pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--[[

 todo:
  - explosions
  - impact fx

--]]

function _init()
 cls(0)
 
 -- globals
 g_speed = 2
 g_max_lives = 3
 g_max_bombs = 3
 g_num_stars = 100
 g_space_speed = 2
 
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
 elseif mode =='game' then
  update_game()
 elseif mode=='over' then
  update_over()
 end
end

function _draw()
 if mode=='start' then
  draw_start()
 elseif mode=='game' then
  draw_game()
 elseif mode=='over' then
  draw_over()
 end
end

function start_game()
 mode='game'
 t=0
 
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
 
 enemies = {}
 
 spawn_enemy()
 
 -- counters
 score = 10000
 lives = 3
 bombs = 2
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
		  del(enemies,en)
		  del(bullets,bul)
		  sfx(2)
		  spawn_enemy()
		 end
		end
 end
 
 -- collision ship x enemies
 if invul==0 then
	 for en in all(enemies) do
	  if collide(ship,en) then
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



function update_over()
 animate_starfield()
 
 if btnp(4) or btnp(5) then
  mode='start'
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
   bullet.spr_id+=0.6
   
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
 
 -- render enemies
 for en in all(enemies) do
  draw_sprite(en)
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
 
 -- bombs
 for i = 1,g_max_bombs do
 	if bombs >= i then
   spr(27,130-(i * 9))
 	else
   spr(28,130-(i * 9))
 	end
 end
end




function draw_start()
 cls(1)
 
 render_starfield()
 print('most amazing shmup',27,40,12)
 print('press any key to start',20,80,blink())
end



function draw_over()
 cls(8)
 
 render_starfield()
 print('game over',44,40,2)
 print('press any key to continue',15,80,blink())
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
 if btnp(5) then
  local new_bullet = {
   x = ship.x,
   y = ship.y,
   spr_id = bullet_spr,
  }
  add(bullets,new_bullet)
  sfx(0)
  muzzle = 5
 end
 
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
  
  -- account for different modes
  if (star.clr == 1) and mode ~= 'game' then
   pset(star.x, star.y, 15)
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
 })
end
__gfx__
00000000000030000003300000033000000330000003000000000000000000000000000000000000000000000880088008800880000000000000000000000000
000000000003b300003bb300003bb300003bb300003b300000077000008778000007700000877800000770008778888280088002000000000000000000000000
000000000003bb30003bb300003bb300003bb30003bb3000008aa8000887788000877800088aa880008aa8008788888280000002000000000000000000000000
00000000003bbb3003b33b3003b33b3003b33b3003bbb30000088000008aa800008aa800008aa800800880008888888280000002000000000000000000000000
0000000000b7bbb00b7c3bb03b37c3b30bb37cb00bbb7b0000000000008aa8000008800000088000000880000888882008000020000000000000000000000000
0000000000bcbbb00b113bb03b3113b30bb311b00bbbcb0000000000000880008008800000088000000009000088820000800200000000000000000000000000
000000000005b3300355bb3003b55b3003bb5530033b500000000000000880000800008000000000000000000008200000082000000000000000000000000000
000000000009900000b99b0000b99b0000b99b000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000001100001c77c100000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000
0000000001c77c101c7777c1000000000000000000000000000000000000000000000000000000000000000000e8800000000000000000000000000000000000
000000001c7777c1c77cc77c00000000000000000000000000000000000000000000000000000000000000000ee8880000000000000000000000000000000000
000000001c7777c1c77cc77c00000000000000000000000000000000000000000000000000000000000000000776660000000000000000000000000000000000
0000000001c77c101c7777c100000000000000000000000000000000000000000000000000000000000000000ee8880000000000000000000000000000000000
00000000001771000c7777c000000000000000000000000000000000000000000000000000000000000000000076600000766000000000000000000000000000
00000000001cc10001c77c1000000000000000000000000000000000000000000000000000000000000000000979690009796900000000000000000000000000
0000000000011000001cc10000000000000000000000000000000000000000000000000000000000000000009979699099796990000000000000000000000000
00000000022002200220022002200220022002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000228228222282282222822822228228220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000288888822888888228888882288888820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000287717822877178228771782287717820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000087117800871178008711780087117800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008778000087780000877800008778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080880800808808008088080080880800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080000808000000808000080088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a9000000ee000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a7a90000e88e00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a777a900e8778e0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a77777a00e8778e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a777a900e8778e0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a7a90000e77e00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a900000e88e00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee000
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
