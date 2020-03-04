local game = Concord.world()

-- ADD SYSTEMS
game:addSystem(_systems.input)
game:addSystem(_systems.turn)
game:addSystem(_systems.hook)
game:addSystem(_systems.enemies)
game:addSystem(_systems.room)
game:addSystem(_systems.health)
game:addSystem(_systems.score)

return game
