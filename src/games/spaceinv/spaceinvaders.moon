import palettes, FONT from require "data/graphics"
import clamp, overlap from require "data/gmath"
import Game from require "games/game"

import isDown from require "data/input"
import floor from math

G = love.graphics
KEYS = love.keyboard
A = love.audio

RNG = love.math.newRandomGenerator!
BKGC = palettes.space[1]
FRGC = palettes.space[2]

SCREEN = G.newCanvas 320, 180
SCREEN\setFilter "nearest", "nearest"
SCALE = 4

PLAYER_SIZE = 16
PLAYER_Y = 180 - 16 - PLAYER_SIZE
SPEED = 175

-- image stuff
IMG = G.newImage "assets/invaders/invaders.png"
IMG\setFilter "nearest", "nearest"
PLAYER_Q = G.newQuad 0, 0, 16, 16, IMG
MSHIP_Q = G.newQuad 16, 0, 16, 16, IMG
ENEMY_Q = {}
ENEMY_Q[1] = {}
ENEMY_Q[1][1] = G.newQuad 2*16, 0, 16, 16, IMG
ENEMY_Q[1][2] = G.newQuad 3*16, 0, 16, 16, IMG
ENEMY_Q[2] = {}
ENEMY_Q[2][1] = G.newQuad 4*16, 0, 16, 16, IMG
ENEMY_Q[2][2] = G.newQuad 5*16, 0, 16, 16, IMG
ENEMY_Q[3] = {}
ENEMY_Q[3][1] = G.newQuad 6*16, 0, 16, 16, IMG
ENEMY_Q[3][2] = G.newQuad 7*16, 0, 16, 16, IMG

-- bulettes
BULLET_SPEED = 200
EB_SPEED = 50
BULLETS = G.newImage "assets/invaders/bullets.png"
BULLETS\setFilter "nearest", "nearest"
PLAYER_B = G.newQuad 0, 0, 3, 3, BULLETS
ENEMY_B = {}
ENEMY_B[1] = G.newQuad 1*3, 0, 3, 3, BULLETS
ENEMY_B[2] = G.newQuad 2*3, 0, 3, 3, BULLETS
ENEMY_B[3] = G.newQuad 3*3, 0, 3, 3, BULLETS
ENEMY_B[4] = G.newQuad 4*3, 0, 3, 3, BULLETS

-- enemy bombs animation
EB_FRQ = 0.1
b_frame = 1
b_timer = 0
update_bomb_anim = (dt) ->
    b_timer += dt
    if b_timer >= EB_FRQ
        b_frame += 1
        b_timer -= EB_FRQ
        b_frame = 1 if b_frame > 4
draw_bomb = (x, y) ->
    G.draw BULLETS, ENEMY_B[b_frame], x, y

-- NOTE: Enemy height = 10 px

-- stuff for playing sounds
SOUNDS = {}
SOUNDS.shot = A.newSource "assets/invaders/shot1.wav", "static"
SOUNDS.bomb = A.newSource "assets/invaders/bomb.wav", "static"
SOUNDS.death = A.newSource "assets/invaders/death.wav", "static"
SOUNDS.kill = A.newSource "assets/invaders/kill.wav", "static"
SOUNDS.mskill = A.newSource "assets/invaders/mskill.wav", "static"
SOUNDS.bomb\setVolume 0.4

play_sound = (name) ->
    src = SOUNDS[name]
    src\stop!
    src\seek 0
    src\play!

-- some colission functions
c_shot_shot = (bullet, bomb) ->
    overlap bullet.x, bullet.y, 3, 3, bomb.x, bomb.y, 3, 3

c_shot_alien = (bullet, alien) ->
    overlap bullet.x, bullet.y, 3, 3, alien.x, alien.y, 16, 16

c_bomb_player = (bomb, px) ->
    overlap bomb.x, bomb.y, 3, 3, px, PLAYER_Y+8, 16, 8

-- Enemy definitions -----------------------------------------------------------------------------------------------
class Enemy
    new: (score=0, x=0, y=0) =>
        @score = score
        @x = x
        @y = y
        @active = true
    
    destroy: =>
        @active = false
        @x = -100
        @y = -100

class MotherShip extends Enemy
    new: =>
        super 10
        @x = -16
        @y = 0
        @vx = 0
        @active = false

    activate: =>
        @x = -16
        @y = 8
        @vx = 1
        @active = true
    update: (dt) =>
        return unless @active
        if @vx > 0
            @x += dt*SPEED
            if @x > 320-16
                @x = 320-16
                @vx = -1
        else
            @x -= dt*SPEED
            if @x < -16
                @active = false
    draw: =>
        return unless @active
        G.draw IMG, MSHIP_Q, @x, @y
        --G.rectangle "fill", @x, @y, 16, 16

