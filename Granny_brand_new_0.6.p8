pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
    current_map_id="forest"
    enemies={}
    shurikens={}
    platform={}
    init_platform()
    scan_platform(current_map_id)
    build_platform_graph() 
    player=create_player(32,64)
    physics=create_physics()
    load_map_enemies(current_map_id)
end

function _update()
    player_update(player)
    check_pickup_shoot()
    shurikens_update()
    enemies_update()
end

function _draw()
    cls()
    map(maps[current_map_id].map_loc.x,maps[current_map_id].map_loc.y)
    spr(player.sprite,player.x,player.y,1,1,player.face)
    print_shurikens()
    
    enemies_draw()
    debug()
    --debug_collision()
    --debug_draw_platforms()
    --debug_print_path()
end



-->8
--and god said, let there be physics and player: and there were physics and player.
function create_physics()
    local physics={
        g=0.4,
        air=0.98,
        f=0.95,
        threshold_speed=0.1,
        accel=0.3,
        shuriken_speed=2
    }
    return physics
end

function create_player(x,y)
    local player={
        x=x,
        y=y,
        vx=0,
        vy=0,

        rx=0,
        ry=0,

        ground=false,
        jump=false,
        face=false,
        sprite=1,

        max_sp=1.5,
        jumpforce=-4,
        able_to_shoot=false,

        cooldown=0
    }
    return player
end



-->8
--and god said, Let every table gathered together unto one place, and let the init appear: and it was so.
maps={
    forest={
        id="forest",
        map_loc={x=0,y=0},
        entry_points={
            {x=48,y=8},
            {x=104,y=8}
            
        },
        exit_points={
            {x=32,y=96,state="unlocked"},
            {x=128,y=56,state="unlocked"}
        },
        enemies={
            {x=96,y=72}
        }
    },
    cave={
        id="cave",
        map_loc={x=16,y=0},
        entry_points={
            {x=16,y=8},
            {x=112,y=64}
        },
        exit_points={
            {x=120,y=104,state="unlocked"}
        },
        enemies={
            {x=96,y=104}
        }
    },
    tree={
        id="tree",
        map_loc={x=32,y=0},
        entry_points={
            {x=8,y=72}
    },
        exit_points={
            {x=96,y=32,state="unlocked"},
            {x=40,y=40,state="unlocked"}
        },
        enemies={
            {x=96,y=104}
        }
    },
    acorn={
        id="acorn",
        map_loc={x=48,y=0},
        entry_points={
            {x=16,y=104}
        },
        exit_points={
            {x=112,y=104,state="unlocked"}
        },
        enemies={
            
        }
    }
}
tunnels={
    forest={
        [1]={
            to="cave",
            to_entry=1
        },
        [2]={
            to="tree",
            to_entry=1
        }
    },
    cave={
        [1]={
            to="forest",
            to_entry=1
        }
    },
    tree={
        [1]={
            to="forest",
            to_entry=2
        },
        [2]={
            to="acorn",
            to_entry=1
        }
    },
    acorn={
        [1]={
            to="cave",
            to_entry=2
        }
    }
}
function teleport(from_exit_index)
    local tunnel=tunnels[current_map_id][from_exit_index]
    local entry_points=maps[tunnel.to].entry_points[tunnel.to_entry]

    clear_enemies() 
    reset_platform()

    current_map_id=tunnel.to

    load_map_enemies(current_map_id)
    scan_platform(current_map_id)

    player.x = flr(entry_points.x / 8) * 8 
    player.y = flr(entry_points.y / 8) * 8 
    player.vx=0
    player.vy=0
    player.ground=false
    player.jump=false
end

function get_colliding_exit_index()
    local current_map_data = maps[current_map_id]
    if not current_map_data or not current_map_data.exit_points then
        return nil
    end
    local EXIT_RANGE = 16
    for i, exit_point in ipairs(current_map_data.exit_points) do
        local dx = player.x - exit_point.x
        local dy = player.y - exit_point.y
        local distance_squared = dx*dx + dy*dy

        if distance_squared < EXIT_RANGE*EXIT_RANGE then
            
            local can_use = exit_point.can_teleport 
                           and exit_point:can_teleport() 
                           or exit_point.state == "unlocked"
            if can_use then
                return i
            else
                if exit_point.state == "locked" then
                    show_message("This door is locked!")
                end
            end
        end
    end
    return nil
end

function show_message(msg)
    print(msg, 40, 100, 7)
end









-->8
--move your granny
function player_update(p)
    player_move(p)

    player_y_control(p)
    if p.vy>0 then
        picmove(p,p.vx,p.vy,nil,callback_ground)
    else
        picmove(p,p.vx,p.vy,nil,nil)
    end

    sprite_update(p)

    local exit_index=get_colliding_exit_index()
    if exit_index then 
        teleport(exit_index)
    end
    if p.able_to_shoot then
        shoot(p)
    end
    p.cooldown-=1
