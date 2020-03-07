local health = Concord.system({_components.health, _components.control, "PLAYER"})
function health:init()
  -- -- a black/white mask image: black pixels will mask, white pixels will pass.
  mask = love.graphics.newImage("resources/misc/health_mask.png")
  mask_shader =
    love.graphics.newShader [[
      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
        // a discarded pixel wont be applied as the stencil.
        discard;
      }
      return vec4(1.0);
  }]]
  self.mask_width = 256
  self.stencil_fn_gen = function(x, y, scale)
    return function()
      love.graphics.setShader(mask_shader)
      love.graphics.draw(mask, x, y, 0, scale or 1, scale or 1)
      love.graphics.setShader()
    end
  end
  self.mask_scale = 0.5
  self.health_colours = {
    {0.443, 0.09, 0.09},
    {0.965, 0.20, 0.388},
    {0.706, 0.20, 0.965},
    {0.278, 0.20, 0.965}
  }
end

function health:reduce_health()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)
  health:reduce(1)
  _audio["LOSE_HEALTH"]:play()
  self:getWorld():emit("shake", 0.5, 0.5)
  if health.current <= 0 then
    self:getWorld():emit("player_died")
  end
end

function health:player_got_collectible(type)
  if type == "health" then
    local player = self.PLAYER:get(1)
    player:get(_components.health):increase(1)
    _audio["HEALTH_PICKUP"]:play()
  end
end

function health:draw_debug()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)
  love.graphics.print(health.current .. "/" .. health.maximum, love.graphics.getWidth() * 0.87, 0)
end

function health:draw_ui()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)

  local health_chunk_height = self.mask_width * self.mask_scale / health.maximum
  local x, y = (love.graphics.getWidth() - self.mask_width * self.mask_scale), 0

  love.graphics.stencil(self.stencil_fn_gen(x, y, self.mask_scale), "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  -- draw 4 equal height rectangles in each health colour

  love.graphics.setColor(0.15, 0.15, 0.15)
  love.graphics.rectangle("fill", x, y, self.mask_width * self.mask_scale, self.mask_width * self.mask_scale)
  for i = 1, health.maximum do
    if i <= health.current then
      love.graphics.setColor(self.health_colours[i])
      love.graphics.rectangle(
        "fill",
        x,
        y + ((health.maximum - i) * health_chunk_height),
        self.mask_width * self.mask_scale,
        health_chunk_height
      )
    end
  end

  _util.l.reset_colour()
  love.graphics.setStencilTest()
end

return health
