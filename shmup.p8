pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
debug=false
--player stuff
p1={}
p1.beamhit=false
p1.up=false
p1.down=false
p1.left=false
p1.right=false
p1.btn1=false
p1.btn2=false
p1.lives=3
p1.score=0
p1.sprite=1
p1.w=2
p1.h=2
p1.x=0
p1.y=0
p1.fire1clk=0 --can shot when 0
p1.beam={}
p1.beam.hitspr={80,81}
p1.beam.hitspri=1
p1.beam.active=false
p1.beam.ysize=0
p1.beam.xsspr=8*1 --x coordinate on the spritesheet
p1.beam.ysspr=8*4 --y coordinate on the spritesheet
p1.beam.wpx=8 --width in px (not cells)
p1.beam.x=p1.x+5
p1.beam.ystart=p1.y
p1.beam.ssproffsets={0,1,2,3,4,5,6,7}
p1.beam.clk=0
p1.draw=function()
    spr(p1.sprite,p1.x,p1.y,p1.w,p1.h)
end
p1.move=function()
    p1.up=btn(2)
    p1.down=btn(3)
    p1.left=btn(0)
    p1.right=btn(1)
    p1.btn1=btn(4)
    p1.btn2=btn(5)

    if(p1.up)then
        p1.y=p1.y-1
    end
    if(p1.down)then
        p1.y=p1.y+1
    end
    if(p1.left)then
        p1.x=p1.x-1
    end
    if(p1.right)then
        p1.x=p1.x+1
    end
    if(p1.btn1)then
       p1.fire1() 
    end
    if(p1.btn2)then
        p1.beam.active=true 
    else
        p1.beam.active=false
    end

    if(p1.x<0)p1.x=0
    if(p1.x+p1.w*8>128)p1.x=128-p1.w*8
    if(p1.y<0)p1.y=0
    if(p1.y+p1.h*8>128)p1.y=128-p1.h*8

    if(p1.fire1clk<0)then
        p1.fire1clk=p1.fire1clk+1
    end
end
p1.fire1=function()
    if(p1.fire1clk>-1)then
        --update the cooldown cloak
        p1.fire1clk=p1.fire1clk-10
        --center bullet
        local bw=0.5 --bullet width and height
        local bh=0.5
        local spawnx=(p1.x+8*p1.w/2)-(8*bw/2)
        local spawny=p1.y-(8*bh/2)
        local b=make_bullet(64,1,spawnx,spawny,bw,bh,0)
        b.update=function()
            local yspeed=2
            b.y=b.y-yspeed
        end
        b.draw=function()
            spr(b.sprite,b.x,b.y,b.w,b.h)
        end
        add(p1_bullets, b)
        --left bullet
        local b=make_bullet(64,1,spawnx,spawny,bw,bh,0)
        b.update=function()
            local yspeed=2
            b.y=b.y-yspeed
            local xspeed=0.45
            b.x=b.x-xspeed
        end
        b.draw=function()
            spr(b.sprite,b.x,b.y,b.w,b.h)
        end
        add(p1_bullets, b)
        --right bullet
        local b=make_bullet(64,1,spawnx,spawny,bw,bh,0)
        b.update=function()
            local yspeed=2
            b.y=b.y-yspeed
            local xspeed=0.45
            b.x=b.x+xspeed
        end
        b.draw=function()
            spr(b.sprite,b.x,b.y,b.w,b.h)
        end
        add(p1_bullets, b)
    end
end



-->8
--bullet and beams stuff
p1_bullets={}
e_bullets={}

function make_bullet(sprite,frames,x,y,w,h,rot)
    b={}
    b.sprite=sprite
    b.frames=frames
    b.x=x
    b.y=y
    b.w=w
    b.h=h
    b.rot=rot
    b.clk=0
    return b
end

function update_p1_bullets()
    for b in all(p1_bullets) do
        --bullet movement
        b.update()
        

        --enemy hit
        for e in all(enemies)do
            local bOverlap=overlap(b,e)
            if(bOverlap)then
                e.hp-=1
                --todo bullet explosion
                if(e.bDidBlink==false)e.bBlink=true
                del(p1_bullets,b)

                if(e.hp<=0)then
                    del(enemies,e)
                end
            end
        end

        --clean gone bullet
        if(b.x<-20 or b.y<-20 or b.x>140 or b.y>140)then
            del(p1_bullets,b)
        end
    end
end

function update_e_bullets()
    for b in all(e_bullets) do
        --bullet movement
        b.update()
        if(b.x<-20 or b.y<-20 or b.x>140 or b.y>140)then
            del(e_bullets,b)
        end
    end
end

