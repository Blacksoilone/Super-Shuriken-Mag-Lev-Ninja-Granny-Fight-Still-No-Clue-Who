pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- super shuriken maglev ninja granny
-- by pangshunning

function _init()
    map_height=15
    map_width=15
    arena_limit=3
    state="title"
    message_text=nil
    message_timer=0
    score=0
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
    if state =="title" then
        check_start()
    elseif state=="game"then
        player_update(player)
        check_pickup_shoot()
        shurikens_update()
        enemies_update()
        hitpoint()
        if current_map_id=="arena" then
            arena_update()
            
        end
    end
end

function _draw()
    if state =="title" then
        cls()
        map(0,16)
        print("press z to start",34,84)
    elseif state=="game"then
        cls()
        map(maps[current_map_id].map_loc.x,maps[current_map_id].map_loc.y)
        spr(player.sprite,player.x,player.y,1,1,player.face)
        print_shurikens()
        enemies_draw()
        print_killed()
        printhp()
        print_message()
        hp_dec()
        if current_map_id=="arena" then
            arena_draw()
        else
            camera(0,0)
        end
    elseif state=="end" then
        cls()
        camera(0,0)
        map(16,16)
    end

    --print("mem: "..stat(0), 0, 0, 7)
    --debug()
    --debug_collision()
    --debug_draw_platforms()
    --debug_print_path()
    --debug_draw_enemy_path()
    
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

        cooldown=0,

        hp=10,
        hp_cooldown=15,
        hp_dec_time=5
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
            {x=52,y=8},
            {x=104,y=8}
            
        },
        exit_points={
            {x=32,y=96,state="locked"},
            {x=120,y=56,state="unlocked"}
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
            {x=96,y=104},
            {x=64,y=64}
        }
    },
    tree={
        id="tree",
        map_loc={x=32,y=0},
        entry_points={
            {x=8,y=72}
    },
        exit_points={
            {x=96,y=32,state="locked"},
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
            {x=112,y=104,state="locked"}
        },
        enemies={
        }
    },
    arena={
        id="arena",
        map_loc={x=64,y=0},
        entry_points={
            {x=16,y=104}
        },
        exit_points={
            {x=248,y=104,state="locked"}
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
            to="arena",
            to_entry=1
        }
    },
    arena={
        [1]={
            to="cave",
            to_entry=2
        }
    }
}
function teleport(from_exit_index)
    if target_map_id=="arena" then
        map_width=31
    else 
        map_width=15
    end
    local tunnel=tunnels[current_map_id][from_exit_index]
    local entry_points=maps[tunnel.to].entry_points[tunnel.to_entry]
    local target_map_id = tunnel.to
    
    clear_enemies() 
    reset_platform()
    for i in all(shurikens) do 
        del(shurikens,i)
    end
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
    local EXIT_RANGE = 10
    for i, exit_point in ipairs(current_map_data.exit_points) do
        local dx = abs(player.x - exit_point.x)
        local dy = abs(player.y - exit_point.y)
        local distance_squared = dx+dy

        if distance_squared < EXIT_RANGE*2 then
            
            local can_use = (exit_point.state == "unlocked")
            if can_use then
                return i
            else
                if exit_point.state == "locked" then
                    message("This door is locked!",60)
                end
            end
        end
    end
    return nil
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
    player.hp=min(13,player.hp)
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

function hp_dec()
    if player.hp_dec_time>0 then
        spr(7,player.x,player.y,1,1,player.face)
        player.hp_dec_time-=1
    else
        hp_dec_time=0
    end
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
            s.vx=0
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
    check_shuriken_unlock_exit()
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
        x=player.x,--(face_dir==1 and 8 or -4),
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

function arena_update()
    
    local alive_count = 0
    for e in all(enemies) do
        if e.alive then
            alive_count += 1
        end
    end
    
    
    if alive_count == 0 then
        for i = 1, arena_limit do
            local rdx, rdy, d_x, d_y
            repeat 
                rdx = flr(rnd(29)) + 1
                rdy = flr(rnd(13)) + 1
                d_x = abs(rdx - player.x)
                d_y = abs(rdy - player.y)
            until fget(mget(rdx, rdy)) ~= 0 and d_x > 5 and d_y > 5
            add_enemy(rdx * 8, rdy * 8)
        end
    end
    
    
    if #enemies > 5 then
        local to_remove = {}
        for e in all(enemies) do
            if not e.alive then
                add(to_remove, e)
            end
        end
        for e in all(to_remove) do
            del(enemies, e)
        end
    end
