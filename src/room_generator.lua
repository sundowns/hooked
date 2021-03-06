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
      * '11' - empty with gremlin
      * '20' - healthpack
      * '21' - key (orange)
      * '22' - key (cyan)
      * '23' - key (purple)
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
    * Generate a nav map -> player spawn
    * Generate a nav map -> collectible
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

function generator:generate_room(floor_count, player_health, max_health)
  local difficulty = self:get_difficulty(floor_count)
  -- local difficulty = "EASIER"
  -- local difficulty = "EASY"
  -- local difficulty = "REGULAR"
  -- local difficulty = "HARD"
  self.player_spawn_position = nil
  self.cols, self.rows = self:get_dimensions(difficulty)
  self.layout = {}
  self.collectible_position = nil

  -- initialise our layout to empty tiles
  for y = 1, self.rows do
    self.layout[y] = {}
    for x = 1, self.cols do
      self.layout[y][x] = 1
    end
  end

  -- perform dark rituals
  -- TODO: add_key MUST come before add_health_pack (or it will get out prioritised)
  local layout =
    self:add_spawn():add_exit():apply_templates(difficulty):add_extra_walls(difficulty):add_health_pack(
    difficulty,
    player_health,
    max_health
  ):add_enemies(difficulty):build()

  -- check the level is actually winnable
  if self:validate_floor() then
    return layout, {
      ["player"] = self:generate_navigation_map(self.player_spawn_position),
      ["collectible"] = self:generate_navigation_map(self.collectible_position)
    }
  else
    return self:generate_room(floor_count, player_health, max_health)
  end
end

function generator:generate_navigation_map(start_position)
  if not start_position then
    return
  end
  --[[
      * create empty open set (cells to check)
      * add start to open set
      * while open_set is not empty
        * grab element of open_set (oldest)
        * for each of element's neighbours
          * if neighbour is an empty tile AND not the tile we came from
            * add this tile to openset (and record the current tile as the tile we 'came from')
    ]]
  -- initialise empty nav mesh with all tiles 'invalid'
  local nav_mesh = {}
  for y = 1, self.rows do
    nav_mesh[y] = {}
    for x = 1, self.cols do
      nav_mesh[y][x] = -1
    end
  end

  local open_set = {}
  function add_to_open_set(position, distance)
    table.insert(
      open_set,
      {
        ["position"] = position,
        ["distance"] = distance or 0
      }
    )
  end
  local visited = {}
  function add_to_visited(node)
    visited[node.position.x .. "," .. node.position.y] = node
  end
  function get_distance(position)
    if visited[position.x .. "," .. position.y] then
      return visited[position.x .. "," .. position.y].distance
    end
    return 1000000000
  end

  -- add spawn point as search origin
  add_to_open_set(start_position)
  local goal_found = false

  while #open_set > 0 do
    -- pop the oldest node
    local current = table.remove(open_set)
    add_to_visited(current)

    for i, neighbour in pairs(self:get_neighbours(current)) do
      local neighbour_type = self.layout[neighbour.position.y][neighbour.position.x]
      -- its traversable
      if self:is_traversable_tile(neighbour_type) and (current.distance + 1 < get_distance(neighbour.position)) then
        add_to_open_set(neighbour.position, current.distance + 1)
      end
    end
  end

  -- iterate over visited and set nav_mesh values
  for _, node in pairs(visited) do
    nav_mesh[node.position.y][node.position.x] = node.distance
  end

  return nav_mesh
end

function generator:validate_floor()
  if self.layout[self.player_spawn_position.y][self.player_spawn_position.x] ~= 0 then
    print("Grid is missing player spawn, INVALID")
    return false
  end

  return self:can_reach_exit(self.player_spawn_position)
end

