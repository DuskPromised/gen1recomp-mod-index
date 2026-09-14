-- Philosopher Stones v1.1.0
-- Lesser Stones teach the binding system; Greater Stones are discovered
-- through location/story conditions. Bindings live on each Pokemon.

local Bag = require("src.inventory.Bag")

local STONES = {
  -- Lesser Stones: badge-awakened.
  PHILOSOPHER_RUBY = {
    tier="LESSER", short="RUBY", name="RUBY STONE", badge="BOULDERBADGE",
    help="+15% damage dealt.",
  },
  PHILOSOPHER_SAPPHIRE = {
    tier="LESSER", short="SAPPHIRE", name="SAPPHIRE STONE", badge="CASCADEBADGE",
    help="-15% damage taken.",
  },
  PHILOSOPHER_EMERALD = {
    tier="LESSER", short="EMERALD", name="EMERALD STONE", badge="RAINBOWBADGE",
    help="Restores 1/16 max HP after each completed battle turn.",
  },
  PHILOSOPHER_AMETHYST = {
    tier="LESSER", short="AMETHYST", name="AMETHYST STONE", badge="MARSHBADGE",
    help="A missed move gets a 10% second-chance accuracy roll.",
  },

  -- Greater Stones: exploration/story relics.
  PHILOSOPHER_OBSIDIAN = {
    tier="GREATER", short="OBSIDIAN", name="OBSIDIAN STONE", essence="SALT",
    help="Once per battle, survive an otherwise lethal hit at 1 HP.",
  },
  PHILOSOPHER_SOLAR = {
    tier="GREATER", short="SOLAR", name="SOLAR STONE", essence="SULFUR",
    help="Creates a Sun aura while active: Fire +25%, Water -25%.",
  },
  PHILOSOPHER_MOON = {
    tier="GREATER", short="MOON", name="MOONSTONE", essence="AETHER",
    help="Cleanses the first major status condition suffered each battle.",
  },
  PHILOSOPHER_TEMPEST = {
    tier="GREATER", short="TEMPEST", name="TEMPEST STONE", essence="MERCURY",
    help="Electric damage +20% and paralysis is immediately cleansed.",
  },
}

local LESSER_ORDER = {
  "PHILOSOPHER_RUBY",
  "PHILOSOPHER_SAPPHIRE",
  "PHILOSOPHER_EMERALD",
  "PHILOSOPHER_AMETHYST",
}
local GREATER_ORDER = {
  "PHILOSOPHER_OBSIDIAN",
  "PHILOSOPHER_SOLAR",
  "PHILOSOPHER_MOON",
  "PHILOSOPHER_TEMPEST",
}
local STONE_ORDER = {
  "PHILOSOPHER_RUBY",
  "PHILOSOPHER_SAPPHIRE",
  "PHILOSOPHER_EMERALD",
  "PHILOSOPHER_AMETHYST",
  "PHILOSOPHER_OBSIDIAN",
  "PHILOSOPHER_SOLAR",
  "PHILOSOPHER_MOON",
  "PHILOSOPHER_TEMPEST",
}

