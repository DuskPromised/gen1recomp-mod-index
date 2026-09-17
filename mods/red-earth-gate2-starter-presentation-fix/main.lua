-- Gate 2.7: timing/presentation repair layered on accepted 0.2.6.
-- No scaling, evolution, starter-selection, Nature, passive, or Irregular-art changes.
local Stats = require("src.pokemon.Stats")
local unpack = table.unpack or unpack
local function pack(...) return { n=select("#", ...), ... } end

local TARGET = {
  FENNEKIN=true,
  BULBASAUR=true, CHIKORITA=true, TREECKO=true, TURTWIG=true,
  SNIVY=true, CHESPIN=true, ROWLET=true,
}

local FXBASE = "mods/crystal_animated_sprites_with_shiny_visuals/assets/shiny_visuals/"
local SEQUENCE = {
  {6,-8,-18,1},{14,12,-12,1},{22,18,8,1},{30,2,19,1},
  {38,-19,12,1},{46,-22,-7,1},{54,-4,-1,2},
}
local GOLD  = {1.00,0.82,0.28,1.00}
local LILAC = {0.78,0.68,1.00,1.00}

local function oakLab(ctx)
  local mapId = ctx and ctx.overworld and ctx.overworld.map and ctx.overworld.map.id
  if mapId == "OAKS_LAB" then return true end
  return ctx and ctx.source and ctx.source.mapId == "OAKS_LAB"
end

local function padDex(n)
  return string.format("%03d", tonumber(n) or 0)
end

