local grid =
  Concord.component(
  function(e, position)
    assert(position and position.x and position.y, "Grid component received a non-vector position on creation")
    e.position = position
  end
)

function grid:set_position(position)
  assert(position.x and position.y, "Grid component received a non-vector position when setting position")
  self.position = position
end

function grid:translate(delta)
  assert(delta and delta.x and delta.y)
  self.position = self.position + delta
end

return grid