return function(mod)
  for id, stone in pairs(STONES) do
    mod.content.items:register(id, {
      id=id, name=stone.name, price=0, keyItem=true, tossable=false,
    })
  end

  local function allMons(save, fn)
    for _,mon in ipairs(save and save.party or {}) do fn(mon) end
    for _,box in ipairs(save and save.boxes or {}) do
      for _,mon in ipairs(box) do fn(mon) end
    end
    for _,mon in ipairs(save and save.box or {}) do fn(mon) end
    if save and save.daycare and save.daycare.mon then fn(save.daycare.mon) end
  end

  local function equip(save, mon, id)
    if id and STONES[id] then
      -- One physical relic may resonate with only one Pokemon at a time.
      allMons(save, function(other)
        if other ~= mon and other.philosopherStone == id then
          other.philosopherStone = nil
        end
      end)
      mon.philosopherStone = id
    else
      mon.philosopherStone = nil
    end
  end

  local function stoneOf(mon)
    local id = mon and mon.philosopherStone
    return id and STONES[id] and id or nil
  end

  local function openStoneMenu(game, mon)
    local items = {}
    for _,id in ipairs(STONE_ORDER) do
      local stone = STONES[id]
      if game.save.inventory and game.save.inventory[id] then
        items[#items+1] = {
          label=stone.name,
          right=(stoneOf(mon)==id) and "ON" or nil,
          value=id,
        }
      end
    end
    items[#items+1] = { label="NONE", value="NONE" }

    local menu
    menu = mod.ui.ListMenu.new(game, "PHILOSOPHER STONE", items, {
      rows=6,
      footer="One relic may bind\nto one POKéMON.",
      onChoose=function(item, list)
        list:close()
        if item and item.value=="NONE" then equip(game.save, mon, nil)
        elseif item and STONES[item.value] then equip(game.save, mon, item.value) end
      end,
    })
    game.stack:push(menu)
  end

  mod.hooks:wrap("ui.party.submenu", function(next, game, items, mon, ctx)
    items = next(game, items, mon, ctx)
    if type(items) ~= "table" or (ctx and ctx.battle) then return items end
    local id = stoneOf(mon)
    items[#items+1] = {
      label=id and ("STONE: "..STONES[id].short) or "STONE: NONE",
      onSelect=function(target) openStoneMenu(game, target) end,
    }
    return items
  end)

  -- The Alchemy Journal is deliberately a start-menu view rather than another
  -- physical item. It records discovery and the four essences learned from the
  -- Greater Stones without consuming those stones.
  local function openJournal(game)
    local items = {}
    for _,id in ipairs(LESSER_ORDER) do
      local s=STONES[id]
      items[#items+1]={ label=s.short, right=game.save.inventory[id] and "FOUND" or "---" }
    end
    for _,id in ipairs(GREATER_ORDER) do
      local s=STONES[id]
      items[#items+1]={ label=s.short, right=game.save.inventory[id] and "FOUND" or "????" }
    end
    for _,id in ipairs(GREATER_ORDER) do
      local s=STONES[id]
      items[#items+1]={
        label=s.essence.." ESSENCE",
        right=mod.save:get("essence_"..s.essence, false) and "KNOWN" or "????",
      }
    end
    local menu
    menu=mod.ui.ListMenu.new(game, "ALCHEMY JOURNAL", items, {
      rows=7,
      footer="Greater relics reveal\nalchemical essences.",
      onChoose=function(_, list) list:close() end,
    })
    game.stack:push(menu)
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out=next(game, items)
    if type(out)~="table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label="ALCHEMY",
      onSelect=function() openJournal(game) end,
    })
  end)

  local function clearMajorStatus(battler)
    if not (battler and battler.mon) then return end
    battler.mon.status=nil
    battler.sleepTurns=nil
    battler.toxicCounter=nil
    battler.statusPenaltyStacks={}
  end

  -- Damage-altering stones share one wrapper so their order is explicit.
  mod.hooks:wrap("battle.damage", function(next, ctx)
    local damage, info = next(ctx)
    if type(damage) ~= "number" then return damage, info end
    local battle = ctx and ctx.battle
    if not (battle and battle.player and battle.player.mon) then return damage, info end
    local holder = stoneOf(battle.player.mon)
    local moveType = tostring(ctx.move and ctx.move.type or ""):upper()

    if ctx.user == battle.player and holder=="PHILOSOPHER_RUBY" then
      damage = math.max(1, math.floor(damage * 1.15))
    end
    if ctx.target == battle.player and holder=="PHILOSOPHER_SAPPHIRE" then
      damage = math.max(1, math.floor(damage * 0.85))
    end

    -- Solar is a field aura while its holder is the active player battler.
    if holder=="PHILOSOPHER_SOLAR" then
      if moveType=="FIRE" then
        damage=math.max(1, math.floor(damage * 1.25))
      elseif moveType=="WATER" then
        damage=math.max(1, math.floor(damage * 0.75))
      end
    end

    if ctx.user == battle.player and holder=="PHILOSOPHER_TEMPEST"
        and moveType=="ELECTRIC" then
      damage=math.max(1, math.floor(damage * 1.20))
    end

    -- Obsidian is deliberately once per battle and only on the holder.
    if ctx.target == battle.player and holder=="PHILOSOPHER_OBSIDIAN"
        and not battle._philosopherObsidianUsed then
      local hp=tonumber(battle.player.mon.hp) or 0
      if hp > 0 and damage >= hp then
        battle._philosopherObsidianUsed=true
        damage=math.max(0, hp-1)
      end
    end

    return damage, info
  end)

  -- Amethyst does not make inaccurate moves guaranteed; it only rescues 10%
  -- of rolls that already failed.
  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    local hit = next(ctx)
    if hit then return hit end
    local battle = ctx and ctx.battle
    if not (battle and battle.player and ctx.user == battle.player
        and stoneOf(battle.player.mon)=="PHILOSOPHER_AMETHYST") then
      return hit
    end
    local rng = ctx.rng
    if type(rng)=="function" then return rng(1,10)==1 end
    return math.random(1,10)==1
  end)

  mod.events:on("battle.status_inflicted", function(ev)
    local battle=ev and ev.battle
    local target=ev and ev.target
    if not (battle and target and target==battle.player and target.mon) then return end
    local holder=stoneOf(target.mon)

    if holder=="PHILOSOPHER_TEMPEST" then
      local status=tostring(ev.status or ""):upper()
      if status=="PAR" or status=="PARALYZE" or status=="PARALYSIS" then
        clearMajorStatus(target)
      end
      return
    end

    if holder=="PHILOSOPHER_MOON" and not battle._philosopherMoonUsed then
      battle._philosopherMoonUsed=true
      clearMajorStatus(target)
    end
  end)

  -- Emerald healing persists because the player battler references the live mon.
  mod.events:on("battle.turn_ended", function(ev)
    local battle = ev and ev.battle
    if not (battle and battle.player and battle.player.mon) or battle.result then return end
    local mon = battle.player.mon
    if stoneOf(mon) ~= "PHILOSOPHER_EMERALD" then return end
    local maxHp = mon.stats and tonumber(mon.stats.hp) or 0
    if maxHp <= 0 or (tonumber(mon.hp) or 0) <= 0 or mon.hp >= maxHp then return end
    local heal = math.max(1, math.floor(maxHp / 16))
    mon.hp = math.min(maxHp, mon.hp + heal)
    battle.player.shownHP = mon.hp
  end)

  local function noteEssence(id)
    local stone=STONES[id]
    if stone and stone.essence then
      mod.save:set("essence_"..stone.essence, true)
    end
  end

  local function awardRelic(game, id, text, consume)
    local save=game and game.save
    if not (save and save.inventory and STONES[id]) then return false end
    if save.inventory[id] then
      noteEssence(id)
      return false
    end
    if not Bag.add(save, id, 1, game.data) then return false end
    if consume and save.inventory[consume] then Bag.remove(save, consume, 1) end
    noteEssence(id)
    local TextBox=require("src.render.TextBox")
    game.stack:push(TextBox.new(game, text.."\fYou found the\n"..STONES[id].name.."!"))
    return true
  end

  local function awardOneLesser(game)
    local save = game and game.save
    if not (save and save.inventory) then return end
    for _,id in ipairs(LESSER_ORDER) do
      local stone = STONES[id]
      local key = "awarded_"..id
      if save.inventory[stone.badge] and not mod.save:get(key, false)
          and not save.inventory[id] then
        if Bag.add(save, id, 1, game.data) then
          mod.save:set(key, true)
          local TextBox = require("src.render.TextBox")
          game.stack:push(TextBox.new(game,
            "A strange relic\nanswered your BADGE!\fYou found the\n"..stone.name.."!"))
          return
        end
      elseif save.inventory[id] and not mod.save:get(key, false) then
        mod.save:set(key, true)
      end
    end
  end

  -- Greater Stone discovery sites. They claim the step only when a discovery
  -- actually fires; otherwise the map's original onStep chain continues.

  -- Moonstone: return to Mt. Moon after Misty with a normal MOON STONE.
  mod.content.map_scripts:register("MT_MOON_B2F", {
    priority=240,
    onStep=function(game, _, x, y)
      if x~=5 or y~=7 then return false end
      local inv=game.save.inventory or {}
      if inv.PHILOSOPHER_MOON then noteEssence("PHILOSOPHER_MOON"); return false end
      if not inv.CASCADEBADGE then return false end
      if not inv.MOON_STONE then
        if not mod.save:get("hint_moon", false) then
          mod.save:set("hint_moon", true)
          local TextBox=require("src.render.TextBox")
          game.stack:push(TextBox.new(game,
            "A pale light is\nbleeding through\nthe rock...\fSomething lunar\nwould answer it."))
          return true
        end
        return false
      end
      return awardRelic(game, "PHILOSOPHER_MOON",
        "Your MOON STONE\nturns cold.\fThe wall opens to\na silver-black relic.", "MOON_STONE")
    end,
  })

  -- Obsidian: the spirit barrier leaves a relic behind on Tower 7F.
  mod.content.map_scripts:register("POKEMON_TOWER_7F", {
    priority=240,
    onStep=function(game, _, x, y)
      if x~=10 or y~=16 then return false end
      local inv=game.save.inventory or {}
      if inv.PHILOSOPHER_OBSIDIAN then noteEssence("PHILOSOPHER_OBSIDIAN"); return false end
      if not (game.save.flags and game.save.flags.EVENT_BEAT_GHOST_MAROWAK) then return false end
      return awardRelic(game, "PHILOSOPHER_OBSIDIAN",
        "The departed spirit\nleft something\nblack as glass.\fIt refuses to\nbreak.")
    end,
  })

  -- Solar: after earning the Volcano Badge, return to Mansion B1F.
  mod.content.map_scripts:register("POKEMON_MANSION_B1F", {
    priority=240,
    onStep=function(game, _, x, y)
      if x~=12 or y~=2 then return false end
      local inv=game.save.inventory or {}
      if inv.PHILOSOPHER_SOLAR then noteEssence("PHILOSOPHER_SOLAR"); return false end
      if not inv.VOLCANOBADGE then return false end
      return awardRelic(game, "PHILOSOPHER_SOLAR",
        "Heat gathers behind\nthe ruined wall.\fYour VOLCANO BADGE\nignites a red-gold\nrelic.")
    end,
  })

  -- Tempest: after defeating/capturing Zapdos, a charged node remains.
  mod.content.map_scripts:register("POWER_PLANT", {
    priority=240,
    onStep=function(game, _, x, y)
      if x~=9 or y~=21 then return false end
      local inv=game.save.inventory or {}
      if inv.PHILOSOPHER_TEMPEST then noteEssence("PHILOSOPHER_TEMPEST"); return false end
      if not (game.save.flags and game.save.flags.EVENT_BEAT_ZAPDOS) then return false end
      return awardRelic(game, "PHILOSOPHER_TEMPEST",
        "Electricity still\ncrawls through the\nfloor.\fA storm-colored\nstone condenses\nfrom the charge.")
    end,
  })

  -- Leaving a Gym awakens Lesser Stones; old saves self-heal their journal.
  mod.events:on("map.entered", function()
    awardOneLesser(mod.game)
    local inv=mod.game and mod.game.save and mod.game.save.inventory or {}
    for _,id in ipairs(GREATER_ORDER) do
      if inv[id] then noteEssence(id) end
    end
  end)
  mod.events:on("game.ready", function()
    awardOneLesser(mod.game)
    local inv=mod.game and mod.game.save and mod.game.save.inventory or {}
    for _,id in ipairs(GREATER_ORDER) do
      if inv[id] then noteEssence(id) end
    end
  end)

  mod.exports.version = "1.1.0"
  mod.exports.stones = STONES
  mod.exports.greater = GREATER_ORDER
end