end
function player_move(p)
    if btn(⬅️) then
        p.face = true  
    elseif btn(➡️) then
        p.face = false  
    end
    if p.ground then
        if (btn(⬅️)) then
            p.vx = max(p.vx - physics.accel, -p.max_sp)
            
        end
        if (btn(➡️)) then
            p.vx = min(p.vx + physics.accel, p.max_sp)
            
        end
    else
        local air_accel = physics.accel * 0.3

        if(btn(⬅️)) then
            p.face=true
            if p.vx > 0 then
                p.vx = max(p.vx - air_accel*0.5, -p.max_sp)
            else
                p.vx = max(p.vx - air_accel, -p.max_sp)
            end
        end
        
        if (btn(➡️)) then
            p.face=false
            if p.vx < 0 then
                p.vx = min(p.vx + air_accel*0.5, p.max_sp)
            else
                p.vx = min(p.vx + air_accel, p.max_sp)
            end
        end
    end
    if (btn(🅾️) and p.ground and not p.jump) then
        p.vy = p.jumpforce  
        p.ground = false
        p.jump=true
    end
    if not(btn (⬅️)or btn (➡️)) then
        apply_friction(p)
    end
    apply_gravity(p)
    --[[if not p.ground then
        apply_gravity(p)
    end]]
end

function sprite_update(p)
    local cool=1
    if p.cooldown<=0 then
        cool=4
    end
    local frame = (t()*3)%3
    
    if (btn(⬅️) or btn(➡️)) then
        p.sprite = flr(frame) + cool
    else
        p.sprite = cool
    end
end

function sprite_update_shuriken(p)
    local frame = (t()*17)%2
        p.sprite = flr(frame) + 10
end




-->8
--and god saw the friction, that it was good
function apply_friction(p)
    local dec = p.ground and 0.05 or 0.03
    local fastf = p.ground and physics.f or physics.air
    if abs(p.vx)>physics.threshold_speed then
        p.vx*=fastf
    else
        local fric= dec*sgn(p.vx)
        p.vx-=fric
        if abs(p.vx)<=dec then
            p.vx=0
        end
    end
end



-->8
--collison,so hard and so complex
function check_collision_map(x,y)
    local cmapxl=flr((x+1)/8)
    local cmapxr=flr((x+7)/8)
    local cmapyt=flr((y+1)/8)
    local cmapyb=flr((y+7)/8)

    if fget(mget(cmapxl,cmapyt),0) then
        return true
    elseif fget(mget(cmapxl,cmapyb),0) then
        return true
    elseif fget(mget(cmapxr,cmapyt),0) then
        return true
    elseif fget(mget(cmapxr,cmapyb),0) then
        return true
    else
        return false
    end
end



function picmove(s,amt_x,amt_y,callbackx,callbacky)
    s.rx+=amt_x
    s.ry+=amt_y
    local movex =flr(s.rx+0.5)
    local movey =flr(s.ry+0.5)

    if movex==0 and movey==0 then 
        return 
    end
    s.rx-=movex
    local sign=sgn(movex)
    while movex~=0 do
        if  check_collision_map(offset(s.x+sign,s.y))==false then
            s.x+=sign
            movex-=sign
        else
            player.vx=0
            if callbackx~=nil then
                callbackx(s)
            end
            break
        end
    end
    s.ry-=movey
    sign=sgn(movey)
    while movey~=0 do
        if  check_collision_map(offset(s.x,s.y+sign))==false then
            s.y+=sign
            movey-=sign
        else
            
            if callbacky~=nil then
                callbacky(s)
            end
            break
        end
    end
end






-->8
--so good that u can shoot shurikens now
function shurikens_update()
    for i=#shurikens,1,-1 do
        local s = shurikens[i]
        picmove_shurikens(s, s.vx)
        sprite_update_shuriken(s)
    end
end
function picmove_shurikens(s,amt_x)
    s.rx+=amt_x
    local movex =flr(s.rx+0.5)

    if movex==0  then 
        return 
    end
    s.rx-=movex
    local sign=sgn(movex)
    while movex~=0 do
        if  check_collision_map(offset(s.x+sign,s.y))==false then
            s.x+=sign
            movex-=sign
        else
            del(shurikens, s) 
            break
        end
    end
    
end

function add_shurikens() 
    local face_dir = player.face and -1 or 1
    add(shurikens,{
        x=player.x+(face_dir==1 and 8 or -4),
        y=player.y,
        vx=face_dir*physics.shuriken_speed,
        rx=0,
        sprite=10
    })
end

function shoot()
    if(btn(❎)and player.cooldown<=0)then
        add_shurikens()
        player.cooldown=15
    end
