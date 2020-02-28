-- e is the Entity being assembled.
-- cuteness and legs are variables passed in
return Concord.assemblage(
  function(e, origin)
    local PLAYER_ACCELERATION = 360
    local bindings = {
      ["left"] = "left",
      ["right"] = "right"
    }

    e:give(_components.transform, origin, Vector(0, 0)):give(_components.control, bindings)
  end
)
