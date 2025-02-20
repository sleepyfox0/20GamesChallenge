return {
    name = "player",
    img = "assets/platformer/images/player.png",
    anims = {
        standing = {
            x = 0,
            y = 0,
            w = 16,
            h = 32
        },
        jumping = {
            x = 0,
            y = 32,
            w = 16,
            h = 32
        },
        falling = {
            x = 0,
            y = 2*32,
            w = 16,
            h = 32
        },
        running = {
            frames = 4,
            x = 0,
            y = 3*32,
            w = 16,
            h = 32,
            duration = 10
        }
    },
    failsafe = "standing"
}