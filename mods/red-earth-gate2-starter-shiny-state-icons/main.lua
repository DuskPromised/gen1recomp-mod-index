-- Gate 2.10 starter shiny contract.
-- Built from the accepted 0.2.6 module and narrowed around Kaizo's native
-- script.command starter seam.  Responsibilities:
--   1) make only the intended Oak-gift Fennekin / approved Grass starters genuine shiny;
--   2) establish shiny identity BEFORE the standard nickname UI;
--   3) show the matching shiny art in Oak's force-owned starter dex preview;
--   4) preserve shiny identity through evolution/save flow;
--   5) route proven shiny battle art + true-color party/menu icons for those lines.
-- It does NOT own followers, scale/grounding, starter selection, Irregular art,
-- Nature, passives, or the player send-out sparkle/audio (separate module).

local Stats = require("src.pokemon.Stats")
local PartyMenu = require("src.ui.PartyMenu")
local Assets = require("src.render.Assets")
local PaletteFX = require("src.render.PaletteFX")
local Commands = require("src.script.Commands")
local Screens = require("src.ui.Screens")
local Strings = require("src.core.Strings")
local unpack = table.unpack or unpack
local function pack(...) return { n=select("#", ...), ... } end

local BASE_STARTERS = {
  FENNEKIN=true,
  BULBASAUR=true, CHIKORITA=true, TREECKO=true, TURTWIG=true,
  SNIVY=true, CHESPIN=true, ROWLET=true,
}

local STARTER_DEX = {
  BULBASAUR=1, IVYSAUR=2, VENUSAUR=3,
  CHIKORITA=152, BAYLEEF=153, MEGANIUM=154,
  TREECKO=252, GROVYLE=253, SCEPTILE=254,
  TURTWIG=387, GROTLE=388, TORTERRA=389,
  SNIVY=495, SERVINE=496, SERPERIOR=497,
  CHESPIN=650, QUILLADIN=651, CHESNAUGHT=652,
  FENNEKIN=653, BRAIXEN=654, DELPHOX=655,
  ROWLET=722, DARTRIX=723, DECIDUEYE=724,
}

local SHINY_DVS = { attack=15, defense=10, speed=10, special=10, hp=8 }

local function cloneDVs()
  return {
    attack=SHINY_DVS.attack,
    defense=SHINY_DVS.defense,
    speed=SHINY_DVS.speed,
    special=SHINY_DVS.special,
    hp=SHINY_DVS.hp,
  }
end

local function isShiny(mon)
  if not mon then return false end
  if mon.shiny == true or mon.isShiny == true then return true end
  return Stats.isShiny and Stats.isShiny(mon.dvs) or false
end

local function speciesOf(ctx)
  if not ctx then return nil end
  return ctx.species or (ctx.mon and ctx.mon.species)
end

local function padDex(n)
  return string.format("%03d", tonumber(n) or 0)
end

local function oakLab(ctx)
  local mapId = ctx and ctx.overworld and ctx.overworld.map
    and ctx.overworld.map.id
  if mapId == "OAKS_LAB" then return true end
  return ctx and ctx.source and ctx.source.mapId == "OAKS_LAB"
end

local function starterPending(ctx)
  local flags = ctx and ctx.save and ctx.save.flags
  return type(flags) == "table"
    and flags.EVENT_FOLLOWED_OAK_INTO_LAB == true
    and flags.EVENT_GOT_STARTER ~= true
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
  if not def then return end
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
  mon.redEarthGate25StarterShiny = true
  mon.redEarthShinySource = mon.redEarthShinySource or "GATE_2_5_OAK_GIFT"
  if changed then recalc(mon, game, refill == true) end
  return true
end

local function preserveMarked(mon, game)
  if not (mon and mon.redEarthGate25StarterShiny) then return false end
  return makeGuaranteedShiny(mon, game, false)
end

local function scanSave(game)
  local save = game and game.save
  if not save then return end
  local function scan(list)
    for _, mon in ipairs(list or {}) do preserveMarked(mon, game) end
  end
  scan(save.party)
  for _, box in ipairs(save.boxes or {}) do scan(box) end
  scan(save.box)
end

local function askNicknameAfterState(ctx, mon)
  local runner = ctx and ctx.runner
  if not runner then return end
  local success = ctx.lastCheck
  local name = ctx.game.stringBuffer
    or (ctx.game.data.pokemon[mon.species] and ctx.game.data.pokemon[mon.species].name)
    or mon.species
  local textId, subs
  if ctx.game.data.text and ctx.game.data.text._DoYouWantToNicknameText then
    textId, subs = "_DoYouWantToNicknameText", { RAM=name }
  else
    textId = Strings("Do you want to\ngive a nickname\nto %s?", name)
  end
  Commands.show_text(ctx, textId, subs, { choice=function(yes)
    if not yes then
      ctx.lastCheck = success
      runner:resume()
      return
    end
    Screens.push(ctx.game, "NamingScreen", {
      title=Strings("NICKNAME?"), maxLen=10, mon=mon,
      onDone=function(nick)
        if nick and #nick > 0 then mon.nickname = nick end
        ctx.lastCheck = success
        runner:resume()
      end,
    })
  end })