end
function arena_draw()
    local cm_x=mid(0,player.x-64,192)
    camera(cm_x,0)
end

function clear_enemies()
    enemies={}
end

-->8
--platforms, for A star
function init_platform()
    for y=0,map_height do
        platform[y] = {}
        for x=0,map_width do
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
    for x=0,map_width do
        platform_grid[x] = {}
    end
end

function reset_platform()

    for y=0,map_height do
        for x=0,map_width do
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
    for x=0,map_width do
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
    

    for j = y_offset+map_height, y_offset, -1 do
        for i = x_offset, x_offset+map_width do
            local cell = mget(i, j)
            

            local local_x = i - x_offset  
            local local_y = j - y_offset  
            
            if fget(cell, 0) then

                platform_grid[local_x][local_y] = {type="unwalkable"}
                platform[local_y][local_x].type = "unwalkable"
            else

                local has_below = (j < y_offset+map_height) and fget(mget(i, j+1), 0)
                local has_left_below = (j < y_offset+map_height and i > x_offset) and fget(mget(i-1, j+1), 0)
                local has_right_below = (j < y_offset+map_height and i < x_offset+map_width) and fget(mget(i+1, j+1), 0)
                
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
--now u can't shoot them 
function check_pickup_shoot()
    local px,py=offset(player.x,player.y)
    local cell=mget(flr(px/8),flr(py/8))
    if cell==214 and not player.able_to_shoot then
        player.able_to_shoot=true
        mset(flr(px/8),flr(py/8),227)
        message("SHURIKEN ACQUIRED!",60)
    end
end

function check_shuriken_unlock_exit()
    local exits = maps[current_map_id].exit_points
    if not exits then return end

    for i, exit in ipairs(exits) do
        if exit.state == "locked" then
            for s in all(shurikens) do
                if colliding(s, {x=exit.x, y=exit.y}) then
                    exit.state = "unlocked"
                    del(shurikens, s)
                    message("DOOR UNLOCKED!",60)
                end
            end
        end
    end
end


-->8
--enemy ai & pathfinding. how could those goomba find u?

enemy_nodes = {}
enemy_edges = {}

function build_platform_graph()
    enemy_nodes = {}
    enemy_edges = {}
    for y=0,map_height do
        for x=0,map_width do
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
                if nx>=0 and nx<=map_width and platform[ny][nx] and platform[ny][nx].type~="air" and platform[ny][nx].type~="unwalkable" then
                    add(enemy_edges[node], {to=find_node(nx,ny), cost=1, type="walk"})
                end
            end
        end

        for dx=-2,2 do
            for dy=-2,2 do
                if abs(dx)+abs(dy)>1 then
                    local tx = node.x+dx
                    local ty = node.y+dy
                    if tx>=0 and tx<=map_width and ty>=0 and ty<=map_height then
                        if can_jump_between(node.x,node.y,tx,ty) then
                            add(enemy_edges[node], {to=find_node(tx,ty), cost=8, type="jump"})
                        end
                    end
                end
            end
        end
        
    end
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
    if e.alive then
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
        for edge in all(enemy_edges[e.path[1]]) do
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
                e.vx = sgn(next_node.x*8 - e.x) * e.max_sp
            else
                e.vx = sgn(next_node.x*8 - e.x) * e.max_sp
            end
        else
            e.vx = sgn(next_node.x*8 - e.x) * e.max_sp
        end
    end

    for s in all(shurikens) do
        if colliding(s, e) then
            e.alive = false
            player.hp+=1
            del(shurikens, s)
            score+=1
            return
        end
    end
end

function enemies_update()
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
        else
            picmove(e,0,4,nil,nil)
        end
    end
end

function enemies_draw()
    for e in all(enemies) do
        if e.alive then
            spr(12, e.x, e.y)
        else 
            spr(13, e.x, e.y)
        end
    end
end

-->8
--before that u were the undead
function hitpoint()
    player.hp_cooldown-=1
    if player.hp_cooldown<0 then
        player.hp_cooldown=0
    end
    for i in all(enemies) do
        if colliding(player,i) and player.hp_cooldown==0 and i.alive then
            player.hp_cooldown=15
            player.hp-=1
            player.hp_dec_time=3
        end
    end
    if player.hp==0 then
        state="end"
    end
end
function printhp()
    local oldcx,oldcy=camera()
    camera(0,0)
    for i =1,player.hp,1 do
        spr(8,4*i,4)
    end
    camera(oldcx,oldcy)
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

function heuristic(a,b)
    return abs(a.x-b.x)+abs(a.y-b.y)
end

