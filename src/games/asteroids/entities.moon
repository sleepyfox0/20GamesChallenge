import Vector2, AABB from require "data/gmath"
import SHIP_G, SHOT_G, BIG_G, MID_G, SML_G from require "games/asteroids/astg"

import isDown from require "data/input"

KEYS = love.keyboard

ROT_SPEED = 4
MAX_SPEED = 400
CUTOFF_SPEED = 0.1
ACC = 5
DAMPENING = 0.01

MAX_LEN = 512
SHOT_SPEED = 500

BIG_SPEED = 50
BIG_ROT = 0.06

MID_SPEED = 75
MID_ROT = 0.125

SMALL_SPEED = 100
SMALL_ROT = 0.5

LIMIT_TOP = 32
LIMIT_BOTTOM = 720-16
LIMIT_LEFT = 0
LIMIT_RIGHT = 1280
LIMIT_HEIGHT = LIMIT_BOTTOM-LIMIT_TOP

RNG = love.math.newRandomGenerator os.time!

wrap_position = (pos) ->
    --print pos
    p = pos\copy!
    if p.y < LIMIT_TOP
        p.y += 720
    elseif p.y > LIMIT_BOTTOM
        p.y -= 720
    if p.x < LIMIT_LEFT
        p.x += 1280
    elseif p.x > LIMIT_RIGHT
        p.x -= 1280
    return p

class Shot
    new: =>
        @pos = Vector2!
        @vel = Vector2!
        @rot = 0
        @travelled = 0
        @active = false
        @g = SHOT_G
    
    activate: (pos, dir, rot) =>
        @pos = pos\copy!
        @travelled = 0
        @vel = dir\copy!
        @rot = rot
        @active = true

    update: (dt) =>
        return unless @active
        dist = dt*SHOT_SPEED
        @travelled += dist
        @pos += @vel*dist
        if @travelled > MAX_LEN
            @active = false
        @pos = wrap_position @pos
    
    draw: =>
        return unless @active
        @g\draw @pos.x, @pos.y, @rot

class Ship
    new: =>
        @pos = Vector2 1280/2, 720/2
        @rot = 0
        @g = SHIP_G
        @dir = Vector2 0, -1
        @vel = Vector2!
        @pt = Vector2 -12, -12
        @aabb = AABB @pos.x-12, @pos.y-12, 24, 24
        @status = "normal"
        @invinceTimer = 0
        @isDraw = true
        @blinkT = 0
    
    getEmitter: =>
        Vector2(0, -16)\rotate(@rot) + @pos
    
    update: (dt) =>
        RNG\random!
        --if KEYS.isDown "left"
        if isDown "left"
            @rot -= dt * ROT_SPEED
        --elseif KEYS.isDown "right"
        elseif isDown "right"
            @rot += dt * ROT_SPEED
        @dir = Vector2(0, -1)\rotate @rot
        a = Vector2!

        --if KEYS.isDown "up"
        if isDown "up"
            a = @dir*ACC*dt
        else
            @vel = @vel\moveTo DAMPENING
        
        @vel += a
        l = @vel\len!
        al = a\len!
        if l > MAX_SPEED
            @vel = @vel\norm! * MAX_SPEED
        elseif l <= CUTOFF_SPEED and al == 0
            @vel = Vector2!

        @pos += @vel
        @pos = wrap_position @pos
        @aabb\updatePosition @pos+@pt

        if @status == "invincible"
            @invinceTimer += dt
            @blinkT += dt
            if @blinkT >= 0.25
                @blinkT -= 0.25
                @isDraw = not @isDraw
            if @invinceTimer >= 2
                @status = "normal"
                @isDraw = true

    draw: =>
        return unless @isDraw
        @g\draw @pos.x, @pos.y, @rot
        @aabb\draw!
    
    colides: (asteroid) =>
        return false if @status == "invincible"
        @aabb\colides asteroid.aabb
    
    kill: =>
        @pos = Vector2 1280/2, 720/2
        @vel = Vector2!
        @turnInvOn!
        @aabb\updatePosition @pos+@pt
    
    turnInvOn: =>
        @status = "invincible"
        @invinceTimer = 0


-- should check more aabbs
class Asteroid
    new: =>
        @pos = Vector2!
        @vel = Vector2!
        @rotspeed = 0
        @aabb = AABB 0, 0, 0, 0
        @pt = Vector2!
        @g = BIG_G
        @rot = 0
        @active = false
        @name = "none"
        @score = 0

    update: (dt) =>
        return unless @active
        @pos += @vel*dt
        @rot += dt*@rotspeed
        @pos = wrap_position @pos
        @aabb\updatePosition @pos+@pt
    
    draw: =>
        return unless @active
        @g\draw @pos.x, @pos.y, @rot
        @aabb\draw!
    
    gotHit: (shot) =>
        @aabb\pointIn shot.pos
    
    destroy: =>
        @active = false

class BigAsteroid extends Asteroid
    new:  =>
        super!
        @score = 1
        @name = "big"
        x = RNG\random 0, 1280
        y = RNG\random 0, 720
        @pos = Vector2 x, y

        dx = RNG\random! * 2 - 1
        dy = RNG\random! * 2 - 1
        @vel = (Vector2(dx, dy)\norm!) * BIG_SPEED
        @rot = 0
        @pt = Vector2 -64, -64
        @aabb = AABB @pos.x-64, @pos.y-64, 128, 128
        @rotspeed = BIG_ROT

        @g = BIG_G
        @active = true

class MidAsteroid extends Asteroid
    new: (pos) =>
        super!
        @score = 2
        @name = "mid"
        @pos = pos\copy!

        dx = RNG\random! * 2 - 1
        dy = RNG\random! * 2 - 1
        @vel = (Vector2(dx, dy)\norm!) * MID_SPEED
        @rot = 0
        @pt = Vector2 -32, -32
        @aabb = AABB @pos.x-32, @pos.y-32, 64, 64
        @rotspeed = MID_ROT

        @g = MID_G
        @active = true

class SmallAsteroid extends Asteroid
    new: (pos) =>
        super!
        @score = 4
        @name = "small"
        @pos = pos\copy!

        dx = RNG\random! * 2 - 1
        dy = RNG\random! * 2 - 1
        @vel = (Vector2(dx, dy)\norm!) * SMALL_SPEED
        @rot = 0
        @pt = Vector2 -16, -16
        @aabb = AABB @pos.x-16, @pos.y-16, 32, 32
        @rotspeed = SMALL_ROT

        @g = SML_G
        @active = true
        

{:Ship, :Shot, :BigAsteroid, :MidAsteroid, :SmallAsteroid}