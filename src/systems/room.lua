local room = Concord.system({})

-- x, y in grid coords, not pixels
function build_quad(x, y)
  return love.graphics.newQuad(
    x * _constants.TILE_SIZE,
    y * _constants.TILE_SIZE,
    _constants.TILE_SIZE,
    _constants.TILE_SIZE,
    1,
    1
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

function lookup_tile(id)
  return _TILE_DICTIONARY[_TILE_LOOKUP[id]]
end

function room:init()
  -- self.timer = Timer.new()
  self.grid = {}
  self.grid_origin = Vector(0, 0)
  self.tile_map = love.graphics.newImage("resources/tilemap.png")

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
    (love.graphics.getWidth() / 2) - (cols / 2 * _constants.TILE_SIZE),
    (love.graphics.getHeight() / 2) - (rows / 2 * _constants.TILE_SIZE)
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
        local tile = lookup_tile(tile_id)

        love.graphics.draw(
          self.tile_map,
          tile.quad,
          self.grid_origin.x + x * _constants.TILE_SIZE,
          self.grid_origin.y + x * _constants.TILE_SIZE
        )
      end
    end
  end
end

return room