end
function print_shurikens()
    for s in all(shurikens) do
        spr(s.sprite, s.x, s.y)  
    end
end




-->8
--mob spawn
function add_enemy(x,y)
    add(enemies,{
        x=x,
        y=y,
        vx=0,
        vy=0,
        alive=true,
        rx=0,
        ry=0,
        face=false,
        ground=false,
        max_sp=1,
        jumpforce=-4,
        need_repath=true,
    })
end
function load_map_enemies(map_id)
    local map_data = maps[map_id]
    if map_data and map_data.enemies then
        for _, enemy_pos in ipairs(map_data.enemies) do
            add_enemy(enemy_pos.x, enemy_pos.y)
        end
    end
end
function clear_enemies()
    enemies={}
end

-->8
--platform
function init_platform()
    for y=0,15 do
        platform[y] = {}
        for x=0,15 do
            platform[y][x] = {
                xloc = x,
                y_loc = y,
                father = nil,
                type = nil,
                link_target = nil
            }
        end
    end
    platform_grid = {}
    for x=0,15 do
        platform_grid[x] = {}
    end
end

function reset_platform()

    for y=0,15 do
        for x=0,15 do
            platform[y][x] = {
                xloc = x,
                y_loc = y,
                father = nil,
                type = nil,
                link_target = nil
            }
        end
    end
    

    platform_grid = {}
    for x=0,15 do
        platform_grid[x] = {}
    end
end

function scan_platform(current_map_id)
    local map_data = maps[current_map_id]
    if not map_data then
        print("map_ID:", current_map_id)
        return
    end
    
    local x_offset = map_data.map_loc.x
    local y_offset = map_data.map_loc.y
    

    for j = y_offset+15, y_offset, -1 do
        for i = x_offset, x_offset+15 do
            local cell = mget(i, j)
            

            local local_x = i - x_offset  
            local local_y = j - y_offset  
            
            if fget(cell, 0) then

                platform_grid[local_x][local_y] = {type="unwalkable"}
                platform[local_y][local_x].type = "unwalkable"
            else

                local has_below = (j < y_offset+15) and fget(mget(i, j+1), 0)
                local has_left_below = (j < y_offset+15 and i > x_offset) and fget(mget(i-1, j+1), 0)
                local has_right_below = (j < y_offset+15 and i < x_offset+15) and fget(mget(i+1, j+1), 0)
                
                if has_below then
                    if has_left_below and has_right_below then
                        platform_grid[local_x][local_y] = {type="plat"}
                        platform[local_y][local_x].type = "plat"
                    elseif has_left_below and not has_right_below then
                        platform_grid[local_x][local_y] = {type="right_edge"}
                        platform[local_y][local_x].type = "right_edge"
                    elseif not has_left_below and has_right_below then
                        platform_grid[local_x][local_y] = {type="left_edge"}
                        platform[local_y][local_x].type = "left_edge"
                    else
                        platform_grid[local_x][local_y] = {type="solo"}
                        platform[local_y][local_x].type = "solo"
                    end
                else
                    platform_grid[local_x][local_y] = {type="air"}
                    platform[local_y][local_x].type = "air"
                end
            end
        end
    end

    build_platform_graph()
end


-->8
--gadgets just some gadgets
function callback_ground (s)
    s.ground=true
    s.jump=false
    if(s.need_repath~=nil) then
        s.need_repath = true
    end
end

function apply_gravity(s)
    s.vy+=physics.g
end

function player_y_control(p)
    p.vy = mid(-5, p.vy, 3)
end


function offset(x,y)
    return x+(maps[current_map_id].map_loc.x)*8,y+(maps[current_map_id].map_loc.y)*8
end
-->8
--ability
function check_pickup_shoot()
    local px,py=offset(player.x,player.y)
    local cell=mget(flr(px/8),flr(py/8))
    if cell==214 and not player.able_to_shoot then
        player.able_to_shoot=true
        mset(flr(px/8),flr(py/8),227)
        show_message("SHURIKEN ACQUIRED!")
    end
end




-->8
--enemy ai & pathfinding

enemy_nodes = {}
enemy_edges = {}

function build_platform_graph()
    enemy_nodes = {}
    enemy_edges = {}

    for y=0,15 do
        for x=0,15 do
            local t = platform[y][x]
            if t and (t.type=="plat" or t.type=="left_edge" or t.type=="right_edge" or t.type=="solo") then
                local node = {x=x, y=y}
                add(enemy_nodes, node)
                enemy_edges[node] = {}
            end
        end
    end

    for node in all(enemy_nodes) do

        for dx=-1,1 do
            if dx!=0 then
                local nx = node.x+dx
                local ny = node.y
                if nx>=0 and nx<=15 and platform[ny][nx] and platform[ny][nx].type~="air" and platform[ny][nx].type~="unwalkable" then
                    add(enemy_edges[node], {to=find_node(nx,ny), cost=1, type="walk"})
                end
            end
        end

        for dx=-2,2 do
            for dy=-2,2 do
                if abs(dx)+abs(dy)>1 and abs(dx)<=2 and abs(dy)<=2 then
                    local tx = node.x+dx
                    local ty = node.y+dy
                    if tx>=0 and tx<=15 and ty>=0 and ty<=15 then
                        if can_jump_between(node.x,node.y,tx,ty) then
                            add(enemy_edges[node], {to=find_node(tx,ty), cost=8, type="jump"})
                        end
                    end
                end
            end
        end
        
    end
