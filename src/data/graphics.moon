
import lerp from require "data/gmath"

convert_colour = (red, green, blue) ->
    rf, gf, bf = love.math.colorFromBytes red, green, blue
    {rf, gf, bf, 1}

convert_colour_string = (str) ->
    red = tonumber str\sub(1,2), 16
    green = tonumber str\sub(3,4), 16
    blue = tonumber str\sub(5,6), 16
    convert_colour red, green, blue

lerp_color = (c1, c2, t) ->
    r1 = c1[1]
    g1 = c1[2]
    b1 = c1[3]
    a1 = c1[4]

    r2 = c2[1]
    g2 = c2[2]
    b2 = c2[3]
    a2 = c2[4]

    r3 = lerp r1, r2, t
    g3 = lerp g1, g2, t
    b3 = lerp b1, b2, t
    a3 = lerp a1, a2, t

    {r3, g3, b3, a3}
    

palettes = {}
pongp = {}
pongp[1] = convert_colour_string "222323"
pongp[2] = convert_colour_string "f0f6f0"
sip = {}
sip[1] = convert_colour_string "25342f"
sip[2] = convert_colour_string "01eb5f"
ast = {}
ast[1] = convert_colour_string "080808"
ast[2] = convert_colour_string "86ea16"
con = {}
con[1] = convert_colour_string "2e3037"
con[2] = convert_colour_string "ebe5ce"

palettes.pong = pongp
palettes.space = sip
palettes.asteroids = ast
palettes.conway = con

FONT = love.graphics.newImageFont "assets/imgfont.png", "!\"#$%&'()*#,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
FONT\setFilter "nearest", "nearest"

{:palettes, :FONT, :lerp_color, :convert_colour_string}