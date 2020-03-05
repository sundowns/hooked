-- e is the Entity being assembled.
-- cuteness and legs are variables passed in
return Concord.assemblage(
  function(e, origin, direction, max_length)
    local head_sprite_quads = {
      [4] = _sprites.build_quad(0, 3),
      [3] = _sprites.build_quad(1, 3),
      [2] = _sprites.build_quad(2, 3),
      [1] = _sprites.build_quad(3, 3),
      [0] = _sprites.build_quad(4, 3)
    }

    local chain_sprite_quads = {
      [4] = _sprites.build_quad(0, 4),
      [3] = _sprites.build_quad(1, 4),
      [2] = _sprites.build_quad(2, 4),
      [1] = _sprites.build_quad(3, 4),
      [0] = _sprites.build_quad(4, 4)
    }

    e:give(_components.grid, origin, true):give(_components.sprite, _sprites.sheet, head_sprite_quads, true):give(
      _components.chain,
      max_length,
      _sprites.sheet,
      chain_sprite_quads
    ):give(_components.head, direction)
  end
)
