-- e is the Entity being assembled.
-- cuteness and legs are variables passed in
return Concord.assemblage(
  function(e, origin)
    local PLAYER_ACCELERATION = 360
    local bindings = {
      ["left"] = "left",
      ["right"] = "right",
      ["up"] = "up",
      ["down"] = "down",
      ["a"] = "left",
      ["d"] = "right",
      ["w"] = "up",
      ["s"] = "down",
      ["space"] = "end_turn",
      ["z"] = "hook",
      ["escape"] = "back"
    }

    e:give(_components.transform, origin, Vector(0, 0)):give(
      _components.selection,
      {
        ["move"] = true,
        ["hook"] = true
      },
      _constants.DIRECTIONS
    ):give(_components.control, bindings):give(_components.hook_thrower)
  end
)
