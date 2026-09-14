-- Red Earth Kaizo Bridge v1.0.0
-- Compatibility layer for Pokémon Red Earth: The Philosopher's Stones.
-- Keeps Allgen Kaizo authoritative for species, encounters, trainer teams and AI,
-- then adds: upward-only dynamic difficulty, a regional second starter, and
-- real shiny DVs for both Oak-lab player starters.

local Stats = require("src.pokemon.Stats")

local REGIONS = {
  { label="KANTO",  grass="BULBASAUR", fire="CHARMANDER", water="SQUIRTLE" },
  { label="JOHTO",  grass="CHIKORITA", fire="CYNDAQUIL",  water="TOTODILE" },
  { label="HOENN",  grass="TREECKO",   fire="TORCHIC",    water="MUDKIP" },
  { label="SINNOH", grass="TURTWIG",   fire="CHIMCHAR",   water="PIPLUP" },
  { label="UNOVA",  grass="SNIVY",     fire="TEPIG",      water="OSHAWOTT" },
  { label="KALOS",  grass="CHESPIN",   fire="FENNEKIN",   water="FROAKIE" },
  { label="ALOLA",  grass="ROWLET",    fire="LITTEN",     water="POPPLIO" },
}

local BALLS = {
  TEXT_OAKSLAB_CHARMANDER_POKE_BALL = {
    element="fire", object="OAKSLAB_CHARMANDER_POKE_BALL",
  },
  TEXT_OAKSLAB_SQUIRTLE_POKE_BALL = {
    element="water", object="OAKSLAB_SQUIRTLE_POKE_BALL",
  },
  TEXT_OAKSLAB_BULBASAUR_POKE_BALL = {
    element="grass", object="OAKSLAB_BULBASAUR_POKE_BALL",
  },
}

local CLAIMED_FLAG = "MOD_RED_EARTH_KAIZO_SECOND_STARTER"
local SHINY_ATK = { 2, 3, 6, 7, 10, 11, 14, 15 }

local function hash(text)
  local h = 0
  text = tostring(text or "")
  for i=1,#text do h = (h * 33 + text:byte(i)) % 2147483647 end
  return h
end

