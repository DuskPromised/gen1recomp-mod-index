-- Red Earth Shiny FX Bridge v1.0.5
-- Presentation-only shiny compatibility layer.
-- Owns subtle Red Earth battle/follower sparkles and party-list marker while
-- leaving shiny state, shiny art, species, starters and evolution untouched.

local Stats = require("src.pokemon.Stats")
local Game = require("src.core.Game")
local Sound = require("src.core.Sound")

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

  -- Match Wilds' own Dramatic Shape emergency-overlay registration point.
  -- Wilds projects (entity.px+8, entity.py+16), then translates the normal
  -- 2D entity draw into that projected location. Reusing the same anchor
  -- prevents direction-dependent drift because we no longer derive the FX
  -- point from pose(), facing, or a guessed billboard centre.
  local function followerAnchor(npc)
    if not npc then return nil end
    local px, py = tonumber(npc.px), tonumber(npc.py)
    if not (px and py) then return nil end
    return px + 8, py + 16, px, py
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
      local wx,wy,px,py = followerAnchor(npc)
      if not wx then return end
      out[#out+1] = {
        wx=wx, wy=wy, px=px, py=py,
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
    local drawScale = tonumber(scale) or 1
    if drawScale <= 0 then drawScale = 1 end
    local camX, camY = tonumber(cam.x) or 0, tonumber(cam.y) or 0

    for _,t in ipairs(followerTargets(ow)) do
      local p=progress(t.key, FOLLOW_DUR, FOLLOW_INTERVAL)
      if p then
        local sx, sy = project(t.wx, t.wy)
        if sx then
          -- This is the exact transform Wilds uses when it spatially overlays
          -- an entity in Dramatic Shape. Draw the sparkle at the stock 2D
          -- follower shiny centre (px+8, py) INSIDE that same transform.
          local fx, fy = t.wx - camX, t.wy - camY
          local localCx = t.px + 8 - camX
          local localCy = t.py - camY

          love.graphics.push()
          love.graphics.scale(drawScale, drawScale)
          love.graphics.translate(
            sx / drawScale - fx,
            sy / drawScale - fy
          )
          drawSubtleBurst(localCx, localCy, p, 1.0, t.seed)
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
    if Pipelines._redEarthShinyFxV105 == Pipelines.drawWorld then return true end
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
    Pipelines._redEarthShinyFxV105 = wrapped
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

  mod.exports.version = "1.0.5"
  mod.exports.sanitizeFollowerFxState = sanitizeFollowerFxState
  mod.exports.followerAnchor = followerAnchor
  mod.exports.clearedStalePlayerFlags = function() return lastCleared end
end
