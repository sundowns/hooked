local room =
  Concord.system(
  {_components.grid, _components.id, "ALL"},
  {_components.grid, _components.sprite, _components.id, "DRAWABLE"},
  {_components.control, _components.grid, _components.id, "PLAYER"},
  {_components.chain, _components.head, _components.id, "HOOK_CHAIN"},
  {_components.grid, _components.selection, "SELECTORS"},
  {_components.collectible, _components.grid, "COLLECTIBLES"}
)

local _TILE_LOOKUP = {
  [0] = "dirt", -- spawn tile
  [1] = "dirt",
  [2] = "wall",
  [3] = "exit",
  [10] = "door_orange",
  [11] = "door_blue",
  [12] = "door_purple"
}
-- can store individual tile data
local _TILE_DICTIONARY = {
  [_TILE_LOOKUP[0]] = {
    name = "spawn",
    quad = _sprites.build_quad(0, 0),
    walkable = true
  },
  [_TILE_LOOKUP[1]] = {
    name = "dirt",
    quad = _sprites.build_quad(0, 0),
    walkable = true
  },
  [_TILE_LOOKUP[2]] = {
    name = "wall",
    quad = _sprites.build_quad(1, 0),
    walkable = false
  },
  [_TILE_LOOKUP[3]] = {
    name = "exit",
    quad = _sprites.build_quad(2, 0),
    walkable = true
  }
}

local _DIRECTION_OFFSETS = {
  ["right"] = Vector(1, 0),
  ["down"] = Vector(0, 1),
  ["left"] = Vector(-1, 0),
  ["up"] = Vector(0, -1)
}

-- from default (pointing UP)
local _DIRECTION_ROTATIONS = {
  ["right"] = math.pi / 2,
  ["down"] = math.pi,
  ["left"] = -math.pi / 2,
  ["up"] = math.pi * 2
}

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

function direction_to_offset(direction)
  assert(_DIRECTION_OFFSETS[direction], "'direction_to_offset' received invalid direction")
  return _DIRECTION_OFFSETS[direction]:clone()
end

function direction_to_rotation(direction)
  assert(_DIRECTION_ROTATIONS[direction], "'direction_to_rotation' received invalid direction")
  return _DIRECTION_ROTATIONS[direction]
end

function lookup_tile(id)
  return _TILE_DICTIONARY[_TILE_LOOKUP[id]]
end

function room:init()
  self.generator = require("src.room_generator")
  self.timer = Timer.new()
  self.grid = {}
  self.grid_origin = Vector(0, 0)
  self.occupancy_map = {}
  self.tile_scale = 8
  self.selector_scale = 4

  -- Screen shake vars
  self.screen_shaking = false
  self.shake_duration = 0
  self.shake_count = 0
  self.shake_magnitude = 2

  self.ALL.onEntityAdded = function(pool, e)
    local grid = e:get(_components.grid)
    if grid.is_occupier then
      self:set_occupancy(grid.position.x, grid.position.y, e)
    end
  end

  self.ALL.onEntityRemoved = function(pool, e)
    local grid = e:get(_components.grid)
    if grid.is_occupier then
      local occupant = self:get_occupant(grid.position.x, grid.position.y)
      if occupant and occupant:get(_components.id).value == e:get(_components.id).value then
        self:set_occupancy(grid.position.x, grid.position.y, nil)
      end
    end
  end
end

function room:set_occupancy(x, y, occupant)
  self.occupancy_map[y + 1][x + 1] = occupant
end

function room:get_occupant(x, y)
  if not self.occupancy_map[y + 1] or not self.occupancy_map[y + 1][x + 1] then
    return nil
  end
  return self.occupancy_map[y + 1][x + 1]
end

function room:next_room(player_health, current_floor)
  self:getWorld():clear()
  local room, navigation_maps =
    self.generator:generate_room(current_floor, player_health, _constants.PLAYER_STARTING_HEALTH)
  self:load_room(room, player_health)
  self:getWorld():emit("room_loaded")
  self:getWorld():emit("navigation_map_generated", "player", navigation_maps["player"])
  if navigation_maps["collectible"] then
    self:getWorld():emit("navigation_map_generated", "collectible", navigation_maps["collectible"])
  end
end

