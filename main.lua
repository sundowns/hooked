function love.load()
    GamestateManager = require("libs.gamestate")
    require("loading")
    require("game")
    GamestateManager.registerEvents()
    GamestateManager.switch(loading)
end

function love.update(dt)
end

function love.draw()
end
