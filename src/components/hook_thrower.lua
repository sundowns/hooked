local hook_thrower =
  Concord.component(
  function(e)
    e.can_throw = true
    e.direction = nil
  end
)

function hook_thrower:throw(direction)
  assert(direction, "hook_thrower requires a direction to throw()")
  self.can_throw = false
  self.direction = direction
end

function hook_thrower:reset()
  self.can_throw = true
  self.direction = nil
end

return hook_thrower
