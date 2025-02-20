
class Anim
    new: (img, name) =>
        @img = img
        @quads = {}
        @duration = 0
        @timer = 0
        @current = -1
        @name = name
    
    setStatic: (quad) =>
        @quads[1] = quad
        @duration = 500
        @timer = 0
        @current = 1
    
    addFrame: (quad) =>
        table.insert @quads, quad
    
    update: =>
        @timer += 1
        if @timer >= @duration
            @current += 1
            @timer = 0
            @current = 1 if @current > #@quads
    
    draw: (x, y, mirror) =>
        q = @quads[@current]

        if mirror
            _, _, w = q\getViewport!
            love.graphics.draw @img, q, x+w, y, 0, -1, 1
        else
            love.graphics.draw @img, q, x, y

add_static = (name, a, animations, img) ->
    quad = love.graphics.newQuad a.x, a.y, a.w, a.h, img
    anim = Anim img, name
    anim\setStatic quad
    animations[name] = anim

add_dynamic = (name, a, animations, img) ->
    anim = Anim img, name
    frames = a.frames
    x = a.x
    y = a.y
    w = a.w
    h = a.h
    anim.duration = a.duration
    for f=1, frames
        quad = love.graphics.newQuad x, y, w, h, img
        anim\addFrame quad
        x += w
    anim.current = 1
    animations[name] = anim

class Animation
    new: (name, img_path) =>
        @name = name
        @img = love.graphics.newImage img_path
        @animations = {}
        @failsafe = nil
        @current = nil
    
    addAnimation: (name, a) =>
        if a.frames
            add_dynamic name, a, @animations, @img
            return
        add_static name, a, @animations, @img unless a.frames
    
    update: =>
        anim = @animations[@current]
        anim = @animations[@failsafe] unless anim
        anim\update!
    
    draw: (x, y, mirror) =>
        anim = @animations[@current]
        anim = @animations[@failsafe] unless anim

        anim\draw x, y, mirror

load_animation = (path) ->
    anim_data = require(path)
    anim = Animation anim_data.name, anim_data.img
    for k, v in pairs(anim_data.anims)
        anim\addAnimation k, v
    anim.failsafe = anim_data.failsafe
    return anim

{:load_animation}