function contains(tbl, val)
    for v in all(tbl) do
        if v==val then 
            return true 
        end
    end
    return false
end

function colliding (a, b)
    return not (a.x > b.x + 8 or
                a.x + 8 < b.x or
                a.y > b.y + 8 or
                a.y + 8 < b.y)
end

function message(m,t)
    message_text=m
    message_timer=t or 60
end

function print_message()
    if message_timer > 0 and message_text then
        print(message_text, player.x-16, player.y-8, 7)
        message_timer -= 1
        if message_timer <= 0 then
            message_text = nil
        end
    end
end

function find_node(x,y)
    for n in all(enemy_nodes) do
        if n.x==x and n.y==y then return n end
    end
    return nil
end

function check_start()
    if(btn(🅾️)) then
        state="game"
    end
end
function print_killed()
    local oldcx,oldcy=camera()
    camera(0)
    spr(9,92,8)
    print(":"..score,100,10,8)
    camera(oldcx,oldcy)
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
    print("hpcd:"..player.hp_cooldown, 0, 56, 8)
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
    
    for y=0,map_height do
        if not platform[y] then break end
        for x=0,map_width do
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

function debug_draw_enemy_path()
    for e in all(enemies) do
        if e.path and #e.path > 1 then
            for i=2,#e.path do
                local a = e.path[i-1]
                local b = e.path[i]
                
                local edge_type = "walk"
                for edge in all(enemy_edges[a]) do
                    if edge.to == b then
                        edge_type = edge.type
                        break
                    end
                end
                local color = edge_type=="walk" and 8 or 7
                line(a.x*8+4, a.y*8+4, b.x*8+4, b.y*8+4, color)
            end
        end
    end
end


