BASE = "games/platformer/"
import FONT, convert_colour_string from require "data/graphics"
import Game from require "games/game"

import load_map, Camera from require "#{BASE}maps"
import CharacterControl from require "#{BASE}chrcontrol"
import PlayerColission from require "#{BASE}colissions"

G = love.graphics

FPS = 60
FRAMER = 1/FPS

COL_SKY = convert_colour_string "2a3b4a"
BKG = G.newImage "assets/platformer/images/bkg.png"

class PGame extends Game
    new: =>
        @fpsT = 0
        @player = CharacterControl!
        @map = load_map "assets/platformer/maps/level1"
        @cam = Camera @player, @map
        @collider = PlayerColission @player, @map
    
    frameUpdate: =>
        -- update movement
        @player\updateMove!
        -- do collision resolution
        @collider\checkColission!
        -- integrate
        @player\integrate!

    update: (dt) =>
        @fpsT += dt
        while @fpsT >= FRAMER
            @frameUpdate!
            @fpsT -= FRAMER
    
    draw: =>
        G.draw BKG
        @cam\update!


        @cam\applyParalax!
        @map\drawPara!
        @cam\detach!

        @cam\apply!
        @map\draw!
        @player\draw!
        @cam\detach!
    
    eventTriggered: (event) =>
        if event == "cancel"
            switch_game selector
        if event == "confirm"
            @player\jump!
    
    eventReleased: (event) =>
        if event = "confirm"
            @player\haltJump!

class Platformer extends Game
    new: =>
        @screen = G.newCanvas 320, 180
        @screen\setFilter "nearest", "nearest"
        @process = PGame!
    
    --load: =>
    
    update: (dt) =>
        @process\update dt

    draw: =>
        G.setFont FONT
        G.setCanvas @screen

        @process\draw!

        G.setCanvas!
        G.setColor 1, 1, 1, 1
        G.draw @screen, 0,0,0, 4
    
    eventTriggered: (event) =>
        @process\eventTriggered event
    
    eventReleased: (event) =>
        @process\eventReleased event

{:Platformer}