return function(mod)
  mod.options:define({
    {
      key="dynamic_wilds", type="toggle", label="DYNAMIC WILDS", default=true,
      help="Wild levels rise with your strongest healthy Pokemon (-2 to +1), never down.",
    },
    {
      key="dynamic_trainers", type="toggle", label="DYNAMIC TRAINERS", default=true,
      help="Kaizo trainer teams rise with your strongest healthy Pokemon (+0 to +2), never down.",
    },
    {
      key="second_starter", type="toggle", label="SECOND STARTER", default=true,
      help="After the rival picks, Oak's remaining ball gives the matching starter from your chosen region.",
    },
    {
      key="shiny_starters", type="toggle", label="SHINY STARTERS", default=true,
      help="Both player starters from Oak's Lab receive real Gen-2-compatible shiny DVs.",
    },
  })

  local function opt(key, fallback)
    local ok, value = pcall(mod.options.get, mod.options, key)
    if ok and value ~= nil then return value end
    return fallback
  end

  local function gameNow()
    return mod.game
  end

  local function region(game)
    local save = game and game.save
    local data = save and save.modData and save.modData.gen1_kaizo or {}
    local n = tonumber(data and data.starter_gen) or 1
    n = math.max(1, math.min(#REGIONS, math.floor(n)))
    return REGIONS[n], n
  end

  local function isRegionalStarter(game, species)
    local r = region(game)
    return r and (species == r.grass or species == r.fire or species == r.water)
  end

  local function strongestHealthy(game)
    local best, fallback = 0, 0
    for _, mon in ipairs(game and game.save and game.save.party or {}) do
      local lv = tonumber(mon.level) or 0
      if lv > fallback then fallback = lv end
      if (tonumber(mon.hp) or 0) > 0 and lv > best then best = lv end
    end
    if best <= 0 then best = fallback end
    return math.max(0, math.min(100, best))
  end

  local function wildTarget(game, species, mapId)
    local top = strongestHealthy(game)
    if top <= 0 then return nil end
    local offsets = { -2, -1, 0, 1 }
    local key = tostring(mapId or "") .. "|" .. tostring(species or "") .. "|" .. tostring(top)
    local off = offsets[(hash(key) % #offsets) + 1]
    return math.max(1, math.min(100, top + off))
  end

  -- Ordinary random encounters: let Kaizo and every earlier encounter mod
  -- choose species/level first, then only raise the result when needed.
  mod.hooks:wrap("encounter.species", function(next, enc, ctx)
    local rolled = next(enc, ctx)
    if not opt("dynamic_wilds", true) or type(rolled) ~= "table" then return rolled end
    local game = gameNow()
    local target = wildTarget(game, rolled.species, ctx and ctx.mapId)
    if not target then return rolled end
    local out = {}
    for k,v in pairs(rolled) do out[k]=v end
    out.level = math.max(tonumber(rolled.level) or 1, target)
    return out
  end)

  local function copyArgs(args)
    local out = {}
    for i,v in ipairs(args or {}) do out[i]=v end
    return out
  end

  local function addSeen(seen, list)
    if type(list) ~= "table" then return end
    for _, mon in ipairs(list) do if type(mon)=="table" then seen[mon]=true end end
  end

  local function snapshotMons(save)
    local seen = {}
    if type(save) ~= "table" then return seen end
    addSeen(seen, save.party)
    if type(save.boxes)=="table" then for _,box in ipairs(save.boxes) do addSeen(seen,box) end end
    addSeen(seen, save.box)
    return seen
  end

  local function firstNew(list, seen)
    if type(list)~="table" then return nil end
    for _,mon in ipairs(list) do
      if type(mon)=="table" and not seen[mon] then return mon end
    end
  end

  local function findNewMon(save, seen)
    local mon = firstNew(save and save.party, seen)
    if mon then return mon end
    for _,box in ipairs((save and save.boxes) or {}) do
      mon = firstNew(box, seen)
      if mon then return mon end
    end
    return firstNew(save and save.box, seen)
  end

  local function makeShiny(mon, game)
    if not (mon and game) then return end
    if Stats.isShiny and Stats.isShiny(mon.dvs) then
      mon.shiny = true
      return
    end
    local atk = SHINY_ATK[(hash(mon.species) % #SHINY_ATK) + 1]
    local dvs = { attack=atk, defense=10, speed=10, special=10 }
    dvs.hp = (dvs.attack % 2) * 8 + (dvs.defense % 2) * 4
           + (dvs.speed % 2) * 2 + (dvs.special % 2)
    mon.dvs = dvs
    mon.shiny = true
    local def = game.data and game.data.pokemon and game.data.pokemon[mon.species]
    if def and def.baseStats then
      mon.stats = Stats.calc(def, mon.level or 1, dvs, mon.statExp)
      if mon.stats and mon.stats.hp then mon.hp = mon.stats.hp end
    end
  end

  -- Script-driven wilds include Wilds of Kanto contact battles. Rewriting a
  -- copied args table avoids permanently mutating a map script row.
  -- The same hook also detects the actual starter species AFTER Kaizo's own
  -- give_pokemon transform has run, so all seven region trios are supported.
  mod.hooks:wrap("script.command", function(next, ctx, name, args, ...)
    if name == "start_battle" and opt("dynamic_wilds", true)
       and type(args)=="table" and args[1]=="wild" then
      local game = (ctx and ctx.game) or gameNow()
      local mapId = ctx and ctx.overworld and ctx.overworld.map and ctx.overworld.map.id
      local target = wildTarget(game, args[2], mapId)
      if target then
        local rewritten = copyArgs(args)
        rewritten[3] = math.max(tonumber(args[3]) or 1, target)
        return next(ctx, name, rewritten, ...)
      end
    end

    local inOakLab = ctx and ctx.overworld and ctx.overworld.map
      and ctx.overworld.map.id == "OAKS_LAB"
    if name ~= "give_pokemon" or not inOakLab or not opt("shiny_starters", true) then
      return next(ctx, name, args, ...)
    end

    local game = (ctx and ctx.game) or gameNow()
    local save = (ctx and ctx.save) or (game and game.save)
    local seen = snapshotMons(save)
    local result = next(ctx, name, args, ...)
    local mon = findNewMon(save, seen)
    if mon and isRegionalStarter(game, mon.species) and (tonumber(mon.level) or 0) == 5 then
      makeShiny(mon, game)
    end
    return result
  end)

  -- Kaizo remains authoritative for team composition, movesets, Megas and AI.
  -- This wrapper sees the final roster and only raises its levels. Authored
  -- Kaizo levels are never lowered, preserving late-game floors.
  mod.hooks:wrap("trainer.party", function(next, trainerClass, partyIndex, party)
    local out = next(trainerClass, partyIndex, party)
    if not opt("dynamic_trainers", true) or type(out) ~= "table" or #out == 0 then
      return out
    end
    local game = gameNow()
    local top = strongestHealthy(game)
    if top <= 0 then return out end

    -- Preserve Kaizo's intentionally vanilla first Oak-lab rival battle.
    local flags = game and game.save and game.save.flags or {}
    local mapId = game and game.overworld and game.overworld.map and game.overworld.map.id
    if tostring(trainerClass):find("RIVAL1", 1, true)
       and mapId == "OAKS_LAB" and not flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB then
      return out
    end

    local scaled = {}
    local n = #out
    for i, member in ipairs(out) do
      local copy = {}
      for k,v in pairs(member) do copy[k]=v end
      local plus
      if n == 1 then plus = 2
      else plus = math.floor((((i-1) * 2) / (n-1)) + 0.5) end
      local target = math.min(100, top + plus)
      copy.level = math.max(tonumber(member.level) or 1, target)
      scaled[i] = copy
    end
    return scaled
  end)

  -- Replace only the surviving Oak-lab ball after the first choice. The
  -- chosen Kaizo region is read from save.modData.gen1_kaizo.starter_gen.
  mod.hooks:wrap("world.talk", function(next, ow, target)
    if not opt("second_starter", true) then return next(ow, target) end
    local game = gameNow()
    local save = game and game.save
    local flags = save and save.flags
    local def = target and target.def
    local ball = def and BALLS[def.text]

    if not (ow and ow.map and ow.map.id=="OAKS_LAB"
        and flags and flags.EVENT_GOT_STARTER and ball) then
      return next(ow, target)
    end
    if flags[CLAIMED_FLAG] then return next(ow, target) end

    local r = region(game)
    local species = r and r[ball.element]
    if not species or not (game.data and game.data.pokemon and game.data.pokemon[species]) then
      return next(ow, target)
    end

    target.frozen = true
    local function done() if target then target.frozen=false end end
    ow.runner:run({
      { "show_text", "The last POKéMON\nis {RAM}!", { RAM=species } },
      { "ask", "Take it with you?" },
      { "jump_if_false", "end" },
      { "text_sound", "Get_Key_Item" },
      { "show_text", "_OaksLabReceivedMonText", { RAM=species } },
      { "give_pokemon", species, 5 },
      { "jump_if_false", "no_room" },
      { "hide_object", "OAKS_LAB", ball.object },
      { "set_flag", CLAIMED_FLAG },
      { "show_text", "Take good care of\nboth POKéMON!" },
      { "jump", "end" },
      { "label", "no_room" },
      { "show_text", "There's no room for\nanother POKéMON!" },
      { "label", "end" },
    }, {
      npc=target, onDone=done,
      source={ modId=mod.id, strict=true, mapId="OAKS_LAB", hook="world.talk" },
    })
    return
  end)

  mod.exports.version = "1.0.0"
  mod.exports.regions = REGIONS
end
