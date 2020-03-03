local room =
  Concord.system(
  {_components.grid, "ALL"},
  {_components.grid, _components.sprite, "DRAWABLE"},
  {_components.control, _components.grid, "PLAYER"},
  {_components.chain, _components.head, "HOOK_CHAIN"}
)

local _TILE_LOOKUP = {
  [0] = "dirt", -- spawn tile
  [1] = "dirt",
  [2] = "wall",
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
      if self:get_occupant(grid.position.x, grid.position.y) == e then
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

function room:load_room(layout_grid)
  local rows = #layout_grid
  local cols = #layout_grid[1]
  print("loading room: " .. rows .. "x" .. cols)
  self.grid = layout_grid
  self.grid_origin =
    Vector(
    (love.graphics.getWidth() / 2) - (cols / 2 * _constants.TILE_SIZE * self.tile_scale),
    (love.graphics.getHeight() / 2) - (rows / 2 * _constants.TILE_SIZE * self.tile_scale)
  )

  self.occupancy_map = {}
  local player_spawn = Vector(0, 0)
  for y, row in ipairs(self.grid) do
    self.occupancy_map[y] = {}
    for x, tile_id in ipairs(row) do
      self:set_occupancy(x - 1, y - 1, nil)
      if tile_id == 0 then
        player_spawn = Vector(x - 1, y - 1)
      end
    end
  end
  _assemblages.player:assemble(Concord.entity(self:getWorld()), player_spawn)

  -- test enemies
  -- TODO: loop over empty tiles (dirt), look for any > 1 square from the enemy and consider as eligible candidate for spawns
  _assemblages.goblin:assemble(Concord.entity(self:getWorld()), Vector(0, 0))
  _assemblages.goblin:assemble(Concord.entity(self:getWorld()), Vector(4, 2))
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
    self:getWorld():emit("shake", 0.15, 0.5)
    -- check if chain is out, if so remove last link
    local hook_thrower = e:get(_components.hook_thrower)
    if not hook_thrower.can_throw then
      self:getWorld():emit("player_with_hook_moved", old_position, grid.position, direction)
    end
    self:getWorld():emit("end_phase", "PLAYER")
    return
  end
end

function room:attempt_entity_move(e, direction)
  if not e:has(_components.grid) then
    return
  end
  if self:validate_direction(e:get(_components.grid).position, direction) then
    self:move_entity(e, direction)
  else
    if e:has(_components.head) then
      -- its a hook, check if we collided with an enemy/obstacle of some kind
      self:hook_collided_with_something(e, direction)
    elseif e:has(_components.enemy) then
      self:enemy_collided_with_something(e, direction)
    elseif e:has(_components.control) then
      --TODO: invalid move SFX
      self:getWorld():emit("invalid_entity_move", e)
      self:getWorld():emit("invalid_directional_action")
    end
  end
end

function room:hook_collided_with_something(hook, direction)
  local collided_at = hook:get(_components.grid).position + direction_to_offset(direction)
  local occupant = self:get_occupant(collided_at.x, collided_at.y)
  if occupant then
    if occupant:has(_components.enemy) then
      self:getWorld():removeEntity(occupant)
      self:set_occupancy(collided_at.x, collided_at.y, nil)
      self:move_entity(hook, direction)
    end
  else
    self:getWorld():emit("invalid_entity_move", hook)
  end
end

function room:enemy_collided_with_something(enemy, direction)
  local position = enemy:get(_components.grid).position
  local collided_at = position + direction_to_offset(direction)
  local occupant = self:get_occupant(collided_at.x, collided_at.y)

  if occupant then
    if occupant:has(_components.control) then
      self:getWorld():emit("reduce")
    elseif occupant:has(_components.head) then
      self:set_occupancy(position.x, position.y, nil)
      self:getWorld():removeEntity(enemy)
    end
  end
end

function room:attempt_hook_throw(e, direction)
  if not e:has(_components.grid) then
    return
  end
  local grid = e:get(_components.grid)
  if self:validate_direction(grid.position, direction) then
    self:getWorld():emit("throw_hook", direction)
  else
    local attempted_position = grid.position + direction_to_offset(direction)
    local occupant = self:get_occupant(attempted_position.x, attempted_position.y)
    if occupant then
      -- we tried to place hook on an enemy, kill it and place the hook there anyway!
      if occupant:has(_components.enemy) then
        self:getWorld():removeEntity(occupant)
        self:set_occupancy(attempted_position.x, attempted_position.y, nil)
        self:getWorld():emit("throw_hook", direction)
      end
    else
      --TODO: invalid move SFX
      self:getWorld():emit("invalid_directional_action")
    end
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

  for i = 1, self.HOOK_CHAIN.size do
    local hook = self.HOOK_CHAIN:get(i)
    local chain = hook:get(_components.chain)
    self:draw_chain(chain, self.PLAYER:get(1):get(_components.health).current)
  end

  for i = 1, self.DRAWABLE.size do
    local e = self.DRAWABLE:get(i)
    local position = e:get(_components.grid).position
    local sprite = e:get(_components.sprite)
    local quad = sprite.quads[#sprite.quads]
    if sprite.is_health_driven then
      quad = sprite.quads[self.PLAYER:get(1):get(_components.health).current]
    end
    love.graphics.draw(
      sprite.sheet,
      quad,
      self.grid_origin.x + (position.x * _constants.TILE_SIZE * self.tile_scale),
      self.grid_origin.y + (position.y * _constants.TILE_SIZE * self.tile_scale),
      0,
      self.tile_scale,
      self.tile_scale
    )

    if e:has(_components.selection) then
      local selection = e:get(_components.selection)
      if selection.direction_sprite then
        self:draw_directional_arrow(position, selection, "right")
        self:draw_directional_arrow(position, selection, "down")
        self:draw_directional_arrow(position, selection, "left")
        self:draw_directional_arrow(position, selection, "up")
      end
    end
  end

  _util.l.reset_colour()

  if self.screen_shaking then
    love.graphics.pop()
  end
end

function room:draw_directional_arrow(player_position, selection, arrow_direction)
  if self:validate_direction(player_position, arrow_direction) then
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
      player_position + direction_to_offset(arrow_direction),
      direction_to_rotation(arrow_direction),
      draw_type
    )
  end
end

function room:draw_chain(chain, current_health)
  local sprite_data = chain.sprite_data
  for j, link in ipairs(chain.links) do
    love.graphics.draw(
      sprite_data.sheet,
      sprite_data.quads[current_health],
      self.grid_origin.x + (link.position.x * _constants.TILE_SIZE * self.tile_scale) +
        _constants.TILE_SIZE * self.tile_scale / 2,
      self.grid_origin.y + (link.position.y * _constants.TILE_SIZE * self.tile_scale) +
        _constants.TILE_SIZE * self.tile_scale / 2,
      direction_to_rotation(link.direction),
      self.selector_scale,
      self.selector_scale,
      _constants.TILE_SIZE / 2,
      _constants.TILE_SIZE / 2
    )
  end
end

function room:draw_arrow_sprite(sprite_data, position, rotation, draw_type)
  love.graphics.draw(
    sprite_data.sheet,
    sprite_data.quads[draw_type],
    self.grid_origin.x + (position.x * _constants.TILE_SIZE * self.tile_scale) +
      _constants.TILE_SIZE * self.tile_scale / 2,
    self.grid_origin.y + (position.y * _constants.TILE_SIZE * self.tile_scale) +
      _constants.TILE_SIZE * self.tile_scale / 2,
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

  love.graphics.setColor(1, 0, 0)
  -- draw the occupancy map
  for _, row in pairs(self.occupancy_map) do
    for _, occupant in pairs(row) do
      -- print(is_occupied)
      if occupant then
        local pos = occupant:get(_components.grid).position
        love.graphics.circle(
          "fill",
          self.grid_origin.x + ((pos.x) * _constants.TILE_SIZE * self.tile_scale) +
            (_constants.TILE_SIZE / 2 * self.tile_scale),
          self.grid_origin.y + ((pos.y) * _constants.TILE_SIZE * self.tile_scale) +
            (_constants.TILE_SIZE / 2 * self.tile_scale),
          5
        )
      end
    end
  end

  _util.l.reset_colour()
end

function room:validate_direction(position, direction)
  local offset = direction_to_offset(direction)
  if self:is_empty(position + offset) then
    return true
  else
    return false
  end
end

return room
