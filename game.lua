game = {}
_DEBUG = false

function game:init()
  Concord = require("libs.concord")
  _components = Concord.components
  _systems = Concord.systems
  _worlds = Concord.worlds
  _assemblages = Concord.assemblages

  Concord.loadComponents("src/components")
  Concord.loadSystems("src/systems")
  Concord.loadWorlds("src/worlds")
  Concord.loadAssemblages("src/assemblages")
end

function game:enter()
  _worlds.game:emit("reset")
  _worlds.game:emit("next_room", _constants.PLAYER_STARTING_HEALTH, 1)
end

function game:update(dt)
  _worlds.game:emit("update", dt)
end

function game:draw()
  _worlds.game:emit("draw")

  _worlds.game:emit("draw_ui")

  if _DEBUG then
    love.graphics.setColor(1, 1, 0)
    _worlds.game:emit("draw_debug")
    _util.l.render_stats(0, love.graphics.getHeight() * 2 / 3)

    -- marker for screen centre
    love.graphics.circle("fill", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 2)
    _util.l.reset_colour()
  end
end

function game:keypressed(key, _, _)
  if key == "r" then
    love.event.quit("restart")
  elseif key == "escape" then
    -- love.event.quit()
  elseif key == "f1" then
    _DEBUG = not _DEBUG -- TODO: remove
  end

  _worlds.game:emit("keypressed", key)
end

function game:keyreleased(key)
  _worlds.game:emit("keyreleased", key)
end

function game:mousepressed(x, y, button, _, _)
  _worlds.game:emit("mousepressed", x, y, button)
end

function game:mousereleased(x, y, button, _, _)
  _worlds.game:emit("mousereleased", x, y, button)
end

function game:resize(w, h)
  _worlds.game:emit("resize", w, h)
end