function room:load_room(layout_grid, player_health)
  local rows = #layout_grid
  local cols = #layout_grid[1]
  self.grid = layout_grid
  self.grid_origin =
    Vector(
    (love.graphics.getWidth() / 2) - (cols / 2 * _constants.TILE_SIZE * self.tile_scale),
    (love.graphics.getHeight() / 2) - (rows / 2 * _constants.TILE_SIZE * self.tile_scale)
  )

  self.occupancy_map = {}
  self.to_spawn = {}
  local player_spawn = Vector(0, 0)
  for y, row in ipairs(self.grid) do
    self.occupancy_map[y] = {}
    for x, tile_id in ipairs(row) do
      self:set_occupancy(x - 1, y - 1, nil)
      if tile_id == 0 then
        player_spawn = Vector(x - 1, y - 1)
        self.grid[y][x] = 1 -- make this a dirt block
      elseif tile_id == 10 or tile_id == 11 or (tile_id >= 20 and tile_id <= 23) then
        table.insert(self.to_spawn, {type = tile_id, position = Vector(x - 1, y - 1)})
        self.grid[y][x] = 1 -- make this a dirt block
      end
    end
  end
  _assemblages.player:assemble(Concord.entity(self:getWorld()), player_spawn, player_health)

  for i, spawner in ipairs(self.to_spawn) do
    if spawner.type == 10 then
      _assemblages.goblin:assemble(Concord.entity(self:getWorld()), spawner.position)
    elseif spawner.type == 11 then
      _assemblages.gremlin:assemble(Concord.entity(self:getWorld()), spawner.position)
    elseif spawner.type == 20 then
      _assemblages.healthpack:assemble(Concord.entity(self:getWorld()), spawner.position)
    end
  end
end

function room:shake(duration, magnitude)
  if self.screen_shaking then
    return
  end
  self.screen_shaking = true
  self.shake_duration = duration
  self.shake_magnitude = magnitude
end

function room:update(dt)
  self.timer:update(dt)
  if self.screen_shaking then
    if self.shake_duration > self.shake_count then
      self.shake_count = self.shake_count + dt
    else
      self.screen_shaking = false
      self.shake_count = 0
      self.shake_duration = 0
    end
  end

  for i = 1, self.COLLECTIBLES.size do
    local e = self.COLLECTIBLES:get(i)
    local position = e:get(_components.grid).position
    local occupant = self:get_occupant(position.x, position.y)
    local collectible_type = e:get(_components.collectible).type
    if occupant then
      if occupant:has(_components.control) then
        -- if its a player, pickup
        self:getWorld():emit("player_got_collectible", collectible_type)
        self:getWorld():removeEntity(e)
      elseif occupant:has(_components.head) or occupant:has(_components.enemy) then
        -- if its a hook or enemy, check for inventory
        local inventory = occupant:get(_components.inventory)
        if inventory and inventory:is_empty() then
          ---- if inventory present, add to it & and delete collectible
          inventory:pickup(collectible_type)
          self:getWorld():removeEntity(e)
        end
      -- else do fuck all
      end
    end
  end
end

function room:is_empty(position)
  if not self.grid[position.y + 1] or not self.grid[position.y + 1][position.x + 1] then
    return false
  end
  if self:get_occupant(position.x, position.y) then
    return false -- something is here already
  end
  local tile = lookup_tile(self.grid[position.y + 1][position.x + 1])
  return tile.walkable
end

function room:move_entity(e, direction)
  local grid = e:get(_components.grid)
  local target_position = grid.position + direction_to_offset(direction)
  local occupant = self:get_occupant(target_position.x, target_position.y)
  local old_position = grid.position:clone()
  grid:translate(direction_to_offset(direction))
  if grid.is_occupier then
    -- empty current tile, occupy new one
    self:set_occupancy(old_position.x, old_position.y, nil)
    self:set_occupancy(grid.position.x, grid.position.y, e)
  end

  -- Fire event if hook was the one that moved:
  if e:has(_components.head) and e:has(_components.chain) then
    self:getWorld():emit("hook_moved", e, old_position)
  end

  -- Fire event if player was one that moved:
  if e:get(_components.control) then
    self:getWorld():emit("shake", 0.15, 0.15)
    -- check if chain is out, if so remove last link
    local hook_thrower = e:get(_components.hook_thrower)
    if not hook_thrower.can_throw then
      self:getWorld():emit("player_with_hook_moved", old_position, grid.position, direction)
    end

    if self:get_tile_at(grid.position.x, grid.position.y).name == "exit" then
      self:getWorld():emit("exit_reached", self:get_screen_coords(grid.position), e:get(_components.health).current)
    else
      self:getWorld():emit(
        "navigation_map_generated",
        "player",
        self.generator:generate_navigation_map(Vector(grid.position.x + 1, grid.position.y + 1), self.grid)
      )
      self:getWorld():emit("end_phase", "PLAYER")
    end
  end
