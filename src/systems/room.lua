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

function lookup_tile(id)
  return _TILE_DICTIONARY[_TILE_LOOKUP[id]]
end

function room:init()
  -- self.timer = Timer.new()
  self.grid = {}
  self.grid_origin = Vector(0, 0)
  self.tile_scale = 8
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

  _assemblages.player:assemble(Concord.entity(self:getWorld()), Vector(0, 0))
end

function room:update(dt)
  -- self.timer:update(dt)
end

function room:is_empty(x, y)
  if not self.grid[y + 1] or not self.grid[y + 1][x + 1] then
    return false
  end
  local tile = lookup_tile(self.grid[y + 1][x + 1])
  return tile.walkable
end

function room:attempt_player_move(direction)
  local player = self.PLAYER:get(1)
  local grid = player:get(_components.grid)
  local offset = Vector(0, 0)
  if direction == "right" then
    offset = Vector(1, 0)
  elseif direction == "down" then
    offset = Vector(0, 1)
  elseif direction == "left" then
    offset = Vector(-1, 0)
  elseif direction == "up" then
    offset = Vector(0, -1)
  end
  if self:is_empty(grid.position.x + offset.x, grid.position.y + offset.y) then
    grid:translate(offset.x, offset.y)
    self:getWorld():emit("end_phase")
  else
    -- TODO: emit some sort of warning/error sound/message
  end
end

function room:draw()
  _util.l.reset_colour()

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
  end
end

return room
