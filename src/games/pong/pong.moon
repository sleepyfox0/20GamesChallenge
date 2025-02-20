import palettes, FONT from require "data/graphics"
import clamp from require "data/gmath"
import Game from require "games/game"
import SelectMenu from require "data/smenu"

JOY = love.joystick

PSPEED = 200
BSPEED_MIN = 150
BSPEED_MAX = 500
AI_SPEED_MIN = 50
AI_SPEED_MAX = 125

SCALE = 4
BKGC = palettes.pong[1]
FRGC = palettes.pong[2]

Y_TOP = 32
Y_BOTTOM = 180-8

HEIGHT = Y_BOTTOM - Y_TOP
START_Y = (HEIGHT / 2 - 8) + Y_TOP
P1_X = 16
P2_X = 320 - 24

G = love.graphics
RNG = love.math.newRandomGenerator!

FNT = G.newImageFont "assets/pong/font.png", "1234567890:"
FNT\setFilter "nearest", "nearest"

p1y = START_Y
p2y = START_Y

bx = 320/2 - 2
by = HEIGHT/2 - 2 + Y_TOP
bspeed = BSPEED_MIN
bvx = 1
bvy = 0

score_p1 = 0
score_p2 = 0

p2ctrl = "human"
menuOpen = false

ai_div = 0

--sound = love.audio.newSource "assets/pong/ball.wav", "static"

score_posx = 320/2 - FONT\getWidth("00:00")

SOUNDS = {}
SOUNDS.wall = love.audio.newSource "assets/pong/wall.wav", "static"
SOUNDS.paddle = love.audio.newSource "assets/pong/paddle.wav", "static"
SOUNDS.play = love.audio.newSource "assets/pong/play.wav", "static"
SOUNDS.out = love.audio.newSource "assets/pong/out.wav", "static"

play_sound = (snd="wall") ->
    sound = SOUNDS[snd]
    sound\stop!
    sound\seek 0
    sound\play!

clamp_paddle = (y) ->
    math.min(Y_BOTTOM-16, math.max(Y_TOP, y))

clamp_by = ->
    by = math.min(Y_BOTTOM-4, math.max(Y_TOP, by))

get_ball_angle = ->
    angle = RNG\random 35, 55
    math.rad angle

get_ball_direction = ->
    return -1 if RNG\random! < 0.5
    1

convert_angle = (angle) ->
    bvx = math.cos angle
    bvy = math.sin angle

adjust_ball = (dir) ->
    angle = get_ball_angle!
    convert_angle angle
    bvx *= dir

reset_ball = (dir) ->
    bx = 320/2 - 2
    by = HEIGHT/2 - 2 + Y_TOP
    bspeed = BSPEED_MIN
    bvx = 0
    bvy = 0
    adjust_ball dir

reset_game = (g) ->
    p1y = START_Y
    p2y = START_Y
    dir = get_ball_direction!
    reset_ball dir
    score_p1 = 0
    score_p2 = 0
    g.isHold = true
    g.holdTimer = 0

check_c = (x, y) ->
    return true if bx > x + 4 or bx + 4 < x
    return true if by > y + 16 or by + 4 < y
    false

apply_diversion = (y) ->
    -- adjust the angle
    dy = ((by + 2) - (y + 8)) / 8
    dy = clamp dy, -1, 1
    angle = dy * 55
    convert_angle math.rad(angle)

check_p1c = ->
    return if bvx > 0
    return if check_c P1_X, p1y

    bx = P1_X + 4
    apply_diversion p1y
    bspeed += 5
    bspeed = math.min bspeed, BSPEED_MAX
    bvx = 1
    ai_div = (RNG\random! * 2 - 1) * 8
    play_sound "paddle"

check_p2c = ->
    return if bvx < 0
    return if check_c P2_X, p2y

    bx = P2_X
    apply_diversion p2y
    bspeed += 5
    bspeed = math.min bspeed, BSPEED_MAX
    bvx = -1
    play_sound "paddle"

getP1Axis = ->
    sticks = JOY.getJoysticks!
    if #sticks > 0
        pad = sticks[1]
        x = pad\getGamepadAxis "lefty"
        if math.abs(x) > 0.1
            return x
        if pad\isGamepadDown "dpup"
            return -1
        elseif pad\isGamepadDown "dpdown"
            return 1
    if love.keyboard.isDown "w"
        return -1
    elseif love.keyboard.isDown "s"
        return 1
    return 0

