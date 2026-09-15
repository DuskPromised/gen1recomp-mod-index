-- Red Earth Shiny FX Bridge v1.0.2
-- Presentation-only shiny compatibility layer.
-- Owns subtle Red Earth battle/follower sparkles and party-list marker while
-- leaving shiny state, shiny art, species, starters and evolution untouched.

local Stats = require("src.pokemon.Stats")
local Game = require("src.core.Game")
local PartyMenu = require("src.ui.PartyMenu")
local Sound = require("src.core.Sound")
local PaletteFX = require("src.render.PaletteFX")

local PLAYER_MON_IDS = {
  SPRITE_PLAYER_POKEMON = true,
  SPRITE_WILDS_PLAYER_MON = true,
}

local BATTLE_DUR = 0.72
local FOLLOW_DUR = 0.62
local FOLLOW_INTERVAL = 3.25
local SHINY_SFX = "Dex_Page_Added"

local function clock()
  if love and love.timer and love.timer.getTime then
    return love.timer.getTime()
  end
  return os.clock()
end

local function isShiny(mon)
  if not mon then return false end
  if mon.shiny == true or mon.isShiny == true then return true end
  return Stats.isShiny and Stats.isShiny(mon.dvs) or false
end

local function drawMiniStar(x, y)
  if not (love and love.graphics) then return end
  local g = love.graphics
  local prev = { g.getColor() }
  g.setColor(0.05, 0.05, 0.05, 1)
  g.rectangle("fill", x + 1, y, 1, 3)
  g.rectangle("fill", x, y + 1, 3, 1)
  g.setColor(1, 1, 0.72, 1)
  g.rectangle("fill", x + 1, y + 1, 1, 1)
  g.setColor(prev[1] or 1, prev[2] or 1, prev[3] or 1, prev[4] or 1)
  if PaletteFX and PaletteFX.markTrueColor then
    PaletteFX.markTrueColor(x, y, 3, 3)
  end
end