function update_p1_beam()
    p1.beam.ystart=p1.y
    p1.beam.x=p1.x+5
    p1.beamHit=false
    if(p1.beam.active==false)then
        p1.beam.ysize=0
    else
        local bEnemyHit=false
        p1.beam.clk=p1.beam.clk+1
        if(p1.beam.clk>1)then
            p1.beam.clk=0
            local tmp=p1.beam.ssproffsets[1]
            del(p1.beam.ssproffsets,tmp)
            add(p1.beam.ssproffsets,tmp)
        end

        --enemy hit
        for e in all(enemies)do
            local b={}
            b.x=p1.x
            b.y=p1.beam.ystart-p1.beam.ysize -- this is kinda fucked because the beam is thought "upside-down"
            b.w=p1.beam.wpx/8
            b.h=p1.beam.ysize/8
            
            local bOverlap=overlap(b,e)
            if(bOverlap)then
                p1.beamHit=true
                bEnemyHit=true
                p1.beam.ysize=p1.beam.ystart-(e.y+e.h*8)
                e.hp-=1
                --todo beam explosion thing
                e.bBlink=true

                if(e.hp<=0)then
                    del(enemies,e)
                end
            end
        end

        if(bEnemyHit==false)p1.beam.ysize+=2
    end
end

function draw_p1_bullets()
    for b in all(p1_bullets) do
        b.draw()
    end
end

function draw_e_bullets()
    for b in all(e_bullets) do
        b.draw()
    end
end

