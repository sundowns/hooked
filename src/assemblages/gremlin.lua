-- e is the Entity being assembled.
-- cuteness and legs are variables passed in
return Concord.assemblage(
  function(e, origin)
    local enemy_sprite_quads = {
      [1] = _sprites.build_quad(6, 6)
    }

    e:give(_components.grid, origin, true):give(_components.enemy):give(
      _components.sprite,
      _sprites.sheet,
      enemy_sprite_quads,
      false
    ):give(_components.brain, "gremlin"):give(_components.inventory):give(_components.id)
  end
)
