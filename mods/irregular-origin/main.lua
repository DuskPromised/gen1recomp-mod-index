-- Irregular Origin v1.0.5
-- Custom three-stage starter line for Pokémon Red Earth: The Philosopher's Stones.
-- Psydren is received before Oak's normal regional companion choice.

local Stats = require("src.pokemon.Stats")

local IDS = {
  PSYDREN="IRR_PSYDREN",
  VESPERIS="IRR_VESPERIS",
  SOLIPSDION="IRR_SOLIPSDION",
}
local GIFT_FLAG="MOD_IRREGULAR_ORIGIN_PSYDREN"
local STARTER_BALL_TEXTS={
  TEXT_OAKSLAB_CHARMANDER_POKE_BALL=true,
  TEXT_OAKSLAB_SQUIRTLE_POKE_BALL=true,
  TEXT_OAKSLAB_BULBASAUR_POKE_BALL=true,
}
local IRREGULAR={
  [IDS.PSYDREN]=true,[IDS.VESPERIS]=true,[IDS.SOLIPSDION]=true,
}

local function hash(text)
  local h=0
  text=tostring(text or "")
  for i=1,#text do h=(h*33+text:byte(i))%2147483647 end
  return h
end

return function(mod)
  local pokemon=mod.content.pokemon
  local moves=mod.content.moves
  if not (pokemon and moves) then
    mod.log:warn("pokemon/moves registry unavailable; Irregular Origin skipped")
    return
  end

  -- Production art map. Normal and shiny assets are separate authored
  -- sprites; the shiny line is not a runtime palette swap.
  local ART={
    [IDS.PSYDREN]={
      front=mod.path.."/assets/psydren_front.png",
      back=mod.path.."/assets/psydren_back.png",
      menu=mod.path.."/assets/psydren_menu.png",
      icon=mod.path.."/assets/psydren_icon.png",
      follower=mod.path.."/assets/psydren_follower.png",
      frontShiny=mod.path.."/assets/psydren_front_shiny.png",
      backShiny=mod.path.."/assets/psydren_back_shiny.png",
      menuShiny=mod.path.."/assets/psydren_menu_shiny.png",
      iconShiny=mod.path.."/assets/psydren_icon_shiny.png",
      followerShiny=mod.path.."/assets/psydren_follower_shiny.png",
    },
    [IDS.VESPERIS]={
      front=mod.path.."/assets/vesperis_front.png",
      back=mod.path.."/assets/vesperis_back.png",
      menu=mod.path.."/assets/vesperis_menu.png",
      icon=mod.path.."/assets/vesperis_icon.png",
      follower=mod.path.."/assets/vesperis_follower.png",
      frontShiny=mod.path.."/assets/vesperis_front_shiny.png",
      backShiny=mod.path.."/assets/vesperis_back_shiny.png",
      menuShiny=mod.path.."/assets/vesperis_menu_shiny.png",
      iconShiny=mod.path.."/assets/vesperis_icon_shiny.png",
      followerShiny=mod.path.."/assets/vesperis_follower_shiny.png",
    },
    [IDS.SOLIPSDION]={
      front=mod.path.."/assets/solipsdion_front.png",
      back=mod.path.."/assets/solipsdion_back.png",
      menu=mod.path.."/assets/solipsdion_menu.png",
      icon=mod.path.."/assets/solipsdion_icon.png",
      follower=mod.path.."/assets/solipsdion_follower.png",
      frontShiny=mod.path.."/assets/solipsdion_front_shiny.png",
      backShiny=mod.path.."/assets/solipsdion_back_shiny.png",
      menuShiny=mod.path.."/assets/solipsdion_menu_shiny.png",
      iconShiny=mod.path.."/assets/solipsdion_icon_shiny.png",
      followerShiny=mod.path.."/assets/solipsdion_follower_shiny.png",
    },
  }

  local function existingMove(...)
    local names={...}
    for _,id in ipairs(names) do
      if id and moves:get(id) then return id end
    end
    return "TACKLE"
  end

  local vanillaConfusion=existingMove("CONFUSION")
  local withdraw=existingMove("WITHDRAW","HARDEN")
  local waterGun=existingMove("WATER_GUN","WATERGUN")
  local hypnosis=existingMove("HYPNOSIS")
  local bubbleBeam=existingMove("BUBBLEBEAM","BUBBLE_BEAM")
  local nightShade=existingMove("NIGHT_SHADE","NIGHTSHADE")
  local psybeam=existingMove("PSYBEAM")
  local confuseRay=existingMove("CONFUSE_RAY","CONFUSERAY")
  local recover=existingMove("RECOVER")
  local dreamEater=existingMove("DREAM_EATER","DREAMEATER")
  local amnesia=existingMove("AMNESIA")
  local aeroblast=existingMove("AEROBLAST","AERO_BLAST","RAZOR_WIND")
  local hydroPump=existingMove("HYDRO_PUMP","HYDROPUMP")
  local psychic=existingMove("PSYCHIC_M","PSYCHIC")

  -- Classic CONFUSION uses a scanline-deformation animation. That looks fine
  -- in the flat renderer but can leave distracting scene/sprite deformation
  -- in the Dramaless 3D battle presentation. Keep the exact move gameplay,
  -- but give the Irregular line a particle-based visual that doesn't warp the
  -- battlefield. SWIFT is preferred; EMBER/TACKLE are only defensive fallbacks.
  local confusionAnim=(moves:get(existingMove("SWIFT","EMBER","TACKLE")) or {}).anim
  local rageAnim=(moves:get(existingMove("DRAGON_RAGE")) or {}).anim
  local beamAnim=(moves:get(existingMove("HYPER_BEAM")) or {}).anim

  mod.content.moves:register("IRR_CONFUSION",{
    id="IRR_CONFUSION",name="CONFUSION",
    type="PSYCHIC",power=50,accuracy=100,pp=25,
    effect="CONFUSION_SIDE_EFFECT",category="special",anim=confusionAnim,
  })

  mod.content.moves:register("IRR_SOVEREIGN_RAGE",{
    id="IRR_SOVEREIGN_RAGE",name="SOVEREIGN RAGE",
    type="DRAGON",power=80,accuracy=100,pp=10,
    effect="NO_ADDITIONAL_EFFECT",category="special",anim=rageAnim,
  })
  mod.content.moves:register("IRR_SERAPHS_VERDICT",{
    id="IRR_SERAPHS_VERDICT",name="SERAPH'S VERDICT",
    type="DRAGON",power=140,accuracy=90,pp=5,
    effect="HYPER_BEAM_EFFECT",category="special",anim=beamAnim,
  })

  local maxDex=0
  for _,def in pokemon:each() do
    maxDex=math.max(maxDex,tonumber(def.dex) or 0)
  end
  local d1,d2,d3=maxDex+1,maxDex+2,maxDex+3

  pokemon:register(IDS.PSYDREN,{
    id=IDS.PSYDREN,name="PSYDREN",dex=d1,
    types={"PSYCHIC","WATER"},
    baseStats={hp=55,attack=40,defense=65,speed=45,special=70},
    catchRate=45,baseExp=80,growthRate="MEDIUM_SLOW",
    level1Moves={"IRR_CONFUSION",withdraw},
    learnset={
      {level=7,move=waterGun},{level=11,move=hypnosis},{level=14,move=bubbleBeam},
    },
    evolutions={{method="LEVEL",level=16,species=IDS.VESPERIS}},
    spriteFront=mod.path.."/assets/psydren_front.png",
    spriteBack=mod.path.."/assets/psydren_back.png",
    frontSize=7,trueColor=true,battleScaleFront=1.0,battleScaleBack=1.0,
    icon={image=mod.path.."/assets/psydren_icon.png",frames=2},
    cry="MEW",
    dexEntry={kind="ABYSSAL SEED",heightFt=2,heightIn=4,weight=18.5,
      text="An aquatic anomaly that drifts between dreams and the sea.",
      text2="A crimson light sleeps beneath its calm exterior."},
  })
  pokemon:register(IDS.VESPERIS,{
    id=IDS.VESPERIS,name="VESPERIS",dex=d2,
    types={"PSYCHIC","GHOST"},
    baseStats={hp=70,attack=55,defense=75,speed=80,special=95},
    catchRate=20,baseExp=150,growthRate="MEDIUM_SLOW",
    level1Moves={"IRR_CONFUSION",withdraw},
    learnset={
      {level=16,move=nightShade},{level=20,move=psybeam},
      {level=25,move=confuseRay},{level=29,move=recover},{level=33,move=dreamEater},
    },
    evolutions={{method="LEVEL",level=36,species=IDS.SOLIPSDION}},
    spriteFront=mod.path.."/assets/vesperis_front.png",
    spriteBack=mod.path.."/assets/vesperis_back.png",
    frontSize=7,trueColor=true,battleScaleFront=1.0,battleScaleBack=1.0,
    icon={image=mod.path.."/assets/vesperis_icon.png",frames=2},
    cry="HAUNTER",
    dexEntry={kind="GRAVEKEEPER STORM",heightFt=4,heightIn=11,weight=71.0,
      text="Its first body dissolves into a violent psychic wraith.",
      text2="It survives the space between life and death by mastering it."},
  })
  pokemon:register(IDS.SOLIPSDION,{
    id=IDS.SOLIPSDION,name="SOLIPSDION",dex=d3,
    types={"PSYCHIC","DRAGON"},
    baseStats={hp=95,attack=85,defense=105,speed=105,special=125},
    catchRate=3,baseExp=220,growthRate="MEDIUM_SLOW",
    level1Moves={"IRR_CONFUSION",nightShade},
    learnset={
      {level=36,move="IRR_SOVEREIGN_RAGE"},{level=42,move=amnesia},
      {level=49,move=aeroblast},{level=57,move=hydroPump},
      {level=65,move=psychic},{level=75,move="IRR_SERAPHS_VERDICT"},
    },
    evolutions={},
    spriteFront=mod.path.."/assets/solipsdion_front.png",
    spriteBack=mod.path.."/assets/solipsdion_back.png",
    frontSize=7,trueColor=true,battleScaleFront=1.0,battleScaleBack=1.0,
    icon={image=mod.path.."/assets/solipsdion_icon.png",frames=2},
    cry="MEWTWO",
    dexEntry={kind="SOVEREIGN APEX",heightFt=7,heightIn=2,weight=269.0,
      text="Seven wings surround a body shaped by repeated transmutation.",
      text2="The red core in its chest resonates with impossible relics."},
  })

  if mod.content.constants then
    mod.content.constants:patch("dexSize",d3)
  end

  -- Gen-II-compatible shiny test used by both battle/menu and follower art.
  -- mon.shiny is honored first because the Irregular gift explicitly marks it.
  local SHINY_ATTACK_DVS={
    [2]=true,[3]=true,[6]=true,[7]=true,
    [10]=true,[11]=true,[14]=true,[15]=true,
  }
  local function isVisualShiny(mon)
    if not mon then return false end
    if mon.shiny==true or mon.isShiny==true then return true end
    local d=mon.dvs
    if type(d)~="table" then return false end
    local a=tonumber(d.attack)
    return tonumber(d.defense)==10
      and tonumber(d.speed)==10
      and tonumber(d.special)==10
      and SHINY_ATTACK_DVS[a]==true
  end

  local function artFor(ctx)
    if not ctx then return nil end
    local species=ctx.species or (ctx.mon and ctx.mon.species)
    return ART[species]
  end

  -- Route every engine battle/stat/dex request through the authored normal or
  -- shiny production art. Summary/Dex use the dedicated portrait instead of
  -- stretching a battle sprite. Call downstream first so graphics hosts such
  -- as Dramaless can choose their presentation. In Dramaless' voxel-card mode,
  -- BACK SPRITES OFF intentionally substitutes the front illustration on the
  -- player side; preserve that choice while swapping in the correct shiny
  -- front rather than falling back to the species' static normal front.
  mod.hooks:wrap("pokemon.sprite",function(next,path,ctx)
    local art=artFor(ctx)
    if not art then return next(path,ctx) end
    ctx.trueColor=true
    local result=next(path,ctx)
    local shiny=isVisualShiny(ctx.mon)
    if ctx.kind=="summary" or ctx.kind=="dex" or ctx.kind=="menu" then
      return shiny and art.menuShiny or art.menu
    end
    if ctx.side=="back" then
      local data=ctx.data
      local def=data and data.pokemon and ctx.species and data.pokemon[ctx.species]
      local staticFront=def and def.spriteFront
      if result==staticFront or result==art.front or result==art.frontShiny then
        return shiny and art.frontShiny or art.front
      end
      return shiny and art.backShiny or art.back
    end
    return shiny and art.frontShiny or art.front
  end,125)

  -- Party icons are separate two-frame 16x32 sheets, also with authored
  -- normal/shiny variants.
  mod.hooks:wrap("pokemon.icon",function(next,path,ctx)
    local art=artFor(ctx)
    if not art then return next(path,ctx) end
    ctx.trueColor=true
    local result=next(path,ctx)
    return isVisualShiny(ctx.mon) and art.iconShiny or art.icon
  end,125)

  -- Wilds of Kanto owns follower rendering. When it is installed, wrap only
  -- its final Pokedex provider so these three custom species get their own
  -- six-frame 16x96 walkers without changing any other Pokémon provider.
  local followerProviderInstalled=false
  local function installIrregularFollowerProvider(game)
    if followerProviderInstalled or type(mod.find)~="function" then return end
    local okFind,wilds=pcall(function()
      return mod:find("overworld_wild_spawns")
    end)
    local ex=okFind and wilds and wilds.exports
    if not (ex and type(ex.getSpriteProvider)=="function"
        and type(ex.registerSpriteProvider)=="function") then return end

    local okBase,base=pcall(ex.getSpriteProvider,"pokedex")
    if not okBase or type(base)~="table" then return end
    if base.__irregularOriginWrapper then
      followerProviderInstalled=true
      return
    end

    local wrapper={id="pokedex",__irregularOriginWrapper=true}
    function wrapper:isAvailable(_game)
      return true,"Irregular Origin production follower provider"
    end
    function wrapper:resolve(speciesId,variant,targetGame)
      local art=ART[speciesId]
      if art then
        local shiny=variant==true or tostring(variant or ""):lower()=="shiny"
        local image=shiny and art.followerShiny or art.follower
        return {
          id="SPRITE_"..tostring(speciesId)..(shiny and "_SHINY" or ""),
          image=image,frames=6,walker=true,trueColor=true,
          frameWidth=16,frameHeight=16,anchorX=8,anchorY=15,
        },{
          providerId="pokedex",
          providerMod=mod.id,
          usedVariant=shiny and "shiny" or "normal",
          bodyRenderer="NATIVE_SPRITE_RENDERER",
        },nil
      end
      if type(base.resolve)=="function" then
        return base:resolve(speciesId,variant,targetGame)
      end
      return nil,nil,"no follower sprite"
    end

    local okRegister,registered=pcall(ex.registerSpriteProvider,"pokedex",wrapper)
    if okRegister and registered~=false then
      followerProviderInstalled=true
      if type(ex.refreshAllEntitySprites)=="function" then
        pcall(ex.refreshAllEntitySprites,game)
      end
      mod.log:info("Irregular production follower art registered with Wilds of Kanto")
    end
  end

  mod.events:on("game.ready",function(ev)
    installIrregularFollowerProvider((ev and ev.game) or mod.game)
  end)
  pcall(installIrregularFollowerProvider,mod.game)

  local function isIrregular(mon)
    return mon and IRREGULAR[mon.species] == true
  end

  local function makeShiny(mon,game)
    if not (mon and game) then return end
    local dvs={attack=15,defense=10,speed=10,special=10}
    dvs.hp=(dvs.attack%2)*8+(dvs.defense%2)*4+(dvs.speed%2)*2+(dvs.special%2)
    mon.dvs=dvs
    mon.shiny=true
    mon.irregularResonance=true
    local def=game.data and game.data.pokemon and game.data.pokemon[mon.species]
    if def and def.baseStats then
      mon.stats=Stats.calc(def,mon.level or 1,dvs,mon.statExp)
      if mon.stats and mon.stats.hp then mon.hp=mon.stats.hp end
    end
  end

  local function snapshot(save)
    local seen={}
    local function add(list)
      for _,m in ipairs(list or {}) do if type(m)=="table" then seen[m]=true end end
    end
    add(save and save.party)
    for _,box in ipairs(save and save.boxes or {}) do add(box) end
    add(save and save.box)
    return seen
  end

  local function findNew(save,seen)
    local function scan(list)
      for _,m in ipairs(list or {}) do if type(m)=="table" and not seen[m] then return m end end
    end
    local m=scan(save and save.party); if m then return m end
    for _,box in ipairs(save and save.boxes or {}) do m=scan(box); if m then return m end end
    return scan(save and save.box)
  end

  -- Force valid shiny DVs only for the anomaly gift. Regional companion
  -- shininess remains owned by Red Earth Kaizo Bridge.
  mod.hooks:wrap("script.command",function(next,ctx,name,args,...)
    if name~="give_pokemon" or type(args)~="table" or args[1]~=IDS.PSYDREN then
      return next(ctx,name,args,...)
    end
    local game=(ctx and ctx.game) or mod.game
    local save=(ctx and ctx.save) or (game and game.save)
    local seen=snapshot(save)
    local result=next(ctx,name,args,...)
    local mon=findNew(save,seen)
    if mon and mon.species==IDS.PSYDREN then makeShiny(mon,game) end
    return result
  end)

  -- The first touch of Oak's starter table is interrupted by the fated
  -- encounter. EVENT_GOT_STARTER remains false, so the next touch runs
  -- Kaizo's normal region selector and gives the conventional companion.
  mod.hooks:wrap("world.talk",function(next,ow,target)
    local game=mod.game
    local save=game and game.save
    local flags=save and save.flags
    local def=target and target.def
    if not (ow and ow.map and ow.map.id=="OAKS_LAB"
        and flags and flags.EVENT_FOLLOWED_OAK_INTO_LAB
        and not flags.EVENT_GOT_STARTER
        and not flags[GIFT_FLAG]
        and def and STARTER_BALL_TEXTS[def.text]) then
      return next(ow,target)
    end

    target.frozen=true
    local function done() if target then target.frozen=false end end
    ow.runner:run({
      {"show_text","OAK: Wait.\nBefore you choose..."},
      {"show_text","This one isn't from\nany region I know.\fIt was found where\nrecords end."},
      {"show_text","It is unlike any\nPOKéMON we've ever\nstudied.\fI'll leave the rest\nto you."},
      {"text_sound","Get_Key_Item"},
      {"show_text","{RAM} was entrusted\nto you!",{RAM="PSYDREN"}},
      {"give_pokemon",IDS.PSYDREN,5},
      {"jump_if_false","no_room"},
      {"set_flag",GIFT_FLAG},
      {"show_text","OAK: Given its unusual\nnature, choose one of\vthe three as a\vcompanion.\fEvery journey needs\nbalance."},
      {"jump","end"},
      {"label","no_room"},
      {"show_text","OAK: Make room in\nyour party or PC, then\vcome back to me."},
      {"label","end"},
    },{
      npc=target,onDone=done,
      source={modId=mod.id,strict=true,mapId="OAKS_LAB",hook="world.talk"},
    })
    return
  end)

  local function stone(mon) return mon and mon.philosopherStone end

  -- Irregular resonance stacks as a modest SECONDARY property on top of
  -- Philosopher Stones rather than replacing their base effects.
  mod.hooks:wrap("battle.damage",function(next,ctx)
    local damage,info=next(ctx)
    if type(damage)~="number" then return damage,info end
    local battle=ctx and ctx.battle
    local mon=battle and battle.player and battle.player.mon
    if not isIrregular(mon) then return damage,info end
    local s=stone(mon)
    local t=tostring(ctx.move and ctx.move.type or ""):upper()

    if ctx.user==battle.player and s=="PHILOSOPHER_RUBY" then
      damage=math.max(1,math.floor(damage*1.05))
    elseif ctx.target==battle.player and s=="PHILOSOPHER_SAPPHIRE" then
      damage=math.max(1,math.floor(damage*0.94))
    end
    if ctx.user==battle.player and s=="PHILOSOPHER_SOLAR"
        and (t=="PSYCHIC" or t=="PSYCHIC" or t=="DRAGON") then
      damage=math.max(1,math.floor(damage*1.10))
    end
    if ctx.user==battle.player and s=="PHILOSOPHER_TEMPEST" and t=="ELECTRIC" then
      damage=math.max(1,math.floor(damage*1.05))
    end
    return damage,info
  end)

  mod.hooks:wrap("battle.accuracy",function(next,ctx)
    local hit=next(ctx)
    if hit then return true end
    local battle=ctx and ctx.battle
    local mon=battle and battle.player and battle.player.mon
    if not (battle and ctx.user==battle.player and isIrregular(mon)
        and stone(mon)=="PHILOSOPHER_AMETHYST") then return hit end
    local rng=ctx.rng
    if type(rng)=="function" then return rng(1,8)==1 end
    return math.random(1,8)==1
  end)

  mod.events:on("battle.turn_ended",function(ev)
    local battle=ev and ev.battle
    local mon=battle and battle.player and battle.player.mon
    if not (battle and mon and isIrregular(mon)) then return end
    local maxhp=mon.stats and tonumber(mon.stats.hp) or 0
    if maxhp<=0 or (tonumber(mon.hp) or 0)<=0 then return end

    if stone(mon)=="PHILOSOPHER_EMERALD" and mon.hp<maxhp then
      local extra=math.max(1,math.floor(maxhp/48))
      mon.hp=math.min(maxhp,mon.hp+extra)
      battle.player.shownHP=mon.hp
    elseif stone(mon)=="PHILOSOPHER_OBSIDIAN"
        and battle._philosopherObsidianUsed and not battle._irregularObsidianRebound then
      battle._irregularObsidianRebound=true
      local heal=math.max(1,math.floor(maxhp/8))
      mon.hp=math.min(maxhp,mon.hp+heal)
      battle.player.shownHP=mon.hp
    end
  end)

  local RESONANCE_TEXT={
    PHILOSOPHER_RUBY="The RUBY burns brighter.\nIts hunger answers the\nred core within.",
    PHILOSOPHER_SAPPHIRE="The SAPPHIRE quiets.\nIts shell folds around\nthe anomaly.",
    PHILOSOPHER_EMERALD="The EMERALD pulses\nin time with a second\nheartbeat.",
    PHILOSOPHER_AMETHYST="The AMETHYST bends\nprobability around\nthe Irregular.",
    PHILOSOPHER_OBSIDIAN="The OBSIDIAN refuses\nto let the cycle end.",
    PHILOSOPHER_SOLAR="The SOLAR STONE sees\nfire where others see\nonly thought.",
    PHILOSOPHER_MOON="The MOONSTONE knows\nthis creature has died\nbefore.",
    PHILOSOPHER_TEMPEST="The TEMPEST STONE\nrecognizes the storm\ninside.",
  }
  mod.hooks:wrap("ui.party.submenu",function(next,game,items,mon,ctx)
    local out=next(game,items,mon,ctx)
    if type(out)~="table" or (ctx and ctx.battle) or not isIrregular(mon) then return out end
    local s=stone(mon)
    if s and RESONANCE_TEXT[s] then
      out[#out+1]={
        label="RESONANCE",
        onSelect=function()
          game.stack:push(mod.ui.TextBox.new(game,RESONANCE_TEXT[s]))
        end,
      }
    end
    return out
  end)

  -- Atmospheric clues: the anomaly senses Greater Stone sites before the
  -- player knows exactly what is hidden there.
  local SENSE={
    MT_MOON_B2F="A cold pressure\npasses through {RAM}.\fSomething behind the\nrock is answering it.",
    POKEMON_TOWER_7F="{RAM} goes perfectly\nstill.\fFor a moment, you\nhear a second heartbeat.",
    POKEMON_MANSION_B1F="The red core inside\n{RAM} begins to glow.\fHeat is gathering\nbehind the ruined wall.",
    POWER_PLANT="Static crawls across\n{RAM}'s body.\fSomething nearby is\nresonating with it.",
  }
  mod.events:on("map.entered",function(ev)
    local game=(ev and ev.game) or mod.game
    local mapId=game and game.overworld and game.overworld.map and game.overworld.map.id
    local msg=SENSE[mapId]
    if not msg or mod.save:get("sense_"..tostring(mapId),false) then return end
    local lead
    for _,m in ipairs(game.save and game.save.party or {}) do
      if isIrregular(m) then lead=m break end
    end
    if not lead then return end
    mod.save:set("sense_"..tostring(mapId),true)
    local name=lead.nickname or (game.data.pokemon[lead.species] or {}).name or "PSYDREN"
    game.stack:push(mod.ui.TextBox.new(game,msg:gsub("{RAM}",name)))
  end)

  mod.exports.version="1.0.5"
  mod.exports.species=IDS
  mod.exports.isIrregular=isIrregular
end
