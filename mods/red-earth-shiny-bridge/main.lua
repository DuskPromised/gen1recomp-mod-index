-- Red Earth Shiny Bridge v1.0.0
-- Separate compatibility layer. It NEVER owns battle/follower rendering.
-- Crystal Animated Sprites owns battle shiny presentation; Wilds owns followers.
-- This mod only guarantees and preserves the underlying shiny Pokemon state.

local Stats = require("src.pokemon.Stats")

local PSYDREN = "IRR_PSYDREN"

-- Base starter species. The current Red Earth selector uses the installed
-- regional roster; including Galar/Paldea here is harmless and future-safe.
local STARTERS = {
  BULBASAUR=true, CHARMANDER=true, SQUIRTLE=true,
  CHIKORITA=true, CYNDAQUIL=true, TOTODILE=true,
  TREECKO=true, TORCHIC=true, MUDKIP=true,
  TURTWIG=true, CHIMCHAR=true, PIPLUP=true,
  SNIVY=true, TEPIG=true, OSHAWOTT=true,
  CHESPIN=true, FENNEKIN=true, FROAKIE=true,
  ROWLET=true, LITTEN=true, POPPLIO=true,
  GROOKEY=true, SCORBUNNY=true, SOBBLE=true,
  SPRIGATITO=true, FUECOCO=true, QUAXLY=true,
}

local SHINY_DVS = {
  attack = 15,
  defense = 10,
  speed = 10,
  special = 10,
}
SHINY_DVS.hp = (SHINY_DVS.attack % 2) * 8
  + (SHINY_DVS.defense % 2) * 4
  + (SHINY_DVS.speed % 2) * 2
  + (SHINY_DVS.special % 2)

local function cloneDVs()
  return {
    attack=SHINY_DVS.attack,
    defense=SHINY_DVS.defense,
    speed=SHINY_DVS.speed,
    special=SHINY_DVS.special,
    hp=SHINY_DVS.hp,
  }
end

local function oakLab(ctx)
  local mapId = ctx and ctx.overworld and ctx.overworld.map
    and ctx.overworld.map.id
  if mapId == "OAKS_LAB" then return true end
  return ctx and ctx.source and ctx.source.mapId == "OAKS_LAB"
end

local function isStarterGiftSpecies(species)
  return species == PSYDREN or STARTERS[species] == true
end

local function snapshot(save)
  local seen = {}
  local function add(list)
    for _, mon in ipairs(list or {}) do
      if type(mon) == "table" then seen[mon] = true end
    end
  end
  add(save and save.party)
  for _, box in ipairs(save and save.boxes or {}) do add(box) end
  add(save and save.box)
  return seen
end

local function findNew(save, seen)
  local function scan(list)
    for _, mon in ipairs(list or {}) do
      if type(mon) == "table" and not seen[mon] then return mon end
    end
  end
  local mon = scan(save and save.party)
  if mon then return mon end
  for _, box in ipairs(save and save.boxes or {}) do
    mon = scan(box)
    if mon then return mon end
  end
  return scan(save and save.box)
end

local function recalc(mon, game, refill)
  local def = game and game.data and game.data.pokemon
    and game.data.pokemon[mon.species]
  if not (def and def.baseStats) then return end

  local oldMax = mon.stats and tonumber(mon.stats.hp) or 0
  local oldHp = tonumber(mon.hp) or oldMax
  mon.stats = Stats.calc(def, tonumber(mon.level) or 1, mon.dvs, mon.statExp)
  local newMax = mon.stats and tonumber(mon.stats.hp) or 0
  if newMax <= 0 then return end

  if refill or oldMax <= 0 then
    mon.hp = newMax
  else
    local ratio = math.max(0, math.min(1, oldHp / oldMax))
    mon.hp = math.max(oldHp > 0 and 1 or 0,
      math.min(newMax, math.floor(newMax * ratio + 0.5)))
  end
end

local function makeGuaranteedShiny(mon, game, refill)
  if not mon then return false end
  local changed = false

  if not (Stats.isShiny and Stats.isShiny(mon.dvs)) then
    mon.dvs = cloneDVs()
    changed = true
  end
  if mon.shiny ~= true then
    mon.shiny = true
    changed = true
  end

  mon.redEarthGuaranteedShiny = true
  mon.redEarthShinySource = mon.redEarthShinySource or "OAK_GIFT"

  if changed then recalc(mon, game, refill == true) end
  return true
end

local function preserveMarked(mon, game)
  if not (mon and mon.redEarthGuaranteedShiny) then return false end
  return makeGuaranteedShiny(mon, game, false)
end

local function scanSave(game)
  local save = game and game.save
  if not save then return end
  local function scan(list)
    for _, mon in ipairs(list or {}) do
      if mon and mon.redEarthGuaranteedShiny then
        preserveMarked(mon, game)
      elseif mon and isStarterGiftSpecies(mon.species)
          and Stats.isShiny and Stats.isShiny(mon.dvs) then
        -- Existing v1.2.1 saves already received shiny DVs from the split
        -- baseline. Do not alter stats; simply normalize the explicit flag.
        mon.shiny = true
      end
    end
  end
  scan(save.party)
  for _, box in ipairs(save.boxes or {}) do scan(box) end
  scan(save.box)
end

return function(mod)
  -- Oak's working dialogue/choice flow remains untouched. We only observe
  -- give_pokemon after every earlier starter transform has finished.
  mod.hooks:wrap("script.command", function(next, ctx, name, args, ...)
    if name ~= "give_pokemon" or not oakLab(ctx) then
      return next(ctx, name, args, ...)
    end

    local game = (ctx and ctx.game) or mod.game
    local save = (ctx and ctx.save) or (game and game.save)
    local seen = snapshot(save)
    local result = next(ctx, name, args, ...)

    local mon = findNew(save, seen)
    if mon and isStarterGiftSpecies(mon.species)
        and (tonumber(mon.level) or 0) == 5 then
      makeGuaranteedShiny(mon, game, true)
      mod.log:info("guaranteed shiny Oak gift: %s", tostring(mon.species))
    end
    return result
  end)

  -- Gen1 evolution mutates the same Pokemon object. Reassert explicit shiny
  -- metadata after the species swap so custom renderers and future bridges
  -- never lose the identity even if another mod only checks mon.shiny.
  mod.events:on("pokemon.evolved", function(ev)
    local mon = ev and ev.mon
    if mon and mon.redEarthGuaranteedShiny then
      makeGuaranteedShiny(mon, mod.game, false)
    end
  end)

  -- Belt-and-suspenders persistence for map reloads and old saves.
  mod.events:on("game.ready", function(ev)
    scanSave((ev and ev.game) or mod.game)
  end)
  mod.events:on("map.entered", function(ev)
    scanSave((ev and ev.game) or mod.game)
  end)

  -- No battle overlay, SpriteRenderer, PaletteFX, or Wilds renderer hooks are
  -- registered here by design. Crystal Animated Sprites sees the shiny DVs
  -- and supplies the battle sparkle/SFX; Wilds sees the same individual state
  -- and owns shiny follower selection/presentation.
  mod.exports.version = "1.0.0"
  mod.exports.makeGuaranteedShiny = function(mon, game)
    return makeGuaranteedShiny(mon, game or mod.game, false)
  end
  mod.exports.isGuaranteed = function(mon)
    return mon and mon.redEarthGuaranteedShiny == true
  end
  mod.exports.shinyDVs = cloneDVs
end
