local chain =
  Concord.component(
  function(e, max_length, spritesheet, quads)
    e.max_length = max_length
    e.links = {}
    e.sprite_data = {
      sheet = spritesheet,
      quads = quads
    }
    e.last_consumed = nil
  end
)

function chain:add_link_to_front(grid_position, direction)
  assert(grid_position and grid_position.x and grid_position.y, "received non-vector position for new chain link")
  self.links[#self.links + 1] = {
    position = grid_position,
    direction = direction
  }
end

function chain:add_link_to_back(grid_position, direction)
  assert(grid_position and grid_position.x and grid_position.y, "received non-vector position for new chain link")

  table.insert(
    self.links,
    1,
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
  return #self.links >= self.max_length
end

function chain:consume_last()
  self.last_consumed = self.links[#self.links]
  self.links[#self.links] = nil
end

function chain:consume_first()
  table.remove(self.links, 1)
end

function chain:restore_last()
  if not self.last_consumed then
    return
  end
  self.links[#self.links + 1] = self.last_consumed
  self.last_consumed = nil
end

return chain
