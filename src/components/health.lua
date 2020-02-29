local health =
  Concord.component(
  function(e, maximum)
    e.current = maximum
    e.maximum = maximum
  end
)

function health:reduce(delta)
  if self.current > 0 then
    self.current = self.current - delta
  end
end

return health
