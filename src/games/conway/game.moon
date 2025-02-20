import palettes, FONT from require "data/graphics"
import Game from require "games/game"

G = love.graphics

BKGC = palettes.conway[1]
FRGC = palettes.conway[2]

RNG = love.math.newRandomGenerator os.time!

FRAMES = 10
FRAMER = 1/FRAMES

class Conway extends Game

    new: =>
        @timer = 0
        @screen = G.newCanvas 640, 360
        @screen\setFilter "nearest", "nearest"

        @boardG = G.newCanvas 320, 180
        @boardG\setFilter "nearest", "nearest"
        @board = {}
        for x=1, 320
            @board[x] = {}
            for y=1, 180
                @board[x][y] = 0
                @board[x][y] = 1 if RNG\random! > 0.5
    
    updateAutomaton: =>
        board = @board
        next = {}
        for x=1, 320
            next[x] = {}
            for y=1, 180
                -- collect neighbours
                yu = y-1
                yu = yu < 1 and 180 or (yu > 180 and 1 or yu)
                yd = y+1
                yd = yd < 1 and 180 or (yd > 180 and 1 or yd)
                xu = x-1
                xu = xu < 1 and 320 or (xu > 320 and 1 or xu)
                xd = x+1
                xd = xd < 1 and 320 or (xd > 320 and 1 or xd)
                sum = board[xu][yu]
                sum += board[x][yu]
                sum += board[xd][yu]
                sum += board[xu][y]
                sum += board[xd][y]
                sum += board[xu][yd]
                sum += board[x][yd]
                sum += board[xd][yd]

                if board[x][y] > 0
                    if sum < 2 or sum > 3
                        next[x][y] = 0
                    else
                        next[x][y] = 1
                else
                    if sum == 3
                        next[x][y] = 1
                    else
                        next[x][y] = 0
        @board = next


    update: (dt) =>
        @timer += dt
        while @timer >= FRAMER
            @updateAutomaton!
            @timer -= FRAMER

    
    drawBoard: =>
        G.setCanvas @boardG
        G.clear FRGC
        G.setColor BKGC
        points = {}
        for x=1, 320
            for y=1, 180
                if @board[x][y] > 0
                    table.insert points, x
                    table.insert points, y
        G.points points
        G.setCanvas @screen
        G.setColor 1, 1, 1, 1
        G.draw @boardG, 0,0,0, 2


    draw: =>
        G.setCanvas @screen
        G.clear BKGC

        @drawBoard!

        G.setCanvas!
        G.setColor 1, 1, 1, 1
        G.draw @screen, 0, 0, 0, 2
        G.setColor 1, 0, 0, 1
        G.print love.timer.getFPS!, 10, 10
    
    eventTriggered: (event) =>
        if event == "cancel"
            switch_game selector

{:Conway}