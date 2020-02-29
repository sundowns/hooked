local health = Concord.system({_components.health, _components.control, "PLAYER"})
function health:init()
  -- -- a black/white mask image: black pixels will mask, white pixels will pass.
  -- local mask = love.graphics.newImage("resources/")
  -- local mask_shader =
  --   love.graphics.newShader [[
  --     vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  --     if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
  --       // a discarded pixel wont be applied as the stencil.
  --       discard;
  --     }
  --     return vec4(1.0);
  -- }]]
  -- self.stencil_fn = function()
  --   love.graphics.setShader(mask_shader)
  --   love.graphics.draw(mask, 0, 0)
  --   love.graphics.setShader()
  -- end
end

function health:reduce()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)
  health:reduce(1)
  if health.current <= 0 then
    print("ur dead dude") -- TODO:
  end
end

function health:draw_debug()
  local player = self.PLAYER:get(1)
  local health = player:get(_components.health)
  love.graphics.print(health.current .. "/" .. health.maximum, love.graphics.getWidth() / 2, 0)
end

function health:draw_ui()
  -- love.graphics.stencil(myStencilFunction, "replace", 1)
  -- love.graphics.setStencilTest("greater", 0)
  -- love.graphics.rectangle("fill", 0, 0, 256, 256)
  -- love.graphics.setStencilTest()
end

return health