end

function room:switch_entity_positions(first, second)
  local first_grid = first:get(_components.grid)
  local second_grid = second:get(_components.grid)
  if first_grid.is_occupier and second_grid.is_occupier then
    local first_pos = first_grid.position:clone()
    local second_pos = second_grid.position:clone()

    first_grid:set_position(second_pos)
    second_grid:set_position(first_pos)

    self:set_occupancy(first_pos.x, first_pos.y, second)
    self:set_occupancy(second_pos.x, second_pos.y, first)
  end
end

function room:get_tile_at(x, y)
  if not self.grid[y + 1] or not self.grid[y + 1][x + 1] then
    return nil
  end
  return lookup_tile(self.grid[y + 1][x + 1])
end

function room:attempt_entity_move(e, direction)
  if not e:has(_components.grid) then
    return
  end
  if self:validate_direction(e, direction) then
    local target_pos = e:get(_components.grid).position + direction_to_offset(direction)
    local occupant = self:get_occupant(target_pos.x, target_pos.y)
    if occupant then
      if e:has(_components.head) then
        self:hook_collided_with_something(e, occupant, target_pos, direction)
      elseif e:has(_components.enemy) then
        self:enemy_collided_with_something(e, occupant, target_pos, direction)
      elseif e:has(_components.control) then
        self:player_collided_with_something(e, occupant, target_pos, direction)
      end
    else
      self:move_entity(e, direction)
    end
  else
    self:getWorld():emit("invalid_entity_move", e)
    if e:has(_components.control) then
      self:getWorld():emit("invalid_directional_action")
    end
  end
end

function room:player_collided_with_something(player, occupant, collided_at, direction)
  if (occupant:has(_components.chain) and occupant:get(_components.chain):get_length() == 0) then
    local inventory = occupant:get(_components.inventory)
    if inventory and not inventory:is_empty() then
      self:getWorld():emit("player_got_collectible", inventory.current)
    end
    self:set_occupancy(collided_at.x, collided_at.y, nil)
    self:move_entity(player, direction)
    self:getWorld():removeEntity(occupant)
    player:get(_components.hook_thrower):reset()
  else
    print("player collided with some unknown entity") --TODO: nuke
  end
end

function room:hook_collided_with_something(hook, occupant, collided_at, direction)
  if occupant:has(_components.enemy) then
    local inventory = occupant:get(_components.inventory)
    if inventory and not inventory:is_empty() then
      self:spawn_collectible(inventory.current, collided_at)
    end

    self:set_occupancy(collided_at.x, collided_at.y, nil)
    occupant:get(_components.enemy):mark_for_deletion()
    self:getWorld():removeEntity(occupant)
    -- no need to unset occupancy for enemy here
    self:move_entity(hook, direction)
  else
    print("hook hit something whack dawg")
  end
end

function room:enemy_collided_with_something(enemy, occupant, collided_at, direction)
  local position = enemy:get(_components.grid).position

  if occupant:has(_components.control) then
    self:getWorld():emit("reduce_health")
  elseif occupant:has(_components.head) then
    self:set_occupancy(position.x, position.y, nil)
    self:getWorld():removeEntity(enemy)
  elseif occupant:has(_components.enemy) and occupant:has(_components.brain) then
    local target_brain = occupant:get(_components.brain)
    if target_brain.type == "goblin" then
      self:switch_entity_positions(enemy, occupant)
    end
  else
    print("enemy hit something unknown")
  end
end

function room:spawn_collectible(type, position)
  if type == "health" then
    _assemblages.healthpack:assemble(Concord.entity(self:getWorld()), position)
  end
end