end

function find_node(x,y)
    for n in all(enemy_nodes) do
        if n.x==x and n.y==y then return n end
    end
    return nil
end

function can_jump_between(x1,y1,x2,y2)

    if abs(x1-x2)==1 and y1==y2 then return false end

    local minx,maxx=min(x1,x2),max(x1,x2)
    local miny,maxy=min(y1,y2),max(y1,y2)
    for x=minx+1,maxx-1 do
        for y=miny,maxy do
            if platform[y][x] and platform[y][x].type=="unwalkable" then
                return false
            end
        end
    end
    return true
end

mincost=0

function astar(start,goal)
    local open_set = {{node=start, cost=0, est=heuristic(start,goal), path={start}}}
    local closed = {}

    while #open_set>0 do

        local current_i = 1
        for i=2,#open_set do
            if open_set[i].cost+open_set[i].est < open_set[current_i].cost+open_set[current_i].est then
                current_i = i
            end
        end
        local current = open_set[current_i]
        deli(open_set, current_i)

        if current.node==goal then
        				mincost=current.cost
            return current.path
        end

        add(closed, current.node)
        for edge in all(enemy_edges[current.node]) do
            local neighbor = edge.to
            if neighbor and not contains(closed, neighbor) then
                local new_cost = current.cost + edge.cost
                local new_path = {}
                for n in all(current.path) do add(new_path, n) end
                add(new_path, neighbor)
                add(open_set, {node=neighbor, cost=new_cost, est=heuristic(neighbor,goal), path=new_path})
            end
        end
    end
    return nil
end

function heuristic(a,b)
    return abs(a.x-b.x)+abs(a.y-b.y)
end

function contains(tbl, val)
    for v in all(tbl) do if v==val then return true end end
    return false
end

function find_nearest_node(x, y)
    local min_dist = 999
    local nearest = nil
    for n in all(enemy_nodes) do
        local dist = abs(n.x*8-x)+abs(n.y*8-y)
        if dist<min_dist then
            min_dist = dist
            nearest = n
        end
    end
    return nearest
end

path=nil

function enemy_update(e)

    if e.need_repath == nil then e.need_repath = true end
    if e.ground and e.need_repath then
        local start = find_nearest_node(e.x, e.y)
        local goal = find_nearest_node(player.x, player.y)
        if start and goal then
            e.path = astar(start, goal)
            e.need_repath = false
        end
    end

    
    if not e.path or #e.path <= 1 then
        e.vx = 0
        return
    end

   
    local next_node = e.path[2]
    local edge_type = "walk"
    for edge in all(enemy_edges[find_nearest_node(e.x, e.y)]) do
        if edge.to == next_node then
            edge_type = edge.type
            break
        end
    end
    if edge_type == "walk" then
        e.vx = sgn(next_node.x*8 - e.x) * e.max_sp
    elseif edge_type == "jump" then
        if e.ground then
            e.vy = e.jumpforce
            e.ground = false
            e.need_repath = true 
        end
    else
        e.vx = sgn(next_node.x*8 - e.x) * e.max_sp
    end
end

function enemies_update()
				print("eu", 90, 45, 5)
    for e in all(enemies) do
        if e.alive then
            enemy_update(e)
            if e.vy>0 then
                picmove(e,e.vx,e.vy,nil,callback_ground)
            else
                picmove(e,e.vx,e.vy,nil,nil)
            end
            e.vy = mid(-5, e.vy+physics.g, 3)

            if e.ground then
                e.vx*=0.8
                if abs(e.vx)<0.05 then e.vx=0 end
            else
                e.vx*=0.95
            end
        end
    end
end

function enemies_draw()
    for e in all(enemies) do
        if e.alive then
            spr(12, e.x, e.y)
        end
    end
end



-->8
--debug
function debug()
    print(current_map_id, 0, 0, 8)
    print("x:"..player.x, 0, 8, 8)
    print("y:"..player.y, 0, 16, 8)
    print("vx:"..player.vx, 0, 24, 8)
    print("vy:"..player.vy, 0, 32, 8)
    print("rx:"..player.rx, 0, 40, 8)
    print("ry:"..player.ry, 0, 48, 8)
    local px,py=offset(player.x,player.y)
    local cell=mget(flr(px/8),flr(py/8))
    print("tile:"..cell, 0, 56, 8)
