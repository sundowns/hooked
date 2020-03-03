local hook =
  Concord.system(
  {_components.control, _components.hook_thrower, _components.grid, "PLAYER"},
  {_components.grid, _components.head, _components.chain, "HOOK"}
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

function get_opposite_direction(direction)
  if direction == "right" then
    return "left"
  elseif direction == "left" then
    return "right"
  elseif direction == "up" then
    return "down"
  elseif direction == "down" then
    return "up"
  end
end

function hook:init()
  self.timer = Timer.new()
end

function hook:throw_hook(direction)
  local player = self.PLAYER:get(1)
  local hook_thrower = player:get(_components.hook_thrower)
  -- check direction is valid

  hook_thrower:throw(direction)
  _assemblages.hook:assemble(
    Concord.entity(self:getWorld()),
    player:get(_components.grid).position + direction_to_offset(direction),
    direction
  )

  player:get(_components.selection):reset()

  self:getWorld():emit("end_phase")
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
    print("skipping phase, there is no hook out")
    self:getWorld():emit("end_phase")
  else
    local to_remove = {}
    for i = 1, self.HOOK.size do
      local e = self.HOOK:get(i)
      local grid = e:get(_components.grid)
      local head = e:get(_components.head)
      local chain = e:get(_components.chain)
      if head.is_extending then
        -- check if we're at max length, if so, begin retracting
        if chain:is_full() then
          -- print("chain is full, lets retract")
          -- head:retract() -- TODO: not sure about this yet
        else
          -- move one step in the head's direction
          self:getWorld():emit("attempt_entity_move", e, head.direction, false)
        end
      end
      -- this is deliberatly not an else, as the above logic could change the state and we want to action that
      if not head.is_extending then
        -- we're retracting, move to the last chain link and shrink the chain

        if #chain.links == 0 then
          self:getWorld():removeEntity(e)
          self.PLAYER:get(1):get(_components.hook_thrower):reset()
        else
          chain:consume_last() -- this will intentionally be undone if the hook failed to move

          self:getWorld():emit("attempt_entity_move", e, head.direction, false)
        end
      end
    end

    for i, entity in ipairs(to_remove) do
      self:getWorld():removeEntity(entity)
    end

    self:getWorld():emit("end_phase")
  end
end

function hook:player_with_hook_moved(old_position, new_position, direction)
  for i = 1, self.HOOK.size do
    local e = self.HOOK:get(i)
    local chain = e:get(_components.chain)
    local current_back_link = chain.links[1]
    if current_back_link then
      if current_back_link.position ~= new_position then
        chain:add_link_to_back(old_position, get_opposite_direction(direction))
      else
        -- also delete the last one (the one we're moving onto)
        chain:consume_first()
      end
    else
      -- there are no links, just add one
      chain:add_link_to_back(old_position, get_opposite_direction(direction))
    end
  end
end

function hook:invalid_entity_move(e)
  if not (e:has(_components.head) and e:has(_components.grid)) then
    return -- that ain't no hook
  end
  print("hook could not move!")
  local chain = e:get(_components.chain)
  local head = e:get(_components.head)
  if chain.last_consumed then
    head:set_direction(get_opposite_direction(chain.last_consumed.direction))
    chain:restore_last()
  end
  if head.is_extending then
    print("wtf?")
    head:set_direction(get_opposite_direction(head.direction))
    head:retract()
  end
end

function hook:hook_moved(e, previous_position)
  local head = e:get(_components.head)
  local chain = e:get(_components.chain)
  if head.is_extending then
    chain:add_link_to_front(previous_position, head.direction)
  else
    if chain.last_consumed then
      head:set_direction(get_opposite_direction(chain.last_consumed.direction))
    end
  end
end

return hook