return function(mod)
  local lastCleared = 0
  local fx = {}
  local battleSfxPlayed = setmetatable({}, { __mode = "k" })

  local function liveOverworld(candidate)
    if candidate and candidate.player then return candidate end
    local game = mod.game or Game
    return game and (game.overworld or game.world) or candidate
  end

  local function trainerControlMode()
    local okFind, wilds = pcall(function()
      return type(mod.find) == "function"
        and mod:find("overworld_wild_spawns") or nil
    end)
    local opts = okFind and wilds and wilds.options
    if not opts then return false end
    local ok, value = pcall(function()
      if type(opts.get) == "function" then
        return opts:get("follow_control")
      end
    end)
    return ok and tostring(value or ""):lower() == "trainer"
  end

  local function clearStalePlayerPokemonFlag(player)
    if not player or not player._pokepcAsPokemon then return false end
    if trainerControlMode() then
      player._pokepcAsPokemon = nil
      player._pokepcControlSpecies = nil
      player._pokepcShiny = nil
      lastCleared = lastCleared + 1
      return true
    end
    local id = player.sprite and player.sprite.def and player.sprite.def.id
    if id and not PLAYER_MON_IDS[id] then
      player._pokepcAsPokemon = nil
      player._pokepcControlSpecies = nil
      player._pokepcShiny = nil
      lastCleared = lastCleared + 1
      return true
    end
    return false
  end

  local function syncFollowerEntity(npc)
    if not (npc and npc.pokepcMon
        and (npc.pokepcTrailer or npc.wildsFollower)) then
      return false
    end
    local shiny = isShiny(npc.pokepcMon)
    npc.pokepcShiny = shiny and true or false
    if npc.sprite and npc.sprite.def then
      npc.sprite.def.pokepcShiny = shiny and true or false
    end
    if npc.spriteDef then
      npc.spriteDef.pokepcShiny = shiny and true or false
    end
    return true
  end

  local function sanitizeFollowerFxState(candidate)
    local ow = liveOverworld(candidate)
    if not ow then return false end
    clearStalePlayerPokemonFlag(ow.player)
    local seen = {}
    for _, npc in ipairs(ow.pokepcTrailers or {}) do
      if npc and not seen[npc] then
        seen[npc] = true
        syncFollowerEntity(npc)
      end
    end
    for _, npc in ipairs(ow.entities or {}) do
      if npc and not seen[npc] then
        seen[npc] = true
        syncFollowerEntity(npc)
      end
    end
    return true
  end

  -- Exact VISUAL position, not the logical trail cell. Wilds' pose() already
  -- contains current interpolation/hop/facing, which is why this fixes the
  -- old vertical drift while the follower is moving up/down.
  local function followerAnchor(npc)
    if not npc then return nil end
    local px, py
    if type(npc.pose) == "function" then
      local ok, _, x, y = pcall(npc.pose, npc)
      if ok and tonumber(x) and tonumber(y) then
        px, py = tonumber(x), tonumber(y)
      end
    end
    px = px or tonumber(npc.px)
    py = py or tonumber(npc.py)
    if not (px and py) then return nil end
    local def = (npc.sprite and npc.sprite.def) or npc.spriteDef or {}
    local fw = tonumber(def.frameWidth) or 16
    local fh = tonumber(def.frameHeight) or 16
    local ax = tonumber(def.anchorX) or math.floor(fw / 2)
    local ay = tonumber(def.anchorY) or (fh - 1)
    return px + ax, py + math.max(3, ay - math.floor(fh * 0.48))
  end

  local function begin(key, duration, loopInterval)
    local t = clock()
    local e = fx[key]
    if not e then
      fx[key] = { t0=t, duration=duration, loop=loopInterval }
      return 0
    end
    local elapsed = t - e.t0
    if loopInterval and elapsed >= loopInterval then
      e.t0 = t
      e.duration = duration
      return 0
    end
    return elapsed
  end

  local function progress(key, duration, loopInterval)
    local elapsed = begin(key, duration, loopInterval)
    if elapsed < 0 or elapsed >= duration then return nil end
    return elapsed / duration
  end

  local function drawSubtleBurst(cx, cy, p, scale, seed)
    if not (p and love and love.graphics) then return false end
    local g = love.graphics
    scale = scale or 1
    seed = seed or 0
    local prev = { g.getColor() }
    local burst = math.min(1, p / 0.20)
    local fade = p < 0.55 and 1 or math.max(0, 1 - (p - 0.55) / 0.45)

    -- Six tiny twinkles. This deliberately replaces SHINY_POKEMON's large
    -- opaque yellow rectangles with 1px glints / brief 3px crosses.
    for i=1,6 do
      local ang = (i / 6) * math.pi * 2 + seed * 0.13
      local rad = (3.5 + p * 9 + (i % 2) * 1.5) * scale
      local x = math.floor(cx + math.cos(ang) * rad * burst + 0.5)
      local y = math.floor(cy + math.sin(ang) * rad * 0.72 * burst + 0.5)
      if (i + math.floor(p * 10)) % 2 == 0 then
        g.setColor(1, 1, 1, fade)
      else
        g.setColor(1, 0.95, 0.50, fade)
      end
      g.rectangle("fill", x, y, 1, 1)
      if p < 0.42 and i % 2 == 0 then
        g.rectangle("fill", x-1, y, 3, 1)
        g.rectangle("fill", x, y-1, 1, 3)
      end
    end
    if p < 0.20 then
      g.setColor(1, 1, 0.78, fade)
      g.rectangle("fill", math.floor(cx), math.floor(cy), 1, 1)
    end
    g.setColor(prev[1] or 1, prev[2] or 1, prev[3] or 1, prev[4] or 1)
    return true
  end

  local function followerTargets(ow)
    local out, seen = {}, {}
    if not ow then return out end
    local function add(npc)
      if not npc or seen[npc] or not npc.pokepcShiny then return end
      if not (npc.pokepcTrailer or npc.wildsFollower) then return end
      seen[npc] = true
      local x,y = followerAnchor(npc)
      if not x then return end
      out[#out+1] = {
        wx=x, wy=y,
        key="red_earth_follow:"..tostring(npc.pokepcTrailerId or npc.id or npc),
        seed=(npc.wildsFollowerSlot or 1) + 7,
      }
    end
    for _,npc in ipairs(ow.pokepcTrailers or {}) do add(npc) end
    for _,npc in ipairs(ow.entities or {}) do add(npc) end
    return out
  end

  local function drawProjectedFollowers(project, scale, cam, ow)
    if not (project and cam and ow and love and love.graphics) then return false end
    local any=false
    for _,t in ipairs(followerTargets(ow)) do
      local p=progress(t.key, FOLLOW_DUR, FOLLOW_INTERVAL)
      if p then
        local sx, sy = project(t.wx, t.wy)
        if sx then
          local fxw, fyw = t.wx - cam.x, t.wy - cam.y
          love.graphics.push()
          love.graphics.scale(scale or 1, scale or 1)
          love.graphics.translate(sx/(scale or 1)-fxw, sy/(scale or 1)-fyw)
          drawSubtleBurst(fxw, fyw, p, 1.0, t.seed)
          love.graphics.pop()
          any=true
        end
      end
    end
    return any
  end

  local function installWorldFx()
    local ok, Pipelines = pcall(require, "src.render.Pipelines")
    if not ok or not Pipelines or type(Pipelines.drawWorld) ~= "function" then
      return false
    end
    if Pipelines._redEarthShinyFxV102 == Pipelines.drawWorld then return true end
    local inner = Pipelines.drawWorld
    local function wrapped(id, ctx)
      pcall(sanitizeFollowerFxState, ctx and ctx.state)
      if ctx and ctx.drawFx and ctx.state then
        local origDrawFx = ctx.drawFx
        local st = ctx.state
        local cam = ctx.cam or st.camera
        ctx.drawFx = function(project, scale)
          origDrawFx(project, scale)
          pcall(drawProjectedFollowers, project, scale, cam, st)
        end
      end
      return inner(id, ctx)
    end
    Pipelines.drawWorld = wrapped
    Pipelines._redEarthShinyFxV102 = wrapped
    return true
  end

  -- BetterParty calls PartyMenu.drawIcon even though it owns the widescreen
  -- presentation. Adding the tiny mark here makes the party LIST agree with
  -- the summary/battle shiny marker.
  local function installPartyMarker()
    if PartyMenu._redEarthShinyFxMarkerV102 == PartyMenu.drawIcon then return true end
    local inner = PartyMenu.drawIcon
    local function wrapped(game, mon, x, y, selected, counter, forceAlt)
      local a,b,c = inner(game, mon, x, y, selected, counter, forceAlt)
      if isShiny(mon) then drawMiniStar(math.floor(x+13), math.floor(y+1)) end
      return a,b,c
    end
    PartyMenu.drawIcon = wrapped
    PartyMenu._redEarthShinyFxMarkerV102 = wrapped
    return true
  end

  local function battleReady(battle, isEnemy)
    if not battle then return false end
    if (battle.introSlide or 0) > 0 then return false end
    if isEnemy then
      if battle.showEnemyTrainer or battle.enemySendingOut then return false end
      if battle.growInScale and battle:growInScale(battle.enemy) then return false end
    else
      if battle.showPlayerBack or battle.sendingOut then return false end
      if battle.growInScale and battle:growInScale(battle.player) then return false end
    end
    return true
  end

  local function playBattleSfxOnce(battle, side)
    if not battle then return end
    local rec = battleSfxPlayed[battle]
    if not rec then rec={}; battleSfxPlayed[battle]=rec end
    if rec[side] then return end
    rec[side]=true
    local data = (battle.game and battle.game.data) or battle.data
      or (mod.game and mod.game.data)
    if data then
      local ok = pcall(Sound.play, data, SHINY_SFX)
      if not ok then pcall(Sound.play, data, "Get_Item1") end
    end
  end

  mod.hooks:wrap("battle.overlay", function(next, battle)
    next(battle)
    if not battle then return end
    local function side(battler, enemy)
      if not (battler and battler.mon and isShiny(battler.mon)) then return end
      if not battleReady(battle, enemy) then return end
      local suffix = enemy and "enemy" or "player"
      local key = "red_earth_battle:"..tostring(battle)..":"..suffix..":"
        ..tostring(battler.mon.species)
      local p=progress(key, BATTLE_DUR, nil)
      if not p then return end
      playBattleSfxOnce(battle, suffix)
      local ax,ay = enemy and 120 or 40, enemy and 32 or 88
      if battle.wide or (battle.wideLayout and battle:wideLayout()) then
        ax,ay = enemy and 200 or 60, enemy and 40 or 100
      end
      drawSubtleBurst(ax,ay,p,1.0,
        (battler.mon.level or 1)+(enemy and 3 or 7))
    end
    side(battle.enemy,true)
    if not (battle.safari or battle.demo) then side(battle.player,false) end
  end, 500)

  mod.events:on("battle.started", function(ev)
    if ev and ev.battle then battleSfxPlayed[ev.battle]=nil end
  end)

  mod.events:on("game.ready", function(ev)
    pcall(sanitizeFollowerFxState, ev and ev.game and ev.game.overworld)
    pcall(installWorldFx)
    pcall(installPartyMarker)
  end)

  mod.events:on("map.entered", function(ev)
    pcall(sanitizeFollowerFxState, ev and ev.game and ev.game.overworld)
    pcall(installWorldFx)
    pcall(installPartyMarker)
  end)

  mod.events:on("world.stepped", function(ev)
    pcall(sanitizeFollowerFxState, ev and (ev.overworld or ev.world))
  end)

  pcall(sanitizeFollowerFxState, mod.game and mod.game.overworld)
  pcall(installWorldFx)
  pcall(installPartyMarker)

  mod.exports.version = "1.0.2"
  mod.exports.sanitizeFollowerFxState = sanitizeFollowerFxState
  mod.exports.followerAnchor = followerAnchor
  mod.exports.clearedStalePlayerFlags = function() return lastCleared end
end