function room:attempt_hook_throw(e, direction)
  if not e:has(_components.grid) then
    return
  end
  local grid = e:get(_components.grid)
  if self:validate_direction(e, direction) then
    local attempted_position = grid.position + direction_to_offset(direction)
    local occupant = self:get_occupant(attempted_position.x, attempted_position.y)
    local item = nil
    if occupant then
      if occupant:has(_components.enemy) then
        local enemy_inventory = occupant:get(_components.inventory)
        if enemy_inventory and not enemy_inventory:is_empty() then
          self:spawn_collectible(enemy_inventory.current, attempted_position)
        end

        self:getWorld():removeEntity(occupant)
        self:set_occupancy(attempted_position.x, attempted_position.y, nil)
      end
    end

    self:getWorld():emit("throw_hook", direction)
  else
    --TODO: invalid move SFX
    self:getWorld():emit("invalid_directional_action")
  end
end

function room:draw()
  _util.l.reset_colour()

  if self.screen_shaking then
    love.graphics.push()
    local dx = love.math.random(-self.shake_magnitude, self.shake_magnitude)
    local dy = love.math.random(-self.shake_magnitude, self.shake_magnitude)
    love.graphics.translate(dx / self.shake_count, dy / self.shake_count)
  end

  -- draw the grid
  if self.grid then
    for y, row in ipairs(self.grid) do
      for x, tile_id in ipairs(row) do
        local tile = lookup_tile(tile_id)

        love.graphics.draw(
          _sprites.sheet,
          tile.quad,
          self.grid_origin.x + ((x - 1) * _constants.TILE_SIZE * self.tile_scale),
          self.grid_origin.y + ((y - 1) * _constants.TILE_SIZE * self.tile_scale),
          0,
          self.tile_scale,
          self.tile_scale
        )
      end
    end
  end

  for i = 1, self.DRAWABLE.size do
    local e = self.DRAWABLE:get(i)
    local position = e:get(_components.grid).position
    local sprite = e:get(_components.sprite)
    local quad = sprite.quads[#sprite.quads]
    if sprite.is_health_driven then
      quad = sprite.quads[self.PLAYER:get(1):get(_components.health).current]
    end
    if quad then
      local scale_offset = 0
      if sprite.scale ~= 1 then
        -- this maths doesnt work for scales other than 0.5, so fuck you
        scale_offset = ((_constants.TILE_SIZE * self.tile_scale * sprite.scale) / 2)
      end

      love.graphics.draw(
        sprite.sheet,
        quad,
        self.grid_origin.x + (position.x * _constants.TILE_SIZE * self.tile_scale) + scale_offset,
        self.grid_origin.y + (position.y * _constants.TILE_SIZE * self.tile_scale) + scale_offset,
        0,
        self.tile_scale * sprite.scale,
        self.tile_scale * sprite.scale
      )
    end
    if e:has(_components.inventory) then
      local inventory = e:get(_components.inventory)
      if not inventory:is_empty() then
        -- whole function is an EASY hack cause i ceebs
        local collectible_quad = nil
        local collectible_scale = 0.25
        if inventory.current == "health" then
          collectible_quad = _sprites.build_quad(3, 5)
        end
        love.graphics.draw(
          _sprites.sheet,
          collectible_quad,
          self.grid_origin.x + (position.x * _constants.TILE_SIZE * self.tile_scale),
          self.grid_origin.y + ((position.y + 0.375) * _constants.TILE_SIZE * self.tile_scale),
          0,
          self.tile_scale * collectible_scale,
          self.tile_scale * collectible_scale
        )
      end
    end
  end

  for i = 1, self.HOOK_CHAIN.size do
    local hook = self.HOOK_CHAIN:get(i)
    local chain = hook:get(_components.chain)
    self:draw_chain(chain, self.PLAYER:get(1):get(_components.health).current)
  end

  for i = 1, self.SELECTORS.size do
    local e = self.SELECTORS:get(i)
    if e:get(_components.selection).direction_sprite then
      self:draw_directional_arrow(e, "right")
      self:draw_directional_arrow(e, "down")
      self:draw_directional_arrow(e, "left")
      self:draw_directional_arrow(e, "up")
    end
  end

  _util.l.reset_colour()

  if self.screen_shaking then
    love.graphics.pop()
  end
end

function room:draw_directional_arrow(player, arrow_direction)
  local selection = player:get(_components.selection)
  local position = player:get(_components.grid).position
  if self:validate_direction(player, arrow_direction) then
    local draw_type = "move_default"
    if selection.direction == arrow_direction then
      if selection.action == "hook" then
        draw_type = "hook_target"
      else
        draw_type = "move_target"
      end
    else
      if selection.action == "hook" then
        draw_type = "hook_default"
      else
        draw_type = "move_default"
      end
    end

    self:draw_arrow_sprite(
      selection.direction_sprite,
      position + direction_to_offset(arrow_direction),
      direction_to_rotation(arrow_direction),
      draw_type
    )
  end
end

function room:draw_chain(chain, current_health)
  local sprite_data = chain.sprite_data
  for j, link in ipairs(chain.links) do
    local screen_coords = self:get_screen_coords(link.position)
    love.graphics.draw(
      sprite_data.sheet,
      sprite_data.quads[current_health],
      screen_coords.x,
      screen_coords.y,
      direction_to_rotation(link.direction),
      self.selector_scale,
      self.selector_scale,
      _constants.TILE_SIZE / 2,
      _constants.TILE_SIZE / 2
    )
  end
end

function room:get_screen_coords(grid_position)
  -- gets the centre of the tile in screen coords
  return Vector(
    self.grid_origin.x + (grid_position.x * _constants.TILE_SIZE * self.tile_scale) +
      _constants.TILE_SIZE * self.tile_scale / 2,
    self.grid_origin.y + (grid_position.y * _constants.TILE_SIZE * self.tile_scale) +
      _constants.TILE_SIZE * self.tile_scale / 2
  )
end

function room:draw_arrow_sprite(sprite_data, position, rotation, draw_type)
  local screen_coords = self:get_screen_coords(position)
  love.graphics.draw(
    sprite_data.sheet,
    sprite_data.quads[draw_type],
    screen_coords.x,
    screen_coords.y,
    rotation,
    self.selector_scale,
    self.selector_scale,
    _constants.TILE_SIZE / 2,
    _constants.TILE_SIZE / 2
  )
  _util.l.reset_colour()
end

function room:draw_debug()
  love.graphics.setColor(0, 1, 0)
  love.graphics.circle("fill", self.grid_origin.x, self.grid_origin.y, 2)

  love.graphics.setColor(1, 0, 1)
  -- draw the occupancy map
  for _, row in pairs(self.occupancy_map) do
    for _, occupant in pairs(row) do
      if occupant then
        local pos = occupant:get(_components.grid).position
        local screen_coords = self:get_screen_coords(pos)
        love.graphics.circle("fill", screen_coords.x, screen_coords.y, 5)
      end
    end
  end

  _util.l.reset_colour()
end

function room:validate_direction(entity, direction)
  local position = entity:get(_components.grid).position
  local offset = direction_to_offset(direction)
  local new_position = position + offset
  local occupant = self:get_occupant(new_position.x, new_position.y)

  if entity:has(_components.head) then
    if occupant and (occupant:has(_components.enemy)) then
      return true
    end
  end
  if entity:has(_components.enemy) then
    if occupant then
      if (occupant:has(_components.control) or occupant:has(_components.head)) then
        return true
      end
      if (occupant:has(_components.enemy) and occupant:has(_components.brain) and entity:has(_components.brain)) then
        local entity_brain = entity:get(_components.brain)
        local target_brain = occupant:get(_components.brain)
        if entity_brain.type == "gremlin" and target_brain.type == "goblin" then
          return true
        end
      end
    end
  end
  if entity:has(_components.control) then
    local selection = entity:get(_components.selection)
    if
      occupant and
        ((selection.action == "move" and occupant:has(_components.head) and
          occupant:get(_components.chain):get_length() == 0) or
          (selection.action == "hook" and occupant:has(_components.enemy)))
     then
      return true
    end
  end
  if self:is_empty(new_position) then
    return true
  else
    return false
  end
end

function room:test_direction_is_valid(entity, direction)
  assert(entity:has(_components.grid))
  if self:validate_direction(entity, direction) then
    self:getWorld():emit("report_player_direction_validity", entity, direction, true)
  else
    self:getWorld():emit("report_player_direction_validity", entity, direction, false)
  end
end

return room