end

return function(mod)
  -- Kaizo's starter replacement wrapper has default priority 0.  This link
  -- deliberately runs AFTER it (-10), so args already contain the selected
  -- regional species.  That lets us remain ignorant of Kaizo's region menu
  -- internals and keeps every non-target command byte-for-byte downstream.
  local previewSpecies
  mod.hooks:wrap("script.command", function(next, ctx, name, args, ...)
    if type(args) ~= "table" or not oakLab(ctx) or not starterPending(ctx) then
      return next(ctx, name, args, ...)
    end

    -- Oak's force-owned dex card is constructed synchronously inside the
    -- downstream push_screen command.  A transient species marker lets the
    -- normal pokemon.sprite seam choose shiny art without replacing or
    -- monkey-patching DexEntryMenu.new (the 0.2.8 regression source).
    if name == "push_screen" and args[1] == "DexEntryMenu"
        and type(args[2]) == "table" and BASE_STARTERS[args[2].species] then
      previewSpecies = args[2].species
      local result = pack(next(ctx, name, args, ...))
      previewSpecies = nil
      return unpack(result, 1, result.n)
    end

    -- The native give_pokemon asks for a nickname before it returns.  For the
    -- one intended level-5 Oak starter only, suppress that one built-in AskName,
    -- let the native command create/add the mon, make it genuinely shiny, then
    -- present the engine-equivalent nickname UI with the already-shiny mon.
    -- This preserves Kaizo's ball/region routing and all non-target gifts.
    if name == "give_pokemon" and BASE_STARTERS[args[1]]
        and (tonumber(args[2]) or 0) == 5 then
      local game = (ctx and ctx.game) or mod.game
      local save = (ctx and ctx.save) or (game and game.save)
      local seen = snapshot(save)
      local forwarded = {}
      for i, v in ipairs(args) do forwarded[i] = v end
      forwarded[3] = true
      local result = pack(next(ctx, name, forwarded, ...))
      local mon = findNew(save, seen)
      if mon and mon.species == args[1] then
        makeGuaranteedShiny(mon, game, true)
        mod.log:info("Gate 2.10 genuine shiny Oak gift before nickname: %s",
          tostring(mon.species))
        if not mon.nickname then askNicknameAfterState(ctx, mon) end
      end
      return unpack(result, 1, result.n)
    end

    return next(ctx, name, args, ...)
  end, -10)

  mod.events:on("pokemon.evolved", function(ev)
    local mon = ev and ev.mon
    if mon and mon.redEarthGate25StarterShiny then
      makeGuaranteedShiny(mon, (ev and ev.game) or mod.game, false)
    end
  end)
  mod.events:on("save.loaded", function(ev) scanSave((ev and ev.game) or mod.game) end)
  mod.events:on("game.ready", function(ev) scanSave((ev and ev.game) or mod.game) end)

  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    ctx = ctx or {}
    local species = speciesOf(ctx)
    local dex = species and STARTER_DEX[species]
    local starterPreview = ctx.kind == "dex" and ctx.mon == nil
      and previewSpecies == species
    if not dex or (not starterPreview and not isShiny(ctx.mon)) then
      return next(path, ctx)
    end
    ctx.trueColor = true
    local root = mod.path .. "/assets/battlers/" .. padDex(dex)
    local chosen = (ctx.side == "back")
      and (root .. "_back_shiny.png")
      or  (root .. "_front_shiny.png")
    return next(chosen, ctx)
  end, 150)

  mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
    local resolved = next(path, ctx)
    local mon = ctx and ctx.mon
    local species = speciesOf(ctx)
    local dex = species and STARTER_DEX[species]
    if not (dex and isShiny(mon)) then return resolved end
    ctx.trueColor = true
    return mod.path .. "/assets/icons/" .. padDex(dex) .. "_shiny.png"
  end, 170)

  local cache = {}
  local function imageFor(path)
    local cached = cache[path]
    if cached ~= nil then return cached or nil end
    local ok, img = pcall(love.graphics.newImage, Assets.resolve(path))
    cache[path] = ok and img or false
    return ok and img or nil
  end

  if PartyMenu._redEarthGate25Rebuild ~= PartyMenu.drawIcon then
    local inner = PartyMenu.drawIcon
    local function wrapped(game, mon, x, y, selected, counter, forceAlt, obp)
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
      end
      return inner(game, mon, x, y, selected, counter, forceAlt, obp)
    end
    PartyMenu.drawIcon = wrapped
    PartyMenu._redEarthGate25Rebuild = wrapped
  end

  mod.exports.version = "0.2.10"
  mod.exports.makeGuaranteedShiny = function(mon, game)
    return makeGuaranteedShiny(mon, game or mod.game, false)
  end
  mod.exports.isGuaranteed = function(mon)
    return mon and mon.redEarthGate25StarterShiny == true
  end
  mod.exports.shinyDVs = cloneDVs
  mod.exports.starterDex = STARTER_DEX
end
