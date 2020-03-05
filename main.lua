function love.load()
    GamestateManager = require("libs.gamestate")
    require("loading")
    require("title")
    require("game")
    GamestateManager.registerEvents()
    GamestateManager.switch(loading)
end

function love.update(dt)
end

function love.draw()
end
