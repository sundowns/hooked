local _valid_types = {
  ["goblin"] = true,
  ["gremlin"] = true
}

local brain =
  Concord.component(
  function(e, type)
    local in_type = string.lower(type)
    assert(_valid_types[in_type], "received invalid brain type: " .. in_type)
    e.type = in_type
  end
)

return brain
