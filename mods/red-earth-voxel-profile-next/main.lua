-- Red Earth Voxel Profile NEXT
-- Gate 0 compatibility shim.
--
-- PotatoVoxel intentionally treats HIGH/MEDIUM/LOW/POTATO as named presets
-- made from several independent mod options. On some cart/save restore paths
-- the pipeline level survives while one or more constituent options do not,
-- causing HIGH to reopen with AA/V-CURVE/V-GRID/3D-BTL mismatched and then
-- collapse to CUSTOM.
--
-- This shim does one thing only: after a save/new game is adopted, if the
-- pipeline is on a named preset (levels 1..4) and that preset no longer
-- matches its own component settings, re-apply THAT SAME preset once.
--
-- CUSTOM (5) and OFF (0) are never changed. ATMOS, WEATHER, DAY/NIGHT,
-- BACK SPRITES, debug settings, etc. are not part of QualityMode.applyMode
-- and are therefore preserved exactly as the player left them.

local Pipelines = require("src.render.Pipelines")
local Game = require("src.core.Game")

local function qualityMode()
  local host = mod.find("potato_voxel")
  if not (host and host.exports and host.exports.lib
      and type(host.exports.lib.require) == "function") then
    return nil, "potato exports unavailable"
  end
  local ok, q = pcall(host.exports.lib.require, "QualityMode")
  if not ok or type(q) ~= "table" then
    return nil, "QualityMode unavailable"
  end
  return q
end

local lastRepairSignature = nil

local function repair(reason)
  local level = Pipelines.level("voxel")

  -- 0=OFF, 1=HIGH, 2=MEDIUM, 3=LOW, 4=POTATO, 5=CUSTOM.
  -- Only named presets have a contract to repair.
  if level < 1 or level > 4 then return false end

  local q, err = qualityMode()
  if not q then
    mod.log.warn("voxel profile repair skipped: " .. tostring(err))
    return false
  end

  local okMatch, matches = pcall(q.matches, level)
  if okMatch and matches then return false end

  local game = Game
  if not (game and game.save and game.save.options) then return false end

  local signature = tostring(reason) .. ":" .. tostring(level)
  if lastRepairSignature == signature then return false end

  local ok, applyErr = pcall(q.applyMode, level, game)
  if not ok then
    mod.log.error("voxel profile repair failed: " .. tostring(applyErr))
    return false
  end

  -- Keep the pipeline ladder and the options file in agreement.
  Pipelines.syncOptions(game.save.options)
  if game.writeOptions then pcall(game.writeOptions, game) end

  lastRepairSignature = signature
  mod.log.info(("restored PotatoVoxel named preset %s after %s")
    :format(Pipelines.levelLabel("voxel", level), tostring(reason)))
  return true
end

mod.events:on("save.loaded", function()
  repair("save.loaded")
end)

mod.events:on("save.created", function()
  repair("save.created")
end)

-- game.ready covers launcher -> new session boots where options are already
-- loaded before the player reaches Continue/New Game. It is harmless when the
-- active level already matches because repair() exits without writing.
mod.events:on("game.ready", function()
  repair("game.ready")
end)

mod.exports.repair = repair
