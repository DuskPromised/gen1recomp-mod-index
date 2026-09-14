-- Irregular Origin v1.0.4
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

-- Production art map. Normal and shiny are deliberately separate authored
-- assets; shiny selection is resolved per individual at runtime.
local ART_FILES={
  [IDS.PSYDREN]={
    normal={front="psydren_front.png",back="psydren_back.png",menu="psydren_menu.png",
      icon="psydren_icon.png",follower="psydren_follower.png"},
    shiny={front="psydren_front_shiny.png",back="psydren_back_shiny.png",
      menu="psydren_menu_shiny.png",icon="psydren_icon_shiny.png",
      follower="psydren_follower_shiny.png"},
  },
  [IDS.VESPERIS]={
    normal={front="vesperis_front.png",back="vesperis_back.png",menu="vesperis_menu.png",
      icon="vesperis_icon.png",follower="vesperis_follower.png"},
    shiny={front="vesperis_front_shiny.png",back="vesperis_back_shiny.png",
      menu="vesperis_menu_shiny.png",icon="vesperis_icon_shiny.png",
      follower="vesperis_follower_shiny.png"},
  },
  [IDS.SOLIPSDION]={
    normal={front="solipsdion_front.png",back="solipsdion_back.png",
      menu="solipsdion_menu.png",icon="solipsdion_icon.png",
      follower="solipsdion_follower.png"},
    shiny={front="solipsdion_front_shiny.png",back="solipsdion_back_shiny.png",
      menu="solipsdion_menu_shiny.png",icon="solipsdion_icon_shiny.png",
      follower="solipsdion_follower_shiny.png"},
  },
}
local SHINY_ATTACK_DVS={ [2]=true,[3]=true,[6]=true,[7]=true,[10]=true,[11]=true,[14]=true,[15]=true }

local function irregularIsShiny(mon)
  if not mon then return false end
  if mon.shiny==true or mon.isShiny==true then return true end
  local d=mon.dvs
  return d and d.defense==10 and d.speed==10 and d.special==10
    and SHINY_ATTACK_DVS[d.attack]==true or false
end

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

  local function artPath(species,variant,kind)
    local row=ART_FILES[species]
    row=row and row[variant]
    local name=row and row[kind]
    return name and (mod.path.."/assets/"..name) or nil
  end

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
    spriteFront=artPath(IDS.PSYDREN,"normal","front"),
    spriteBack=artPath(IDS.PSYDREN,"normal","back"),
    frontSize=7,trueColor=true,battleScaleFront=1.0,battleScaleBack=1.0,
    icon={image=artPath(IDS.PSYDREN,"normal","icon"),frames=2},
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
    spriteFront=artPath(IDS.VESPERIS,"normal","front"),
    spriteBack=artPath(IDS.VESPERIS,"normal","back"),
    frontSize=7,trueColor=true,battleScaleFront=1.0,battleScaleBack=1.0,
    icon={image=artPath(IDS.VESPERIS,"normal","icon"),frames=2},
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
    spriteFront=artPath(IDS.SOLIPSDION,"normal","front"),
    spriteBack=artPath(IDS.SOLIPSDION,"normal","back"),
    frontSize=7,trueColor=true,battleScaleFront=1.0,battleScaleBack=1.0,
    icon={image=artPath(IDS.SOLIPSDION,"normal","icon"),frames=2},
    cry="MEWTWO",
    dexEntry={kind="SOVEREIGN APEX",heightFt=7,heightIn=2,weight=269.0,
      text="Seven wings surround a body shaped by repeated transmutation.",
      text2="The red core in its chest resonates with impossible relics."},
  })

  if mod.content.constants then
    mod.content.constants:patch("dexSize",d3)
  end

  -- Every battle/summary image load passes through pokemon.sprite. Route the
  -- Irregular line to its authored shiny sheet without mutating the frozen
  -- species registry or relying on a palette swap.
  mod.hooks:wrap("pokemon.sprite",function(next,path,ctx)
    local result=next(path,ctx)
    if not (ctx and IRREGULAR[ctx.species]) then return result end
    local variant=irregularIsShiny(ctx.mon) and "shiny" or "normal"
    local kind
    if ctx.kind=="summary" or ctx.kind=="box" then
      kind="menu"
    elseif ctx.side=="back" then
      kind="back"
    else
      kind="front"
    end
    local chosen=artPath(ctx.species,variant,kind)
    if chosen then
      ctx.trueColor=true
      return chosen
    end
    return result
  end,120)

  -- Party/menu icons have their own sanctioned runtime seam.
  mod.hooks:wrap("pokemon.icon",function(next,path,ctx)
    local result=next(path,ctx)
    if not (ctx and IRREGULAR[ctx.species]) then return result end
    local variant=irregularIsShiny(ctx.mon) and "shiny" or "normal"
    local chosen=artPath(ctx.species,variant,"icon")
    if chosen then
      ctx.trueColor=true
      return chosen
    end
    return result
  end,120)

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

  -- Wilds already owns follower rendering. At game.ready (after all mods have
  -- loaded), wrap its Pokédex fallback provider so custom Irregular species use
  -- our dedicated six-frame walker sheets while every other species delegates
  -- to Wilds unchanged.
  local wildsArtInstalled=false
  local function installWildsArt(game)
    if wildsArtInstalled then return end
    local wilds=mod:find("overworld_wild_spawns")
    local ex=wilds and wilds.exports
    if not (ex and type(ex.getSpriteProvider)=="function"
        and type(ex.registerSpriteProvider)=="function") then return end
    local base=ex.getSpriteProvider("pokedex")
    if not (base and type(base.resolve)=="function") then return end

    local function irregularSpeciesKey(speciesId,g)
      if IRREGULAR[speciesId] then return speciesId end
      local dex=tonumber(speciesId)
      local rows=g and g.data and g.data.pokemon
      if dex and type(rows)=="table" then
        for id,def in pairs(rows) do
          if IRREGULAR[id] and tonumber(def and def.dex)==dex then return id end
        end
      end
      return nil
    end

    local provider={
      id="pokedex",builtin=true,modId=mod.id,
      isAvailable=function() return true,"Irregular art + Pokédex fallback" end,
      resolve=function(_,speciesId,variant,g)
        local species=irregularSpeciesKey(speciesId,g)
        if species then
          local want=(variant=="shiny" or variant==true) and "shiny" or "normal"
          local art=ART_FILES[species][want]
          return {
            id="SPRITE_"..species.."_"..want,
            image=mod.path.."/assets/"..art.follower,
            frames=6,walker=true,trueColor=true,
            frameWidth=16,frameHeight=16,anchorX=8,anchorY=16,
          },{
            usedVariant=want,providerMod=mod.id,
            bodyRenderer="NATIVE_SPRITE_RENDERER",
          },nil
        end
        return base.resolve(base,speciesId,variant,g)
      end,
    }
    local ok,err=ex.registerSpriteProvider("pokedex",provider)
    if ok~=false then
      wildsArtInstalled=true
      mod.log:info("Irregular production follower art installed")
      if type(ex.refreshAllEntitySprites)=="function" then
        pcall(ex.refreshAllEntitySprites,game)
      end
    else
      mod.log:warn("Irregular follower art provider failed: %s",tostring(err))
    end
  end

  mod.events:on("game.ready",function(ev)
    installWildsArt((ev and ev.game) or mod.game)
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

  mod.exports.version="1.0.4"
  mod.exports.species=IDS
  mod.exports.isIrregular=isIrregular
end
