local background_music = love.audio.newSource("resources/audio/music.mp3", "stream")
background_music:setLooping(true)

return {
  ["MUSIC"] = background_music,
  ["LOSE_HEALTH"] = love.audio.newSource("resources/audio/lose_health.wav", "static"),
  ["HEALTH_PICKUP"] = love.audio.newSource("resources/audio/health_pickup.mp3", "static"),
  ["ENEMY_DEATH"] = love.audio.newSource("resources/audio/enemy_death.wav", "static"),
  ["FLOOR_CLEARED"] = love.audio.newSource("resources/audio/victory_sound.wav", "static"),
  ["GAME_OVER"] = love.audio.newSource("resources/audio/game_over.wav", "static"),
  ["PLAYER_MOVED"] = love.audio.newSource("resources/audio/player_moved.wav", "static"),
  ["HOOK_MOVED"] = love.audio.newSource("resources/audio/hook_moved.wav", "static"),
  ["ENEMY_MOVED"] = love.audio.newSource("resources/audio/enemy_moved.wav", "static"),
  ["HOOK_RETURNED"] = love.audio.newSource("resources/audio/hook_returned.wav", "static")
}
