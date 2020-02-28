local game = Concord.world()

-- ADD SYSTEMS
game:addSystem(_systems.motion)
game:addSystem(_systems.input)
game:addSystem(_systems.turn)
game:addSystem(_systems.hook)
game:addSystem(_systems.enemies)

return game
