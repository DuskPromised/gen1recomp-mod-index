-- Red Earth Voxel Profile NEXT
-- Gate 0 persistence shim, v0.2.0.
--
-- Observed failure on iOS:
--   launcher/global PotatoVoxel settings survive app restart,
--   but CONTINUE can reopen the playthrough with a different voxel pipeline
--   level and/or different PotatoVoxel component settings. That produces the
--   confusing state where the launcher says CUSTOM while the in-game menu
--   says HIGH with AA/V-CURVE/V-GRID/3D-BTL changed.
--
-- Source of truth:
--   the PotatoVoxel configuration that exists at game.ready, before CONTINUE.
-- That is the standalone options.lua state edited by the launcher and by
-- PotatoVoxel's own settings writes. We snapshot it once, then re-apply that
-- exact snapshot after a save is loaded.
--
-- This is deliberately not a HIGH-forcing mod. OFF/HIGH/MEDIUM/LOW/POTATO/
-- CUSTOM all survive as selected. ATMOS, WEATHER, DAY/NIGHT, BACK SPRITES and
-- every other PotatoVoxel option are copied exactly rather than recomputed.

local Pipelines = require("src.render.Pipelines")
local Game = require("src.core.Game")

local bootProfile = nil

local function clone(value, seen)
  local t = type(value)
  if t ~= "table" then
    if t == "string" or t == "number" or t == "boolean" or t == "nil" then
      return value
    end
    return nil
  end
  seen = seen or {}
  if seen[value] then return nil end
  seen[value] = true
  local out = {}
  for k, v in pairs(value) do
    local ck, cv = clone(k, seen), clone(v, seen)
    if ck ~= nil and cv ~= nil then out[ck] = cv end
  end
  seen[value] = nil
  return out
end

local function capture(game)
  game = game or Game
  local opts = game and game.save and game.save.options
  if type(opts) ~= "table" then return nil end
  local modOptions = type(opts.modOptions) == "table" and opts.modOptions or {}
  local potato = type(modOptions.potato_voxel) == "table"
    and modOptions.potato_voxel or {}
  return {
    level = Pipelines.level("voxel"),
    potato = clone(potato) or {},
  }
end

local function sameTable(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do
    if type(v) == "table" then
      if not sameTable(v, b[k]) then return false end
    elseif b[k] ~= v then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

local function restore(profile, reason)
  if type(profile) ~= "table" then return false end
  local game = Game
  local opts = game and game.save and game.save.options
  if type(opts) ~= "table" then return false end

  opts.modOptions = type(opts.modOptions) == "table" and opts.modOptions or {}
  local current = type(opts.modOptions.potato_voxel) == "table"
    and opts.modOptions.potato_voxel or {}

  local wantedLevel = math.floor(tonumber(profile.level) or 0)
  local changed = Pipelines.level("voxel") ~= wantedLevel
               or not sameTable(current, profile.potato or {})

  if not changed then return false end

  local restored = clone(profile.potato) or {}
  opts.modOptions.potato_voxel = restored

  -- PotatoVoxel's ModSetting:read() reads the loader copy live, so update the
  -- same backing the mod reads before the next QualityMode.enforce tick.
  if game.mods then
    game.mods.modOptions = type(game.mods.modOptions) == "table"
      and game.mods.modOptions or {}
    game.mods.modOptions.potato_voxel = clone(restored) or {}
  end

  Pipelines.setLevel("voxel", wantedLevel)
  Pipelines.syncOptions(opts)

  if game.writeOptions then pcall(game.writeOptions, game) end
  mod.log.info(("restored PotatoVoxel boot profile after %s (voxel=%s)")
    :format(tostring(reason), Pipelines.levelLabel("voxel", wantedLevel)))
  return true
end

-- Capture after the engine has loaded standalone options.lua and applied its
-- pipeline state, but before the player chooses CONTINUE.
mod.events:on("game.ready", function(payload)
  bootProfile = capture(payload and payload.game or Game)
  if bootProfile then
    mod.log.info(("captured PotatoVoxel boot profile (voxel=%s)")
      :format(Pipelines.levelLabel("voxel", bootProfile.level)))
  end
end, -100)

-- CONTINUE adopts the progress save. Reconcile it back to the global/launcher
-- display configuration after every participating mod has seen save.loaded.
mod.events:on("save.loaded", function()
  restore(bootProfile, "save.loaded")
end, -100)

-- If the player changes PotatoVoxel settings in-game and saves, refresh our
-- in-memory source of truth too. PotatoVoxel itself writes those settings to
-- options.lua immediately; this keeps checkpoint/load activity in the same
-- session aligned with the newest choice.
mod.events:on("save.writing", function()
  local latest = capture(Game)
  if latest then bootProfile = latest end
end, -100)

mod.exports.capture = capture
mod.exports.restore = function() return restore(bootProfile, "manual") end
