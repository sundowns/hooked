local room =
  Concord.system({_components.grid, _components.sprite, "DRAWABLE"}, {_components.control, _components.grid, "PLAYER"})

local _TILE_LOOKUP = {
  [1] = "dirt",
  [2] = "wall",
  [10] = "door_orange",
  [11] = "door_blue",
  [12] = "door_purple"
}
-- can store individual tile data
local _TILE_DICTIONARY = {
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
  self.tile_scale = 8
  self.selector_scale = 4

  -- Screen shake vars
  self.screen_shaking = false
  self.shake_duration = 0
  self.shake_count = 0
  self.shake_magnitude = 2
end

function room:load_room(layout_grid)
  local rows = #layout_grid
  local cols = #layout_grid[1]
  print(rows .. " x " .. cols)
  self.grid = layout_grid
  self.grid_origin =
    Vector(
    (love.graphics.getWidth() / 2) - (cols / 2 * _constants.TILE_SIZE * self.tile_scale),
    (love.graphics.getHeight() / 2) - (rows / 2 * _constants.TILE_SIZE * self.tile_scale)
  )

  _assemblages.player:assemble(Concord.entity(self:getWorld()), Vector(1, 1))
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
  local tile = lookup_tile(self.grid[position.y + 1][position.x + 1])
  return tile.walkable
end

function room:attempt_player_move(direction)
  local player = self.PLAYER:get(1)
  local grid = player:get(_components.grid)
  if self:validate_direction(grid.position, direction) then
    grid:translate(direction_to_offset(direction))
    -- grid:translate(offset.x, offset.y)
    self:getWorld():emit("shake", 0.15, 0.5)
    self:getWorld():emit("end_phase")
  else
    print("invalid move")
  end
  -- local offset = direction_to_offset(direction)
  -- if self:is_empty(grid.position + offset) then
  --   -- TODO: we need to use transforms with absolute positions to tween position properly
  --   -- self.timer:tween(0.15, grid, {position = Vector(grid.position.x + offset.x, grid.position.y + offset.y)})
  -- else
  --   -- TODO: emit some sort of warning/error sound/message
  -- end
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
      local health = e:get(_components.health)
      quad = sprite.quads[health.current]
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
        self:draw_directional_arrow(position, selection.direction_sprite, "right", selection.direction)
        self:draw_directional_arrow(position, selection.direction_sprite, "down", selection.direction)
        self:draw_directional_arrow(position, selection.direction_sprite, "left", selection.direction)
        self:draw_directional_arrow(position, selection.direction_sprite, "up", selection.direction)
      end
    end
  end

  if self.screen_shaking then
    love.graphics.pop()
  end
end

function room:draw_directional_arrow(player_position, sprite_data, arrow_direction, selected_direction)
  if self:validate_direction(player_position, arrow_direction) then
    self:draw_arrow_sprite(
      sprite_data,
      player_position + direction_to_offset(arrow_direction),
      direction_to_rotation(arrow_direction),
      selected_direction == arrow_direction
    )
  end
end

function room:draw_arrow_sprite(sprite_data, position, rotation, highlight)
  local quad = sprite_data.quads[1]
  if highlight then
    quad = sprite_data.quads[2]
  end
  love.graphics.draw(
    sprite_data.sheet,
    quad,
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

function room:validate_direction(position, direction)
  local offset = direction_to_offset(direction)
  if self:is_empty(position + offset) then
    return true
  else
    return false
  end
end

return room
