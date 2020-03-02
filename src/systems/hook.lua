local hook =
  Concord.system(
  {_components.control, _components.hook_thrower, _components.grid, "PLAYER"},
  {_components.grid, _components.grid, _components.chain, "HOOK"}
)

local _DIRECTION_OFFSETS = {
  ["right"] = Vector(1, 0),
  ["down"] = Vector(0, 1),
  ["left"] = Vector(-1, 0),
  ["up"] = Vector(0, -1)
}

function direction_to_offset(direction)
  assert(_DIRECTION_OFFSETS[direction], "'direction_to_offset' received invalid direction")
  return _DIRECTION_OFFSETS[direction]:clone()
end

function hook:init()
  self.timer = Timer.new()
end

function hook:throw_hook(direction)
  local player = self.PLAYER:get(1)
  local hook_thrower = player:get(_components.hook_thrower)
  hook_thrower:throw(direction)

  _assemblages.hook:assemble(
    Concord.entity(self:getWorld()),
    player:get(_components.grid).position + direction_to_offset(direction)
  )
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
      0.5,
      function()
        self:getWorld():emit("end_phase")
      end
    )
  end
end

return hook
