-- Gate 2.9 QA acquisition rebuilt from the accepted Gate 2.6 path.
-- The only behavioral change from the 0.2.0 harness is nickname timing:
-- QA gifts are created with vanilla nickname handling temporarily skipped,
-- their intended shiny/normal identity is applied, then the engine-equivalent
-- nickname prompt is shown.  This keeps the nickname icon consistent with the
-- already-selected shiny state without touching Oak/region/starter routing.
local Stats=require("src.pokemon.Stats")
local Commands=require("src.script.Commands")
local Screens=require("src.ui.Screens")
local Strings=require("src.core.Strings")
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

local function askNicknameAfterState(ctx,mon)
  local runner=ctx and ctx.runner
  if not runner then return end
  local success=ctx.lastCheck
  local name=ctx.game.stringBuffer
    or (ctx.game.data.pokemon[mon.species] and ctx.game.data.pokemon[mon.species].name)
    or mon.species
  local textId,subs
  if ctx.game.data.text and ctx.game.data.text._DoYouWantToNicknameText then
    textId,subs="_DoYouWantToNicknameText",{RAM=name}
  else
    textId=Strings("Do you want to\ngive a nickname\nto %s?",name)
  end
  -- Mirrors Commands.give_pokemon's private AskName flow.  The important
  -- difference is only ordering: mon shiny identity already exists here.
  Commands.show_text(ctx,textId,subs,{choice=function(yes)
    if not yes then
      ctx.lastCheck=success
      runner:resume()
      return
    end
    Screens.push(ctx.game,"NamingScreen",{
      title=Strings("NICKNAME?"),maxLen=10,mon=mon,
      onDone=function(nick)
        if nick and #nick>0 then mon.nickname=nick end
        ctx.lastCheck=success
        runner:resume()
      end,
    })
  end})
end

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

    -- QA-only: suppress Commands.give_pokemon's nickname prompt for this one
    -- harness-owned gift so its shiny/normal state can be finalized first.
    -- No production Oak/region command reaches this branch because source.modId
    -- must equal this test harness's own id.
    local forwarded={}
    for i,v in ipairs(args or {}) do forwarded[i]=v end
    forwarded[3]=true
    local result=pack(next(ctx,name,forwarded,...))

    local created
    each(ctx.save,function(mon)
      if not created and not seen[mon] and mon.species==active.species then
        created=mon
      end
    end)

    if created then
      if active.shiny then
        local shiny=mod:find("red_earth_irregular_shiny")
        assert(shiny and shiny.exports.makeShiny(created,ctx.game),"Gate 2 shiny module unavailable")
      else
        created.dvs={attack=15,defense=15,speed=15,special=15,hp=15}
        created.shiny=false
        created.stats=Stats.calc(ctx.game.data.pokemon[created.species],created.level,created.dvs,created.statExp)
      end
      created.hp=created.stats.hp
      if not created.nickname then askNicknameAfterState(ctx,created) end
    end

    return unpack(result,1,result.n)
  end,50)

  -- Baseline QA-ball routing below is intentionally unchanged from 0.2.0.
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
  mod.exports.version="0.2.9"
  mod.exports.testOnly=true
end
