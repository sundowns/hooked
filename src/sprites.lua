local _spritesheet = love.graphics.newImage("resources/spritesheet.png")

local build_quad = function(x, y)
  return love.graphics.newQuad(
    x * _constants.TILE_SIZE,
    y * _constants.TILE_SIZE,
    _constants.TILE_SIZE,
    _constants.TILE_SIZE,
    _spritesheet:getWidth(),
    _spritesheet:getHeight()
  )
end

return {
  ["build_quad"] = build_quad,
  ["sheet"] = _spritesheet
}
