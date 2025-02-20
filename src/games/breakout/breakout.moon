import palettes, FONT from require "data/graphics"
import Vector2 from require "data/gmath"
import Game from require "games/game"

import clamp from require "data/gmath"
import getLeftRight from require "data/input"

G = love.graphics
--FONT = G.newImageFont "assets/imgfont.png", "!\"#$%&'()*#,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "

MINBSPEED = 150
MAXBSPEED = 400

SPEED = 220

SCALE = 4
--BKGC = palettes.pong[1]
BKGC = {0, 0, 0, 1}
FRGC = palettes.pong[2]

LX_LEFT = 4
LX_RIGHT = 228
LY_TOP = 4
P_WIDTH = LX_RIGHT - LX_LEFT

GO_TX = (P_WIDTH/2 - FONT\getWidth("GAME OVER")/2) + LX_LEFT
GO_TY = 180/2

PRINT_X = 224+8

PLAYER_Y = 180 - 8
PLAYER_WIDTH = 24
C_X = LX_RIGHT - PLAYER_WIDTH

BEGIN_LIVE = 3

screen = G.newCanvas 320, 180
screen\setFilter "nearest", "nearest"

bx = 0
by = 0
bvx = 0
bvy = 0
state = "onhold"
bspeed = MINBSPEED
rng = love.math.newRandomGenerator!
-- 8 rows of 16 bricks

px = (P_WIDTH/2 - PLAYER_WIDTH/2) + LX_LEFT
pwidth = PLAYER_WIDTH
vx = 0

sources = {}
sources.brick = love.audio.newSource "assets/breakout/brick.wav", "static"
sources.out = love.audio.newSource "assets/breakout/out.wav", "static"
sources.paddle = love.audio.newSource "assets/breakout/paddle.wav", "static"
sources.wall = love.audio.newSource "assets/breakout/wall.wav", "static"

play_sound = (name) ->
    src = sources[name]
    src\stop!
    src\seek 0
    src\play!

center_ball = ->
    by = PLAYER_Y - 4
    bx = px + (PLAYER_WIDTH/2 - 2)

random_angle = ->
    math.rad(rng\random(25, 55))

convert_angle = (angle) ->
    math.cos(angle), math.sin(angle)

check_player = (width) ->
    return if bvy < 0
    return if bx > px + width or bx + 4 < px
    return if by > PLAYER_Y + 4 or by + 4 < PLAYER_Y

    by = PLAYER_Y - 4
    mb = bx + 2
    mp = px + pwidth/2
    dp = (mb-mp) / (pwidth/2)
    dp = clamp dp, -1, 1
    angle = 65*dp
    dir = Vector2 0, -1
    dir = dir\rotate math.rad(angle)
    bvx = dir.x
    bvy = dir.y
    --bvy = -1
    play_sound "paddle"

BRICK_HEIGHT = 4
BRICK_WIDTH = 14

class Brick
    new: (x, y) =>
        @x = x
        @y = y
        @active = true
    
    draw: =>
        return unless @active
        G.rectangle "fill", @x, @y, BRICK_WIDTH, BRICK_HEIGHT
        G.setColor BKGC
        G.line @x+BRICK_WIDTH, @y, @x+BRICK_WIDTH, @y+BRICK_HEIGHT
        G.setColor FRGC

class Row
    new: (y) =>
        @y = y
        @bricks = {}
        x = P_WIDTH/2 - (16*(BRICK_WIDTH))/2 + LX_LEFT
        for i=1, 16
            table.insert @bricks, Brick(x, @y)
            x += BRICK_WIDTH
    
    draw: =>
        for brick in *@bricks
            brick\draw!
    
    getBrickCount: =>
        cnt = 0
        for brick in *@bricks
            cnt += 1 if brick.active
        return cnt

class Field
    new: =>
        @rows = {}
        y = 40
        for i = 1, 8
            table.insert @rows, Row(y)
            y += BRICK_HEIGHT + 2
    
    draw: =>
        for row in *@rows
            row\draw!
    
    getBrickCount: =>
        cnt = 0
        for row in *@rows
            cnt += row\getBrickCount!
        return cnt

game_field = Field!

check_colission = (bx,by,x,w,y,h) ->
    return false if bx > x + w or bx + 4 < x
    return false if by > y + h or by + 4 < y
    return true

get_colission = (bx, by) ->
    c = nil

    rows = game_field.rows
    for row in *rows
        bricks = row.bricks
        for brick in *bricks
            continue unless brick.active
            x = brick.x
            y = brick.y
            if check_colission bx, by, x, BRICK_WIDTH, y, BRICK_HEIGHT
                c = brick
                return c
    return c


score = 0
highscore = 0
lives = BEGIN_LIVE


-- Saving
save_score = (scr) ->
    content = "1\n#{scr}"
    file, errorstr = love.filesystem.newFile "bo_hiscores.txt", "w"
    if errorstr
        print errorstr
        return
    file\write content
    file\close!

