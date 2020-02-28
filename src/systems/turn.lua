local turn = Concord.system({_components.control, "PLAYER"})
function turn:action_released(action, e)
  print("action")
end
return turn
