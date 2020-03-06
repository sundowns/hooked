local enemies =
  Concord.system(
  {_components.enemy, _components.grid, _components.brain, "ENEMIES"},
  {_components.control, _components.grid, _components.health, "PLAYER"}
)
function enemies:init()
  self.timer = Timer.new()
  self.process_enemy_callback_fn = nil
  self.enemies_to_action = {}
  self.current_phase = nil
  self.active = false
  self.turn_duration = 0.5
  self.navigation_map = nil
end

function enemies:navigation_map_generated(navigation_map)
  self.navigation_map = navigation_map
end

function enemies:update(dt)
  if self.active then
    self.timer:update(dt)

    if #self.enemies_to_action == 0 then
      -- all enemies processed, weeeeee
      self.active = false
      self:getWorld():emit("end_phase", "ENEMIES")
    end
  end
end

function enemies:begin_phase(phase)
  if phase ~= "ENEMIES" then
    return
  end

  self.active = true
  self.enemies_to_action = {}
  for i = 1, self.ENEMIES.size do
    local e = self.ENEMIES:get(i)
    table.insert(self.enemies_to_action, e)
  end

  self.process_enemy_callback_fn =
    self.timer:every(
    self.turn_duration / self.ENEMIES.size,
    function()
      self:action_top_enemy()
    end,
    #self.enemies_to_action
  )
end

function enemies:action_top_enemy()
  -- pop enemy from our table
  local enemy = table.remove(self.enemies_to_action, 1)
  if enemy:get(_components.enemy).marked_for_deletion then
    return
  end
  local brain = enemy:get(_components.brain)
  if brain.type == "goblin" then
    -- choose an action with their BRAIN
    self:action_goblin(enemy)
  else
    print("mystery brain...duhhh....")
  end
end

function enemies:draw_debug()
  if self.navigation_map then
    for y = 1, #self.navigation_map do
      for x = 1, #self.navigation_map[y] do
        love.graphics.print(self.navigation_map[y][x], 30 * x, 30 * y)
      end
    end
  end
end

function enemies:action_goblin(e)
  local enemy_pos = e:get(_components.grid).position
  local adjusted_pos = Vector(enemy_pos.x + 1, enemy_pos.y + 1)
  local current_distance = self.navigation_map[adjusted_pos.y][adjusted_pos.x]
  local choices = {{"wait", 1}}

  if
    adjusted_pos.x - 1 > 0 and self.navigation_map[adjusted_pos.y][adjusted_pos.x - 1] ~= -1 and
      self.navigation_map[adjusted_pos.y][adjusted_pos.x - 1] < current_distance
   then
    table.insert(
      choices,
      {
        "left",
        5
      }
    )
  end
  -- RIGHT
  if
    adjusted_pos.x + 1 <= #self.navigation_map[adjusted_pos.y] and
      self.navigation_map[adjusted_pos.y][adjusted_pos.x + 1] ~= -1 and
      self.navigation_map[adjusted_pos.y][adjusted_pos.x + 1] < current_distance
   then
    table.insert(
      choices,
      {
        "right",
        5
      }
    )
  end
  -- TOP
  if
    adjusted_pos.y - 1 > 0 and self.navigation_map[adjusted_pos.y - 1][adjusted_pos.x] ~= -1 and
      self.navigation_map[adjusted_pos.y - 1][adjusted_pos.x] < current_distance
   then
    table.insert(
      choices,
      {
        "up",
        5
      }
    )
  end
  -- BOTTOM
  if
    adjusted_pos.y + 1 <= #self.navigation_map and self.navigation_map[adjusted_pos.y + 1][adjusted_pos.x] ~= -1 and
      self.navigation_map[adjusted_pos.y + 1][adjusted_pos.x] < current_distance
   then
    table.insert(
      choices,
      {
        "down",
        5
      }
    )
  end

  local choice = _util.g.choose_weighted(unpack(choices))

  if choice ~= "wait" then
    self:getWorld():emit("attempt_entity_move", e, choice)
  end
end

return enemies
