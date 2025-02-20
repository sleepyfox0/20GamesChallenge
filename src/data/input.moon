
KEYS = love.keyboard
JOY = love.joystick

-- First make keyboard
event_key_lu = {}
event_key_lu.up = "up"
event_key_lu.left = "left"
event_key_lu.down = "down"
event_key_lu.right = "right"

event_key_lu.confirm = "a"
event_key_lu.cancel = "escape"

-- Gamepad
event_gp_lu = {}
event_gp_lu.up = "dpup"
event_gp_lu.left = "dpleft"
event_gp_lu.down = "dpdown"
event_gp_lu.right = "dpright"

event_gp_lu.confirm = "a"
event_gp_lu.cancel = "b"

-- First make keyboard
key_event_lu = {}
key_event_lu.up = "up"
key_event_lu.left = "left"
key_event_lu.down = "down"
key_event_lu.right = "right"

key_event_lu.a = "confirm"
key_event_lu.escape = "cancel"

-- Gamepad
gp_event_lu = {}
gp_event_lu.dpup = "up"
gp_event_lu.dpleft = "left"
gp_event_lu.dpdown = "down"
gp_event_lu.dpright = "right"

gp_event_lu.a = "confirm"
gp_event_lu.b = "cancel"

isDown = (event) ->
    button = event_gp_lu[event]
    return false unless button
    sticks = JOY.getJoysticks!
    if #sticks > 0
        gp = sticks[1]
        return true if gp\isGamepadDown(button)
    -- check kezboard
    key = event_key_lu[event]
    return false unless key
    return KEYS.isDown key

getUpDown = ->
    sticks = JOY.getJoysticks!
    if #sticks > 0
        gp = sticks[1]
        x = gp\getGamepadAxis "lefty"
        return x math.abs(x) > 0.1
    return -1 if isDown "up"
    return 1 if isDown "down"
    0

getLeftRight = ->
    sticks = JOY.getJoysticks!
    if #sticks > 0
        gp = sticks[1]
        x = gp\getGamepadAxis "leftx"
        return x if math.abs(x) > 0.1
    return -1 if isDown "left"
    return 1 if isDown "right"
    0

receiver = nil

setReceiver = (rec) ->
    receiver = rec

keypressed = (key, scancode, isrepeat) ->
    return unless receiver
    event = key_event_lu[key]
    return unless event
    receiver\eventTriggered event if receiver.eventTriggered

gamepadpressed = (joystick, button) ->
    return unless receiver
    event = gp_event_lu[button]
    return unless event
    receiver\eventTriggered event if receiver.eventTriggered

keyreleased = (key, scancode, isrepeat) ->
    return unless receiver
    event = key_event_lu[key]
    return unless event
    receiver\eventReleased event if receiver.eventReleased

gamepadreleased = (joystick, button) ->
    return unless receiver
    event = gp_event_lu[button]
    return unless event
    receiver\eventReleased event if receiver.eventReleased

{:isDown, :keypressed, :gamepadpressed, :setReceiver, :getUpDown, :getLeftRight, :keyreleased, :gamepadreleased}