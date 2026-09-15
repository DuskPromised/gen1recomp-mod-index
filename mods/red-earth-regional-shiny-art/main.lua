-- Red Earth Regional Shiny Art v1.0.0
-- Separate presentation layer. Shiny state remains owned by Red Earth Shiny Bridge.
-- Irregular-line authored sprites remain owned by Irregular Origin.

local Stats = require("src.pokemon.Stats")

local STARTER_DEX = {
  BULBASAUR=1, IVYSAUR=2, VENUSAUR=3,
  CHARMANDER=4, CHARMELEON=5, CHARIZARD=6,
  SQUIRTLE=7, WARTORTLE=8, BLASTOISE=9,

  CHIKORITA=152, BAYLEEF=153, MEGANIUM=154,
  CYNDAQUIL=155, QUILAVA=156, TYPHLOSION=157,
  TOTODILE=158, CROCONAW=159, FERALIGATR=160,

  TREECKO=252, GROVYLE=253, SCEPTILE=254,
  TORCHIC=255, COMBUSKEN=256, BLAZIKEN=257,
  MUDKIP=258, MARSHTOMP=259, SWAMPERT=260,

  TURTWIG=387, GROTLE=388, TORTERRA=389,
  CHIMCHAR=390, MONFERNO=391, INFERNAPE=392,
  PIPLUP=393, PRINPLUP=394, EMPOLEON=395,

  SNIVY=495, SERVINE=496, SERPERIOR=497,
  TEPIG=498, PIGNITE=499, EMBOAR=500,
  OSHAWOTT=501, DEWOTT=502, SAMUROTT=503,

  CHESPIN=650, QUILLADIN=651, CHESNAUGHT=652,
  FENNEKIN=653, BRAIXEN=654, DELPHOX=655,
  FROAKIE=656, FROGADIER=657, GRENINJA=658,

  ROWLET=722, DARTRIX=723, DECIDUEYE=724,
  LITTEN=725, TORRACAT=726, INCINEROAR=727,
  POPPLIO=728, BRIONNE=729, PRIMARINA=730,
}

-- Proper directional walker art is packaged for the current Kalos companion
-- line. Earlier starters use Wilds' own normal/shiny runtime walker sheets.
local FENNEKIN_FOLLOWER = {
  FENNEKIN=653, BRAIXEN=654, DELPHOX=655,
}

local function speciesOf(ctx)
  if not ctx then return nil end
  return ctx.species or (ctx.mon and ctx.mon.species)
end

local function isShiny(mon)
  if not mon then return false end
  if mon.shiny == true or mon.isShiny == true then return true end
  return Stats.isShiny and Stats.isShiny(mon.dvs) or false
end

local function padDex(n)
  return string.format("%03d", tonumber(n) or 0)
end

return function(mod)
  -- Regional starter battle / summary art. Only shiny individuals are
  -- intercepted; normal art remains entirely owned by Allgen Kaizo.
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    local resolved = next(path, ctx)
    local species = speciesOf(ctx)
    local dex = species and STARTER_DEX[species]
    if not dex or not isShiny(ctx and ctx.mon) then
      return resolved
    end

    ctx.trueColor = true
    local root = mod.path .. "/assets/battlers/" .. padDex(dex)
    if ctx.side == "back" then
      return root .. "_back_shiny.png"
    end
    -- Enemy/front, summary, dex and menu all use the front shiny portrait.
    return root .. "_front_shiny.png"
  end, 150)

  -- Two-frame 16x32 true-color shiny icons derived from the same canonical
  -- shiny art. This makes the small party sprite visibly shiny as well as
  -- keeping SHINY_POKEMON's star marker beside the name.
  mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
    local resolved = next(path, ctx)
    local species = speciesOf(ctx)
    local dex = species and STARTER_DEX[species]
    if not dex or not isShiny(ctx and ctx.mon) then
      return resolved
    end
    ctx.trueColor = true
    return mod.path .. "/assets/icons/" .. padDex(dex) .. "_shiny.png"
  end, 150)

  -- Wilds owns follower rendering. It already ships shiny walker sheets for
  -- Treecko and the other <=649 starter families. Its built-in land set stops
  -- at 649, so provide proper normal/shiny walkers for Fennekin's full line.
  local providerInstalled = false
  local function installFollowerProvider(game)
    if providerInstalled or type(mod.find) ~= "function" then return end
    local okFind, wilds = pcall(function()
      return mod:find("overworld_wild_spawns")
    end)
    local ex = okFind and wilds and wilds.exports
    if not (ex and type(ex.getSpriteProvider) == "function"
        and type(ex.registerSpriteProvider) == "function") then
      return
    end

    local okBase, base = pcall(ex.getSpriteProvider, "pokedex")
    if not okBase or type(base) ~= "table" then return end
    if base.__redEarthRegionalShinyArt then
      providerInstalled = true
      return
    end

    local wrapper = {
      id = "pokedex",
      __redEarthRegionalShinyArt = true,
    }

    function wrapper:isAvailable(_game)
      return true, "Red Earth regional shiny-art follower bridge"
    end

    function wrapper:resolve(speciesId, variant, targetGame)
      local species = speciesId
      if type(species) ~= "string" then
        -- The follower service normally passes species keys; retain a numeric
        -- fallback for callers that resolve by National Dex id.
        local dex = tonumber(speciesId)
        if dex then
          for key, value in pairs(FENNEKIN_FOLLOWER) do
            if value == dex then species = key break end
          end
        end
      end

      local dex = species and FENNEKIN_FOLLOWER[species]
      if dex then
        local shiny = variant == true
          or tostring(variant or ""):lower() == "shiny"
        local suffix = shiny and "shiny" or "normal"
        return {
          id = "SPRITE_RED_EARTH_" .. tostring(species)
            .. (shiny and "_SHINY" or ""),
          image = mod.path .. "/assets/followers/" .. padDex(dex)
            .. "_" .. suffix .. ".png",
          frames = 6,
          walker = true,
          trueColor = true,
          frameWidth = 16,
          frameHeight = 16,
          anchorX = 8,
          anchorY = 15,
          pokepcShiny = shiny and true or false,
        }, {
          providerId = "pokedex",
          providerMod = mod.id,
          usedVariant = suffix,
          bodyRenderer = "NATIVE_SPRITE_RENDERER",
        }, nil
      end

      if type(base.resolve) == "function" then
        return base:resolve(speciesId, variant, targetGame)
      end
      return nil, nil, "no follower sprite"
    end

    local okRegister, registered = pcall(ex.registerSpriteProvider, "pokedex", wrapper)
    if okRegister and registered ~= false then
      providerInstalled = true
      if type(ex.refreshAllEntitySprites) == "function" then
        pcall(ex.refreshAllEntitySprites, game)
      end
      mod.log:info("regional shiny-art follower provider installed")
    end
  end

  mod.events:on("game.ready", function(ev)
    installFollowerProvider((ev and ev.game) or mod.game)
  end)
  mod.events:on("map.entered", function(ev)
    installFollowerProvider((ev and ev.game) or mod.game)
  end)
  pcall(installFollowerProvider, mod.game)

  mod.exports.version = "1.0.0"
  mod.exports.starterDex = STARTER_DEX
end
