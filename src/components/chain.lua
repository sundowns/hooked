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

function chain:add_link_to_front(grid_position, direction)
  assert(grid_position and grid_position.x and grid_position.y, "received non-vector position for new chain link")
  assert(#self.links < self.max_length, "Attempted to add link to full chain")
  self.links[#self.links + 1] = {
    position = grid_position,
    direction = direction
  }
end

function chain:add_link_to_back(grid_position, direction)
  assert(grid_position and grid_position.x and grid_position.y, "received non-vector position for new chain link")
  assert(#self.links < self.max_length, "Attempted to add link to full chain")

  assert(
    "I haven't implemented this, next challenge!!!! (need to add at the LOWEST index, like a 2-way linked list dealio)"
  )
end

function chain:get_length()
  return #self.links
end

function chain:is_full()
  return #self.links == self.max_length
end

function chain:consume_last()
  table.remove(self.links)
end

return chain