function generator:can_reach_exit(start_position)
  --[[
    * create empty open set (cells to check)
    * add start to open set
    * while open_set is not empty
      * grab element of open_set (oldest)
      * for each of element's neighbours
        * if neighbour is the exit 
          * there is a valid path. break out of the loop
        * if neighbour is an empty tile AND not the tile we came from
          * add this tile to openset (and record the current tile as the tile we 'came from')
  ]]
  local open_set = {}
  function add_to_open_set(position)
    table.insert(
      open_set,
      {
        ["position"] = position
      }
    )
  end
  local visited = {}
  function add_to_visited(position)
    visited[position.x .. "," .. position.y] = true
  end
  function is_visited(position)
    return visited[position.x .. "," .. position.y]
  end

  -- add spawn point as search origin
  add_to_open_set(start_position)
  local goal_found = false

  while #open_set > 0 and not goal_found do
    -- pop the oldest node
    local current = table.remove(open_set)
    add_to_visited(current.position)

    for i, neighbour in pairs(self:get_neighbours(current)) do
      local neighbour_type = self.layout[neighbour.position.y][neighbour.position.x]
      -- it's the goal, a valid path exists
      if neighbour_type == 3 then
        goal_found = true
      end
      -- its traversable and NOT visisted
      if self:is_traversable_tile(neighbour_type) and not is_visited(neighbour.position) then
        add_to_open_set(neighbour.position)
      end
    end
  end

  return goal_found
end

function generator:get_neighbours(current_node)
  local position = current_node.position
  assert(position and position.x and position.y)
  local neighbours = {}
  -- LEFT
  if position.x - 1 > 0 and self:is_traversable_tile(self.layout[position.y][position.x - 1]) then
    table.insert(
      neighbours,
      {
        position = Vector(position.x - 1, position.y)
      }
    )
  end
  -- RIGHT
  if position.x + 1 <= self.cols and self:is_traversable_tile(self.layout[position.y][position.x + 1]) then
    table.insert(
      neighbours,
      {
        position = Vector(position.x + 1, position.y)
      }
    )
  end
  -- TOP
  if position.y - 1 > 0 and self:is_traversable_tile(self.layout[position.y - 1][position.x]) then
    table.insert(
      neighbours,
      {
        position = Vector(position.x, position.y - 1)
      }
    )
  end
  -- BOTTOM
  if position.y + 1 <= self.rows and self:is_traversable_tile(self.layout[position.y + 1][position.x]) then
    table.insert(
      neighbours,
      {
        position = Vector(position.x, position.y + 1)
      }
    )
  end
  return neighbours
end

function generator:add_extra_walls(difficulty)
  local wall_count = self:get_wall_count(difficulty)
  print("Adding " .. wall_count .. " extra walls")
  for _ = 1, wall_count do
    local selected_tile = -1
    local selection = nil

    while selected_tile ~= 1 do
      selection = Vector(love.math.random(1, self.cols), love.math.random(1, self.rows))
      selected_tile = self.layout[selection.y][selection.x]
    end

    self.layout[selection.y][selection.x] = 2
  end
  return self
end

function generator:add_enemies(difficulty)
  local enemy_count = self:get_enemy_count(difficulty)
  print("Creating " .. enemy_count .. " enemies")

  local gremlin_created = false
  for _ = 1, enemy_count do
    local selected_tile = -1
    local selection = nil

    local attempts = 0
    local max_attempts = 15
    while selected_tile ~= 1 and attempts <= max_attempts do
      selection = Vector(love.math.random(1, self.cols), love.math.random(1, self.rows))
      local distance_from_spawn =
        math.floor(
        _util.m.distance_between(self.player_spawn_position.x, self.player_spawn_position.y, selection.x, selection.y)
      )
      if distance_from_spawn > 2 and self:can_reach_exit(selection) then
        selected_tile = self.layout[selection.y][selection.x]
      end
      attempts = attempts + 1
    end

    if attempts <= max_attempts then
      if not gremlin_created and self.collectible_position then
        self.layout[selection.y][selection.x] = 11
        gremlin_created = true
      else
        self.layout[selection.y][selection.x] = 10
      end
    end
  end

  return self
