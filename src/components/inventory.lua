local inventory =
  Concord.component(
  function(e, item)
    e.current = item
  end
)

function inventory:is_empty()
  return not self.current
end

function inventory:pickup(collectible)
  self.current = collectible
  print(self.current)
end

function inventory:drop()
  if not self.current then
    return
  end
  local item = self.current
  self.current = nil
  return item
end

return inventory
