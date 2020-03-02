local chain =
  Concord.component(
  function(e, max_length, spritesheet, quads)
    e.max_length = max_length
    e.links = {}
    e.sprite_data = {
      sheet = spritesheet,
      quads = quads
    }
  end
)

function chain:add_link(grid_position, direction)
  assert(grid_position and grid_position.x and grid_position.y, "received non-vector position for new chain link")
  assert(#self.links < self.capacity, "Attempted to add link to full chain")
  direction = direction
  table.insert(
    self.links,
    {
      position = grid_position,
      direction = direction
    }
  )
end

function chain:get_length()
  return #self.links
end

function chain:is_full()
  return #self.links == self.max_length
end

return chain
