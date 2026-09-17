-- Gate 2.8: presentation-only repair built directly on accepted 0.2.6.
-- It never changes a Pokémon's shiny state/DVs and never touches scaling,
-- starter routing, evolution logic, authored Irregular art, Natures or passives.
local DexEntryMenu = require("src.ui.DexEntryMenu")
local Assets = require("src.render.Assets")
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
    "Gate 2.6 starter shiny module required")
  local sx = starter.exports or {}
  local dexMap = sx.starterDex or {}

  local function shinyAsset(species)
    local dex = dexMap[species]
    if not dex then return nil end
    return starter.path .. "/assets/battlers/"
      .. string.format("%03d", tonumber(dex) or 0) .. "_front_shiny.png"
  end

  -- Oak's starter preview is uniquely passed to DexEntryMenu with
  -- { species=..., forceOwned=true }.  Replace the *constructed screen's*
  -- sprite, rather than relying on script-command timing or changing the mon.
  -- This leaves ordinary Pokédex entries and every 0.2.6 shiny route alone.
  if DexEntryMenu._redEarthGate28 ~= DexEntryMenu.new then
    local innerNew = DexEntryMenu.new
    local cache = {}
    DexEntryMenu.new = function(game, speciesOrOpts, onDone)
      local inst = innerNew(game, speciesOrOpts, onDone)
      if type(speciesOrOpts) == "table" and speciesOrOpts.forceOwned == true then
        local species = speciesOrOpts.species or speciesOrOpts[1]
        local path = shinyAsset(species)
        if path then
          local img = cache[path]
          if img == nil then
            local ok, loaded = pcall(love.graphics.newImage, Assets.resolve(path))
            img = ok and loaded or false
            cache[path] = img
          end
          if img then
            inst.sprite = img
            inst.spriteTrueColor = true
          end
        end
      end
      return inst
    end
    DexEntryMenu._redEarthGate28 = DexEntryMenu.new
  end

  -- Presentation-only sparkle for the already-working 0.2.6 starter marker.
  -- No write to mon.shiny, mon.dvs, stats, species, moves, or evolution state.
  local installed = setmetatable({}, { __mode="k" })
  local image, quads

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

  local function drawFX(fx,x,y,scale)
    if not makeImage() then return end
    local t = (love.timer.getTime()-fx.started)*60
    local g = love.graphics
    g.push("all"); g.setColor(1,1,1,1)
    for _,v in ipairs(SEQUENCE) do
      local age = t-v[1]
      if age >= 0 and age < 24 then
        local frame = age<4 and 1 or age<9 and 2 or age<15 and 3 or age<20 and 4 or 1
        g.draw(image,quads[frame],math.floor(x+v[2]*scale),
          math.floor(y+v[3]*scale),0,v[4],v[4],8,8)
      end
    end
    g.pop()
  end

  local function install(battle)
    if not battle or installed[battle] then return end
    local fx
    local function target(self,battler)
      if not (self and battler and battler == self.player) then return nil end
      local mon = battler.mon
      return mon and sx.isGuaranteed and sx.isGuaranteed(mon) and mon or nil
    end

    local innerPic = battle.drawBattlerPic
    battle.drawBattlerPic = function(self,battler,x,y,scale,...)
      local r = pack(innerPic(self,battler,x,y,scale,...))
      if fx and fx.mon == battler.mon and target(self,battler)
          and love.timer.getTime()-fx.started < 1.5 then
        local img = battler.sprite
        if img then drawFX(fx,x+img:getWidth()*scale/2,y+img:getHeight()*scale/2,scale) end
      end
      return unpack(r,1,r.n)
    end

    local innerCry = battle.playEntranceCry
    battle.playEntranceCry = function(self,battler)
      if not target(self,battler) then return innerCry(self,battler) end
      local ok, source = pcall(love.audio.newSource,
        FXBASE .. "gen2_shiny_sparkle.mp3", "static")
      if not ok or not source then return innerCry(self,battler) end
      if fx and fx.source then fx.source:stop() end
      fx = { mon=battler.mon, battler=battler, source=source,
             started=love.timer.getTime(), cried=false }
      source:setLooping(false); source:play()
      return source
    end

    local innerUpdate = battle.update
    battle.update = function(self,dt)
      local r = pack(innerUpdate(self,dt))
      if fx and not fx.cried and fx.source and not fx.source:isPlaying() then
        fx.cried = true
        if self.player and self.player.mon == fx.mon then innerCry(self,fx.battler) end
      end
      return unpack(r,1,r.n)
    end

    local innerExit = battle.exit
    battle.exit = function(self,...)
      if fx and fx.source then fx.source:stop() end
      fx = nil
      return innerExit(self,...)
    end
    installed[battle] = true
  end

  mod.events:on("battle.started",function(ev) install(ev and ev.battle) end)
  mod.exports.version = "0.2.8"
  mod.exports.palette = { gold=GOLD, lilac=LILAC }
end