-- Loading
load_score = ->
    info = love.filesystem.getInfo "bo_hiscores.txt"
    return unless info
    file, errorstr = love.filesystem.newFile "bo_hiscores.txt", "r"
    if errorstr
        print errorstr
        return
    lines = file\lines!
    lines!
    highscore = tonumber lines!
    file\close!

class Breakout extends Game

    load: =>
        load_score!
        center_ball!
    
    reset: =>
        pwidth = PLAYER_WIDTH
        score = 0
        lives = BEGIN_LIVE
        game_field = Field!
        px = (P_WIDTH/2 - PLAYER_WIDTH/2) + LX_LEFT
        center_ball!
        state = "over"
    
    playerResize: (back=false) =>
        if back
            px -= pwidth/2
            pwidth = PLAYER_WIDTH
            return
        return if pwidth < PLAYER_WIDTH
        pwidth = PLAYER_WIDTH / 2
        px += pwidth/2

    updateBall: (dt) =>
        nx = bx + dt*bspeed*bvx
        ny = by + dt*bspeed*bvy

        block = false
        -- left right
        if nx < LX_LEFT
            nx = LX_LEFT
            bvx *= -1
            play_sound "wall"
        elseif nx > LX_RIGHT-4
            nx = LX_RIGHT-4
            bvx *= -1
            play_sound "wall"
        -- check lr colissions
        c = get_colission nx, by
        if c
            -- handle colission
            if bvx < 0
                nx = c.x + BRICK_WIDTH + 1
            else
                nx = c.x-5
            bvx *= -1
            c.active = false
            score += 1
            bspeed += 1
            play_sound "brick"

        -- up down
        if ny < LY_TOP
            @playerResize!
            ny = LY_TOP
            bvy *= -1
            play_sound "wall"

        c = get_colission nx, ny
        if c
            -- handle colission
            if bvy < 0
                ny = c.y + BRICK_HEIGHT + 1
            else
                ny = c.y-5
            bvy *= -1
            c.active = false
            score += 1
            bspeed += 1
            play_sound "brick"

        

        bx = nx
        by = ny
        
        bspeed = math.min(bspeed, MAXBSPEED)

        -- check player colission
        check_player pwidth

    update: (dt) =>
        return if state == "gameover"
        vx = getLeftRight!
        px += vx*SPEED*dt
        px = clamp px, LX_LEFT, LX_RIGHT-pwidth

        if state == "onhold"
            center_ball!
        elseif state == "ingame"
            @updateBall dt
            if by > 188
                play_sound "out"
                lives -= 1
                bspeed = MINBSPEED
                state = "onhold"
                @playerResize true
                if lives <= 0
                    state = "gameover"
                    lives = 0
                    save_score highscore
            if game_field\getBrickCount == 0
                game_field = Field!
                @state = "onhold"
                center_ball!
        elseif state == "over"
            state = "onhold"
        highscore = score if score > highscore

    draw: =>
        G.setCanvas screen
        G.clear BKGC
        G.setFont FONT

        unless state == "gameover"
            game_field\draw!
            
            --draw player
            G.rectangle "fill", px, PLAYER_Y, pwidth,4
            -- draw ball
            G.rectangle "fill", bx, by, 4, 4
        if state == "gameover"
            G.print "GAME OVER", GO_TX, GO_TY

        -- draw the walls and ceiling
        G.rectangle "fill", 0, 0, 4, 180
        G.rectangle "fill", LX_RIGHT, 0, 4, 180
        G.rectangle "fill", 0, 0, 228, 4

        y = 8
        G.print "HISCORE:", PRINT_X, y-1
        y += 8
        G.print "#{string.format("%04d", highscore)}", PRINT_X, y-1
        y += 8
        G.print "SCORE:", PRINT_X, y-1
        y += 8
        G.print "#{string.format("%04d", score)}", PRINT_X, y-1
        y = 180 - 32
        G.print "LIVES:", PRINT_X, y-1
        y += 8
        if state == "gameover"
            G.print "#{lives}", PRINT_X, y-1
        else
            G.print "#{lives-1}", PRINT_X, y-1

        -- draw Colours
        G.setBlendMode "multiply", "premultiplied"
        y = 40
        adder = BRICK_HEIGHT*2+4
        G.setColor 1, 0, 0, 1
        G.rectangle "fill", 0, y, 320, adder
        y += adder
        G.setColor 0.97, 0.46, 0.13, 1
        G.rectangle "fill", 0, y, 320, adder
        y += adder
        G.setColor 0, 1, 0, 1
        G.rectangle "fill", 0, y, 320, adder
        y += adder
        G.setColor 1, 1, 0, 1
        G.rectangle "fill", 0, y, 320, adder
        G.setBlendMode "alpha"
        G.setColor FRGC

        G.setCanvas!
        G.setColor 1, 1, 1, 1
        G.draw screen, 0,0, 0, SCALE

    eventTriggered: (event) =>
        if state == "gameover" and event == "confirm"
            @reset!
        -- update ball
        elseif state == "onhold" and event == "confirm"
            play_sound "paddle"
            state = "ingame"
            bvx, bvy = convert_angle random_angle!
            bvx *= -1 if vx < 0
            bvy *= -1
        if event == "cancel"
            switch_game selector

{:Breakout}