-- Row definition --------------------------------------------------------------------------------------------------
class EnemyRow
    new: (parent, y=0, score=1, eq=1) =>
        @parent = parent
        @iid = eq
        @frame = 1
        @enemies = {}
        x = 0
        for i=1, 10
            table.insert @enemies, Enemy(score, x, y)
            x += 24
        @mov = 8
        @active = true
    
    getRandomEnemy: =>
        eid = RNG\random 1, #@enemies
        @enemies[eid]

    update: =>
        stop = 0
        @frame += 1
        @frame = 1 if @frame > 2
        --print PLAYER_Y
        for enemy in *@enemies
            continue unless enemy.active
            enemy.x += @mov
            if enemy.x >= 320 - 16
                stop = -1
            if enemy.x <= 0
                stop = 1
            if enemy.y >= PLAYER_Y
                @parent\go!
        if stop < 0
            @mov = -8
            @parent\moveDown @mov
        elseif stop > 0
            @mov = 8
            @parent\moveDown @mov
        if @getEnemyCount! == 0
            @active = false
    
    draw: =>
        for enemy in *@enemies
            G.draw IMG, ENEMY_Q[@iid][@frame], enemy.x, enemy.y if enemy.active
    
    getHit: (bullet) =>
        for alien in *@enemies
            if c_shot_alien bullet, alien
                return alien if alien.active
        return nil
    
    moveDown: (dir) =>
        for enemy in *@enemies
            enemy.y += 8
        @mov = dir
    
    getEnemyCount: =>
        cnt = 0
        for enemy in *@enemies
            cnt += 1 if enemy.active
        return cnt

-- Group definition --------------------------------------------------------------------------------------------------
class EnemyGroup
    new: (game) =>
        @game = game
        @rows = {}
        y = 20
        for i=1, 5
            score = 6
            score = 3 if i > 1
            score = 1 if i > 3
            eq = 3
            eq = 1 if i > 1
            eq = 2 if i > 3
            table.insert @rows, EnemyRow(@, y, score, eq)
            y += 12
        @activeRow = 1
        @tickerTimer = 0
        @bSpawnT = 0
        @ttime = 0.4
    
    updateTick: =>
        row = @rows[@activeRow]
        while not row.active
            @activeRow += 1
            @activeRow = 1 if @activeRow > #@rows
            row = @rows[@activeRow]
        row\update!
        @activeRow += 1
        @activeRow = 1 if @activeRow > #@rows
    
    moveDown: (dir) =>
        for row in *@rows
            row\moveDown dir
    
    getRandomRow: =>
        ridx = RNG\random 1, #@rows
        @rows[ridx]
    getRandomEnemy: =>
        row = @getRandomRow!
        row\getRandomEnemy!

    update: (dt) =>
        @tickerTimer += dt
        @bSpawnT += dt
        if @tickerTimer >= @ttime
            @tickerTimer -= @ttime
            @updateTick!
        if @bSpawnT >= 1
            @bSpawnT -= 1
            enemy = @getRandomEnemy!
            @game\activateBomb enemy
            
    draw: =>
        for row in *@rows
            row\draw!
    
    getHit: (bullet) =>
        ridx = #@rows
        alien = nil
        for i=ridx, 1, -1
            alien = @rows[i]\getHit bullet
            return alien if alien
        return nil
    
    getEnemyCount: =>
        cnt = 0
        for row in *@rows
            cnt += row\getEnemyCount!
        return cnt
    
    go: =>
        @game\gameOver!

-- Bullet definitions -----------------------------------------------------------------------------------------
class Shot
    new: =>
        @x = 0
        @y = 0
        @active = false

    activate: (x, y) =>
        return if @active
        @x = x
        @y = y
        @active = true
        @playSound!
    
    playSound: () =>
    update: (dt) =>
    draw: =>

class Bullet extends Shot
    playSound: =>
        play_sound "shot"
    
    update: (dt) =>
        return unless @active
        @y -= dt*BULLET_SPEED
        if @y <= -3
            @active = false
        
    draw: =>
        return unless @active
        G.draw BULLETS, PLAYER_B, @x, @y

class Bomb extends Shot
    playSound: =>
        play_sound "bomb"
    update: (dt) =>
        return unless @active
        @y += dt*EB_SPEED
        if @y > 180
            @active = false
    draw: =>
        return unless @active
        draw_bomb @x, @y

