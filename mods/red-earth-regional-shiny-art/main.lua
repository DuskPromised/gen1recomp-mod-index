-- Red Earth Regional Shiny Art v1.0.2
-- Separate presentation layer. Shiny state remains owned by Red Earth Shiny Bridge.
-- Irregular-line authored sprites remain owned by Irregular Origin.

local Stats = require("src.pokemon.Stats")
local PartyMenu = require("src.ui.PartyMenu")

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


  -- BetterParty and the stock party screen both eventually call
  -- PartyMenu.drawIcon.  Re-seat the shiny icon there as well as through the
  -- pokemon.icon hook, because presentation mods can cache/replace icon paths
  -- before our Runtime hook gets a chance to paint the row.
  local function installPartyIconOverride()
    if PartyMenu._redEarthRegionalShinyArtV102 == PartyMenu.drawIcon then
      return true
    end
    local inner = PartyMenu.drawIcon
    local function wrapped(game, mon, x, y, selected, counter, forceAlt)
      local dex = mon and STARTER_DEX[mon.species]
      if dex and isShiny(mon) and game and game.data then
        local icons = game.data.icons
        if icons then
          icons.bySpecies = icons.bySpecies or {}
          local old = icons.bySpecies[mon.species]
          icons.bySpecies[mon.species] = {
            image = mod.path .. "/assets/icons/" .. padDex(dex) .. "_shiny.png",
            frames = 2,
            trueColor = true,
          }
          local ok, a, b, c = pcall(
            inner, game, mon, x, y, selected, counter, forceAlt
          )
          icons.bySpecies[mon.species] = old
          if not ok then error(a, 0) end
          return a, b, c
        end
      end
      return inner(game, mon, x, y, selected, counter, forceAlt)
    end
    PartyMenu.drawIcon = wrapped
    PartyMenu._redEarthRegionalShinyArtV102 = wrapped
    return true
  end

  installPartyIconOverride()

  -- Wilds owns follower rendering. Public style "followers" resolves through
  -- followers_ex -> pokemmo -> pokedex. Wrap every available provider in that
  -- chain so Fennekin/Braixen/Delphox cannot be claimed by an earlier normal-
  -- art provider before our dedicated shiny/normal walkers are reached.
  local wrappedProviders = {}

  local function fennekinFollowerDef(species, variant)
    local dex = species and FENNEKIN_FOLLOWER[species]
    if not dex then return nil end
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
      providerMod = mod.id,
      usedVariant = suffix,
      bodyRenderer = "NATIVE_SPRITE_RENDERER",
    }, nil
  end

  local function speciesKey(speciesId)
    if type(speciesId) == "string" and FENNEKIN_FOLLOWER[speciesId] then
      return speciesId
    end
    local dex = tonumber(speciesId)
    if dex then
      for key, value in pairs(FENNEKIN_FOLLOWER) do
        if value == dex then return key end
      end
    end
    return speciesId
  end

  local function wrapProvider(ex, providerId, game)
    if wrappedProviders[providerId] then return true end
    local okBase, base = pcall(ex.getSpriteProvider, providerId)
    if not okBase or type(base) ~= "table" then return false end
    if base.__redEarthRegionalShinyArt then
      wrappedProviders[providerId] = true
      return true
    end

    local wrapper = {
      id = providerId,
      __redEarthRegionalShinyArt = true,
    }

    function wrapper:isAvailable(targetGame)
      if type(base.isAvailable) == "function" then
        local ok, available, why = pcall(base.isAvailable, base, targetGame)
        if ok then return available, why end
      end
      return true, "Red Earth regional shiny-art follower bridge"
    end

    function wrapper:resolve(speciesId, variant, targetGame)
      local species = speciesKey(speciesId)
      local def, meta, err = fennekinFollowerDef(species, variant)
      if def then
        meta.providerId = providerId
        return def, meta, err
      end
      if type(base.resolve) == "function" then
        return base:resolve(speciesId, variant, targetGame)
      end
      return nil, nil, "no follower sprite"
    end

    -- Preserve optional water/state methods from the original provider for
    -- every species Red Earth does not override.
    function wrapper:resolveWater(speciesId, variant, targetGame)
      local species = speciesKey(speciesId)
      local def, meta, err = fennekinFollowerDef(species, variant)
      if def then
        meta.providerId = providerId
        return def, meta, err
      end
      if type(base.resolveWater) == "function" then
        return base:resolveWater(speciesId, variant, targetGame)
      end
      if type(base.resolve) == "function" then
        return base:resolve(speciesId, variant, targetGame)
      end
      return nil, nil, "no follower sprite"
    end

    function wrapper:resolveForState(speciesId, variant, state, targetGame)
      local species = speciesKey(speciesId)
      local def, meta, err = fennekinFollowerDef(species, variant)
      if def then
        meta.providerId = providerId
        return def, meta, err
      end
      if type(base.resolveForState) == "function" then
        return base:resolveForState(speciesId, variant, state, targetGame)
      end
      if state == "water" and type(base.resolveWater) == "function" then
        return base:resolveWater(speciesId, variant, targetGame)
      end
      if type(base.resolve) == "function" then
        return base:resolve(speciesId, variant, targetGame)
      end
      return nil, nil, "no follower sprite"
    end

    local okRegister, registered = pcall(
      ex.registerSpriteProvider, providerId, wrapper
    )
    if okRegister and registered ~= false then
      wrappedProviders[providerId] = true
      mod.log:info("regional shiny-art wrapped Wilds provider: %s",
        tostring(providerId))
      return true
    end
    return false
  end

  local function installFollowerProviders(game)
    if type(mod.find) ~= "function" then return end
    local okFind, wilds = pcall(function()
      return mod:find("overworld_wild_spawns")
    end)
    local ex = okFind and wilds and wilds.exports
    if not (ex and type(ex.getSpriteProvider) == "function"
        and type(ex.registerSpriteProvider) == "function") then
      return
    end

    -- Mirrors Wilds' public "followers" chain.
    wrapProvider(ex, "followers_ex", game)
    wrapProvider(ex, "pokemmo", game)
    wrapProvider(ex, "pokedex", game)

    if type(ex.refreshAllEntitySprites) == "function" then
      pcall(ex.refreshAllEntitySprites, game)
    end
  end

  mod.events:on("game.ready", function(ev)
    installFollowerProviders((ev and ev.game) or mod.game)
  end)
  mod.events:on("map.entered", function(ev)
    installFollowerProviders((ev and ev.game) or mod.game)
  end)
  pcall(installFollowerProviders, mod.game)

  mod.exports.version = "1.0.2"
  mod.exports.starterDex = STARTER_DEX
end
