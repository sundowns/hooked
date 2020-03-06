local id =
  Concord.component(
  function(e)
    e.value = _util.s.random_string(10)
  end
)

return id