-- MAIN GAME !!! -------------------------------------------------------------------------------------------------
class SpaceInv extends Game
    new: =>
        super!
        @reset!
    
    reset: (no_score=false) =>
        @px = 320/2 - PLAYER_SIZE/2 unless no_score
        @tickerTimer = 0
        @bullet = Bullet!
        @bombs = [Bomb! for i = 1, 10]
        @enemies = EnemyGroup @
        @pstate = "active"
        @killTimer = 0
        @invTimer = 0
        @motherShip = MotherShip!
        @msSpawn = false
        @score = 0 unless no_score
        @lives = 3 unless no_score
        @shipTime = 0
    
    killPlayer: =>
        @pstate = "killed"
        @killTimer = 0
    
    respawnPlayer: =>
        @px = 320/2 - PLAYER_SIZE/2
        @invTimer = 0
        @pstate = "inv"
    
    gameOver: =>
        @pstate = "gameover"
    
    checkColission: =>
        for bomb in *@bombs
            continue unless bomb.active
            -- checking shot - shot colissions
            if @bullet.active and c_shot_shot @bullet, bomb
                @bullet.active = false
                bomb.active = false
            continue unless bomb.active
            -- checking bomb - player colissions
            if c_bomb_player bomb, @px
                bomb.active = false
                play_sound "death"
                @lives -= 1
                @killPlayer!
        -- cheking for shot alien colissions
        return unless @bullet.active
        alien = @enemies\getHit @bullet
        if alien
            @bullet.active = false
            play_sound "kill"
            @score += alien.score
            @enemies.ttime -= 0.008
            alien\destroy!
        return unless @bullet.active
        -- check mothership
        return unless @motherShip.active
        if c_shot_alien @bullet, @motherShip
            play_sound "mskill"
            @score += @motherShip.score
            @motherShip\destroy!
            @bullet.active = false
        

    update: (dt) =>
        -- current key recognition problem???
        --print KEYS.isDown("left")
        RNG\random!
        return if @pstate == "gameover"
        -- update player movement
        if @pstate == "active" or @pstate == "inv"
            dx = dt*SPEED
            --str = "none"
            --if KEYS.isDown "left"
            if isDown "left"
                @px -= dx
                --str = "left"
            elseif isDown "right"
            --elseif KEYS.isDown "right"
                @px += dx
                --str = "right"
            @px = clamp @px, 0, 320-PLAYER_SIZE
            --print str
        if @pstate == "killed"
            --print "Nani the fuck?"
            @killTimer += dt
            if @killTimer >= 0.5
                @respawnPlayer!
        if @pstate == "inv"
            @invTimer += dt
            if @invTimer >= 1
                @pstate == "active"
        -- update all shots
        @bullet\update dt
        for bomb in *@bombs
            bomb\update dt
        -- update enemies
        @enemies\update dt
        @motherShip\update dt
        -- mother ship?
        @shipTime += dt unless @motherShip.active
        if @shipTime > 5 + RNG\random(1, 4)
            @shipTime = 0
            @msSpawn = true
        if @msSpawn
            @activateMotherShip!
        -- COLISSIONS!!!
        @checkColission!
        -- check Game Over
        if @lives <= 0
            @pstate = "gameover"
        -- check win
        if @enemies\getEnemyCount! <= 0
            @reset true
        -- update animation
        update_bomb_anim dt

    drawPlayer: =>
        return if @pstate == "killed"
        x = floor @px
        G.draw IMG, PLAYER_Q, x, PLAYER_Y

    drawGameOver: =>
        w = FONT\getWidth "Game Over!"
        x = 320/2 - w/2
        y = 180/2 - 8
        G.print "Game Over!", x, y

    drawGame: =>
        -- draw the player
        --G.rectangle "fill", x, PLAYER_Y, PLAYER_SIZE, PLAYER_SIZE
        @drawPlayer!
        -- draw enemy
        @enemies\draw!
        @motherShip\draw!
        -- draw shots
        for bomb in *@bombs
            bomb\draw!
        @bullet\draw!

    draw: =>
        G.setCanvas SCREEN
        G.clear BKGC
        G.setFont FONT

        G.setColor FRGC
        if @pstate == "gameover"
            @drawGameOver!
        else
            @drawGame!

        -- draw UI
        s = string.format "%06d", @score
        G.print s, 8, 0
        y = 180 - 9
        G.print "Lives: #{@lives}", 8, y

        G.setCanvas!
        G.setColor 1, 1, 1, 1
        G.draw SCREEN, 0, 0, 0, SCALE
    
    activateBomb: (enemy) =>
        rand = RNG\random!
        return if rand > 0.5
        return unless enemy.active
        bidx = -1
        for i, v in ipairs(@bombs)
            unless v.active
                bidx = i
                break
        return if bidx == -1
        bomb = @bombs[bidx]
        x = enemy.x + 7
        y = enemy.y + 16
        bomb\activate floor(x), floor(y)
    
    activateShot: =>
        return if @bullet.active
        x = @px + 7
        y = PLAYER_Y + 6
        @bullet\activate floor(x), floor(y)
    
    activateMotherShip: =>
        return if @motherShip.active
        @motherShip\activate!
        @msSpawn = false
    
    --keypressed: (key) =>
    --    if @pstate == "gameover"
    --        if key == "a"
    --            @reset!
    --        return
    --    if key == "a"
    --        @activateShot!
    
    eventTriggered: (event) =>
        if @pstate == "gameover"
            if event == "confirm"
                @reset!
            return
        if event == "confirm"
            @activateShot!

{:SpaceInv}