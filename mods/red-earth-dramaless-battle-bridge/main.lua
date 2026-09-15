-- Red Earth Dramaless Battle Bridge v1.0.1
-- Narrow compatibility patch for DRAMALESS_SHAPE 2.0.x native battle cards.
--
-- Dramaless intentionally captures its 160x144 world cards at 1x. That is
-- correct for its mirrored FRONT-card presentation, but Red Earth's custom
-- starter pipeline supplies real player BACK sprites. Gen1Recomp renders back
-- sprites at 2x by default and keeps their feet grounded. During Dramaless'
-- synchronous capture this bridge restores ONLY the engine's normal back-pic
-- scale resolver for the authored Irregular starter line, while leaving Dramaless'
-- camera/card renderer and every other species untouched.

local BattleState = require("src.battle.BattleState")
local ENGINE_RESOLVE = BattleState.resolveBattleScale
local unpack = table.unpack or unpack

local TARGET = {
  IRR_PSYDREN=true,
  IRR_VESPERIS=true,
  IRR_SOLIPSDION=true,
}

return function(mod)
  local wrappedBattles = setmetatable({}, { __mode = "k" })
  local providerPatched = false
  local captures = 0

  local function playerSpecies(battle)
    return battle and battle.player and battle.player.mon
      and battle.player.mon.species or nil
  end

  local function installBattleWrapper(battle)
    if not battle then return false end
    if wrappedBattles[battle] then return true end
    local inner = battle.drawPicsLayer
    if type(inner) ~= "function" then return false end

    battle.drawPicsLayer = function(self, slide, sx, sy, onlySide, skipMenuClip)
      local species = playerSpecies(self)
      if onlySide ~= "player" or not TARGET[species] then
        return inner(self, slide, sx, sy, onlySide, skipMenuClip)
      end

      -- VoxelBattleCardProvider.withOriginalPlacement temporarily replaces
      -- resolveBattleScale with "return 1" immediately before this call.
      -- Reinstall the engine resolver only for the player's target BACK pic,
      -- then restore Dramaless' temporary resolver before returning.
      local prior = BattleState.resolveBattleScale
      BattleState.resolveBattleScale = function(data, side, path, resolvedSpecies)
        if side == "back" and TARGET[resolvedSpecies] then
          local ok, value = pcall(ENGINE_RESOLVE,
            data, side, path, resolvedSpecies)
          if ok and tonumber(value) then return value end
          return 2
        end
        return prior(data, side, path, resolvedSpecies)
      end

      local results = {
        pcall(inner, self, slide, sx, sy, onlySide, skipMenuClip)
      }
      BattleState.resolveBattleScale = prior
      if not results[1] then error(results[2], 0) end
      table.remove(results, 1)
      captures = captures + 1
      return unpack(results)
    end

    wrappedBattles[battle] = true
    return true
  end

  local function findDramaless()
    if type(mod.find) ~= "function" then return nil end
    local ok, found = pcall(function() return mod:find("DRAMALESS_SHAPE") end)
    if not ok then return nil end
    return found
  end

  local function patchProvider()
    if providerPatched then return true end
    local dr = findDramaless()
    local provider = dr and dr.exports and dr.exports.voxelCardProvider
    if not provider then return false end
    if provider._redEarthBattleScaleBridge then
      providerPatched = true
      return true
    end

    for _, name in ipairs({ "begin", "update" }) do
      local inner = provider[name]
      if type(inner) == "function" then
        provider[name] = function(self, context, ...)
          if context and context.battle then
            pcall(installBattleWrapper, context.battle)
          end
          return inner(self, context, ...)
        end
      end
    end

    provider._redEarthBattleScaleBridge = true
    providerPatched = true
    return true
  end

  mod.events:on("mods.loaded", function()
    pcall(patchProvider)
  end)

  mod.events:on("game.ready", function()
    pcall(patchProvider)
  end)

  mod.events:on("battle.started", function(ev)
    pcall(patchProvider)
    if ev and ev.battle then pcall(installBattleWrapper, ev.battle) end
  end)

  pcall(patchProvider)

  mod.exports.version = "1.0.1"
  mod.exports.targetSpecies = TARGET
  mod.exports.providerPatched = function() return providerPatched end
  mod.exports.captureCount = function() return captures end
end
