local turn = Concord.system({_components.control, _components.selection, _components.hook_thrower, "PLAYER"})

function turn:init()
  self.turn_count = 0
  self.phase_index = 1
  self.phases = {
    [1] = "PLAYER",
    [2] = "HOOK",
    [3] = "ENEMIES"
  }
  self.text = {
    ["HOOK"] = love.graphics.newText(_fonts["CONTROLS"], "[Z] - Select Hook"),
    ["FIRE_HOOK"] = love.graphics.newText(_fonts["CONTROLS"], "[SPACE]: Fire Hook"),
    ["DIRECT"] = love.graphics.newText(_fonts["CONTROLS"], "[WASD/Arrows] - Select Direction"),
    ["MOVE"] = love.graphics.newText(_fonts["CONTROLS"], "[SPACE] - Move"),
    ["BACK"] = love.graphics.newText(_fonts["CONTROLS"], "[ESCAPE] - Deselect"),
    ["PASS"] = love.graphics.newText(_fonts["CONTROLS"], "Press [SPACE] to confirm PASS"),
    ["PROMPT_PASS"] = love.graphics.newText(_fonts["CONTROLS"], "[SPACE] - Pass"),
    ["PHASES"] = {}
  }
  self.gameplay_paused = false

  for i, phase in ipairs(self.phases) do
    self.text["PHASES"][phase] = love.graphics.newText(_fonts["PHASES"], phase)
  end
end

function turn:action_pressed(action, e)
  if not e:has(_components.control) or not e:has(_components.selection) then
    return
  end
  if self.gameplay_paused then
    return
  end
  if (action == "end_turn" or action == "back") and self.phases[self.phase_index] ~= "PLAYER" then
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
          selection:reset()
          self:end_phase("PLAYER")
        else
          selection:prompt_pass()
        end
      else
        self:getWorld():emit("attempt_entity_move", e, direction)
      end
    elseif action == "hook" and direction ~= "none" then
      local hook_thrower = e:get(_components.hook_thrower)
      if hook_thrower.can_throw then
        self:getWorld():emit("attempt_hook_throw", e, direction)
      else
        -- TODO: some sort of error/warning about 1 hook at a time
      end
    end
  end
end

function turn:exit_reached()
  self.gameplay_paused = true
end

function turn:player_died()
  self.gameplay_paused = true
end

function turn:next_room()
  self.gameplay_paused = false
end

function turn:end_phase(current)
  assert(current, "received nil phase to turn:end_phase")
  if current ~= self.phases[self.phase_index] then
    -- ignore that
    return
  end
  if self.gameplay_paused then
    return
  end

  self.phase_index = self.phase_index + 1
  if self.phase_index > #self.phases then
    self:getWorld():emit("turn_ended")
    self:begin_turn()
  else
    self:getWorld():emit("begin_phase", self.phases[self.phase_index])
  end
end

function turn:room_loaded()
  self.turn_count = 0
  self:begin_turn()
end

function turn:begin_turn()
  self.phase_index = 1
  self.turn_count = self.turn_count + 1
  local player = self.PLAYER:get(1)
  if player then
    local selection = player:get(_components.selection)
    local direction_held = false
    local control = player:get(_components.control)
    local held_direction = nil
    if control.is_held["left"] and not (control.is_held["right"] or control.is_held["up"] or control.is_held["down"]) then
      held_direction = "left"
    end
    if control.is_held["right"] and not (control.is_held["left"] or control.is_held["up"] or control.is_held["down"]) then
      held_direction = "right"
    end
    if control.is_held["up"] and not (control.is_held["right"] or control.is_held["left"] or control.is_held["down"]) then
      held_direction = "up"
    end
    if control.is_held["down"] and not (control.is_held["right"] or control.is_held["up"] or control.is_held["left"]) then
      held_direction = "down"
    end
    if held_direction then
      self:getWorld():emit("test_direction_is_valid", player, held_direction)
    end
  end
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
    self:getWorld():emit("test_direction_is_valid", e, action)
  end
end

function turn:report_player_direction_validity(player, direction, is_valid)
  if not (player:has(_components.control) and player:has(_components.selection)) then
    return
  end
  if is_valid then
    player:get(_components.selection):set_direction(direction)
  else
    player:get(_components.selection):reset()
  end
end

function turn:invalid_directional_action()
  -- reset player's direction
  self.PLAYER:get(1):get(_components.selection):reset()
end

function turn:draw_ui()
  -- draw controls
  if self.phases[self.phase_index] == "PLAYER" and not self.gameplay_paused then
    local player = self.PLAYER:get(1)
    local selection = player:get(_components.selection)
    local text_to_draw = {}
    local control_text_width = 0
    local buffer_width = 30
    function prepare_text_to_draw(text)
      table.insert(text_to_draw, text)
      control_text_width = control_text_width + text:getWidth() + buffer_width
    end

    -- draw options/controls
    if selection.is_passing then
      prepare_text_to_draw(self.text["PASS"])
    else
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
        prepare_text_to_draw(self.text["PROMPT_PASS"])
      end

      if selection.action == "move" and selection.direction ~= "none" then
        prepare_text_to_draw(self.text["MOVE"])
      end

      if (selection.direction ~= "none" and selection.action == "move") or selection.action == "hook" then
        prepare_text_to_draw(self.text["BACK"])
      end
    end

    local offset = 0
    for i, text in ipairs(text_to_draw) do
      love.graphics.draw(
        text,
        (love.graphics.getWidth() / 2) - (control_text_width / 2) + offset,
        love.graphics.getHeight() - text:getHeight() * 1.35
      )
      offset = offset + text:getWidth() + buffer_width
    end
  end

  -- draw phase tracker
  local tracker_coords =
    Vector(0, love.graphics.getHeight() / 2 - (#self.phases * _fonts["PHASES"]:getHeight() * 2 / 3))
  for i, phase_name in ipairs(self.phases) do
    local text = self.text["PHASES"][phase_name]
    if i == self.phase_index then
      love.graphics.setColor(_constants.COLOURS["GOLD"])
    end
    love.graphics.draw(text, tracker_coords.x, tracker_coords.y)
    tracker_coords.y = tracker_coords.y + text:getHeight() * 1.5
    _util.l.reset_colour()
  end
end

function turn:draw_debug()
  local player = self.PLAYER:get(1)
  local selection = player:get(_components.selection)
  love.graphics.print(selection:to_string(), 0, love.graphics.getHeight() - 20)
end
return turn
