A = love.audio

class SoundPlayer
    new: =>
        @sources = {}
        @sources.hit = A.newSource "assets/asteroids/hit.wav", "static"
        @sources.killed = A.newSource "assets/asteroids/killed.wav", "static"
        @sources.select = A.newSource "assets/asteroids/select.wav", "static"
        @sources.shoot = A.newSource "assets/asteroids/shoot.wav", "static"
    
    play: (name) =>
        src = @sources[name]
        src\stop!
        src\seek 0
        src\play!

{:SoundPlayer}