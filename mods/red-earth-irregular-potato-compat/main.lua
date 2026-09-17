-- Gate 1.3: separate compatibility for Irregular back art + PotatoVoxel 1.9.6.
-- No upstream files, species records, assets, or save data are modified.
local unpack = table.unpack or unpack
local function pack(...) return {n=select("#", ...), ...} end
local FACTOR = { PSYDREN=1, VESPERIS=1.18, SOLIPSDION=1.30 }

return function(mod)
  local installed = setmetatable({}, {__mode="k"})
  local function install(battle)
    if not battle or installed[battle] then return end
    local potato = mod:find("potato_voxel")
    local lib = potato and potato.exports and potato.exports.lib
    if not lib then return end
    local ow = lib.require("OverworldBattle")
    local pics = lib.require("BattlePics")
    local state = require("src.battle.BattleState")
    if type(pics.filled)~="function" or type(state.resolveBattleScale)~="function"
        or type(battle.picImage)~="function" or type(battle.drawPicsLayer)~="function" then
      return
    end

    local function target(self)
      if not self.dramaticShapeShot or not ow.backPinned() then return nil end
      local player = self.player
      local species = player and player.mon and player.mon.species
      local def = species and self.data and self.data.pokemon[species]
      if not (FACTOR[species] and def and def.trueColor) then return nil end
      return species, player
    end

    -- Keep the complete upstream picImage pipeline (fades/monochrome/etc.).
    -- Only while that pipeline resolves this one authored player image, skip
    -- its paper reconstruction. These RGBA assets already contain their whites.
    -- The temporary function is restored even if rendering throws an error.
    local innerPic = battle.picImage
    battle.picImage = function(self, img, ...)
      local species, player = target(self)
      if not species or img ~= player.sprite then return innerPic(self, img, ...) end
      local prior = pics.filled
      pics.filled = function(resolved) return resolved end
      local result = pack(pcall(innerPic, self, img, ...))
      pics.filled = prior
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end

    -- Potato rounds 0.94/1.00/1.05 to 1 for pinned pics. Retain the species
    -- scale, with explicit stage framing factors, for this back pic only.
    -- No permanent class-level wrapper and no change to billboard captures,
    -- front pics, trainers, other species, or battles outside the pinned mode.
    local innerDraw = battle.drawPicsLayer
    battle.drawPicsLayer = function(self, slide, sx, sy, onlySide, skipMenuClip)
      local species = target(self)
      if not species or onlySide=="enemy" then
        return innerDraw(self, slide, sx, sy, onlySide, skipMenuClip)
      end
      local prior = state.resolveBattleScale
      state.resolveBattleScale = function(data, side, path, resolvedSpecies)
        if data==self.data and side=="back" and resolvedSpecies==species then
          local def = data.pokemon[species]
          -- Exact authored path prevents affecting another provider's image.
          if path==def.spriteBack then
            return (def.battleScaleBack or 1) * FACTOR[species]
          end
        end
        return prior(data, side, path, resolvedSpecies)
      end
      local result = pack(pcall(innerDraw, self, slide, sx, sy, onlySide, skipMenuClip))
      state.resolveBattleScale = prior
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end
    installed[battle] = true
  end

  mod.events:on("battle.started", function(ev)
    install(ev and ev.battle)
  end)
  mod.exports.version = "0.1.3"
end
