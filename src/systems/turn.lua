local turn = Concord.system({_components.control, _components.selection, _components.hook_thrower, "PLAYER"})

function turn:init()
  self.turn_count = 0
  self.phases = {
    "PLAYER",
    "HOOK",
    "ENEMIES"
  }
  self.done = {
    ["hook"] = false,
    ["enemies"] = false,
    ["items"] = false
  }
  self.phase_index = 1
  self.text = {
    ["HOOK"] = love.graphics.newText(love.graphics.getFont(), "[Z] - Select Hook"),
    ["FIRE_HOOK"] = love.graphics.newText(love.graphics.getFont(), "[SPACE] - Fire Hook"),
    ["DIRECT"] = love.graphics.newText(love.graphics.getFont(), "[WASD/Arrows] - Select Direction"),
    ["MOVE"] = love.graphics.newText(love.graphics.getFont(), "[SPACE] - Move"),
    ["BACK"] = love.graphics.newText(love.graphics.getFont(), "[ESCAPE] - Back"),
    ["PASS"] = love.graphics.newText(love.graphics.getFont(), "Press [SPACE] again to confirm pass"),
    ["PHASES"] = {}
  }

  for i, phase in ipairs(self.phases) do
    self.text["PHASES"][phase] = love.graphics.newText(love.graphics.getFont(), phase)
  end
end

function turn:action_pressed(action, e)
  if self.phases[self.phase_index] ~= "PLAYER" then
    return
  end
  if not e:has(_components.control) or not e:has(_components.selection) then
    return
  end
  if action == "end_turn" then
    if e:get(_components.selection).action then
      self:end_player_phase(e)
    end
  elseif action == "back" then
    e:get(_components.selection):reset()
  else
    self:make_selection(action, e)
  end
end

function turn:end_player_phase(e)
  local selection = e:get(_components.selection)
  local action = selection.action
  local direction = selection.direction

  if action and direction then
    if action == "move" then
      if direction == "none" then
        if selection.is_passing then
          self:end_phase("pass")
        else
          selection:prompt_pass()
        end
      else
        self:getWorld():emit("attempt_entity_move", e, direction, true)
      end
    elseif action == "hook" and direction ~= "none" then
      local hook_thrower = e:get(_components.hook_thrower)
      if hook_thrower.can_throw then
        self:getWorld():emit("attempt_hook_throw", e, direction)
      else
        -- TODO: some sort of error/warning about 1 hook at a time
        print("hook is already out :c!")
      end
    end
  end
end

function turn:end_phase()
  self.phase_index = self.phase_index + 1
  if self.phase_index > #self.phases then
    self:getWorld():emit("turn_ended")
    self:begin_turn()
  else
    self:getWorld():emit("begin_phase", self.phases[self.phase_index])
  end
end

function turn:begin_turn()
  self.phase_index = 1
  self.turn_count = self.turn_count + 1
  print("Begin turn: " .. self.turn_count)
  local player = self.PLAYER:get(1)
  local selection = player:get(_components.selection)
  local direction_held = false
  local control = player:get(_components.control)
  if control.is_held["left"] and not (control.is_held["right"] or control.is_held["up"] or control.is_held["down"]) then
    selection:set_direction("left")
    direction_held = true
  end
  if control.is_held["right"] and not (control.is_held["left"] or control.is_held["up"] or control.is_held["down"]) then
    selection:set_direction("right")
    direction_held = true
  end
  if control.is_held["up"] and not (control.is_held["right"] or control.is_held["left"] or control.is_held["down"]) then
    selection:set_direction("up")
    direction_held = true
  end
  if control.is_held["down"] and not (control.is_held["right"] or control.is_held["up"] or control.is_held["left"]) then
    selection:set_direction("down")
    direction_held = true
  end
  selection:reset(direction_held)
end

function turn:make_selection(action, e)
  local selection = e:get(_components.selection)
  local action = string.lower(action)
  if selection.all_actions[action] then
    local hook_thrower = e:get(_components.hook_thrower)
    if action ~= "hook" or hook_thrower.can_throw then
      selection:set_action(action)
    end
  elseif selection.all_directions[action] then
    selection:set_direction(action)
  end
end

function turn:invalid_directional_action()
  -- reset player's direction
  self.PLAYER:get(1):get(_components.selection):reset_direction()
end

function turn:draw_ui()
  local player = self.PLAYER:get(1)
  local selection = player:get(_components.selection)

  local text_to_draw = {}
  local control_text_width = 0
  local buffer_width = 20
  function prepare_text_to_draw(text)
    table.insert(text_to_draw, text)
    control_text_width = control_text_width + text:getWidth() + buffer_width
  end

  -- draw options/controls
  if selection.is_passing then
    prepare_text_to_draw(self.text["PASS"])
  else
    if (selection.direction ~= "none" and selection.action == "move") or selection.action == "hook" then
      prepare_text_to_draw(self.text["BACK"])
    end

    local hook_thrower = player:get(_components.hook_thrower)
    if hook_thrower.can_throw then
      if selection.action == "hook" then
        if selection.direction ~= "none" then
          prepare_text_to_draw(self.text["FIRE_HOOK"])
        end
      else
        prepare_text_to_draw(self.text["HOOK"])
      end
    end

    if selection.direction == "none" then
      prepare_text_to_draw(self.text["DIRECT"])
    end

    if selection.action == "move" and selection.direction ~= "none" then
      prepare_text_to_draw(self.text["MOVE"])
    end
  end

  local offset = 0
  for i, text in ipairs(text_to_draw) do
    love.graphics.draw(
      text,
      (love.graphics.getWidth() / 2) - (control_text_width / 2) + offset,
      love.graphics.getHeight() - text:getHeight() * 2
    )
    offset = offset + text:getWidth() + buffer_width
  end

  -- draw phase tracker
  local tracker_coords = Vector(0, 0)
  for i, phase_name in ipairs(self.phases) do
    local text = self.text["PHASES"][phase_name]
    if phase_name == self.phases[self.phase_index] then
      love.graphics.setColor(0, 1, 0)
    end
    love.graphics.draw(text, tracker_coords.x, tracker_coords.y)
    tracker_coords.y = tracker_coords.y + text:getHeight()
    _util.l.reset_colour()
  end
end

function turn:draw_debug()
  local player = self.PLAYER:get(1)
  local selection = player:get(_components.selection)
  love.graphics.print(selection:to_string(), 0, love.graphics.getHeight() - 20)
end
return turn
