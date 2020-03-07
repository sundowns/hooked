local enemies =
  Concord.system(
  {_components.enemy, _components.grid, _components.brain, "ENEMIES"},
  {_components.control, _components.grid, _components.health, "PLAYER"},
  {_components.collectible, "COLLECTIBLE"}
)
function enemies:init()
  self.timer = Timer.new()
  self.process_enemy_callback_fn = nil
  self.enemies_to_action = {}
  self.current_phase = nil
  self.active = false
  self.turn_duration = 0.25
  self.navigation_maps = {}
  self.collectible_exists = false

  self.COLLECTIBLE.onEntityAdded = function(pool, e)
    self.collectible_exists = true
  end

  self.COLLECTIBLE.onEntityRemoved = function(pool, e)
    self.collectible_exists = false
  end
end

function enemies:navigation_map_generated(type, navigation_map)
  self.navigation_maps[type] = navigation_map
end

function enemies:collectible_created()
end

function enemies:update(dt)
  self.timer:update(dt)
  if self.active then
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

  self.timer:clear()

  self.enemies_to_action = {}
  for i = 1, self.ENEMIES.size do
    local e = self.ENEMIES:get(i)
    table.insert(self.enemies_to_action, e)
  end

  if self.ENEMIES.size > 0 then
    self.active = true
    self.process_enemy_callback_fn =
      self.timer:every(
      math.min(self.turn_duration * 2 / self.ENEMIES.size, self.turn_duration),
      function()
        self:action_top_enemy()
      end,
      #self.enemies_to_action
    )
  else
    self.timer:after(
      self.turn_duration,
      function()
        self:getWorld():emit("end_phase", "ENEMIES")
      end
    )
  end
end

function enemies:action_top_enemy()
  -- pop enemy from our table
  local enemy = table.remove(self.enemies_to_action, 1)
  if enemy:get(_components.enemy).marked_for_deletion then
    return
  end
  local brain = enemy:get(_components.brain)
  if brain.type == "goblin" then
    self:action_goblin(enemy)
  elseif brain.type == "gremlin" then
    self:action_gremlin(enemy)
  else
    print("mystery brain...duhhh....")
  end
end

function enemies:draw_debug()
  love.graphics.setColor(1, 0, 0)
  if self.navigation_maps["player"] then
    for y = 1, #self.navigation_maps["player"] do
      for x = 1, #self.navigation_maps["player"][y] do
        love.graphics.print(self.navigation_maps["player"][y][x], 25 * x, 25 * y)
      end
    end
  end

  love.graphics.setColor(0, 1, 0)
  if self.navigation_maps["collectible"] then
    for y = 1, #self.navigation_maps["collectible"] do
      for x = 1, #self.navigation_maps["collectible"][y] do
        love.graphics.print(self.navigation_maps["collectible"][y][x], 800 + (25 * x), 25 * y)
      end
    end
  end
end

function enemies:navigate_to(entity, map_name, default_choices)
  local entity_pos = entity:get(_components.grid).position
  local adjusted_pos = Vector(entity_pos.x + 1, entity_pos.y + 1)
  local current_distance = self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x]

  local choices = default_choices or {}
  local adjacent_option = nil
  if
    adjusted_pos.x - 1 > 0 and self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x - 1] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x - 1] < current_distance
   then
    if self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x - 1] == 0 then
      adjacent_option = "left"
    end

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
    adjusted_pos.x + 1 <= #self.navigation_maps[map_name][adjusted_pos.y] and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x + 1] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x + 1] < current_distance
   then
    if self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x + 1] == 0 then
      adjacent_option = "right"
    end
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
    adjusted_pos.y - 1 > 0 and self.navigation_maps[map_name][adjusted_pos.y - 1][adjusted_pos.x] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y - 1][adjusted_pos.x] < current_distance
   then
    if self.navigation_maps[map_name][adjusted_pos.y - 1][adjusted_pos.x] == 0 then
      adjacent_option = "up"
    end
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
    adjusted_pos.y + 1 <= #self.navigation_maps[map_name] and
      self.navigation_maps[map_name][adjusted_pos.y + 1][adjusted_pos.x] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y + 1][adjusted_pos.x] < current_distance
   then
    if self.navigation_maps[map_name][adjusted_pos.y + 1][adjusted_pos.x] == 0 then
      adjacent_option = "down"
    end
    table.insert(
      choices,
      {
        "down",
        5
      }
    )
  end

  return choices, adjacent_option
