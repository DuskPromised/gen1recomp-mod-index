-- Gate 2.5: shiny party/menu/icon repair only.
-- Derived from the later proven regional shiny-art icon path, stripped of
-- battle sprite, follower, scaling, starter-flow, and palette-transfer hooks.
local Stats = require("src.pokemon.Stats")
local PartyMenu = require("src.ui.PartyMenu")
local Assets = require("src.render.Assets")
local PaletteFX = require("src.render.PaletteFX")

local STARTER_DEX = {
  BULBASAUR=1, IVYSAUR=2, VENUSAUR=3,
  CHIKORITA=152, BAYLEEF=153, MEGANIUM=154,
  TREECKO=252, GROVYLE=253, SCEPTILE=254,
  TURTWIG=387, GROTLE=388, TORTERRA=389,
  SNIVY=495, SERVINE=496, SERPERIOR=497,
  CHESPIN=650, QUILLADIN=651, CHESNAUGHT=652,
  FENNEKIN=653, BRAIXEN=654, DELPHOX=655,
  ROWLET=722, DARTRIX=723, DECIDUEYE=724,
  GROOKEY=810, THWACKEY=811, RILLABOOM=812,
  SPRIGATITO=906, FLORAGATO=907, MEOWSCARADA=908,
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
  -- Generic menu/box/summary icon path. Normal individuals are untouched.
  mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
    local resolved = next(path, ctx)
    local species = speciesOf(ctx)
    local dex = species and STARTER_DEX[species]
    if not dex or not isShiny(ctx and ctx.mon) then
      return resolved
    end
    ctx.trueColor = true
    return mod.path .. "/assets/icons/" .. padDex(dex) .. "_shiny.png"
  end, 170)

  -- Stock PartyMenu and BetterParty ultimately call PartyMenu.drawIcon.  Draw
  -- the packaged shiny icon directly for only the targeted shiny starters.
  -- Never mutate the engine's global bySpecies icon table: that historical
  -- approach could blank rows and leak icon changes into unrelated species.
  local cache = {}
  local function imageFor(path)
    local cached = cache[path]
    if cached ~= nil then return cached or nil end
    local ok, img = pcall(love.graphics.newImage, Assets.resolve(path))
    cache[path] = ok and img or false
    return ok and img or nil
  end

  local inner = PartyMenu.drawIcon
  local function wrapped(game, mon, x, y, selected, counter, forceAlt)
    local dex = mon and STARTER_DEX[mon.species]
    if dex and isShiny(mon) and love and love.graphics then
      local path = mod.path .. "/assets/icons/" .. padDex(dex) .. "_shiny.png"
      local img = imageFor(path)
      if img then
        local iw, ih = img:getDimensions()
        local frame = 0
        if ih >= 32 then
          local alt = forceAlt or false
          if selected and not forceAlt then
            local maxhp = mon.stats and mon.stats.hp or 1
            local px = math.floor((mon.hp or 0) * 48 / math.max(1, maxhp))
            local speed = px >= 27 and 5 or px >= 10 and 16 or 32
            alt = math.floor((counter or 0) / speed) % 2 == 1
          end
          frame = alt and 1 or 0
        end
        love.graphics.setColor(1,1,1,1)
        if ih >= 32 then
          local quad = love.graphics.newQuad(0, frame * 16, 16, 16, iw, ih)
          love.graphics.draw(img, quad, x, y)
        else
          love.graphics.draw(img, x, y)
        end
        if PaletteFX and PaletteFX.markTrueColor then
          PaletteFX.markTrueColor(x, y, 16, 16)
        end
        return true
      end
      -- Asset failure falls through to the accepted engine icon; never blank.
    end
    return inner(game, mon, x, y, selected, counter, forceAlt)
  end

  PartyMenu.drawIcon = wrapped
  PartyMenu._redEarthGate25RegionalShinyIcon = wrapped

  mod.exports.version = "0.2.5"
  mod.exports.starterDex = STARTER_DEX
end
