import floor from math
import Vector2 from require "data/gmath"

G = love.graphics

particle = G.newImage "assets/particle.png"
particle\setFilter "nearest", "nearest"

draw_line = (v1, v2, t=Vector2(0, 0), r=0) ->
    vec1 = v1\rotate r
    vec2 = v2\rotate r
    vec1 = vec1 + t
    vec2 = vec2 + t
    x1 = floor vec1.x
    y1 = floor vec1.y
    x2 = floor vec2.x
    y2 = floor vec2.y
    G.line x1-0.5, y1-0.5, x2, y2

class VectorPainter
    new: =>
        @vlist = {}
    
    add: (v, y) =>
        if type(v) == "number"
            table.insert @vlist, Vector2(v, y)
            return
        table.insert @vlist, v

    draw: (x, y, r) =>
        return if #@vlist < 2
        translate = Vector2 x, y
        if #@vlist == 2
            draw_line @vlist[1], @vlist[2], translate, r
            return
        first = @vlist[1]
        for i=2, #@vlist
            next = @vlist[i]
            draw_line first, next, translate, r
            first = next
        draw_line first, @vlist[1], translate, r

class Shape
    new: =>
        @vp = VectorPainter!
        @build!
    
    build: =>
    draw: (x=0, y=0, r=0) =>
        @vp\draw x, y, r
        -- draw all directions!
        @vp\draw x+1280, y, r
        @vp\draw x-1280, y, r
        @vp\draw x, y-720, r
        @vp\draw x, y+720, r

class Rect extends Shape
    build: =>
        @vp\add Vector2(-50, -50)
        @vp\add Vector2(50, -50)
        @vp\add Vector2(50, 50)
        @vp\add Vector2(-50, 50)

class ShipG extends Shape
    build: =>
        @vp\add 0, -16
        @vp\add 16, 16
        @vp\add 0, 8
        @vp\add -16, 16

class ShotG extends Shape
    build: =>
        @vp\add 0, -4
        @vp\add 0, 4

map = (x, y, size=128) ->
    t = size / 2
    Vector2 x-t, y-t

-- Make nicer shapes please!
class BigG extends Shape
    build: =>
        @vp\add map(40, 0)
        @vp\add map(96, 0)
        @vp\add map(117, 29)
        @vp\add map(99, 56)
        @vp\add map(126, 78)

        @vp\add map(115, 126)
        @vp\add map(74, 122)
        @vp\add map(68, 104)
        @vp\add map(2, 94)
        @vp\add map(2, 38)

class MidG extends Shape
    build: =>
        @vp\add map(20, 1, 64)
        @vp\add map(56, 2, 64)
        @vp\add map(62, 17, 64)
        @vp\add map(63, 48, 64)
        @vp\add map(58, 63, 64)

        @vp\add map(8, 62, 64)
        @vp\add map(0, 47, 64)
        @vp\add map(1, 15, 64)
        @vp\add map(15, 11, 64)


class SmallG extends Shape
    build: =>
        @vp\add map(6, 0, 32)
        @vp\add map(20, 0, 32)
        @vp\add map(31, 8, 32)
        @vp\add map(25, 22, 32)
        @vp\add map(28, 32, 32)

        @vp\add map(8, 30, 32)
        @vp\add map(0, 17, 32)
        

class HitParticles
    new: (pos, dir) =>
        @pos = pos\copy!
        @psys = G.newParticleSystem particle, 500
        @psys\setParticleLifetime 0.25, 0.5
        @psys\setLinearAcceleration -400, -400, 400, 400
        --@psys\setRadialAcceleration -400, 400
        @psys\setSizes 1, 2, 3, 4
        @psys\setColors 1,1,1,1, 1,1,1,0
        @psys\emit 500
        @lifetime = 0.5
        @active = true
    
    update: (dt) =>
        return unless @active
        @lifetime -= dt
        @psys\update dt
        if @lifetime <= 0
            @active = false
    
    draw: =>
        return unless @active
        G.draw @psys, @pos.x, @pos.y
    
SHIP_G = ShipG!
SHOT_G = ShotG!
BIG_G = BigG!
MID_G = MidG!
SML_G = SmallG!

{:Rect, :SHIP_G, :SHOT_G, :BIG_G, :MID_G, :SML_G, :HitParticles}