local head =
  Concord.component(
  function(e, direction)
    e.is_extending = true
    e.direction = direction
  end
)

function head:retract()
  self.is_extending = false
  if self.direction == "right" then
    self.direction = "left"
  elseif self.direction == "left" then
    self.direction = "right"
  elseif self.direction == "up" then
    self.direction = "down"
  elseif self.direction == "down" then
    self.direction = "up"
  end
end

return head
