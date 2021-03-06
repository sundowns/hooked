-- e is the Entity being assembled.
-- cuteness and legs are variables passed in
return Concord.assemblage(
  function(e, origin)
    local health_sprite_quads = {
      [1] = _sprites.build_quad(3, 5)
    }

    e:give(_components.grid, origin, false):give(_components.collectible, "health"):give(
      _components.sprite,
      _sprites.sheet,
      health_sprite_quads,
      false,
      0.5
    ):give(_components.id)
  end
)
