clamp = (t, min, max) ->
    math.min(max, math.max(min, t))

overlap = (x1, y1, w1, h1, x2, y2, w2, h2) ->
    return false if x2 > x1+w1 or x2+w2 < x1
    return false if y2 > y1+h1 or y2+h2 < y1
    true

lerp = (v1, v2, t) ->
    (1 - t) * v1 + t * v2

DRAW_AABB = false

class Vector2
    new: (x=0, y=0) =>
        @x = x
        @y = y
    
    -- Arithmetic
    __add: (b) =>
        Vector2 @x+b.x, @y+b.y
    
    __sub: (b) =>
        Vector2 @x-b.x, @y-b.y
    
    __mul: (b) =>
        if type(@) == "number"
            return Vector2 @*b.x, @*b.y
        if type(b) == "number"
            return Vector2 @x*b, @y*b
        -- assume two vectors
        Vector2 @x*b.x, @y*b.y
    
    -- misc
    __len: =>
        math.sqrt (math.pow(@x, 2) + math.pow(@y, 2))
    
    len: =>
        math.sqrt (math.pow(@x, 2) + math.pow(@y, 2))
    
    __tostring: =>
        "Vector2( x = #{@x}, y = #{@y} )"
    
    -- Vector Functions
    norm: =>
        l = @\len!
        Vector2 @x/l, @y/l
    
    rotate: (r) =>
        cs = math.cos r
        ss = math.sin r
        x = @x * cs + @y * -ss
        y = @x * ss + @y * cs
        Vector2 x, y
    
    moveTo: (t=1, v=Vector2!) =>
        x = lerp @x, v.x, t
        y = lerp @y, v.y, t
        Vector2 x, y
    
    copy: =>
        Vector2 @x, @y

class AABB
    new: (x, y, w, h) =>
        @pos = Vector2 x, y
        @dim = Vector2 w, h
    
    updatePosition: (pos) =>
        @pos = pos
    
    pointIn: (p) =>
        x, y = @pos.x, @pos.y
        w, h = @pos.x+@dim.x, @pos.y+@dim.y
        return false if p.x < x or p.x > w
        return false if p.y < y or p.y > h
        true
    
    colides: (aabb) =>
        x1, y1 = @pos.x, @pos.y
        w1, h1 = @dim.x, @pos.y

        x2, y2 = aabb.pos.x, aabb.pos.y
        w2, h2 = aabb.dim.x, aabb.dim.y

        overlap x1, y1, w1, w2, x2, y2, w2, h2

    draw: =>
        return unless DRAW_AABB
        r, g, b, a = love.graphics.getColor!
        love.graphics.setColor 0.1, 0.25, 0.75, 0.5
        love.graphics.rectangle "fill", @pos.x, @pos.y, @dim.x, @dim.y
        love.graphics.setColor r,g,b,a

{:clamp, :overlap, :lerp, :Vector2, :AABB}