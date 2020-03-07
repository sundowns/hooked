local background_music = love.audio.newSource("resources/audio/music.mp3", "stream")
background_music:setLooping(true)

return {
  ["MUSIC"] = background_music
}
