-- Gate 2.10: isolated player-side shiny reveal for guaranteed starter shinies.
-- This is intentionally separate from the accepted Irregular presentation.
-- It only recognizes mons marked by red_earth_gate2_starter_shiny_state_icons.

local unpack = table.unpack or unpack
local function pack(...) return { n=select("#", ...), ... } end

local FXBASE = "mods/crystal_animated_sprites_with_shiny_visuals/assets/shiny_visuals/"
local SEQUENCE = {
  {6,-8,-18,1},{14,12,-12,1},{22,18,8,1},{30,2,19,1},
  {38,-19,12,1},{46,-22,-7,1},{54,-4,-1,2},
}
local GOLD  = {1.00,0.82,0.28,1.00}
local LILAC = {0.78,0.68,1.00,1.00}

return function(mod)
  local starter = assert(mod:find("red_earth_gate2_starter_shiny_state_icons"),
    "Gate 2.10 starter shiny contract required")
  local sx = starter.exports or {}
  local installed = setmetatable({}, { __mode="k" })
  local image, quads

  local function target(self, battler)
    if not (self and battler and battler == self.player) then return nil end
    local mon = battler.mon
    return mon and sx.isGuaranteed and sx.isGuaranteed(mon) and mon or nil
  end

  local function makeImage()
    if image then return true end
    local ok, data = pcall(love.image.newImageData, FXBASE .. "gen2_sparkles.png")
    if not ok or not data then return false end
    data:mapPixel(function(x,y,r,g,b,a)
      if a <= 0 then return 0,0,0,0 end
      local c = ((x+y)%7 == 0) and LILAC or GOLD
      return c[1],c[2],c[3],a
    end)
    image = love.graphics.newImage(data)
    image:setFilter("nearest","nearest")
    quads = {}
    for i=0,3 do
      quads[i+1] = love.graphics.newQuad(i*16,0,16,16,64,16)
    end
    return true
  end

  local function drawFX(fx, x, y, scale)
    if not makeImage() then return end
    local t = (love.timer.getTime() - fx.started) * 60
    local g = love.graphics
    g.push("all")
    g.setColor(1,1,1,1)
    for _, v in ipairs(SEQUENCE) do
      local age = t - v[1]
      if age >= 0 and age < 24 then
        local frame = age < 4 and 1 or age < 9 and 2 or age < 15 and 3
          or age < 20 and 4 or 1
        g.draw(image, quads[frame],
          math.floor(x + v[2] * scale),
          math.floor(y + v[3] * scale),
          0, v[4], v[4], 8, 8)
      end
    end
    g.pop()
  end

  local function install(battle)
    if not battle or installed[battle] then return end
    local fx

    local innerPic = battle.drawBattlerPic
    battle.drawBattlerPic = function(self, battler, x, y, scale, ...)
      local result = pack(innerPic(self, battler, x, y, scale, ...))
      if fx and fx.mon == battler.mon and target(self, battler)
          and love.timer.getTime() - fx.started < 1.5 then
        local img = battler.sprite
        if img then
          drawFX(fx,
            x + img:getWidth() * scale / 2,
            y + img:getHeight() * scale / 2,
            scale)
        end
      end
      return unpack(result, 1, result.n)
    end

    local innerCry = battle.playEntranceCry
    battle.playEntranceCry = function(self, battler)
      if not target(self, battler) then return innerCry(self, battler) end
      local ok, source = pcall(love.audio.newSource,
        FXBASE .. "gen2_shiny_sparkle.mp3", "static")
      if not ok or not source then return innerCry(self, battler) end
      if fx and fx.source then fx.source:stop() end
      fx = {
        mon=battler.mon,
        battler=battler,
        source=source,
        started=love.timer.getTime(),
        cried=false,
      }
      source:setLooping(false)
      source:play()
      return source
    end

    local innerUpdate = battle.update
    battle.update = function(self, dt)
      local result = pack(innerUpdate(self, dt))
      if fx and not fx.cried and fx.source and not fx.source:isPlaying() then
        fx.cried = true
        if self.player and self.player.mon == fx.mon then
          innerCry(self, fx.battler)
        end
      end
      return unpack(result, 1, result.n)
    end

    local innerExit = battle.exit
    battle.exit = function(self, ...)
      if fx and fx.source then fx.source:stop() end
      fx = nil
      return innerExit(self, ...)
    end

    installed[battle] = true
  end

  mod.events:on("battle.started", function(ev)
    install(ev and ev.battle)
  end)

  mod.exports.version = "0.2.10"
  mod.exports.palette = { gold=GOLD, lilac=LILAC }
end
