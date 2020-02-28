local hook = Concord.system({_components.control, _components.hook_thrower, "PLAYER"})
function hook:init()
  self.timer = Timer.new()
end

function hook:throw_hook(direction)
  local player = self.PLAYER:get(1)
  local hook_thrower = player:get(_components.hook_thrower)
  hook_thrower:throw(direction)
  -- TODO: spawn the actual hook entity
end

function hook:update(dt)
  self.timer:update(dt)
end

function hook:begin_phase(phase)
  if phase ~= "HOOK" then
    return
  end

  local player = self.PLAYER:get(1)
  if player:get(_components.hook_thrower).can_throw then
    self:getWorld():emit("end_phase")
  else
    print("hook is out, lets move it!")
    self.timer:after(
      1,
      function()
        self:getWorld():emit("end_phase")
      end
    )
  end
end

return hook