__gfx__
00000000b0666660b0666660b0666660806666608066666080666660575555570000000080044008000000000007700000044000000000000000000000000000
000000000bbbb1b00bbbb1b00bbbb1b0088881800888818008888180700000070111110008744480077707700007770000744400000000000000000000000000
00700700006fffff006fffff006fffff006fffff006fffff006fffff770000051181811007844840077777700777770007444440007000000000000000000000
00077000992ffff0992ffff0992ffff0992ffff0992ffff0992ffff0500000071878881044188144007007707770077744144144071880000000000000000000
000770009222d2009222d2009222d2009222d2009222d2009222d200500000771188811044188144077007007770077744144144841488800000000000000000
0070070092f2d2f0922fd2f092f2d22f92f2d2f0922fd2f092f2d22f500000070118110004844840077777700077777004444440844444440000000000000000
0000000099dddd0099dddd0099dddd0099dddd0099dddd0099dddd005000007700111000081ff1800770777000777000001ff1000848f1400000000000000000
0000000000f00f0000f00f0000f00f0000f00f0000f00f0000f00f00775775700000000081100118000000000007700001100110099809900000000000000000
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
1efeefefffefeefffefeeff1feed55551ffeeff15555deef5555555511111111dd5444449494556511111111dffffff7d6666667151515150000000000000000
feeefeeeeeeeeeeeeeedeeeffed5d565eeeeeeef565d5def56555655111111115d5449444444dddd111111112dffff7f5d666676151515150000000000000000
fedddeddefddedddddedddefedde6555feeddeef5556edde5556555511111111deedd441113ddeed1bbbb11122eeeeff55dddd66155515550000000000000000
eeddd5ddedddedddddeddeeedd555555fee55eee555555dd555555d511111111de5d111111b33eed1b33bb1122eeeeff55dddd66151515150000000000000000
ededddd5dddddded5dddeede5d555555edd55ede555555d5555555dd11111111ee3b1111111131ee1b3bbbbb22eeeeff55dddd66151515150000000000000000
fdddd5555ddd5de5555ddddf55556555eeed5ddf555655555556edde11111111ed1b11111113b3ed1b36b66622eeeeff55dddd66551555150000000000000000
fed5d56555d555d5555dddef55655565fed55def56555655565d5def11111111e11311111113131e1b3bbbbb221111ef551111d6151515150000000000000000
eedd555555565555565dddde55555555f65555de555555555555deef11111111f11311111113133f1b3bbbbb2111111e5111111d151515150000000000000000
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
d99949d99449d4499d44992d11212215dd5d25d5dd21221218888888888777788888888211212212112125120007666666660000076666666666660000000000
22952949d494994594d252dd2121221d5ddddddddd5d221288888888888888888888888821212212212125520076666666666000076666666666666000000000
d225254444d4594d4452522d212112dd5dd9999cdd5dd51188888877888888888888888821211214447115510766000000076600076000000000766000000000
5d2d4544445454d44454d2d2212212dddd99cccccdd2d51188887777788888888888877821221244744445110760000000007600076000000000076000000000
d2254554455454dd4554552d211115dd9cccccc77cddd55588887777778888888888877721111999444444220760000000000700076000000000076000000000
d2524554455444dd455425dd2121151dccccc77777cdd5d588887777788887777888877721219a99944444420760000000000000076000000000766000000000
d255d455554d544d554d525d1255ddddcccccc777cccddd21222111216668777788887721229a999999444420760000000000000076666666666666000000000
dd2d45544545d445454dd22d112115ddccccccccccccd5d2454dd22d166666661121121211999999999944440760000007666660076666666666660000000000
2dd444545d44454555444d2d11215ddc7777ccccccccd5d25544442d1666676211212212199a9999999994450760000000076600076007660000000000000000
d2d54555454455455452552d21215d9777777cccccccd512545244cc666676122121221229999944499994450760000000006600076000766000000000000000
d2d5455445d454454452522d2121dd9c77ccccccccc9d511445249cc666766112121121199a99446649994510760000000006600076000076660000000000000
dd2d45444454d4544454d2d22155dd99cccccccbbc99d21144229cc1666672112122121199999466549994510076000000076600076000007666000000000000
d22525544d545455455452dd211dddd999ccccccbbdd15524524ccc26667622221111222999994655499d5220076666666666000076000000076666000000000
dd222454455444d5455422dd212115ddd9ccccccc9ddd51242249cc1666676122121121229999465549d12120000766666660000076600000007660000000000
d225d45555455445554d522d122211d5dccccccccd55dd12552d9cc21666777712221112122dddddd4d211120000000000000000000000000000000000000000
dd24d4544545d445454dd2dd112112d5ddccc2cc9d51d512452dccc2166666777721187200000000000000000000000000000000000000000000000000000000
2dd444555d44454554444dd2112122d5ddd999c99d5155125229ccc2116666676761878800000007600000000760000000007600076000000000076000000000
d2d52445454455455452552d212122155dddd999dd51521254229cc2212666666676226200000076660000000766000000000760076600000000766000000000
d2d5244445d454454442522d212112115d5ddddddd211211445299cc2cc716666677677100000076660000000766600000000760007660000007660000000000
2d2d45454454d4545454d2d2212212112d55d51d5d5212114454229cc7cc72166666776100000766666000000766660000000760000766000076600000000000
dd2445151d145451515442dd21111222211dd55255111222455452dc7c6612226666667200000760076000000760766000000760000076600766000000000000
d2141411111141d14151412d21211212215d151221211212455422dd212662126666676700007660076600000760076600000760000007666660000000000000
111111111111111111111111122211121222111212221112554d522d122266121666667700007600007600000760007660000760000000766600000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000007600007600000760000766000760000000076000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000076600007660000760000076600760000000076000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000076666666660000760000007660760000000076000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000766666666666000760000000766660000000076000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000766000000766000760000000076660000000076000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007660000000076600760000000007660000000076000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007660000000076600076000000000700000000766600000000000000
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
44496555555556655569994417b7b771000076000076000000766666666666000766000000007660000007666660000000000000000000000000000000000000
49966655666566966556999417755bb5000076000076000007666666666666600760000000000760000766666666600000000000000000000000000000000000
4496665666966999666699441bb11775000766000076600007660000000000000760000000000760007666000076660000000000000000000000000000000000
49999669999999999669999417751555000766600766600007600000000000000766000000007660007600000000760000000000000000000000000000000000
4999999999999949969999941bb51511007600767600760007600000000000000076000000007600076600000000766000000000000000000000000000000000
44949949994949499994994457751515007600767600760007660000000000000076600000076600076000000000076000000000000000000000000000000000
5444444444444444444444451bb51515007600767600760007666666666660000007600000076000076000000000076000000000000000000000000000000000
00000000000000000000000000000000007600767600760007666666666666000007660000766000076000000000076000000000000000000000000000000000
00000000000000000000000000000000007600767600760007660000000000000000760000760000076000000000076000000000000000000000000000000000
00000000000000000000000000000000007600766600760007600000000000000000766007660000076600000000766000000000000000000000000000000000
00000000000000000000000000000000076600766600676007600000000000000000076007600000007600000000760000000000000000000000000000000000
00000000000000000000000000000000076000076000076007660000000000000000076666600000007666000076660000000000000000000000000000000000
00000000000000000000000000000000076000076000076007666666666666000000007666000000000766666666600000000000000000000000000000000000
00000000000000000000000000000000076600076000766000766666666666600000000760000000000007666660000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
c000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000c
c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccc
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccc
c000000000000066666066006606666600666666066666000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccc0000c
c0000000000006111116116611611111661111116111116000000000000000000000000000cccccccccccccccccccccccccccccccccccccc000000000000000c
c00000000000619aaaa19a119a19aaaa119aaaaa19aaaa160000000000000000000cccccccccccccccccccccccccccccccccc00000000000000000000000000c
c0000000000619a111119a119a19a119a19a111119a119a16000000000000cccccccccccccccccccccccccccccc000000000000000000000000000000000000c
c0000000000619a111619a119a19a119a19a111619a119a160000ccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000c
c00000000000619aaa119a119a19aaaa119aaaa119aaaa16cccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000c
c00000000000061119a19a119a19a111619a111619a9a16cccccccccccc00000000000000000000000000000000000000000000000000000000000000000000c
c00000000000611119a19a119a19a166019a111119a19a16c000000000000000000000000000000000000000000000000000000000000000000000000000000c
c0000000000619aaaa1619aaa119a16cc19aaaaa19a119a16000000000000000000000000000000000000000000000000000000000000000000000000000000c
c000000000006111116c61111777777770777711777777770077770777777770777777777007700077770777777770777700777700000000000000000000000c
c00000ccccccc666660006667111111117111177111111117711117111111117111111111771170711117111111117111177111170000000000000000000000c
ccccccc000000000000000071167777711167177167116717716711167777711167777771116717116711677777711167177167170000000000000000000000c
c000000000000000000000071677777771167177167116717716711677777771167777777116711167111677777771167117167170000000000000000000000c
c000000000000000000000071671111111167177167116717716711671111671111167111116711671171671111111167711167170000000000000000000000c
c000000000000000000000071671111111167111167116717716711671111671777167177716716711771671111177167771167170000000000000000000000c
c000777770000000007777071677777711167777777116717716711677777771707167170716777117071677777117167677167170000000000000000000000c
c007666667000000076666771167777771167777777116717716711677777711707167170716777117071677777717167167777170000000000000000000000c
c000766667000000007666707111111671167111167116717716711671677117777167177716716711771671111117167116777170000000000000000ccccccc
c000076666700000007666771111111671167177167116711116711671167711111167111716711671171671111117167111677170000000000ccccccccccc0c
c000076666670000007666771677777771167177167116777777711671116771167777771116711167111677777711167171167170000cccccccccccccc0000c
c00007666666700000766677116777771116717716711167777711167171167116777777711671711671116777777116717716717ccccccccccccccc0000000c
c00007666666670000766670711111111711117711117111111117111177111111111111111111d7111171111111111111771111d77777777c7770000000000c
c0000766676666700076667007777777707777007777077777777077770077777777777777ddeeddddddddddd7dddddd77c7ddeeddddddddd7ddd7000000000c
c000076667766667007666700000000000000000000000000000000000000000000000007ddeeedddeeedeeedddeeeedd77ddeedddeeedded7ded7000000000c
c00007666707666670766670077000000007700000000000000000000000000000000007ddeededdeededdddeddeddded7ddeedd7deddeded7ded7000000000c
c0000766670076666776667076670000007667000000000000000000000000000000007ddeeddedeeddedeeeeddedddedddeedd77deeeededdded7000000000c
c0000766670007666676667076677777707667077777000000000000000000000000cc7deedddeeedddededdeddedddeddeeddddddedddddededd7000000000c
c00007666700007666666670077766666707707666667000000000000000000ccccccc7dedd7deedd7dedeeeeeddeeeeddeeeeeeeddeeedddedd70000000000c
c00007666700000766666670766766776676677777667000000000000cccccccccccccc7dd77dddd77dddddddddddddeddddddddddddddd7ddd700000000000c
c00007666700000076666670766766776676676666667000000ccccccccccccccccccccc77cc7777cc777777777dddded777777777777770777000000000000c
c00007666700000007666670766766776676676677667ccccccccc77777777cccccccccccccccc0000000000007deeedd700000000000000000000000000000c
c00007666700000000766667766766776676676677667cccccccc7222222227ccccccccc0000000000000000007ddddd7000000000000000000000000000000c
c00007666670000000766666666666666666666666667ccccccc72222222227cc00000000000000000000000000777770000000000000000000000000000000c
c00000777700000000077777777777777776677777767cccccc7222222222227000000000000000000000000000000000000000000000077000000000000000c
c000000000000000000000cccccccccc777667ccccc7ccccccc7222222222222700000000000000000000000000000000000000007777722770000000000000c
c000000000000000ccccccccccccccc7666667cccccccc777707222222222222270000000777777777000000000000000000000772222266667000000000000c
c000000000cccccccccccccccccccccc76667c77777707222277222222222222270000077222222222700000077770077777707666222268867000000000000c
c000ccccccccccccccccccccccccccccc7777766666672222222222222222222227000722222222222700077766667766666677686622268866700000000000c
cccccccccccccccccccccccccccc000000776668888666662222222222222222227777222222222222277766668866668888666668662266886700000000000c
ccccccccccccccccccccccc00000007777666888888888866222222222222222222222226666226666666668866688888888888668862226886700000000000c
ccccccccccccccccc00000000000072266688886666888886622222222222222222226666886626888866888886668886666688668862226886700000000000c
ccccccccccc0000000000000000072266888866622666888866626666622222222226688888866666888888688866688622268866886222688670000000000cc
cccc0000000000000000000000072226888666222222666688866688866666666226688886688622668866666886268862226886688622268867777ccccccccc
c00000000000000000000000007222668886222222222226688866886668888866668886666886222688622268862688622268866886222688662227cccccc0c
c000000000000000000000000072226888662222222222226888668866888888866888662268862226886222688626886622688668866226688622270000000c
c000000000000000000000000722266886622222222222226688668888866668886886622268862226886622688666888622668866886222688622227000000c
c000000000000000000000000722268886222222222222222666668888662266666886622268866226688622668866688622268866886622688622227000000c
c000000000000000000000000722268866222222222222222226668886622222226688622266886222688622268862688622268866688666688622222700000c
c000000000000000000000007222268862222222222266666666866886222222222688622226886222688622268862688622268862688888888622222700000c
c000000000000000000000007222268866222222222268888888866886222222222688622226886222688622268862688622268862666888888622222700000c
c000000000000000000000007222268886222222222268888888866886222222222688622226886622688622268862688622268862226666688662227000000c
c000000000000000000000007222266886222222222266666688866886222222222688622266888662688622268862688622266662222222668867770000000c
c000000000000000000000007222226886622222222222226688866886222222222688666668888866688622266862666622222226666666688867000000000c
c000000000000000000000007222226688662222222222266888866886222222222688668888886888668622226662222266666666888888886667000000000c
c000000000000000000000000722222688866222222222268888866886622222222668888888866666666622222666666668888888888888866770000000000c
c00000000000000000000cccc722222668886662222226668886886688622222222266886666662222226666666688888888888888666666667000000000000c
c00000000000000ccccccccccc72222266888866622666888866886688622222222226666222266666666888888888888886666666677777770000000000000c
c00000000cccccccccccccccccc7222226688888666688886668886688622222222222666666668888888888888866666666777777700000000000000000000c
cccccccccccccccccccccccccccc772222668888888888666266666666622226666666688888888888888666666662222777000000000000000000000000000c
cccccccccccccccccccccccccccccc7777766666888866622222222266666666888888888888886666666622222222227000000000000000000000000000000c
ccccccccccccccccccccccccccccccccc0072226666662222266666668888888888888866666666222222222227222227000000000000000000000000000000c
ccccccccccccccccccccccccccc0000000007222222666666668888888888888666666667777777722222222270777770000000000000000000000000000000c
cccccccccccccccccccccc000000000000007266666688888888888886666666622222770000000077722227700000000000000000000000000000000000000c
ccccccccccccccccc00000000000000000007268888888888866666666777777222222700000000000077770000000000000000000000000000000000000000c
ccccccccccc00000000000000000000000000766668666666662277777000000777777000000000000000000000000000000000000000000000000000000000c
cccccc0000000000000000000000000000000722266622222222270000000000000000000000000000000000000000000000000000000000000000000000000c
c000000000000000007777700000007777700077222222222222270000000000000000000000000000000000000000000000000000000000000000000000000c
c00000000000000007aaaaa7000007aaaaa707aaaaaaaaaaaaa270000000000000007777777777000000000000000000000000077777777770000000cccccccc
c00000000000000007aaaaa700007a7aaa707aa7aaaaaaaaaaa700000000000000074444444444700000000000000000000000744444444447cccccccccccccc
c00000000000000007a7aaa7000077aaaa77aa7aaaaaaaaaaaa7000000000000007744444444447700000000000000000cccc77444444444477ccccccccccc0c
c00000000000000007a7aaa70007a7aaa707a7aaaaaaaaaaaaa7000000000000074444444444444470000ccccccccccccccc7444444444444447cccccc00000c
c00000000000000007a7aaa700077aaaa707a7aaa77777a7aaa7000000000000774444444444444477ccccccccccccccccc7744444444444444770000000000c
c00000000000000007a7aaa7007a7aaa707aa7aa70007a7aaa700000000000c74444444444444444447ccccccccccccccc74444444444444444447000000000c
c00000000000000007a7aa700077aaa7007a7aaa70007a7aaa7ccccccccccc7744444444444444444477ccccccccccccc774444444444444444447700000000c
c0000000000000007aa7aa7007a7aaa7007a7aaa7ccc7aaaaa7cccccccccc744444444444444444444447ccccccccccc7444444444444444444444470000000c
c0000000000000007a7aaa707a7aaa7cc7aa7aaaa7ccc77777cccccccccc77444444444444444444444477cc000000077444444444444444444444477000000c
c0000000000000007a7aaa7c7a7aaa7cc7aa7aaaaa7cccccccccccccccc74411114444444444444411114470000000744111144444444444444111144700000c
c0000ccccccccccc7a7aaa77a7aaa7ccc7aaaaaaaaa77ccccccccccccc774411114444444444444411114477000007744111144444444444444111144770000c
cccccccccccccccc7a7aaa77a7aa7ccccc7aaaaaaaaaa7cccccccc0007444444ff11444444444411ff44444470007444444ff11444444444411ff4444447000c
cccccccccccccccc7a7aaa7a7aaa7cc000077aaaaaaaaa700000000007444444ff11444444444411ff44444470007444444ff11444444444411ff4444447000c
ccccccccccccc0007a7aaa7a7aa70000000007aaaaaaaaa70000000007444444ff11111111111111ff44444470007444444ff11111111111111ff4444447000c
cc000000000000007a7aa7a7aaa700000000007aa777aaa70000000077444444ff11111111111111ff44444477077444444ff11111111111111ff4444447700c
c0000000000000007aaaaaa7aa70000000000007aaa7aaa70000000744444444ff11ff444444ff11ff44444444744444444ff11ff444444ff11ff4444444470c
c0000000000000007aaaaa7aa70000077777000077aaaaa70000000744444444ff11ff444444ff11ff44444444744444444ff11ff444444ff11ff4444444470c
c0000000000000007a7aaaaaa700007aaaaa70007aa7aa700000000744444444ffffff444444ffffff44444444744444444ffffff444444ffffff4444444470c
c000000000000007aa7aaaaa7000007aa7aa70007a7aaa700000000744444444ffffff444444ffffff44444444744444444ffffff444444ffffff4444444470c
c000000000000007a7aaaaaa7000007a7aaa77777a7aaa700000000744444444444444444444444444444444447444444444444444444444444444444444470c
c000000000000007a7aaaaa7000007aa7aaaaaaaa7aaa7000000000744444444444444444444444444444444447444444444444444444444444444444444470c
c000000000000007a7aaaa70000007a7aaaaaaaaa7aaa700000000007744444444ffffffffffffff444444447707744444444ffffffffffffff444444447700c
c000000000000007aaaaaa70000007a7aaaaaaaaaaaa7000000000000744444444ffffffffffffff444444447000744444444ffffffffffffff44444444700cc
c000000000000007aaaaa700000007aaaaaaaaaaaaa700000000000000777777ffffffffffffffffff77777700000777777ffffffffffffffffff777777ccccc
c000000000000000777770000000007777777777777000000000000000007777ffffffffffffffffff77770000000007777ffffffffffffffffff7777cc0000c
c000000000000000000000000000000000000000000000000000000000071111ffffffffffffffffff11117000000c71111ffffffffffffffffff1111700000c
c000000000000000000000000000000000000000000000000000000000771111ffffffffffffffffff111177ccccc771111ffffffffffffffffff1111770000c
c0000000000000000000000000000000000000000000000cccccccccc71111111111ffffffffff1111111111700071111111111ffffffffff11111111117000c
c00000000000000000000000000cccccccccccccccccccccccccccccc71111111111ffffffffff1111111111700071111111111ffffffffff11111111117000c
c00000000000000cccccccccccccccccccccccccccccccccccccccccc7111111111111ffffff11111111111170007111111111111ffffff1111111111117000c
c000000cccccccccccccccccccccccccccccccccccccccccccccccc007111111111111ffffff11111111111170007111111111111ffffff1111111111117000c
cccccccccccccccccccccccccccccccccccccccccccc00000000000000771111111111ffffff11111111117700000771111111111ffffff1111111111770000c
cccccccccccccccccccccccccccccccc00000000000000000000000000071111111111ffffff11111111117000000071111111111ffffff1111111111700000c
ccccccccccccccccccccc0000000000000000000000000000000000000007777777777777777777777777700000000077777777777777777777777777000000c
cccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccc
c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccc00c
c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccc00000000c
c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccc0000000000000c
c00000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccc0000000000000000000c
c0000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccc0000000000000000000000000c
c000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000c
c000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000c
c00000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000c
c00000000000000000000000000000ccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000c
c0000000000000000000ccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000c
c0000000000ccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
ccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
ccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
cccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0000000000000000000000000000000001010101010101010101010101010100000000000000000000010101010001000000010001000000010101010100010001010101010101000000000101000000010101010101010000000000000000000101010101010000000000000000000000000000000000000000000000000000
0101010000000101010000000000000001010100000001010000000000000000010101000000010101000000000000000000000000000000000000000000000001010101010101000000000000000000010101010100000000000000000000000101010000000000000000000000000000000000000000000000000000000000
__map__
20202020203031202020202020202a2b46484963515151515151466161635151919191919191a1a1a1a1919191919191d1c3e1e1e1e1e1e1e1e1e1e1e1e1c4d14b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b00000000000000000000000000000000000000000000000000000000000000
20202020202020202020202020333232525859606346616351466247476063519191919191a298989898a0a1a1a19191c3e2d5d5d5d5d5d5d5d5d5d5d5d5e0c44b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
2b2c2020202020202020202020343a3b52474747506247606352474747475051919191a1a2989898989898989898a091d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
32322020202020202020202020202029524747475447474750524747474760639191a298989898989898838485989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
3b3c26272020202020202020202024295247474764474747506247474747475091a29898989898989898939495989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
292020202020242520202020202020295247474747474747644747474747475092989898898a98989898a3a4a5989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
292020202020202020202020262720355247474747474747474747474747475092989898999a98989898989898989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
2920202020202020202020202020203652474747474747474747474747c9ca5092989880818182989898989898989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4c4c4c4d4d4c4c4c4c4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
2920202020282020202020202020383952474747474747474747474747d9da5096989898989898989898868788989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c4c4c4c4c4c4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
292020201c1d2020202020202220372952474747474747474747474065654143a6989898989898989898989798989890d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d04b4c4c4c4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
1d202017161a1d20202223201c1d2229524747474747474747475362474760639298989898808181829898a7a8988091d2d5d5d5d5d5d5d6d6d5d5d5d5d5d5d04b4d4d4d4d4d4d4d4d4c4c4c4c4d4d4d4c4c4c4d4d4d4d4d4d4d4d4d4d4d4d4d4b00000000000000000000000000000000000000000000000000000000000000
1e2120342d2e1a1010101010161a10105247474744474747474747474747475091818298989898989898988081819191d2d5d5d5d5d5d5c0c2d5d5d5d5d5d5d04b4d4d4d4d4c4c4c4c4c4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c4c4c4d4d4b00000000000000000000000000000000000000000000000000000000000000
1a1b23283d3e1313131313131313131352474747504247474447474747474a5091919182989898989898989898989091d2cbccd5d5d5d5d0d2d5d5d5d5c7c8d04bc9ca4d4d4d4d4d4d4d4d4d4d4c4c4c4d4d4d4c4c4c4d4d4d4d4d4d4d4dc7c84b00000000000000000000000000000000000000000000000000000000000000
131a101613131313131313131313131352474740434541415642474747475a5091919191829898989898989898809191d2dbdcd5d5d5c0d4d3c2d5d5d5d7d8d04bd9da4d4c4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c4c4d4d4d4d4dd7d84b00000000000000000000000000000000000000000000000000000000000000
131313131313131313131313131313134541414351515151514541414141414391919191918181818181818181919191d3c1c1c1c1c1d4c5c6d3c1c1c1c1c1d44b4c4c4c4c4d4d4d4d4d4c4c4c4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4d4c4c4b00000000000000000000000000000000000000000000000000000000000000
131313131313131313131313131313135151515151515151515151515151515191919191919191919191919191919191d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d14b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b00000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20008b8c8d8ea9aaabacabacadae002020008b8c00a9aa0000e4e500e6e70020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20009b9c9d9eb9babbbcbbbcbdbe002020009b9c00b9ba0000f4f500f6f70020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000eaebe8e9e6e78d8e00000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000fafbf8f9f6f79d9e00000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
200000000000000400000a000000002020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000c000d2020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
201210174041420000808182c0c1c22020000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
