local _valid_types = {
  ["health"] = true
}

local collectible =
  Concord.component(
  function(e, type)
    type = string.lower(type)
    assert(_valid_types[type], "collectible component received unknown type :c")
    e.type = type
  end
)

return collectible
