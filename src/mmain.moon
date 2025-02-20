nextg = nil
export switch_game = (g) ->
    nextg = g

input = require "data/input"
import Selector from require "games/selector"
--import Pong from require "games/pong/pong"
--import SpaceInv from require "games/spaceinv/spaceinvaders"
--import Breakout from require "games/breakout/breakout"
--import Asteroids from require "games/asteroids/asteroids"
--import Conway from require "games/conway/game"
import Platformer from require "games/platformer/platform"

export selector = Selector!

--game = Platformer!
game = selector
input.setReceiver game

love.load = ->
    game\load!

love.update = (dt) ->
    if nextg
        game = nextg
        input.setReceiver game
        game\load!
        nextg = nil

    game\update dt

love.draw = ->
    game\draw!

love.keypressed = (key, scancode, isrepeat) ->
    input.keypressed key, scancode, isrepeat
    game\keypressed key, scancode

love.keyreleased = (key, scancode, isrepeat) ->
    input.keyreleased key, scancode, isrepeat

love.gamepadpressed = (joystick, button) ->
    input.gamepadpressed joystick, button

love.gamepadreleased = (joystick, button) ->
    input.gamepadreleased joystick, button