local generator = {}

--[[ ROOM GENERATOR
  JARGON:
    * F# = Floor Number.
    * Tiles:
      * '0' - player spawn
      * '1' - empty
      * '2' - wall 
      * '3' - exit 
      * '10' - empty with goblin
  PROCESS:
    * Determine difficulty
      Based on F#
    * Choose dimensions 
      * Very Easy: 5x5
      * Easy: 7x7
      * Regular: 12x12
      * etc...
    * Fill the grid with '1's
    * Randomly select an edge, place a spawn point ('0') adjacent to it
    * Using the opposite edge to the spawn point, add the exit ('3')
    * Randomly apply a few simple pre-defined templates 
      * use F# to determine how many and which size templates to use (its basically matrix addition)
    * Randomly sprinkle in enemies on the remaining empty ('1') tiles
      * Enemy count & type based on F#/difficulty
  VALIDITY:
  For a room to be valid it must:
    * have one '0' tile to spawn the player
    * have one '3' tile - the exit.
    * contain a valid path between the spawn tile ('0') and an exit tile ('3')
]]
local _opposite_edge = {
  ["LEFT"] = "RIGHT",
  ["RIGHT"] = "LEFT",
  ["BOTTOM"] = "TOP",
  ["TOP"] = "BOTTOM"
}

function generator:generate(floor_count)
  local difficulty = self:get_difficulty(floor_count)
  local cols, rows = self:get_dimensions(difficulty)
  local layout = {}

  for y = 1, rows do
    layout[y] = {}
    for x = 1, cols do
      layout[y][x] = 1
    end
  end

  layout, chosen_spawn_edge = self:add_spawn(layout, cols, rows)
  layout = self:add_exit(layout, cols, rows, chosen_spawn_edge)
  -- layout = self:apply_templates(layout, difficulty)
  -- layout = self:add_enemies(layout, difficulty)

  return layout
  -- return {
  --   {1, 1, 1, 2, 2, 1},
  --   {1, 0, 3, 1, 1, 1},
  --   {1, 1, 1, 1, 10, 10},
  --   {1, 1, 1, 1, 10, 10},
  --   {1, 1, 1, 1, 1, 2},
  --   {1, 2, 2, 2, 2, 2}
  -- }
end

function generator:add_exit(layout, cols, rows, spawn_edge)
  local edge = _opposite_edge[spawn_edge]
  local x, y = 1, 1
  if edge == "LEFT" then
    y = love.math.random(1, rows)
  elseif edge == "TOP" then
    x = love.math.random(1, cols)
  elseif edge == "RIGHT" then
    x = cols
    y = love.math.random(1, rows)
  elseif edge == "BOTTOM" then
    x = love.math.random(1, cols)
    y = rows
  end
  layout[y][x] = 3
  return layout, edge
end

function generator:add_spawn(layout, cols, rows)
  local edge = _util.g.choose("LEFT", "TOP", "RIGHT", "BOTTOM")
  local x, y = 1, 1
  if edge == "LEFT" then
    y = love.math.random(1, rows)
  elseif edge == "TOP" then
    x = love.math.random(1, cols)
  elseif edge == "RIGHT" then
    x = cols
    y = love.math.random(1, rows)
  elseif edge == "BOTTOM" then
    x = love.math.random(1, cols)
    y = rows
  end
  layout[y][x] = 0
  return layout, edge
end

function generator:get_difficulty(floor_count)
  if floor_count <= 3 then
    return "EASIER"
  elseif floor_count <= 8 then
    return "EASY"
  elseif floor_count <= 15 then
    return "REGULAR"
  elseif floor_count <= 22 then
    return "HARD"
  end
end

function generator:get_dimensions(difficulty)
  if difficulty == "EASIER" then
    return 5, 5
  elseif difficulty == "EASY" then
    return 10, 7
  elseif difficulty == "REGULAR" then
    return 15, 10
  elseif difficulty == "HARD" then
    return 20, 12
  end
end

generator["templates"] = {
  ["3x3"] = {
    {
      {1, 1, 1},
      {1, 2, 1},
      {1, 1, 1}
    },
    {
      {1, 1, 1},
      {2, 2, 2},
      {1, 1, 1}
    },
    {
      {2, 1, 1},
      {2, 1, 2},
      {2, 1, 1}
    }
  }
}

return generator