getP2Axis = ->
    sticks = JOY.getJoysticks!
    if #sticks > 1
        pad = sticks[2]
        x = pad\getGamepadAxis "lefty"
        if math.abs(x) > 0.1
            return x
        if pad\isGamepadDown "dpup"
            return -1
        elseif pad\isGamepadDown "dpdown"
            return 1
    if love.keyboard.isDown "up"
        return -1
    elseif love.keyboard.isDown "down"
        return 1
    return 0

class Pong extends Game
    new: =>
        @holdTimer = 0
        @isHold = true
        @screen = G.newCanvas 320, 180
        @screen\setFilter "nearest", "nearest"
        @gameMenu = SelectMenu @
        @buildMenu!
        print @
    
    onReset: (called) =>
        reset_game @
        @gameMenu.active = false
    onEnableAI: =>
        p2ctrl = if p2ctrl == "human" then "ai" else "human"
        @gameMenu.active = false
    onBack: =>
        switch_game selector
        @gameMenu.active = false

    buildMenu: =>
        @gameMenu\setColours BKGC, FRGC
        @gameMenu\add "Reset Game", @onReset
        @gameMenu\add "Enable AI", @onEnableAI
        @gameMenu\add "Back to selection", @onBack

        w, h = @gameMenu\getSize!
        @gameMenu.x = 320/2 - w/2
        @gameMenu.y = 180/2 - h/2

    load: =>
        reset_game @
    
    controlAI: (dt) =>
        fromY = by+2
        targetY = fromY - 8 + ai_div
        dtarget = targetY - p2y
        v = 0
        if dtarget < 0
            v = -1
        elseif dtarget > 0
            v = 1
        speed = bvx < 0 and AI_SPEED_MIN or AI_SPEED_MAX
        dtdist = math.abs(dtarget)
        maxdy = speed * dt
        p2y += math.min(maxdy, dtdist) * v

    update: (dt) =>
        --print @gameMenu.active
        return if @gameMenu.active
        dy = getP1Axis!
        p1y += dy*PSPEED*dt
        
        -- p1 input processing
        if p2ctrl == "human"
            dy = getP2Axis!
            p2y += dy*PSPEED*dt
        else
            @controlAI dt
        
        -- clamp
        p1y = clamp_paddle p1y
        p2y = clamp_paddle p2y

        -- update ball movement
        if @isHold
            @holdTimer += dt
            if @holdTimer >= 1
                play_sound "play"
                @isHold = false
        else
            bx += bspeed * bvx * dt
            by += bspeed * bvy * dt

        -- colissions!!!
        if by < Y_TOP or by+4 > Y_BOTTOM
            play_sound!
            clamp_by!
            bvy *= -1
        check_p1c!
        check_p2c!

        -- check ball out
        if bx < -4
            play_sound "out"
            score_p2 += 1
            score_p2 = 0 if score_p2 > 99
            reset_ball 1
            @isHold = true
            @holdTimer = 0

        elseif bx > 320
            play_sound "out"
            score_p1 += 1
            score_p1 = 0 if score_p1 > 99
            reset_ball -1
            @isHold = true
            @holdTimer = 0
        
    
    drawScore: =>
        -- draw score
        strs1 = string.format "%02d", "#{score_p1}"
        strs2 = string.format "%02d", "#{score_p2}"
        score = "#{strs1}:#{strs2}"
        G.print score, score_posx, 4, 0, 2

    draw: =>
        fnt = G.getFont!
        G.setFont FNT
        G.setCanvas @screen
        G.clear BKGC

        G.setColor FRGC
        @drawScore!        

        -- draw the walls
        G.rectangle "fill", 0, 24, 320, 8
        G.rectangle "fill", 0, Y_BOTTOM, 320, 8

        -- draw the paddles
        G.rectangle "fill", P1_X, p1y, 4, 16
        G.rectangle "fill", P2_X, p2y, 4, 16

        -- draw the ball
        G.rectangle "fill", bx, by, 4, 4

        -- draw the menu
        if @gameMenu.active
            @gameMenu\draw!

        G.setCanvas!
        G.setColor 1,1,1,1
        G.draw @screen, 0, 0, 0, SCALE
    
    eventTriggered: (event) =>
        if @gameMenu.active
            @gameMenu\eventTriggered event
        else
            if event == "cancel"
                --menuOpen = not menuOpen
                @gameMenu.active = true
            

{:Pong}