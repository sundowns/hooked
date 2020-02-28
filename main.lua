local _worlds = nil -- should not have visbility of each other...
_DEBUG = true

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest", 0)
  -- Globals
  Vector = require("libs.vector")
  Timer = require("libs.timer")
  _constants = require("src.constants")
  _util = require("libs.util")
  Concord = require("libs.concord")

  _components = Concord.components
  _systems = Concord.systems
  _worlds = Concord.worlds
  _assemblages = Concord.assemblages

  Concord.loadComponents("src/components")
  Concord.loadSystems("src/systems")
  Concord.loadWorlds("src/worlds")
  Concord.loadAssemblages("src/assemblages")

  _assemblages.player:assemble(
    Concord.entity(_worlds.game),
    Vector(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
  )

  _worlds.game:emit("begin_turn")
end

function love.update(dt)
  _worlds.game:emit("update", dt)
end

function love.draw()
  _worlds.game:emit("draw")

  _worlds.game:emit("draw_ui")

  if _DEBUG then
    love.graphics.setColor(1, 1, 0)
    _worlds.game:emit("draw_debug")
    _util.l.render_stats(0, love.graphics.getHeight() / 2)
    _util.l.reset_colour()
  end
end

function love.keypressed(key, _, _)
  if key == "r" then
    love.event.quit("restart")
  elseif key == "escape" then
    -- love.event.quit()
  elseif key == "f1" then
    _DEBUG = not _DEBUG
  end

  _worlds.game:emit("keypressed", key)
end

function love.keyreleased(key)
  _worlds.game:emit("keyreleased", key)
end

function love.mousepressed(x, y, button, _, _)
  _worlds.game:emit("mousepressed", x, y, button)
end

function love.mousereleased(x, y, button, _, _)
  _worlds.game:emit("mousereleased", x, y, button)
end

function love.resize(w, h)
  _worlds.world:emit("resize", w, h)
end