end

function debug_collision()
    for dy=-1,1 do
        for dx=-1,1 do
            local x, y = player.x + dx*8, player.y + dy*8
            if check_collision_map(offset(x, y)) then
                rect(x, y, x+7, y+7, 8) 
            end
        end
    end
end

function debug_draw_platforms()
    if not platform then return end

    local color_map = {
        unwalkable = 8,  
        air = 0,         
        plat = 11,       
        left_edge = 10,  
        right_edge = 9,  
        solo = 5         
    }
    
    if not platform[0] or not platform[0][0] then return end
    
    for y=0,15 do
        if not platform[y] then break end
        for x=0,15 do
            local tile = platform[y][x]
            if not tile or not tile.type then break end
            
            local color = color_map[tile.type]
            
            if tile.type ~= "air" then
                pset(x, y, color)
                print(sub(tile.type,1,1), x*8+1, y*8+1, 7)
            end
        end
    end
    

    if platform[0][0] and platform[0][0].type then
        print("unwalkable", 90, 5, 8)
        print("plat", 90, 15, 11)
        print("left_edge", 90, 25, 10)
        print("right_edge", 90, 35, 9)
        print("solo", 90, 45, 5)
    end
end

function debug_print_path()
    local y = 30
    for i,e in ipairs(enemies) do
        if e.path then
            print("enemy "..i.." |path|="..#e.path, 90, y, 9)
            print("cost="..(mincost or "nil"), 90, y+10, 9)
            local idx=0
            for n in all(e.path) do
                idx+=1
                if n then
                    print(idx, n.x*8+1, n.y*8+1, 7)
                end
            end
            y += 30 
        else
            print("enemy "..i.." |path|=nil", 90, y, 9)
            y += 20
        end
    end
end

__gfx__
00000000b0666660b0666660b0666660806666608066666080666660000000000000000000000000000000000007700000044000000000000000000000000000
000000000bbbb1b00bbbb1b00bbbb1b0088881800888818008888180000000000000000000000000077707700007770000444400000000000000000000000000
00700700006fffff006fffff006fffff006fffff006fffff006fffff000000000000000000000000077777700777770004444440000000000000000000000000
00077000992ffff0992ffff0992ffff0992ffff0992ffff0992ffff0000000000000000000000000007007707770077744144144000000000000000000000000
000770009222d2009222d2009222d2009222d2009222d2009222d200000000000000000000000000077007007770077744444444000000000000000000000000
0070070092f2d2f0922fd2f092f2d22f92f2d2f0922fd2f092f2d22f000000000000000000000000077777700077777004444440000000000000000000000000
0000000099dddd0099dddd0099dddd0099dddd0099dddd0099dddd00000000000000000000000000077077700077700000900900000000000000000000000000
0000000000f00f0000f00f0000f00f0000f00f0000f00f0000f00f00000000000000000000000000000000000007700009900990000000000000000000000000
bbb3bb3b99464444bbbbbbbb4444444499444444cbbbbbbbb3999444cbbbbbbb54444499444449994454993bbbbbbbbccbbbbbbbbbbbbbbc4499933b00000000
b39b3b9399944644b39b3bb34544456499944654b39b3bb3b9944464b3b9bb3344445499444454994444494bb3b9bb33b39b3bb3b3b9b3bb4449493b00000000
33939b9994444444939393b94464444499994444939349b934944444b9349b39446449494464494944644993b9394b39bb9349b9b9399b3b6499499b00000000
394993949999445499399939444444549449444694999939994454443949939944499999544999994444549439949394b94999393994933b4444933b00000000
943444449494644439443999444444449934944494494949944444449444494944444449444444934444444994449949b3394949944934334449993b00000000
444644449944444494444444464446449994454499444444494446449964494946444999464449994644464449454999b39944444649993b4644943b00000000
44444564999954969444464444454444b3994464b94546444454444494445499444544994444994b445444444444464bbb394946444493bb4445499b00000000
64454444999444449946444544444446b3344644b34444544444444646444949444499494449933b444444464464443bb39494444544993b4449933b00000000
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc244425cccccc333c333c33c333ccccc944944554444444400000000
ccccccccccccccccccccccccccccccccccccccccc777cccccccccccc777c7cccccccccccc244425cccc33bbb3b1b3b333b113ccc944949d65444449400000000
ccccccccccccccccccccccccccccccccccccc777777777ccccccc777777777ccccccccccc244442ccc33bbbb3b3b3bb33bb333cc999949dd5594444400000000
cccccccccccc8ccccccccccccccacccccccc77777777777cc7777777777777ccccccccccc524442ccc313b33b3bb33b3b3bb3c3ccc9999ddd544444400000000
ccccccccccc888ccccccccccccaaaccccc7777777777777ccc777777777777ccccccbbccc524422cc33b33bbbbbbbbbbbbbbbb3cccc111eedd44444400000000
ccccccccccc8b8cccc3c3cccccaaacccccc77777777777cccccc77777777cccccc3b8bbcc244442c33bbbbbb33bbb33333bbb333ccccc111eed4494400000000
cccccccccccccbccc33c3c3ccccbccccccccc77777777ccccccccc7777ccccccc38bbb8bc524442cc1bbbbbb33b3bbb333b3bbb3cccccc111dd5444400000000
cccccccccccccbcc3333333ccccbccccccccccccccccccccccccccccccccccccc3333333c524222c133bb3bbbb33bbb3bb33bbb3ccccc1111ed5444900000000
ccccb7bbbbbbcccc3bb333bbccccccccccbccc3cc244425cccccc95cc88788cc222222222244425c3bb333bbbb3bb3bbbb3bbbb3cccccc111ee5444400000000
ccccb7bbbbbbcccc3bb33bbbccccccccccbcccbcc224425cccccc25ccc888cccc25444444444425c3bb33bbb3bb3b33bbbb3bbb3cccc1c111ee5449400000000
cccbb7bbbbbbbcccbbbbbbb3cccccccccc38cbbcc299442cccccc92cccccccccc22222444244442c3bbbbbb33bb333bbbbb33331cccccc111e9d444400000000
ccbbbbbbbbbbbbcc333b33b3cccccccccc3ccabcccc9942ccccc992ccccccccccccbc2224424442c333b33b3b33b3bbbb33b3b33cccc1bb1eed4444400000000
ccb3b7bbbbbb3bccb3bb3331ccccccccc8bccc3ccccc992ccccc922ccccccccccc8b8cc22524422cc3bb3331b3bb3b1333bbb31ccc9cbeeeedd4444400000000
ccb3333333333bcc3b3311b13ccccccccc8cccbcccccc92cc299442cccccccccc88b88ccc244442cc33311b1bb33b3b3313331139499bdddd954494400000000
ccbbbbbbbbbbbbcc3b1313b33b3b33b4ccccccbaccccc92cc524442ccccccccc8788888cc524442cc11313b33333333333b33c3cb34455dd4444444400000000
cccccccccccccccc3313bb33c3394434ccccccacccccc92cc524222ccccccccc8788888cc524222ccc1ccc33c224423c4ccccc3cb33445654544444900000000
1efeefefffefeefffefeeff1feed55551ffeeff15555deef5555555511111111dd54444494945565111111110000000000000000000000000000000000000000
feeefeeeeeeeeeeeeeedeeeffed5d565eeeeeeef565d5def56555655111111115d5449444444dddd111111110000000000000000000000000000000000000000
fedddeddefddedddddedddefedde6555feeddeef5556edde5556555511111111deedd441113ddeed1bbbb1110000000000000000000000000000000000000000
eeddd5ddedddedddddeddeeedd555555fee55eee555555dd555555d511111111de5d111111b33eed1b33bb110000000000000000000000000000000000000000
ededddd5dddddded5dddeede5d555555edd55ede555555d5555555dd11111111ee3b1111111131ee1b3bbbbb0000000000000000000000000000000000000000
fdddd5555ddd5de5555ddddf55556555eeed5ddf555655555556edde11111111ed1b11111113b3ed1b36b6660000000000000000000000000000000000000000
fed5d56555d555d5555dddef55655565fed55def56555655565d5def11111111e11311111113131e1b3bbbbb0000000000000000000000000000000000000000
eedd555555565555565dddde55555555f65555de555555555555deef11111111f11311111113133f1b3bbbbb0000000000000000000000000000000000000000
fedf555555555555555dfdee1feeffeffed55deefefeeff1feed55ef00000000113311111113813b1b3bbbbb0000000000000000000000000000000000000000
feeeddd5555555655d5deeeffeeedeedfeee5ddfdeedeeeffed55dde00000000113b1111118311311b3bbbbb0000000000000000000000000000000000000000
eeedd55556556555555ddeeeeed5ee55fedd5dee555dddefedde55ed0000000011ab111111131a311b3bbbbb0000000000000000000000000000000000000000
fedddd555555555555ddeeeffddd55d5eed55def5d55dddedd55555d00000000111b1111111b113a1b3bbbbb0000000000000000000000000000000000000000
eedd55565555555555ddddefede55555eeed55df55555ede5d55555500000000111b3111111111311bbbbb110000000000000000000000000000000000000000
ededdd555555555555dddedffde55555fedd5ddf555ddedf555565550000000011138111111111b11bbbb1110000000000000000000000000000000000000000
eeeeed55556555655555ddeefeedee5deeedddeed5eeeeef55655565000000001113111111111111111111110000000000000000000000000000000000000000
feddd55555555555555ddffe1feeffeefedddffeeeffeff155555555000000001113111111111111111111110000000000000000000000000000000000000000
eeddd555555555655555ddef55555555eed5555fefefffee00000000000000000000000000000000000000000000000000000000000000000000000000000000
feeed5655555555565555dde56555565fee555efedeeddef00000000000000000000000000000000000000000000000000000000000000000000000000000000
feed5555d55dd55555e55dde55555555fedd55dedddd5ddf00000000000000000000000000000000000000000000000000000000000000000000000000000000
fed55ddddd5dedd555feeede5d655655fed555ee5555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
fedddeededddeedd55ddeeeed5e55555fdddddef5d55ddd500000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeddfedededeeededdddeefedd55565eedddfefdd5deded00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeefeeddd555eeedeeeeeeedeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
1ffeeffeffefeeffffeffef1ffed55551ffeeff1fffeefef00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1229999d94999499d99992d111211212115d1215d121121211288888888777788888121211211212112112120000000000000000000000000000000000000000
d99949d99449d4499d44992d11212215dd5d25d5dd21221218888888888777788888888211212212112125120000000000000000000000000000000000000000
22952949d494994594d252dd2121221d5ddddddddd5d221288888888888888888888888821212212212125520000000000000000000000000000000000000000
d225254444d4594d4452522d212112dd5dd9999cdd5dd51188888877888888888888888821211214447115510000000000000000000000000000000000000000
5d2d4544445454d44454d2d2212212dddd99cccccdd2d51188887777788888888888877821221244744445110000000000000000000000000000000000000000
d2254554455454dd4554552d211115dd9cccccc77cddd55588887777778888888888877721111999444444220000000000000000000000000000000000000000
d2524554455444dd455425dd2121151dccccc77777cdd5d588887777788887777888877721219a99944444420000000000000000000000000000000000000000
d255d455554d544d554d525d1255ddddcccccc777cccddd21222111216668777788887721229a999999444420000000000000000000000000000000000000000
dd2d45544545d445454dd22d112115ddccccccccccccd5d2454dd22d166666661121121211999999999944440000000000000000000000000000000000000000
2dd444545d44454555444d2d11215ddc7777ccccccccd5d25544442d1666676211212212199a9999999994450000000000000000000000000000000000000000
d2d54555454455455452552d21215d9777777cccccccd512545244cc666676122121221229999944499994450000000000000000000000000000000000000000
d2d5455445d454454452522d2121dd9c77ccccccccc9d511445249cc666766112121121199a99446649994510000000000000000000000000000000000000000
dd2d45444454d4544454d2d22155dd99cccccccbbc99d21144229cc1666672112122121199999466549994510000000000000000000000000000000000000000
d22525544d545455455452dd211dddd999ccccccbbdd15524524ccc26667622221111222999994655499d5220000000000000000000000000000000000000000
dd222454455444d5455422dd212115ddd9ccccccc9ddd51242249cc1666676122121121229999465549d12120000000000000000000000000000000000000000
d225d45555455445554d522d122211d5dccccccccd55dd12552d9cc21666777712221112122dddddd4d211120000000000000000000000000000000000000000
dd24d4544545d445454dd2dd112112d5ddccc2cc9d51d512452dccc2166666777721187200000000000000000000000000000000000000000000000000000000
2dd444555d44454554444dd2112122d5ddd999c99d5155125229ccc2116666676761878800000000000000000000000000000000000000000000000000000000
d2d52445454455455452552d212122155dddd999dd51521254229cc2212666666676226200000000000000000000000000000000000000000000000000000000
d2d5244445d454454442522d212112115d5ddddddd211211445299cc2cc716666677677100000000000000000000000000000000000000000000000000000000
2d2d45454454d4545454d2d2212212112d55d51d5d5212114454229cc7cc72166666776100000000000000000000000000000000000000000000000000000000
dd2445151d145451515442dd21111222211dd55255111222455452dc7c6612226666667200000000000000000000000000000000000000000000000000000000
d2141411111141d14151412d21211212215d151221211212455422dd212662126666676700000000000000000000000000000000000000000000000000000000
111111111111111111111111122211121222111212221112554d522d122266121666667700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54444444444444444444444555555555555555555566665555555555151515551515155515111555151511111515155515151555000000000000000000000000
44944949949994949494994455555555555555556664466656775675151511cccc15111115111199991511111515111115151111000000000000000000000000
4999499999969499999499945555555556555555674444465677777515155666c6c5555515111aaa9a9555551515555515155555000000000000000000000000
449999669966996666999994555566666656555566999966556556751511ccc6c6cc11151511999a9a9911111511111515111115000000000000000000000000
499696666666666666669944555556699666555556a999655675565515556666c66615551555aaaa9aaa11111555155515551555000000000000000000000000
496666655556656656569994555669999996655556a99965567777751116c6ccccc6c511111a9a99999a91111115151111151511000000000000000000000000
449665555555555555666994556699949999665556699665567567755516c6c666c6c515551a9a9aaa9a91115515194444451515000000000000000000000000
496655555555555555699944555669444499665555666655555555551516c6c6c6c6c515151a9a9a9a9a91111515941666641515000000000000000000000000
499666555555555556999994555699944999655515151555158778551516c666c6c6c555151a9aaa9a9a91111519441216644555000000000000000000000000
499966555555555556669994555669444496655515151111178787711516ccccc6c6c111151a99999a9a91111519421212664111000000000000000000000000
4449666555555555555699445555699999965555151555551775588515166666c6c6c555151aaaaa9a9a95551519412212664555000000000000000000000000
499966555555555555666994555666966966655515111115188117751511ccc6c6cc11151511999a9a9911151519412212664115000000000000000000000000
449996655555555555669994555556666665555515551555177515551555c666c66c155515559aaa9aa915551559411211664555000000000000000000000000
44499665555555555569944455555565565555551115151118851511111516ccccc5151111151a99999515111119411222664511000000000000000000000000
49996655555555555566999455555555555555555515151557751515551515c6661515151115119aaa1515115519421212664515000000000000000000000000
49966555555555555556999455555555555555551515151518851515151515151515151511151115111515111519422112664515000000000000000000000000
49999655555555555556999415b77b55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44496555555556655569994417b7b771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49966655666566966556999417755bb5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4496665666966999666699441bb11775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999669999999999669999417751555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4999999999999949969999941bb51511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44949949994949499994994457751515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5444444444444444444444451bb51515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888777777888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88778877788888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee87777877788888e88888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8777787778888eee8888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee87777877788888e88888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee877788877888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee877777777888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116661611166616161666166688881111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161611161616161611161688881111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116661611166616661661166188881111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111611161611161611161688881111111111111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116111666161616661666161688881111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111117771111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111117777111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822888828228888888888888888888888888888888888888888888888888888888888888822882288882822282288222822288866688
82888828828282888888882888288828888888888888888888888888888888888888888888888888888888888888882888288828828288288282888288888888
82888828828282288888882888288828888888888888888888888888888888888888888888888888888888888888882888288828822288288222822288822288
82888828828282888888882888288828888888888888888888888888888888888888888888888888888888888888882888288828828288288882828888888888
82228222828282228888822282888222888888888888888888888888888888888888888888888888888888888888822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000001010101010101010101010101010100000000000000000000010101010001000000010001000000010101010100010001010101010101000000000000000000010101010101010000000000000000000101010101010000000000000000000000000000000000000000000000000000
0101010000000101010000000000000001010100000001010000000000000000010101000000010101000000000000000000000000000000000000000000000001010101010101000000000000000000010101010100000000000000000000000101010000000000000000000000000000000000000000000000000000000000
__map__
20202020203031202020202020202a2b46484963515151515151466161635151919191919191a1a1a1a1919191919191d1c3e1e1e1e1e1e1e1e1e1e1e1e1c4d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020202020202020202020333232525859606346616351466247476063519191919191a298989898a0a1a1a19191c3e2d5d5d5d5d5d5d5d5d5d5d5d5e0c400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2c2020202020202020202020343a3b52474747506247606352474747475051919191a1a2989898989898989898a091d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
32322020202020202020202020202029524747475447474750524747474760639191a298989898989898838485989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3c26272020202020202020202024295247474764474747506247474747475091a29898989898989898939495989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292020202020242520202020202020295247474747474747644747474747475092989898898a98989898a3a4a5989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292020202020202020202020262720355247474747474747474747474747475092989898999a98989898989898989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2920202020202020202020202020203652474747474747474747474747c9ca5092989880818182989898989898989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2920202020282020202020202020383952474747474747474747474747d9da5096989898989898989898868788989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292020201c1d2020202020202220372952474747474747474747474065654143a6989898989898989898989798989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d202012161a1d20202223201c1d2229524747474747474747475362474760639298989898808181829898a7a8988091d2d5d5d5d5d5d5d6d6d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e21202d2e131a1010101010161a10105247474744474747474747474747475091818298989898989898988081819191d2d5d5d5d5d5d5c0c2d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1b283d3e131313131313131313131352474747504247474447474747474a5091919182989898989898989898989091d2cbccd5d5d5d5d0d2d5d5d5d5c7c8d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
131a101613131313131313131313131352474740434541415642474747475a5091919191829898989898989898809191d2dbdcd5d5d5c0d4d3c2d5d5d5d7d8d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
131313131313131313131313131313134541414351515151514541414141414391919191918181818181818181919191d3c1c1c1c1c1d4c5c6d3c1c1c1c1c1d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
