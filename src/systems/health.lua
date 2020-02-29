local health = Concord.system({_components.health, _components.control, "PLAYER"})
function health:init()
  -- self.timer = Timer.new()
end

function health:update(dt)
  -- self.timer:update(dt)
end

function health:reduce()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)
  health:reduce(1)
  if health.current <= 0 then
    print("ur dead dude") -- TODO:
  end
end

function health:draw_debug()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)
  love.graphics.print(health.current .. "/" .. health.maximum, love.graphics.getWidth() / 2, 0)
end

return health
