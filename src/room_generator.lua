local room_generator = {}

function room_generator:generate(current_floor)
  print("generating floor: " .. current_floor)
  -- Valid rooms must:
  --  * have one '0' tile to spawn the player
  --  * have one or more '3' tiles - the exit.
  local choice = _util.g.choose(1, 2)
  if choice == 1 then
    return {
      {1, 1, 1, 2, 2, 1},
      {1, 0, 1, 1, 1, 1},
      {1, 3, 2, 1, 1, 1},
      {1, 1, 2, 1, 1, 1},
      {1, 1, 1, 1, 1, 2},
      {1, 2, 2, 2, 2, 2}
    }
  else
    return {
      {1, 1, 1, 2, 2, 1},
      {1, 0, 3, 1, 1, 1},
      {1, 1, 1, 1, 1, 1},
      {1, 1, 1, 1, 1, 1},
      {1, 1, 1, 1, 1, 2},
      {1, 2, 2, 2, 2, 2}
    }
  end
end

return room_generator