return function(mod)
  local starter = assert(mod:find("red_earth_gate2_starter_shiny_state_icons"),
    "Gate 2.6 starter shiny module required")
  local starterExports = starter.exports or {}
  local activePreviewSpecies

  -- Run after Allgen Kaizo's default-priority script.command swap so args
  -- already contain the actual Fennekin/regional starter selected for the ball.
  mod.hooks:wrap("script.command", function(next, ctx, name, args, ...)
    if not (oakLab(ctx) and type(args) == "table") then
      return next(ctx, name, args, ...)
    end

    -- Oak's StarterDex preview is constructed synchronously inside push_screen.
    -- Keep the shiny preview flag alive only for that one screen call.
    if name == "push_screen" and args[1] == "DexEntryMenu"
        and type(args[2]) == "table" and TARGET[args[2].species] then
      activePreviewSpecies = args[2].species
      local r = pack(pcall(next, ctx, name, args, ...))
      activePreviewSpecies = nil
      if not r[1] then error(r[2], 0) end
      return unpack(r, 2, r.n)
    end

    -- The 0.2.6 module repaired the mon immediately AFTER give_pokemon.
    -- That was sufficient for menus/battle art, but too late for first-presentation
    -- consumers. Arm a one-shot Pokemon.new shim for exactly this transformed Oak
    -- gift, consume it on the level-5 construction, then restore Pokemon.new before
    -- give_pokemon can continue into nickname/UI flow.
    if name == "give_pokemon" and TARGET[args[1]]
        and (tonumber(args[2]) or 0) == 5 then
      local targetSpecies = args[1]
      local Pokemon = require("src.pokemon.Pokemon")
      local originalNew = Pokemon.new
      local armed = true
      Pokemon.new = function(data, species, level, rng)
        local mon = originalNew(data, species, level, rng)
        if armed and species == targetSpecies and (tonumber(level) or 0) == 5 then
          armed = false
          Pokemon.new = originalNew
          if starterExports.makeGuaranteedShiny then
            starterExports.makeGuaranteedShiny(mon, (ctx and ctx.game) or mod.game)
          end
        end
        return mon
      end
      local r = pack(pcall(next, ctx, name, args, ...))
      if Pokemon.new ~= originalNew then Pokemon.new = originalNew end
      if not r[1] then error(r[2], 0) end
      return unpack(r, 2, r.n)
    end

    return next(ctx, name, args, ...)
  end, -50)

  -- Only the active Oak acceptance/Dex preview bypasses the mon-dependent 0.2.6
  -- shiny route. Ordinary Pokédex entries remain untouched.
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    if ctx and ctx.kind == "dex" and ctx.side ~= "back"
        and activePreviewSpecies and ctx.species == activePreviewSpecies then
      local dex = starterExports.starterDex and starterExports.starterDex[ctx.species]
      if dex then
        ctx.trueColor = true
        return starter.path .. "/assets/battlers/" .. padDex(dex) .. "_front_shiny.png"
      end
    end
    return next(path, ctx)
  end, 190)

  -- Crystal's native reveal does not currently fire for these all-gen starter
  -- replacements on-device, so provide the already-accepted Red Earth reveal
  -- only for the guaranteed starter-shiny contract. This does not touch the
  -- Irregular line, which remains owned by Gate 2.0/2.4 presentation modules.
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

  local function drawFX(fx, x, y, scale)
    if not makeImage() then return end
    local t = (love.timer.getTime() - fx.started) * 60
    local g = love.graphics
    g.push("all")
    g.setColor(1,1,1,1)
    for _,v in ipairs(SEQUENCE) do
      local age = t - v[1]
      if age >= 0 and age < 24 then
        local frame = age < 4 and 1 or age < 9 and 2 or age < 15 and 3 or age < 20 and 4 or 1
        g.draw(image, quads[frame], math.floor(x+v[2]*scale),
          math.floor(y+v[3]*scale), 0, v[4], v[4], 8, 8)
      end
    end
    g.pop()
  end

  local function isTarget(mon)
    if not (mon and TARGET[mon.species]) then return false end
    if starterExports.isGuaranteed and starterExports.isGuaranteed(mon) then return true end
    return Stats.isShiny and Stats.isShiny(mon.dvs) or false
  end

  local function install(battle)
    if not battle or installed[battle] then return end
    local fx

    local function target(self, battler)
      if not (self and battler and battler == self.player) then return nil end
      local mon = battler.mon
      return isTarget(mon) and mon or nil
    end

    local innerPic = battle.drawBattlerPic
    battle.drawBattlerPic = function(self, battler, x, y, scale, ...)
      local r = pack(innerPic(self, battler, x, y, scale, ...))
      if fx and fx.mon == battler.mon and battler == self.player and target(self,battler)
          and love.timer.getTime() - fx.started < 1.5 then
        local img = battler.sprite
        if img then
          drawFX(fx, x + img:getWidth()*scale/2, y + img:getHeight()*scale/2, scale)
        end
      end
      return unpack(r, 1, r.n)
    end

    local innerCry = battle.playEntranceCry
    battle.playEntranceCry = function(self, battler)
      if not target(self, battler) then return innerCry(self, battler) end
      local ok, source = pcall(love.audio.newSource,
        FXBASE .. "gen2_shiny_sparkle.mp3", "static")
      if not ok or not source then return innerCry(self, battler) end
      if fx and fx.source then fx.source:stop() end
      fx = { mon=battler.mon, battler=battler, source=source,
             started=love.timer.getTime(), cried=false }
      source:setLooping(false)
      source:play()
      return source
    end

    local innerUpdate = battle.update
    battle.update = function(self, dt)
      local r = pack(innerUpdate(self, dt))
      if fx and not fx.cried and fx.source and not fx.source:isPlaying() then
        fx.cried = true
        if self.player and self.player.mon == fx.mon then
          innerCry(self, fx.battler)
        end
      end
      return unpack(r, 1, r.n)
    end

    local innerExit = battle.exit
    battle.exit = function(self, ...)
      if fx and fx.source then fx.source:stop() end
      fx = nil
      return innerExit(self, ...)
    end

    installed[battle] = true
  end

  mod.events:on("battle.started", function(ev) install(ev and ev.battle) end)

  mod.exports.version = "0.2.7"
  mod.exports.palette = { gold=GOLD, lilac=LILAC }
end
