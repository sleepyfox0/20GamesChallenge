G = love.graphics

class TileData
    new: (id, collision=false)=>
        @id = id
        @collision = collision

class TileSet
    new: =>
        @img = G.newImage "assets/platformer/images/tiles.png"
        width = @img\getWidth!
        height = @img\getHeight!
        w = width / 16
        h = height / 16
        @tiles = {}
        for y=1, h
            for x=1, w
                xs = (x-1) * 16
                ys = (y - 1) * 16
                quad = G.newQuad xs, ys, 16, 16, @img
                table.insert @tiles, quad
        ts_data = require("assets/platformer/maps/tiles")
        tiles_d = ts_data.tiles
        @data = {}
        for t in *tiles_d
            id = t.id + 1
            colission = false
            for k, v in pairs(t.properties)
                if k == "col"
                    colission = v
            @data[id] = TileData(id, colission)

tile_set = TileSet!

class MapData
    new: (width, height, data, para) =>
        @width = width
        @height = height
        @data = data
        @para = para
    
    isColission: (idx) =>
        --print "#\t#{idx}"
        return false if idx == 0
        td = tile_set.data[idx]
        --print "#\t\t#{td}"
        return false unless td
        --print "#\t#{td.collision}"
        td.collision
    
    drawPara: =>
        return unless @para
        for x=1, @width
            xx = (x-1) * 16
            for y=1, @height
                yy = (y-1) * 16
                idx = (y-1)*@width + x
                continue if @para[idx] == 0
                --print @data[idx]
                G.draw tile_set.img, tile_set.tiles[@para[idx]], xx, yy

    draw: =>
        for x=1, @width
            xx = (x-1) * 16
            for y=1, @height
                yy = (y-1) * 16
                idx = (y-1)*@width + x
                continue if @data[idx] == 0
                --print @data[idx]
                G.draw tile_set.img, tile_set.tiles[@data[idx]], xx, yy

load_map = (path) ->
    map_data = require(path)
    width = map_data.width
    height = map_data.height
    
    --data = map_data.layers[1].data
    data = {}
    para = nil
    for i, v in ipairs(map_data.layers)
        print v.name
        if v.name == "base"
            data = v.data
        if v.name == "para"
            para = v.data
    --field = data
    MapData width, height, data, para

class Camera
    new: (player, map) =>
        @tx = 0
        @ty = 0
        @player = player
        @map = map
        @width = map.width*16
        @height = map.height*16
    
    update: =>
        pos = @player.pos
        -- center on player
        tx = pos.x - 320/2
        ty = pos.y - 180/2

        @tx = math.floor tx
        @ty = math.floor ty

        @tx = @tx < 0 and 0 or @tx
        @ty = @ty < 0 and 0 or @ty

        @tx = @tx + 320 > @width and @width - 320 or @tx
        @ty = @ty + 180 > @height and @height - 180 or @ty

    apply: =>
        G.push!
        G.translate -@tx, -@ty
    
    applyParalax: =>
        G.push!
        tx = math.floor @tx/2
        ty = math.floor @ty/2
        G.translate -(tx), -(ty)

    detach: =>
        G.pop!

{:load_map, :Camera}
            