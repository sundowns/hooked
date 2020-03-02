local head =
  Concord.component(
  function(e, direction)
    e.is_extending = true
    e.direction = direction
  end
)

function head:set_direction(direction)
  self.direction = direction
end

function head:retract()
  self.is_extending = false
end

return head
