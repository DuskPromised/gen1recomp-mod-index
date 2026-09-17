-- QA-only acquisition. Four test gifts; the production starter remains Kaizo's.
local Stats=require("src.pokemon.Stats")
local unpack=table.unpack or unpack
local function pack(...) return {n=select("#",...),...} end
local TESTS={
  TEXT_OAKSLAB_CHARMANDER_POKE_BALL={
    {species="PSYDREN",level=15,shiny=true,flag="RE_G2_SHINY_PSYDREN"},
    {species="PSYDREN",level=15,shiny=false,flag="RE_G2_NORMAL_CONTROL"},
  },
  TEXT_OAKSLAB_SQUIRTLE_POKE_BALL={
    {species="VESPERIS",level=35,shiny=true,flag="RE_G2_SHINY_VESPERIS"},
  },
  TEXT_OAKSLAB_BULBASAUR_POKE_BALL={
    {species="SOLIPSDION",level=50,shiny=true,flag="RE_G2_SHINY_SOLIPSDION"},
  },
}
return function(mod)
  local active
  local function each(save,fn)
    for _,m in ipairs(save.party or {}) do fn(m) end
    for _,box in ipairs(save.boxes or {}) do for _,m in ipairs(box) do fn(m) end end
    for _,m in ipairs(save.box or {}) do fn(m) end
  end
  mod.hooks:wrap("script.command",function(next,ctx,name,args,...)
    if not(active and name=="give_pokemon" and ctx.source and ctx.source.modId==mod.id) then
      return next(ctx,name,args,...)
    end
    local seen={};each(ctx.save,function(m) seen[m]=true end)
    local result=pack(next(ctx,name,args,...))
    each(ctx.save,function(mon)
      if not seen[mon] and mon.species==active.species then
        if active.shiny then
          local shiny=mod:find("red_earth_irregular_shiny")
          assert(shiny and shiny.exports.makeShiny(mon,ctx.game),"Gate 2 shiny module unavailable")
        else
          mon.dvs={attack=15,defense=15,speed=15,special=15,hp=15}
          mon.shiny=false
          mon.stats=Stats.calc(ctx.game.data.pokemon[mon.species],mon.level,mon.dvs,mon.statExp)
        end
        mon.hp=mon.stats.hp
      end
    end)
    return unpack(result,1,result.n)
  end,50)
  mod.hooks:wrap("world.talk",function(next,ow,target)
    local game=mod.game
    local flags=game and game.save and game.save.flags
    local choices=target and target.def and TESTS[target.def.text]
    if not(ow and ow.map and ow.map.id=="OAKS_LAB" and flags and choices
        and flags.EVENT_FOLLOWED_OAK_INTO_LAB and not flags.EVENT_GOT_STARTER) then
      return next(ow,target)
    end
    local all=true
    for _,list in pairs(TESTS) do for _,test in ipairs(list) do
      if not flags[test.flag] then all=false end
    end end
    if all then return next(ow,target) end
    local selected
    for _,test in ipairs(choices) do if not flags[test.flag] then selected=test;break end end
    target.frozen=true
    if not selected then
      ow.runner:run({{"show_text","GATE 2: This ball is done.\nTry the other balls.\fLeft ball also gives\na normal control."}},
        {npc=target,onDone=function() target.frozen=false end,
         source={modId=mod.id,strict=true,mapId="OAKS_LAB",hook="world.talk"}})
      return
    end
    active=selected
    local label=(selected.shiny and "SHINY " or "NORMAL ")..selected.species
    ow.runner:run({
      {"show_text","GATE 2 QA\n"..label.."\nLv."..selected.level},
      {"give_pokemon",selected.species,selected.level},
      {"jump_if_false","no_room"},
      {"set_flag",selected.flag},
      {"check_flag","RE_G2_CANDIES"},
      {"jump_if_true","done"},
      {"give_item","RARE_CANDY",50},
      {"jump_if_false","done"},
      {"set_flag","RE_G2_CANDIES"},
      {"label","done"},
      {"show_text","Check battle and menus.\nLeft ball: talk twice\nfor the normal control.\fRare Candies are for\nevolution testing."},
      {"jump","end"},
      {"label","no_room"},
      {"show_text","No room. Make space\nand try this ball again."},
      {"label","end"},
    },{npc=target,onDone=function() active=nil;target.frozen=false end,
       source={modId=mod.id,strict=true,mapId="OAKS_LAB",hook="world.talk"}})
  end,50)
  mod.exports.version="0.2.2"
  mod.exports.testOnly=true
end
