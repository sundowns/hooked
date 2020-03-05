loading = {}
local splash_displaying = false
local splash_screen = nil
local MINIMUM_LOAD_TIME = 0.1 --TODO: 1.25
local load_timer = 0

function loading:init()
  love.graphics.setDefaultFilter("nearest", "nearest", 4)
  love.graphics.setBackgroundColor(0.05, 0.1, 0.1)
  splash_screen = love.graphics.newImage("resources/misc/splashscreen.png")
end

function loading:enter(previous, task, data)
end

function loading:leave()
end

function loading:update(dt)
  if splash_displaying and load_timer > MINIMUM_LOAD_TIME then
    load_game()
  end

  splash_displaying = true
  load_timer = load_timer + dt
end

function loading:draw()
  love.graphics.draw(
    splash_screen,
    0,
    0,
    0,
    love.graphics:getWidth() / splash_screen:getWidth(),
    love.graphics.getHeight() / splash_screen:getHeight()
  )
end

function load_game()
  math.randomseed(os.time())
  -- Globals
  Vector = require("libs.vector")
  Timer = require("libs.timer")
  _util = require("libs.util")
  _constants = require("src.constants")
  _sprites = require("src.sprites")
  -- moonshine = require("libs.moonshine")

  _fonts = {
    ["FLOOR_COUNTER"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 48),
    ["CONTROLS"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 20),
    ["PHASES"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 28),
    ["HIGH_SCORE"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 20),
    ["TITLE"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 100),
    ["GAME_OVER"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 128),
    ["START"] = love.graphics.newFont("resources/fonts/slkscr.ttf", 24)
  }

  -- GamestateManager.switch(game, {})
  GamestateManager.switch(title, {floor_count = 0})
end
