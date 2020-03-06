local sprite =
  Concord.component(
  function(e, sheet, quads, is_health_driven, scale)
    e.sheet = sheet
    e.quads = quads
    e.is_health_driven = is_health_driven or false
    e.scale = scale or 1
  end
)

return sprite
