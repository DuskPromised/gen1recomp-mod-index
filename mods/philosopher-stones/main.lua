-- Philosopher Stones v1.0.0
-- Four persistent relics that can be bound to one Pokemon at a time.
-- The binding is stored directly on the mon table and survives save/PC/evolution.

local Bag = require("src.inventory.Bag")

local STONES = {
  PHILOSOPHER_RUBY = {
    short="RUBY", name="RUBY STONE", badge="BOULDERBADGE",
    help="+15% damage dealt.",
  },
  PHILOSOPHER_SAPPHIRE = {
    short="SAPPHIRE", name="SAPPHIRE STONE", badge="CASCADEBADGE",
    help="-15% damage taken.",
  },
  PHILOSOPHER_EMERALD = {
    short="EMERALD", name="EMERALD STONE", badge="RAINBOWBADGE",
    help="Restores 1/16 max HP after each completed battle turn.",
  },
  PHILOSOPHER_AMETHYST = {
    short="AMETHYST", name="AMETHYST STONE", badge="MARSHBADGE",
    help="A missed move gets a 10% second-chance accuracy roll.",
  },
}

local AWARD_ORDER = {
  "PHILOSOPHER_RUBY",
  "PHILOSOPHER_SAPPHIRE",
  "PHILOSOPHER_EMERALD",
  "PHILOSOPHER_AMETHYST",
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
      -- A physical stone can resonate with only one Pokémon at a time.
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
    for _,id in ipairs(AWARD_ORDER) do
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
      footer="One stone may bind\nto one POKéMON.",
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

  -- Ruby/Sapphire modify only the active player's side and preserve the
  -- engine's (damage, info) return contract.
  mod.hooks:wrap("battle.damage", function(next, ctx)
    local damage, info = next(ctx)
    if type(damage) ~= "number" then return damage, info end
    local battle = ctx and ctx.battle
    if not (battle and battle.player) then return damage, info end

    if ctx.user == battle.player and stoneOf(battle.player.mon)=="PHILOSOPHER_RUBY" then
      damage = math.max(1, math.floor(damage * 1.15))
    end
    if ctx.target == battle.player and stoneOf(battle.player.mon)=="PHILOSOPHER_SAPPHIRE" then
      damage = math.max(1, math.floor(damage * 0.85))
    end
    return damage, info
  end)

  -- Amethyst does not turn inaccurate moves into guaranteed hits; it only
  -- rescues 10% of rolls that would otherwise miss.
  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    local hit = next(ctx)
    if hit then return hit end
    local battle = ctx and ctx.battle
    if not (battle and ctx.user == battle.player
        and stoneOf(battle.player.mon)=="PHILOSOPHER_AMETHYST") then
      return hit
    end
    local rng = ctx.rng
    if type(rng)=="function" then return rng(1,10)==1 end
    return math.random(1,10)==1
  end)

  -- Player battlers reference the live party mon, so Emerald healing persists
  -- naturally after battle. shownHP is kept in sync for the HUD.
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

  local function awardOne(game)
    local save = game and game.save
    if not (save and save.inventory) then return end
    for _,id in ipairs(AWARD_ORDER) do
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

  -- Leaving a Gym naturally enters another map, which makes badge-earned
  -- relics feel discovered rather than injected mid-leader dialogue.
  mod.events:on("map.entered", function() awardOne(mod.game) end)
  mod.events:on("game.ready", function() awardOne(mod.game) end)

  mod.exports.version = "1.0.0"
  mod.exports.stones = STONES
end
