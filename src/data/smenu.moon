import lerp_color, FONT from require "data/graphics"

G = love.graphics

class Selection
    new: (text, caller, f) =>
        @txt = text
        @caller = caller
        @fun = f
    
    call: =>
        fun = @fun
        c = @caller
        fun(c)

class SelectMenu
    new: (caller) =>
        @caller = caller
        @selections = {}
        @selected = -1
        @active = false
        @stayActive = false
        @x = 0
        @y = 0
        @bkgc = {0, 0, 0, 1}
        @frgc = {1, 1, 1, 1}
        @midc = lerp_color @bkgc, @frgc, 0.5
    
    setColours: (c1, c2) =>
        @bkgc = c1
        @frgc = c2
        @midc = lerp_color c1, c2, 0.5
    
    add: (text, fun) =>
        s = Selection text, @caller, fun
        table.insert @selections, s
        @selected = 1 if @selected == -1
    
    getSize: =>
        height = #@selections * 8 + 16
        width = 0
        for s in *@selections
            w = FONT\getWidth s.txt
            width = math.max width, w
        return width+16, height

    eventTriggered: (event) =>
        return unless @active
        if event == "up"
            @selected -= 1
        elseif event == "down"
            @selected += 1
        elseif event == "confirm"
            s = @selections[@selected]
            s\call!
        elseif event == "cancel"
            @active = false unless @stayActive
        @selected = @selected < 1 and #@selections or (@selected > #@selections and 1 or @selected)


    draw: =>
        return unless @active
        width, height = @getSize!
        fnt = G.getFont!

        G.push!
        G.translate @x, @y
        G.setFont FONT
        G.setColor @bkgc
        G.rectangle "fill", 0, 0, width, height
        y = 8
        for i, s in ipairs(@selections)
            if i == @selected
                G.setColor @frgc
            else
                G.setColor @midc
            G.print s.txt, 8, y
            y += 8
        G.pop!
        G.setFont fnt
            
{:SelectMenu}