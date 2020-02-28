local enemies = Concord.system({})
function enemies:init()
  self.timer = Timer.new()
end

function enemies:update(dt)
  self.timer:update(dt)
end

function enemies:begin_phase(phase)
  if phase ~= "ENEMIES" then
    return
  end

  self.timer:after(
    1,
    function()
      self:getWorld():emit("end_phase")
    end
  )
end

return enemies
