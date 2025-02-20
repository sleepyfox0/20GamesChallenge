import Vector2, lerp from require "data/gmath"
import convert_colour_string from require "data/graphics"
import getLeftRight from require "data/input"
import load_animation from require "games/platformer/animations"

G = love.graphics

SPEED = 100/60
GRAVITY = 0.08
JUMP = -3
TERMINAL_VELOCITY = 10
COLOUR = convert_colour_string "e53b44"

--LIMIT_Y = 180-48
LIMIT_Y = 18*16 - 32
SPOS = Vector2 1, 9

animation = load_animation "assets/platformer/animations/player"

getLR = ->
    x = getLeftRight!
    return -1 if x < 0
    return 1 if x > 0
    return 0

class CharacterControl
    new: =>
        --@pos = Vector2 320/2-8, 180-48
        --@pos = Vector2 320/2-8, 0
        @pos = SPOS * 16
        @grav = 0
        @vdown = 0
        @facing = "right"
        @onground = true
        @state = "standing"
        @quad = Q
        @next = @pos
        @nv = Vector2!
    
    jump: =>
        return unless @onground
        --return unless @state == "onground"
        @state = "jumping"
        @onground = false
        @grav = JUMP
    
    haltJump: =>
        return unless @state == "jumping"
        @grav = lerp @grav, 0, 0.75
    

    updateMove: =>
        x = getLR!

        if x < 0
            @facing = "left"
        elseif x > 0
            @facing = "right"

        @grav += GRAVITY
        @grav = TERMINAL_VELOCITY if @grav > TERMINAL_VELOCITY

        nv = Vector2 SPEED * x, @grav
        @next = @pos + nv
    
    integrate: =>
        -- check grounded
        nv = @next - @pos
        x = nv.x
        if @onground and x == 0
            @state = "standing"
        elseif @onground and x ~= 0
            @state = "running"
        
        @pos = @next
        animation.current = @state
        animation\update!
    
    draw: =>
        x = math.floor @pos.x
        y = math.floor @pos.y
        G.setColor 1, 1, 1, 1

        animation\draw x, y, @facing == "left"

{:CharacterControl}