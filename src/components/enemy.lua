local enemy =
  Concord.component(
  function(e)
    e.marked_for_deletion = false
  end
)

function enemy:mark_for_deletion()
  self.marked_for_deletion = true
end

return enemy
