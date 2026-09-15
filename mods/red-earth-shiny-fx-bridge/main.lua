-- Red Earth Shiny FX Bridge v1.0.1
-- Keeps the upstream SHINY_POKEMON renderer intact, but corrects the Wilds
-- follower target state before its voxel sparkle pass runs.

local Stats = require("src.pokemon.Stats")
local Game = require("src.core.Game")

local PLAYER_MON_IDS = {
  SPRITE_PLAYER_POKEMON = true,
  SPRITE_WILDS_PLAYER_MON = true,
}

local function isShiny(mon)
  if not mon then return false end
  if mon.shiny == true or mon.isShiny == true then return true end
  return Stats.isShiny and Stats.isShiny(mon.dvs) or false
end

return function(mod)
  local lastCleared = 0

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

    -- In Red Earth's locked Wilds configuration Control=Trainer, the visible
    -- player is always the trainer and the Pokemon is a separate trailer.
    -- Therefore _pokepcAsPokemon is unambiguously stale and must never be a
    -- sparkle target, even when a renderer rebuild leaves sprite.def.id nil.
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

    -- Reassert shiny state on the actual Wilds follower entity in BOTH lists.
    -- Wilds may keep the same trailer in pokepcTrailers and entities, while
    -- SHINY_POKEMON's voxel target collector reads ow.entities.
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

  local function installDrawGuard()
    local ok, Pipelines = pcall(require, "src.render.Pipelines")
    if not ok or not Pipelines or type(Pipelines.drawWorld) ~= "function" then
      return false
    end
    if Pipelines._redEarthShinyFxBridge == Pipelines.drawWorld then
      return true
    end

    local inner = Pipelines.drawWorld
    local function wrapped(id, ctx)
      pcall(sanitizeFollowerFxState, ctx and ctx.state)
      return inner(id, ctx)
    end
    Pipelines.drawWorld = wrapped
    Pipelines._redEarthShinyFxBridge = wrapped
    return true
  end

  mod.events:on("game.ready", function(ev)
    pcall(sanitizeFollowerFxState, ev and ev.game and ev.game.overworld)
    pcall(installDrawGuard)
  end)

  mod.events:on("map.entered", function(ev)
    pcall(sanitizeFollowerFxState, ev and ev.game and ev.game.overworld)
    -- Re-seat after map rebuilds in case another presentation mod rewrapped
    -- Pipelines.drawWorld during its own map-enter lifecycle.
    pcall(installDrawGuard)
  end)

  mod.events:on("world.stepped", function(ev)
    pcall(sanitizeFollowerFxState, ev and (ev.overworld or ev.world))
  end)

  pcall(sanitizeFollowerFxState, mod.game and mod.game.overworld)
  pcall(installDrawGuard)

  mod.exports.version = "1.0.1"
  mod.exports.sanitizeFollowerFxState = sanitizeFollowerFxState
  mod.exports.clearedStalePlayerFlags = function() return lastCleared end
end
