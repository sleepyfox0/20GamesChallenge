import palettes, FONT from require "data/graphics"
import Game from require "games/game"
import Pong from require "games/pong/pong"
import Breakout from require "games/breakout/breakout"
import SpaceInv from require "games/spaceinv/spaceinvaders"
import Asteroids from require "games/asteroids/asteroids"
import Conway from require "games/conway/game"
import Platformer from require "games/platformer/platform"
import SelectMenu from require "data/smenu"

SCALE = 2
BKGC = palettes.pong[1]
FRGC = palettes.pong[2]

G = love.graphics

class Selector extends Game
    new: =>
        @screen = G.newCanvas 640, 360
        @screen\setFilter "nearest", "nearest"
        @menu = SelectMenu @
        @buildMenu!
    
    onPong: =>
        switch_game Pong!
    onBreakout: =>
        switch_game Breakout!
    onSpaceInvaders: =>
        switch_game SpaceInv!
    onAsteroids: =>
        switch_game Asteroids!
    onConway: =>
        switch_game Conway!
    onPlatformer: =>
        switch_game Platformer!

    buildMenu: =>
        @menu\setColours BKGC, FRGC
        @menu\add "01. Pong", @onPong
        @menu\add "02. Breakout", @onBreakout
        @menu\add "03. Space Invaders", @onSpaceInvaders
        @menu\add "04. Asteroids", @onAsteroids
        @menu\add "05. Conway's Game of Life", @onConway
        @menu\add "06. Platformer (WIP)", @onPlatformer
        @menu.x = 24
        @menu.y = 24
        @menu.active = true
        @menu.stayActive = true
    
    load: =>
        FONT\setFilter "nearest", "nearest"
    
    draw: =>
        G.setCanvas @screen
        G.clear BKGC
        G.setFont FONT
        @menu\draw!

        G.setCanvas!
        G.setColor 1, 1, 1, 1
        G.draw @screen, 0,0, 0, SCALE
    
    keypressed: (key, scancode) =>
        if key == "1" or key == "kp1"
            switch_game Pong!
        elseif key == "2" or key == "kp2"
            switch_game Breakout!
        elseif key == "3" or key == "kp3"
            switch_game SpaceInv!
        elseif key == "4" or key == "kp4"
            switch_game Asteroids!
        elseif key == "5" or key == "kp5"
            switch_game Conway!
        elseif key == "6" or key == "kp6"
            switch_game Platformer!

    eventTriggered: (event) =>
        @menu\eventTriggered event

{:Selector}