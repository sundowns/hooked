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
      self:set_occupancy(grid.position.x, grid.position.y, true)
    end
  end

  self.ALL.onEntityRemoved = function(pool, e)
    local grid = e:get(_components.grid)
    if grid.is_occupier then
      self:set_occupancy(grid.position.x, grid.position.y, false)
    end
  end
end

function room:set_occupancy(x, y, is_occupied)
  assert(is_occupied ~= nil, "no bueno")
  self.occupancy_map[y + 1][x + 1] = is_occupied
end

function room:is_occupied(x, y)
  if not self.occupancy_map[y + 1] or not self.occupancy_map[y + 1][x + 1] then
    return false
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
      self:set_occupancy(x - 1, y - 1, false)
      if tile_id == 0 then
        player_spawn = Vector(x - 1, y - 1)
      end
    end
  end
  _assemblages.player:assemble(Concord.entity(self:getWorld()), player_spawn)
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
  if self:is_occupied(position.x, position.y) then
    return false -- something is here already
  end
  local tile = lookup_tile(self.grid[position.y + 1][position.x + 1])
  return tile.walkable
end

function room:attempt_entity_move(e, direction, is_player)
  if not e:has(_components.grid) then
    return
  end
  local grid = e:get(_components.grid)
  if self:validate_direction(grid.position, direction) then
    local old_position = grid.position:clone()
    grid:translate(direction_to_offset(direction))
    if grid.is_occupier then
      -- empty current tile, occupy new one
      self:set_occupancy(old_position.x, old_position.y, false)
      self:set_occupancy(grid.position.x, grid.position.y, true)
    end
    self:getWorld():emit("shake", 0.15, 0.5)

    -- Fire event if hook was the one that moved:
    if e:has(_components.head) and e:has(_components.chain) then
      self:getWorld():emit("hook_moved", e, old_position)
    end

    -- Fire event if player was one that moved:
    if is_player then
      -- check if chain is out, if so remove last link
      local hook_thrower = e:get(_components.hook_thrower)
      if not hook_thrower.can_throw then
        self:getWorld():emit("player_with_hook_moved", old_position, direction)
      end
      self:getWorld():emit("end_phase")
    end
  else
    --TODO: invalid move SFX
    self:getWorld():emit("invalid_entity_move", e)
    self:getWorld():emit("invalid_directional_action")
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

  for i = 1, self.HOOK_CHAIN.size do
    local hook = self.HOOK_CHAIN:get(i)
    local chain = hook:get(_components.chain)
    love.graphics.setColor(1, 0, 1)
    for j, link in ipairs(chain.links) do
      love.graphics.circle(
        "fill",
        self.grid_origin.x + (link.position.x * _constants.TILE_SIZE * self.tile_scale) +
          _constants.TILE_SIZE * self.tile_scale / 2,
        self.grid_origin.y + (link.position.y * _constants.TILE_SIZE * self.tile_scale) +
          _constants.TILE_SIZE * self.tile_scale / 2,
        5
      )
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
    _constants.TILE_SIZE * self.selector_scale / 8,
    _constants.TILE_SIZE * self.selector_scale / 8
  )
  _util.l.reset_colour()
end

function room:draw_debug()
  love.graphics.setColor(0, 1, 0)
  love.graphics.circle("fill", self.grid_origin.x, self.grid_origin.y, 2)

  love.graphics.setColor(1, 0, 0)
  -- draw the occupancy map
  for y, row in ipairs(self.occupancy_map) do
    for x, is_occupied in ipairs(row) do
      if is_occupied then
        love.graphics.circle(
          "fill",
          self.grid_origin.x + ((x - 1) * _constants.TILE_SIZE * self.tile_scale) +
            (_constants.TILE_SIZE / 2 * self.tile_scale),
          self.grid_origin.y + ((y - 1) * _constants.TILE_SIZE * self.tile_scale) +
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