end

function enemies:navigate_away_from(entity, map_name, default_choices)
  local entity_pos = entity:get(_components.grid).position
  local adjusted_pos = Vector(entity_pos.x + 1, entity_pos.y + 1)
  local current_distance = self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x]

  local choices = default_choices or {}
  if
    adjusted_pos.x - 1 > 0 and self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x - 1] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x - 1] > current_distance
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
    adjusted_pos.x + 1 <= #self.navigation_maps[map_name][adjusted_pos.y] and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x + 1] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x + 1] > current_distance
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
    adjusted_pos.y - 1 > 0 and self.navigation_maps[map_name][adjusted_pos.y - 1][adjusted_pos.x] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y - 1][adjusted_pos.x] > current_distance
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
    adjusted_pos.y + 1 <= #self.navigation_maps[map_name] and
      self.navigation_maps[map_name][adjusted_pos.y + 1][adjusted_pos.x] ~= -1 and
      self.navigation_maps[map_name][adjusted_pos.y + 1][adjusted_pos.x] > current_distance
   then
    table.insert(
      choices,
      {
        "down",
        5
      }
    )
  end

  return choices
end

function enemies:get_unblocked_options(entity, map_name, default_choices)
  local entity_pos = entity:get(_components.grid).position
  local adjusted_pos = Vector(entity_pos.x + 1, entity_pos.y + 1)
  local current_distance = self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x]

  local choices = default_choices or {}
  if adjusted_pos.x - 1 > 0 and self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x - 1] ~= -1 then
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
    adjusted_pos.x + 1 <= #self.navigation_maps[map_name][adjusted_pos.y] and
      self.navigation_maps[map_name][adjusted_pos.y][adjusted_pos.x + 1] ~= -1
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
  if adjusted_pos.y - 1 > 0 and self.navigation_maps[map_name][adjusted_pos.y - 1][adjusted_pos.x] ~= -1 then
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
    adjusted_pos.y + 1 <= #self.navigation_maps[map_name] and
      self.navigation_maps[map_name][adjusted_pos.y + 1][adjusted_pos.x] ~= -1
   then
    table.insert(
      choices,
      {
        "down",
        5
      }
    )
  end

  return choices
end

function enemies:action_goblin(e)
  local choices = {{"wait", 1}}

  local player = self.PLAYER:get(1)
  local player_position = player:get(_components.grid).position
  local enemy_position = e:get(_components.grid).position
  local distance_to_player =
    math.floor(_util.m.distance_between(player_position.x, player_position.y, enemy_position.x, enemy_position.y))

  if distance_to_player < 8 then
    choices, immediate_option = self:navigate_to(e, "player", choices)

    local choice = _util.g.choose_weighted(unpack(choices))

    if immediate_option then
      self:getWorld():emit("attempt_entity_move", e, immediate_option)
    elseif choice and choice ~= "wait" then
      self:getWorld():emit("attempt_entity_move", e, choice)
    end
  else
    choices = self:get_unblocked_options(e, "player", choices)
    local choice = _util.g.choose_weighted(unpack(choices))
    if choice and choice ~= "wait" then
      self:getWorld():emit("attempt_entity_move", e, choice)
    end
  end
end

function enemies:action_gremlin(e)
  local choices = {}
  if self.collectible_exists then
    choices = self:navigate_to(e, "collectible")
  else
    choices = {{"wait", 1}}
    choices = self:navigate_away_from(e, "player")
  end
  local choice = _util.g.choose_weighted(unpack(choices))
  if choice and choice ~= "wait" then
    self:getWorld():emit("attempt_entity_move", e, choice)
  end
end

return enemies
