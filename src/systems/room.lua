local room = Concord.system({})

local tile_map = love.graphics.newImage("resources/tilemap.png")

-- x, y in grid coords, not pixels
function build_quad(x, y)
  return love.graphics.newQuad(
    x * _constants.TILE_SIZE,
    y * _constants.TILE_SIZE,
    _constants.TILE_SIZE,
    _constants.TILE_SIZE,
    tile_map:getWidth(),
    tile_map:getHeight()
  )
end

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
    quad = build_quad(0, 0)
  },
  [_TILE_LOOKUP[2]] = {
    name = "wall",
    quad = build_quad(1, 0)
  }
}

function room:lookup_tile(id)
  return _TILE_DICTIONARY[_TILE_LOOKUP[id]]
end

function room:init()
  -- self.timer = Timer.new()
  self.grid = {}
  self.grid_origin = Vector(0, 0)
  self.tile_scale = 8

  local test_room = {
    {1, 1, 1, 1},
    {1, 2, 2, 1},
    {1, 2, 2, 1},
    {1, 1, 1, 1}
  }

  self:load(test_room)
end

function room:load(layout_grid)
  local rows = #layout_grid
  local cols = #layout_grid[1]
  print(rows .. " x " .. cols)
  self.grid = layout_grid
  self.grid_origin =
    Vector(
    (love.graphics.getWidth() / 2) - (cols / 2 * _constants.TILE_SIZE * self.tile_scale),
    (love.graphics.getHeight() / 2) - (rows / 2 * _constants.TILE_SIZE * self.tile_scale)
  )
  print(self.grid_origin)
end

function room:update(dt)
  -- self.timer:update(dt)
end

function room:draw()
  _util.l.reset_colour()

  if self.grid then
    for y, row in ipairs(self.grid) do
      for x, tile_id in ipairs(row) do
        local tile = self:lookup_tile(tile_id)

        love.graphics.draw(
          tile_map,
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
end

return room
