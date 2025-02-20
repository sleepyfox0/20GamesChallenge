import Vector2, lerp from require "data/gmath"
LIMIT_Y = 18*16 - 32

class PlayerColission
    new: (player, map) =>
        @player = player
        @map = map
    
    ----------------------------------------------------------------------------------------------- FALL CHECK
    checkFall: (next, pos, nv) =>
        -- check falling
        @player.onground = false
        @player.state = "falling"

        left_scan = @player.pos.x
        right_scan = left_scan + 15
        left_scan = math.floor(left_scan / 16)
        right_scan = math.floor(right_scan / 16)

        sy = math.floor((@player.pos.y + 32) / 16)
        maxY = @map.height
        for x=left_scan, right_scan
            y = sy
            while y < @map.height
                idx = (y*@map.width) + x + 1
                tile_id = @map.data[idx]
                if @map\isColission tile_id
                    maxY = math.min maxY, y
                    break
                y += 1
        maxYStep = maxY * 16
        cpy = maxYStep - 32
        if math.abs(cpy) < math.abs(next.y)
            @player.onground = true
            @player.state = "onground"
            @player.grav = 0
        next.y = math.min(next.y, cpy) -- some better math
    
    ----------------------------------------------------------------------------------------------- JUMP CHECK
    checkJump: (next, pos, nv) =>
        @player.onground = false

        left_scan = @player.pos.x
        right_scan = left_scan + 15
        left_scan = math.floor(left_scan / 16)
        right_scan = math.floor(right_scan / 16)

        sy = math.floor((@player.pos.y) / 16)
        maxY = 0
        for x=left_scan, right_scan
            y = sy
            while y > 0
                idx = (y*@map.width) + x + 1
                tile_id = @map.data[idx]
                if @map\isColission tile_id
                    maxY = math.max maxY, y
                    break
                y -= 1
        maxYStep = maxY * 16
        cpy = maxYStep + 16
        if cpy > next.y
            next.y = cpy
            @player.grav = lerp @player.grav, 0, 0.25
    
    ------------------------------------------------------------------------------------------------ LEFT CHECK
    checkLeft: (next, pos, nv) =>
        up_scan = @player.pos.y
        down_scan = up_scan + 31
        up_scan = math.floor(up_scan / 16)
        down_scan = math.floor(down_scan / 16)

        sx = math.floor((@player.pos.x) / 16)
        maxX = 0
        for y=up_scan, down_scan
            x = sx
            while x > 0
                idx = (y*@map.width) + x + 1
                tile_id = @map.data[idx]
                if @map\isColission tile_id
                    maxX = math.max maxX, x
                    break
                x -= 1
        maxXStep = maxX * 16
        cpx = maxXStep + 16
        next.x = math.max(next.x, cpx)
    
    ------------------------------------------------------------------------------------------------ RIGHT CHECK
    checkRight: (next, pos, nv) =>
        up_scan = @player.pos.y
        down_scan = up_scan + 31
        up_scan = math.floor(up_scan / 16)
        down_scan = math.floor(down_scan / 16)

        sx = math.floor((@player.pos.x + 16) / 16)
        minX = @map.width
        for y=up_scan, down_scan
            x = sx
            while x < @map.width
                idx = (y*@map.width) + x + 1
                tile_id = @map.data[idx]
                if @map\isColission tile_id
                    minX = math.min minX, x
                    break
                x += 1
        minXStep = minX * 16
        cpx = minXStep - 16
        next.x = math.min(next.x, cpx)
    
    ------------------------- ALL COLLISIONS --------------------------------------------------------------------
    checkColission: =>
        next = @player.next
        pos = @player.pos
        nv = next - pos
        -- try real collision please
        if nv.x < 0
            @checkLeft next, pos, nv
        elseif nv.x > 0
            @checkRight next, pos, nv
    
        if nv.y > 0
            @checkFall next, pos, nv
        elseif nv.y < 0
            @checkJump next, pos, nv
            

{:PlayerColission}