-- Gate 2: opt-in genuine shiny identity and authored art. No acquisition flow.
local Stats = require("src.pokemon.Stats")
local TARGET = {PSYDREN=true,VESPERIS=true,SOLIPSDION=true}
return function(mod)
  local art={}
  for species in pairs(TARGET) do
    local stem=species:lower()
    art[species]={}
    for _,kind in ipairs({"front","back","menu","icon"}) do
      art[species][kind]=mod.path.."/assets/"..stem.."_"..kind.."_shiny.png"
    end
  end
  local function isShiny(mon)
    return mon and TARGET[mon.species]==true and Stats.isShiny(mon.dvs) or false
  end
  local function normalize(mon)
    if mon and TARGET[mon.species] then mon.shiny=Stats.isShiny(mon.dvs) end
  end
  local function scan(save)
    if not save then return end
    local function list(ms) for _,m in ipairs(ms or {}) do normalize(m) end end
    list(save.party); list(save.box)
    for _,box in ipairs(save.boxes or {}) do list(box) end
  end
  mod.exports.makeShiny=function(mon,game)
    if not (mon and TARGET[mon.species]) then return false end
    game=game or mod.game
    local def=game and game.data and game.data.pokemon[mon.species]
    if not def then return false end
    local lost=math.max(0,(mon.stats and mon.stats.hp or mon.hp or 0)-(mon.hp or 0))
    local fainted=mon.hp==0
    mon.dvs={attack=15,defense=10,speed=10,special=10,hp=8}
    mon.shiny=true
    mon.stats=Stats.calc(def,mon.level,mon.dvs,mon.statExp)
    mon.hp=fainted and 0 or math.max(1,mon.stats.hp-lost)
    return true
  end
  mod.exports.isShiny=isShiny
  mod.exports.art=art
  mod.exports.version="0.2.0"

  -- The normal core runs at 125. This terminal, species-specific route runs
  -- after it, so a normal core cannot overwrite the selected authored variant.
  mod.hooks:wrap("pokemon.sprite",function(next,path,ctx)
    local a=ctx and art[ctx.species]
    if not (a and isShiny(ctx.mon)) then return next(path,ctx) end
    ctx.trueColor=true
    if ctx.kind=="summary" or ctx.kind=="dex" or ctx.kind=="menu" or ctx.kind=="box" then
      return a.menu
    end
    return ctx.side=="back" and a.back or a.front
  end,120)
  mod.hooks:wrap("pokemon.icon",function(next,path,ctx)
    local a=ctx and art[ctx.species]
    if not (a and isShiny(ctx.mon)) then return next(path,ctx) end
    ctx.trueColor=true
    return a.icon
  end,120)
  mod.events:on("pokemon.evolved",function(ev) normalize(ev and ev.mon) end)
  mod.events:on("save.loaded",function(ev) scan(ev and ev.save) end)
  mod.events:on("game.ready",function(ev)
    local game=(ev and ev.game) or mod.game
    scan(game and game.save)
  end)
end