end

function generator:add_health_pack(difficulty, player_health, max_health)
  local damage = max_health - player_health
  local continue = true
  if damage == 0 then
    continue = love.math.random() > 0.85 -- 15% chance to spawn health
  elseif player_health == 1 then
    continue = love.math.random() > 0.4 -- 60% chance to spawn health
  else
    continue = love.math.random() > 0.65 -- 35% chance to spawn health
  end
  if difficulty == "EASIER" then
    continue = false
  end
  if self.collectible_position then
    self.continue = false
  end

  if not continue then
    return self
  end

  print("Spawning a health pickup")
  local selected_tile = -1
  local selection = nil
  local attempts = 0
  local max_attempts = 20
  while selected_tile ~= 1 and attempts <= max_attempts do
    selection = Vector(love.math.random(1, self.cols), love.math.random(1, self.rows))
    if self:can_reach_exit(selection) then
      selected_tile = self.layout[selection.y][selection.x]
    end
    attempts = attempts + 1
  end

  if attempts <= max_attempts then
    self.layout[selection.y][selection.x] = 20
    self.collectible_position = selection
  end

  return self
end

-- randomly pick a template
-- randomly pick a point on the layout
-- validate the layout wouldnt be replacing a spawn or exit block
-- apply the template matrix at that random point
function generator:apply_templates(difficulty)
  local template_count = self:get_template_count(difficulty)
  print("Applying " .. template_count .. " templates")

  for i = 1, template_count do
    -- Pick a 3x3 random template (for now)
    local template_class = _util.g.choose("3")
    local template_index = love.math.random(1, #self.templates[template_class])
    local template = self.templates[template_class][template_index]
    local t_rows = #template
    local t_cols = #template[1]

    local attempts = 0
    local max_attempts = 10
    local template_applied = false
    while not template_applied and (attempts < max_attempts) do
      -- pick a random place on the map
      local random_position = Vector(love.math.random(1, self.cols - t_cols), love.math.random(1, self.rows - t_rows))

      local contains_invalid_placement = false
      -- iterate 3x3 and check if there are any special tiles we cant override (spawn (0), exit (3))
      for x = 1, t_cols do
        for y = 1, t_rows do
          local world_x, world_y = random_position.x + x, random_position.y + y
          if self:is_sacred_tile(self.layout[world_y][world_x]) then
            contains_invalid_placement = true
          end
        end
      end

      if not contains_invalid_placement then
        -- apply the template matrix
        for x = 1, t_cols do
          for y = 1, t_rows do
            self.layout[random_position.y + y][random_position.x + x] = template[y][x]
          end
        end
        template_applied = true
      end

      attempts = attempts + 1
    end
  end
  return self
end

function generator:add_exit()
  local edge = _opposite_edge[self.chosen_spawn_edge]
  print("Exit edge: " .. edge)
  local x, y = 1, 1
  if edge == "LEFT" then
    y = love.math.random(1, self.rows)
  elseif edge == "TOP" then
    x = love.math.random(1, self.cols)
  elseif edge == "RIGHT" then
    x = self.cols
    y = love.math.random(1, self.rows)
  elseif edge == "BOTTOM" then
    x = love.math.random(1, self.cols)
    y = self.rows
  end
  self.layout[y][x] = 3
  return self
end

function generator:add_spawn()
  self.chosen_spawn_edge = _util.g.choose("LEFT", "TOP", "RIGHT", "BOTTOM")
  print("Spawn edge: " .. self.chosen_spawn_edge)
  local x, y = 1, 1
  if self.chosen_spawn_edge == "LEFT" then
    y = love.math.random(1, self.rows)
  elseif self.chosen_spawn_edge == "TOP" then
    x = love.math.random(1, self.cols)
  elseif self.chosen_spawn_edge == "RIGHT" then
    x = self.cols
    y = love.math.random(1, self.rows)
  elseif self.chosen_spawn_edge == "BOTTOM" then
    x = love.math.random(1, self.cols)
    y = self.rows
  end
  self.player_spawn_position = Vector(x, y)
  self.layout[y][x] = 0
  return self
end

function generator:build()
  return self.layout
end

-- HELPER FUNCTIONS

-- Whether or not this tile can be overriden by templates/random walls (spawns and exits shouldnt be)
function generator:is_sacred_tile(id)
  return id == 0 or id == 3
end

function generator:is_traversable_tile(id)
  return id == 1 or id == 3 or id == 10 or id == 11 or (id >= 20 and id <= 23)
end

function generator:get_difficulty(floor_count)
  if floor_count <= 3 then
    return "EASIER"
  elseif floor_count <= 8 then
    return "EASY"
  elseif floor_count <= 15 then
    return "REGULAR"
  else
    -- elseif floor_count <= 30 then
    --   return "HARDER"
    return "HARD"
  end
end

function generator:get_dimensions(difficulty)
  if difficulty == "EASIER" then
    return 5, 5
  elseif difficulty == "EASY" then
    return 8, 6
  elseif difficulty == "REGULAR" then
    return 11, 8
  elseif difficulty == "HARD" then
    return 15, 10
  end
end

function generator:get_enemy_count(difficulty)
  if difficulty == "EASIER" then
    return love.math.random(1, 2)
  elseif difficulty == "EASY" then
    return love.math.random(2, 3)
  elseif difficulty == "REGULAR" then
    return love.math.random(4, 5)
  elseif difficulty == "HARD" then
    return love.math.random(6, 9)
  end
end

function generator:get_template_count(difficulty)
  if difficulty == "EASIER" then
    return love.math.random(3, 5)
  elseif difficulty == "EASY" then
    return love.math.random(6, 8)
  elseif difficulty == "REGULAR" then
    return love.math.random(13, 18) -- duno yet
  elseif difficulty == "HARD" then
    return love.math.random(15, 22) -- duno yet
  end
end

function generator:get_wall_count(difficulty)
  if difficulty == "EASIER" then
    return love.math.random(1, 3)
  elseif difficulty == "EASY" then
    return love.math.random(3, 5)
  elseif difficulty == "REGULAR" then
    return love.math.random(8, 12)
  elseif difficulty == "HARD" then
    return love.math.random(12, 18) -- duno yet
  end
end

-- These have to be RECTANGULAR, not just squares
generator["templates"] = {
  ["3"] = {
    {
      {1, 2, 1},
      {1, 2, 1},
      {1, 2, 1}
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
    },
    {
      {2, 2, 2},
      {1, 2, 1},
      {1, 2, 1}
    },
    {
      {1, 2, 1},
      {1, 2, 1},
      {2, 2, 2}
    },
    {
      {2, 1, 2},
      {1, 1, 1},
      {2, 1, 2}
    },
    {
      {2, 1, 2},
      {1, 2, 1},
      {1, 1, 1}
    },
    {
      {1, 1, 2},
      {1, 2, 1},
      {2, 1, 1}
    },
    {
      {2, 1, 1},
      {1, 2, 1},
      {1, 1, 2}
    },
    {
      {2, 2, 1},
      {1, 1, 1},
      {1, 1, 2}
    },
    {
      {1, 1, 2},
      {1, 1, 1},
      {2, 2, 1}
    },
    {
      {1, 1, 2},
      {2, 1, 1},
      {1, 1, 1}
    },
    {
      {1, 1, 1},
      {2, 1, 1},
      {2, 1, 2}
    },
    {
      {1, 1, 1},
      {2, 1, 1},
      {1, 1, 2}
    },
    {
      {1, 2, 1},
      {1, 2, 2},
      {1, 1, 1}
    }
  }
}

return generator
