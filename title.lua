title = {}

local _game_title = "Hooked"

function title:init()
  self.high_score = 0
  self.construct_score_text = function()
    return "Highest Floor: #" .. self.high_score
  end
  self.text = {
    ["HIGH_SCORE"] = love.graphics.newText(_fonts["HIGH_SCORE"], self.construct_score_text()),
    ["TITLE"] = love.graphics.newText(_fonts["TITLE"], _game_title),
    ["START"] = love.graphics.newText(_fonts["START"], "Press [SPACE] to start!")
  }
end

function title:enter(previous, data)
  if not data then
    data = {}
  end
  self.high_score = math.max(data["floor_count"] or 0, self.high_score)
  self:update_high_score()
end

function title:leave()
end

function title:update(dt)
end

function title:update_high_score()
  self.text["HIGH_SCORE"]:set(self.construct_score_text())
end

function title:draw()
  love.graphics.setColor(_constants.COLOURS["GOLD"])
  love.graphics.draw(
    self.text["TITLE"],
    love.graphics.getWidth() / 2 - self.text["TITLE"]:getWidth() / 2,
    self.text["TITLE"]:getHeight()
  )
  _util.l.reset_colour()

  love.graphics.draw(
    self.text["START"],
    love.graphics.getWidth() / 2 - self.text["START"]:getWidth() / 2,
    love.graphics.getHeight() / 2 - self.text["START"]:getHeight() / 2
  )

  if self.high_score > 0 then
    love.graphics.draw(
      self.text["HIGH_SCORE"],
      love.graphics.getWidth() / 2 - self.text["HIGH_SCORE"]:getWidth() / 2,
      self.text["TITLE"]:getHeight() * 2
    )
  end
end

function title:keypressed(key)
  if key == "space" then
    GamestateManager.switch(game)
  end
end
