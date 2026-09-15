-- Red Earth Shiny FX Bridge v1.0.0
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

  local function sanitizeFollowerFxState(candidate)
    local ow = liveOverworld(candidate)
    if not ow then return false end

    local player = ow.player
    if player and player._pokepcAsPokemon then
      local id = player.sprite and player.sprite.def and player.sprite.def.id
      -- Wilds uses _pokepcAsPokemon only when the trainer body has actually
      -- been replaced by the controlled Pokemon. If the trainer sprite is
      -- visible again, a stale flag makes SHINY_POKEMON project the sparkle
      -- burst onto RED instead of the follower behind him.
      if id and not PLAYER_MON_IDS[id] then
        player._pokepcAsPokemon = nil
        player._pokepcControlSpecies = nil
        player._pokepcShiny = nil
        lastCleared = lastCleared + 1
      end
    end

    -- Reassert the individual shiny state on the actual Wilds trailers.
    -- SHINY_POKEMON's projected FX pass keys from pokepcTrailer +
    -- pokepcShiny, so this makes the follower the authoritative target.
    for _, npc in ipairs(ow.pokepcTrailers or {}) do
      if npc and npc.pokepcMon then
        local shiny = isShiny(npc.pokepcMon)
        npc.pokepcShiny = shiny and true or false
        if npc.sprite and npc.sprite.def then
          npc.sprite.def.pokepcShiny = shiny and true or false
        end
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

  mod.exports.version = "1.0.0"
  mod.exports.sanitizeFollowerFxState = sanitizeFollowerFxState
  mod.exports.clearedStalePlayerFlags = function() return lastCleared end
end