function draw_beam(redraw_offset)
    if(debug)then
        print("beamxsspr "..p1.beam.xsspr,64,64,6)
        print("beamysspr "..p1.beam.ysspr,64,100,6)
        print("p1.beam.ssproffsets[1] "..p1.beam.ssproffsets[1],10,30,6)
    end
    local i=redraw_offset
    for of in all(p1.beam.ssproffsets)do
        i=i+1
        if(i>=p1.beam.ysize)then
            break
        end
        sspr(p1.beam.xsspr,p1.beam.ysspr+of,p1.beam.wpx,1,p1.beam.x,p1.y-i)
    end
    if(i<p1.beam.ysize)draw_beam(redraw_offset+8)

    if(p1.beamHit)then
        spr(p1.beam.hitspr[p1.beam.hitspri],p1.beam.x,p1.beam.ystart-p1.beam.ysize-7)
        p1.beam.hitspri+=1
        if(p1.beam.hitspri>#p1.beam.hitspr)p1.beam.hitspri=0
    end
end
-->8
--init draw update utils
cpu=0
mem=0

function _init()
    make_levels()
    -- make_bg_stars()
    star_emitter_1.make()
    load_level(1)
end

function _draw()
    cls()
    draw_bg_stars()
    p1.draw()
    draw_enemies()
    draw_p1_bullets()
    draw_e_bullets()
    draw_beam(0)
    if(debug)draw_debug()
end

function _update60()
    p1.move()
    update_p1_bullets()
    update_p1_beam()
    update_enemies()
    update_e_bullets()
    update_bg_stars()
    if(debug)update_debug()
end

function draw_debug()
    print("mem "..mem,0,128-7*1,6)
    print("cpu "..cpu.."%",0,128-7*2,6)
    print("p1.x "..p1.x,50,128-7*1,6)
    print("p1.y "..p1.y,50,128-7*2,6)
    
    print("#enemies "..#enemies,50,128-7*3,6)
end

function update_debug()
    mem=stat(0)
    cpu=stat(1)/100
end

--utils
function overlap(a,b)
    --thanks @MBoffin
    local a_x1=a.x
    local a_x2=a.x+a.w*8
    local b_x1=b.x
    local b_x2=b.x+b.w*8
    local a_y1=a.y
    local a_y2=a.y+a.h*8
    local b_y1=b.y
    local b_y2=b.y+b.h*8

    if(a_x1>b_x2)return false
    if(a_y1>b_y2)return false
    if(a_x2<b_x1)return false
    if(a_y2<b_y1)return false
    
    return true
end
-->8
--enemy spawn and behavior stuff
enemies={}

function make_enemy(type,frames,x,y,w,h)
    local e={}
    e.type=type
    e.frames=frames
    e.x=x
    e.y=y
    e.w=w
    e.h=h
    e.hp=1
    e.bBlink=false
    e.bDidBlink=false
    e.clk=0
    --default draw function
    e.draw=function()
        spr(e.type,e.x,e.y,e.w,e.h)
    end

    if(e.type==1)then
        e.hp=20
        --this one moves down slowly
        --and shots a bullet sometimes
        e.update=function()
            e.clk+=1
            e.y+=0.05 
            if(e.clk>60)then
                e.clk=0
                --TODO: define params
                local bw=0.5 --bullet width and height
                local bh=0.5
                local spawnx=(e.x+8*e.w/2)-(8*bw/2)
                local spawny=e.y+(8*bh/2)
                local b=make_bullet(67,1,spawnx,spawny,bw,bh,0)
                b.update=function()
                    local yspd=0.5
                    b.y+=yspd
                end
                b.draw=function()
                    spr(b.sprite,b.x,b.y,b.w,b.h)
                end
                add(e_bullets,b)
            end
        end
    end

    return e
end

function update_enemies()
    for e in all(enemies)do
        e.update()
    end
end

function draw_enemies()
    for e in all(enemies)do
        if(e.bBlink and not e.bDidBlink)then
            --briefly make whole palette white to bBlink injured enemy
            for c=0,15 do
                pal(c,7)
            end
            e.draw()
            e.bDidBlink=true
            e.bBlink=false
            pal()
        else
            e.bDidBlink=false
            e.draw()
        end
    end
end
-->8
--level scripting stuff
--manually indenting make_levels so i don't get lost
levels={}

function make_levels()
    local l={}
        l.n=1
        l.prelude=3 --seconds before lvl begin, for cinematic or pause
        l.enemies={}
        local e1=make_enemy(1,1,90,10,1,1)
        add(l.enemies,e1)
        local e2=make_enemy(1,1,50,10,1,1)
        add(l.enemies,e2)
    add(levels,l)
end

function load_level(n)
    lvl=levels[n]
    enemies=lvl.enemies
end
-->8
--background stuff
bg_stars={}
star_emitter_1={}
star_emitter_1.clk=0
star_emitter_1.maxclk=20
star_emitter_1.make=function()
    for i=0,rnd(5) do
        local star={}
        star.x=rnd(127)
        star.y=-10
        
        local spd=rnd(25)/100
        star.update=function()
            star.y+=spd+1
            if(star.y>128)del(bg_stars,star)
        end
        star.draw=function()
            pset(star.x,star.y,7)
        end
        add(bg_stars,star)
    end
end

star_emitter_2={}
star_emitter_2.clk=0
star_emitter_2.maxclk=40
star_emitter_2.size=4
star_emitter_2.make=function()
    for i=0,rnd(3) do
        local star={}
        star.x=rnd(127)
        star.y=-10
        
        local spd=rnd(225)/100
        star.update=function()
            star.y+=spd+2.5
            if(star.y>128)del(bg_stars,star)
        end
        star.draw=function()
            for i=0,rnd(star_emitter_2.size) do
                pset(star.x,star.y-i,7)
            end
        end
        add(bg_stars,star)
    end
end

function draw_bg_stars()
    for s in all(bg_stars)do
        s.draw()
    end
end

function update_bg_stars()
    for s in all(bg_stars)do
        s.update()
    end
    star_emitter_1.clk+=1
    if(star_emitter_1.clk>star_emitter_1.maxclk)then
        star_emitter_1.clk=0
        star_emitter_1.make()
    end

    star_emitter_2.clk+=1
    if(star_emitter_2.clk>star_emitter_2.maxclk)then
        star_emitter_2.clk=0
        star_emitter_2.make()
    end
end
-- bg_stars={}

-- function make_bg_stars()
--     for x=0,127 do
--         for y=0,127 do
--             local r=rnd(10000)
--             if(r<20)then
--                 local star={}
--                 star.x=x
--                 star.y=y 
--                 add(bg_stars, star)
--             end
--         end
--     end
-- end

-- function draw_bg_stars()
--     for s in all(bg_stars)do
--         pset(s.x,s.y,7)
--     end
-- end

-- function update_bg_stars()
--     local respawn=0

--     for s in all(bg_stars)do
--         local r=0
--         s.y+=1
--         if(s.y>128)then
--             del(bg_stars,s)
--             r=s.y-128
--             if(r>respawn)respawn=r
--         end
--     end

--     for i=0,respawn do
--         for x=0,127 do
--             local r=rnd(10000)
--             if(r<20)then
--                 local star={}
--                 star.x=x
--                 star.y=1-i
--                 add(bg_stars, star)
--             end
--         end
--     end
-- end
-->8
--score stuff
-->8
--title screen stuff
__gfx__
0000000000000cccccc0000000000cccccc0000000000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000c666666c00000000c666666c00000000c666666c0000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000c65c55c56c000000c65c55c56c000000c65c55c56c000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000c66fddf66c000000c66dddf66c000000c66fddd66c000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000c6661dd1666c0000c666f0d1666c0000c6661d0f666c00000000000000000000000000000000000000000000000000000000000000000000000000
007007000c6666dffd6666c00c6666fffdd666c00c666ddfff6666c0000000000000000000000000000000000000000000000000000000000000000000000000
00000000c66666611666666cc66666611d66666cc66666d11666666c000000000000000000000000000000000000000000000000000000000000000000000000
00000000c61666611666616cc61666611666616cc61666611666616c000000000000000000000000000000000000000000000000000000000000000000000000
00000000c11166666666111cc11166666666111cc11166666666111c000000000000000000000000000000000000000000000000000000000000000000000000
0000000011111cccccc1111111111cccccc1111111111cccccc11111000000000000000000000000000000000000000000000000000000000000000000000000
00000000199910000001999119991000000199911999100000019991000000000000000000000000000000000000000000000000000000000000000000000000
00000000099900000000999009990000000099900999000000009990000000000000000000000000000000000000000000000000000000000000000000000000
00000000009000000000090000900000000009000090000000000900000000000000000000000000000000000000000000000000000000000000000000000000
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
08800000888588852020202002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8998000008888858828282822ee20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8998000008888588888888882ee20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800000028868808888888802200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888688800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887882800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000878888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000788878880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80008008808000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82828282282828280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
