import palettes, FONT from require "data/graphics"
import Vector2 from require "data/gmath"
import Game from require "games/game"
import HitParticles from require "games/asteroids/astg"
import Ship, Shot, BigAsteroid, MidAsteroid, SmallAsteroid from require "games/asteroids/entities"
import SoundPlayer from require "games/asteroids/soundplayer"
import SelectMenu from require "data/smenu"


G = love.graphics

BKGC = palettes.asteroids[1]
FRGC = palettes.asteroids[2]

particle = G.newImage "assets/particle.png"

-- State -> Menu, InGame, GameOver
class Asteroids extends Game
    new: =>
        love.keyboard.setKeyRepeat false
        @txtPlane = G.newCanvas 1280, 360
        @txtPlane\setFilter "nearest", "nearest"

        @sounds = SoundPlayer!

        @particles = {}
        @menu = SelectMenu @
        @buildMenu!
        
        @reset!
    
    onNewGame: =>
        @reset!
        @state = "game"
        @sounds\play "select"
        @menu.active = false
    onBack: =>
        switch_game selector
        @menu.active = false
    onExit: =>
        love.event.push "quit"
        @menu.active = false
    
    buildMenu: =>
        @menu\setColours BKGC, FRGC

        @menu\add "New Game", @onNewGame
        @menu\add "Back to selection", @onBack
        @menu\add "Exit Game", @onExit unless love.system.getOS! == "Web"

        @menu.x = 32
        @menu.y = 32
        @menu.active = true
        @menu.stayActive = true

    reset: =>
        @player = Ship!
        @shots = [Shot! for i=1, 4]

        @score = 0

        @asteroids = {}
        @level = 1
        @state = "menu"
        @lives = 3
        @createAsteroids!
    
    createAsteroids: (level=1) =>
        @player\turnInvOn!
        @asteroids = [BigAsteroid! for i=1, level]
    
    update: (dt) =>
        @menu.active = @state == "menu"
        return if @state == "menu"
        return if @state == "gameover"
        @player\update dt
        for asteroid in *@asteroids
            asteroid\update dt
        for shot in *@shots
            shot\update dt
        -- colissions!
        for shot in *@shots
            continue unless shot.active
            for asteroid in *@asteroids
                continue unless asteroid.active
                if asteroid\gotHit shot
                    asteroid\destroy!
                    @score += asteroid.score
                    direction = Vector2 0, -1
                    direction = direction\rotate shot.rot
                    table.insert @particles, HitParticles(shot.pos, direction)
                    shot.active = false
                    @sounds\play "hit"
                    break
        for asteroid in *@asteroids
            continue unless asteroid.active
            if @player\colides asteroid
                @player\kill!
                @lives -= 1
                @sounds\play "killed"
                break
        -- clean up
        if @lives <= 0
            @state = "gameover"
        ast = {}
        for asteroid in *@asteroids
            if asteroid.active
                table.insert ast, asteroid
            else
                if asteroid.name == "big"
                    table.insert ast, MidAsteroid(asteroid.pos)
                    table.insert ast, MidAsteroid(asteroid.pos)
                elseif asteroid.name == "mid"
                    table.insert ast, SmallAsteroid(asteroid.pos)
                    table.insert ast, SmallAsteroid(asteroid.pos)
        for ps in *@particles
            ps\update dt
        @asteroids = ast
        parts = {}
        for psys in *@particles
            table.insert parts, psys if psys.active
        @particles = parts
        if #@asteroids == 0
            @level += 1
            @createAsteroids @level

    drawUI: =>
        G.setColor FRGC
        G.print "Level: #{string.format("%02d", @level)}", 8, 8
        G.print "Score: #{string.format("%05d", @score)}", 8, 16
        G.print "Lives: #{string.format("%02d", @lives)}", 8, 352
    
    drawMenu: =>
        G.clear BKGC
        G.setColor FRGC
        @menu\draw!
    
    drawGameOver: =>
        G.clear BKGC
        G.setColor FRGC
        G.print "GAME OVER", 32, 32
        G.print "Your Score:", 32, 40
        G.print "#{@score}", 32, 48

    draw: =>
        G.clear BKGC
        G.setFont FONT
        G.setColor FRGC
        @player\draw!
        for asteroid in *@asteroids
            asteroid\draw!
        for shot in *@shots
            shot\draw!
        for ps in *@particles
            ps\draw!

        -- text overlay
        G.setCanvas @txtPlane
        G.clear {0, 0, 0, 0}
        G.setColor FRGC

        if @state == "menu"
            @drawMenu!
        elseif @state == "gameover"
            @drawGameOver!
        else
            @drawUI!

        G.setCanvas!
        G.setColor 1, 1, 1, 1
        G.draw @txtPlane,0,0,0, 1, 2
    
    tryShoot: =>
        idx = -1
        for i, v in ipairs(@shots)
            unless v.active
                idx = i
                break
        return if idx < 1
        emitter = @player\getEmitter!
        @shots[idx]\activate emitter, @player.dir, @player.rot, @player.vel
        @sounds\play "shoot"
    
    keypressed: (key, scancode) =>
        if @state == "menu"
            if key == "1" or key == "kp1"
                @reset!
                @state = "game"
                @sounds\play "select"
            elseif key == "2" or key == "kp2"
                switch_game selector
            elseif key == "3" or key == "kp3"
                return if love.system.getOS! == "Web"
                love.event.push "quit" 
            return
    
    eventTriggered: (event) =>
        if @state == "menu"
            @menu\eventTriggered event
            return
        if @state == "gameover"
            if event ~= "confirm"
                @state = "menu"
        if event == "confirm"
            @tryShoot!


{:Asteroids}
        