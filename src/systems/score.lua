-- exit_reached

local score = Concord.system()
function score:init()
  self.timer = Timer.new()
  self.floor_counter = 1
  self.victory_pulse = {}
  self.pulse_lifespan = 1
  self.score_text = love.graphics.newText(_fonts["FLOOR_COUNTER"], "FLOOR #1")
  self:reset_pulse()
end

function score:reset_pulse()
  self.victory_pulse = {
    is_active = false,
    position = nil,
    radius = 0,
    alpha = 0.9,
    speed = 450,
    colour = {r = 0.867, g = 0.655, b = 0.047}
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
  self.score_text:set("FLOOR #" .. self.floor_counter)
  self:getWorld():emit("next_room", player_health, self.floor_counter)
end

function score:update(dt)
  self.timer:update(dt)
end

function score:draw()
  if self.victory_pulse.is_active then
    love.graphics.setColor(
      self.victory_pulse.colour.r,
      self.victory_pulse.colour.g,
      self.victory_pulse.colour.b,
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
  love.graphics.draw(self.score_text, love.graphics.getWidth() / 2 - self.score_text:getWidth() / 2, 50)
end

return score
