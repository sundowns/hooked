-- exit_reached

local score = Concord.system()
function score:init()
  self.pulse_lifespan = 1
  self.text = {
    ["SCORE"] = love.graphics.newText(_fonts["FLOOR_COUNTER"], "FLOOR #1"),
    ["DEFEAT"] = love.graphics.newText(_fonts["GAME_OVER"], "GAME OVER")
  }
  self:reset()
end

function score:reset()
  print('what the actual fuck')
  self.defeat = false
  self.timer = Timer.new()
  self.floor_counter = 1
  self.victory_pulse = {}
  self.text["SCORE"]:set("FLOOR #" .. self.floor_counter)
  self:reset_pulse()
end

function score:reset_pulse()
  self.victory_pulse = {
    is_active = false,
    position = nil,
    radius = 0,
    alpha = 0.9,
    speed = 450,
    colour = _constants.COLOURS["GOLD"]
  }
end

function score:exit_reached(position, player_health)
  self.victory_pulse.is_active = true
  self.victory_pulse.position = position

  self.timer:tween(self.pulse_lifespan, self.victory_pulse, {alpha = 0}, "out-circ")

  self.timer:during(
    self.pulse_lifespan,
    function(dt)
      self.victory_pulse.radius = self.victory_pulse.radius + dt * self.victory_pulse.speed
    end,
    function()
      self:next_floor(player_health)
    end
  )
end

function score:next_floor(player_health)
  self.timer:clear()
  self:reset_pulse()
  self.floor_counter = self.floor_counter + 1
  self.text["SCORE"]:set("FLOOR #" .. self.floor_counter)
  self:getWorld():emit("next_room", player_health, self.floor_counter)
end

function score:player_died()
  self.defeat = true
  self.timer:after(
    5,
    function()
      self:getWorld():clear()
      self.defeat = false
      GamestateManager.switch(title, {floor_count = self.floor_counter})
    end
  )
end

function score:update(dt)
  self.timer:update(dt)
end

function score:draw()
  if self.victory_pulse.is_active then
    love.graphics.setColor(
      self.victory_pulse.colour[1],
      self.victory_pulse.colour[2],
      self.victory_pulse.colour[3],
      self.victory_pulse.alpha
    )
    love.graphics.circle(
      "fill",
      self.victory_pulse.position.x,
      self.victory_pulse.position.y,
      self.victory_pulse.radius
    )
    _util.l.reset_colour()
  end
end

function score:draw_ui()
  love.graphics.draw(self.text["SCORE"], love.graphics.getWidth() / 2 - self.text["SCORE"]:getWidth() / 2, 50)
  if self.defeat then
    love.graphics.setColor(0.965, 0.20, 0.388)
    love.graphics.draw(
      self.text["DEFEAT"],
      love.graphics.getWidth() / 2 - self.text["DEFEAT"]:getWidth() / 2,
      love.graphics.getHeight() / 2 - self.text["DEFEAT"]:getHeight() / 2
    )
    _util.l.reset_colour()
  end
end

return score
