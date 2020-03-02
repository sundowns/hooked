local head =
  Concord.component(
  function(e)
    e.extending = true
  end
)

function head:retract()
  self.extending = false
end

return head
