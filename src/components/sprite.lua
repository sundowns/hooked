local sprite =
  Concord.component(
  function(e, sheet, quads, is_health_driven)
    e.sheet = sheet
    e.quads = quads
    e.is_health_driven = is_health_driven or false
  end
)

return sprite
