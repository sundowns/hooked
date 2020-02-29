-- e is the Entity being assembled.
-- cuteness and legs are variables passed in
return Concord.assemblage(
  function(e, origin, sprite_sheet, sprite_quad)
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

    local player_sprite_quads = {
      [5] = _sprites.build_quad(0, 2),
      [4] = _sprites.build_quad(1, 2),
      [3] = _sprites.build_quad(2, 2),
      [2] = _sprites.build_quad(3, 2),
      [1] = _sprites.build_quad(4, 2)
    }

    e:give(_components.grid, origin):give(
      _components.selection,
      {
        ["move"] = true,
        ["hook"] = true
      },
      _constants.DIRECTIONS
    ):give(_components.control, bindings):give(_components.hook_thrower):give(
      _components.sprite,
      _sprites.sheet,
      player_sprite_quads
    )
  end
)
