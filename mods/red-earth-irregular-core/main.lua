-- Red Earth — Gate 1: Irregular Core v0.1.0
-- Clean standalone species/data layer built on the verified Gate 0A foundation.
-- Intentionally NO Oak/starter flow, shiny routing, followers/Wilds, rival/player
-- overrides, passives, Philosopher's Stone logic, or environment mechanics.

local IDS = {
  PSYDREN = "IRR_PSYDREN",
  VESPERIS = "IRR_VESPERIS",
  SOLIPSDION = "IRR_SOLIPSDION",
}

local IRREGULAR = {
  [IDS.PSYDREN] = true,
  [IDS.VESPERIS] = true,
  [IDS.SOLIPSDION] = true,
}

return function(mod)
  local pokemon = mod.content and mod.content.pokemon
  local moves = mod.content and mod.content.moves
  if not (pokemon and moves) then
    mod.log:warn("Red Earth Gate 1: pokemon/moves registry unavailable; core skipped")
    return
  end

  local function existingMove(...)
    local names = {...}
    for _, id in ipairs(names) do
      if id and moves:get(id) then return id end
    end
    return "TACKLE"
  end

  local withdraw   = existingMove("WITHDRAW", "HARDEN")
  local waterGun  = existingMove("WATER_GUN", "WATERGUN")
  local hypnosis  = existingMove("HYPNOSIS")
  local bubbleBeam= existingMove("BUBBLEBEAM", "BUBBLE_BEAM")
  local nightShade= existingMove("NIGHT_SHADE", "NIGHTSHADE")
  local psybeam   = existingMove("PSYBEAM")
  local confuseRay= existingMove("CONFUSE_RAY", "CONFUSERAY")
  local recover   = existingMove("RECOVER")
  local dreamEater= existingMove("DREAM_EATER", "DREAMEATER")
  local amnesia   = existingMove("AMNESIA")
  local aeroblast = existingMove("AEROBLAST", "AERO_BLAST", "RAZOR_WIND")
  local hydroPump = existingMove("HYDRO_PUMP", "HYDROPUMP")
  local psychic   = existingMove("PSYCHIC_M", "PSYCHIC")

  -- Keep Confusion's gameplay identity while using a projectile-style psychic
  -- animation that composes cleanly with PotatoVoxel's 3D battle presentation.
  local confusionAnim = (moves:get(existingMove(
    "PSYBEAM", "CONFUSE_RAY", "PSYCHIC_M", "PSYCHIC"
  )) or {}).anim
  local rageAnim = (moves:get(existingMove("DRAGON_RAGE")) or {}).anim
  local beamAnim = (moves:get(existingMove("HYPER_BEAM")) or {}).anim

  moves:register("IRR_CONFUSION", {
    id="IRR_CONFUSION", name="CONFUSION",
    type="PSYCHIC", power=50, accuracy=100, pp=25,
    effect="CONFUSION_SIDE_EFFECT", category="special", anim=confusionAnim,
  })

  moves:register("IRR_SOVEREIGN_RAGE", {
    id="IRR_SOVEREIGN_RAGE", name="SOVEREIGN RAGE",
    type="DRAGON", power=80, accuracy=100, pp=10,
    effect="NO_ADDITIONAL_EFFECT", category="special", anim=rageAnim,
  })

  -- Gate 1 registers the move as its neutral/default Dragon form.
  -- Gate 11 will own environment-driven secondary typing and Verdict typing.
  moves:register("IRR_SERAPHS_VERDICT", {
    id="IRR_SERAPHS_VERDICT", name="SERAPH'S VERDICT",
    type="DRAGON", power=140, accuracy=90, pp=5,
    effect="HYPER_BEAM_EFFECT", category="special", anim=beamAnim,
  })

  local maxDex = 0
  for _, def in pokemon:each() do
    maxDex = math.max(maxDex, tonumber(def.dex) or 0)
  end
  local d1, d2, d3 = maxDex + 1, maxDex + 2, maxDex + 3

  local ART = {
    [IDS.PSYDREN] = {
      front=mod.path.."/assets/psydren_front.png",
      back=mod.path.."/assets/psydren_back.png",
      menu=mod.path.."/assets/psydren_menu.png",
      icon=mod.path.."/assets/psydren_icon.png",
    },
    [IDS.VESPERIS] = {
      front=mod.path.."/assets/vesperis_front.png",
      back=mod.path.."/assets/vesperis_back.png",
      menu=mod.path.."/assets/vesperis_menu.png",
      icon=mod.path.."/assets/vesperis_icon.png",
    },
    [IDS.SOLIPSDION] = {
      front=mod.path.."/assets/solipsdion_front.png",
      back=mod.path.."/assets/solipsdion_back.png",
      menu=mod.path.."/assets/solipsdion_menu.png",
      icon=mod.path.."/assets/solipsdion_icon.png",
    },
  }

  pokemon:register(IDS.PSYDREN, {
    id=IDS.PSYDREN, name="PSYDREN", dex=d1,
    types={"PSYCHIC","WATER"},
    baseStats={hp=55,attack=40,defense=65,speed=45,special=70},
    catchRate=45, baseExp=80, growthRate="MEDIUM_SLOW",
    level1Moves={"IRR_CONFUSION", withdraw},
    learnset={
      {level=7,move=waterGun},
      {level=11,move=hypnosis},
      {level=14,move=bubbleBeam},
    },
    evolutions={{method="LEVEL",level=16,species=IDS.VESPERIS}},
    spriteFront=ART[IDS.PSYDREN].front,
    spriteBack=ART[IDS.PSYDREN].back,
    frontSize=7, trueColor=true,
    battleScaleFront=1.0, battleScaleBack=1.0,
    icon={image=ART[IDS.PSYDREN].icon,frames=2},
    cry="MEW",
    dexEntry={
      kind="ABYSSAL SEED",heightFt=2,heightIn=4,weight=18.5,
      text="An aquatic anomaly that drifts between dreams and the sea.",
      text2="A crimson light sleeps beneath its calm exterior.",
    },
  })

  pokemon:register(IDS.VESPERIS, {
    id=IDS.VESPERIS, name="VESPERIS", dex=d2,
    types={"PSYCHIC","GHOST"},
    baseStats={hp=70,attack=55,defense=75,speed=80,special=95},
    catchRate=20, baseExp=150, growthRate="MEDIUM_SLOW",
    level1Moves={"IRR_CONFUSION", withdraw},
    learnset={
      {level=16,move=nightShade},
      {level=20,move=psybeam},
      {level=25,move=confuseRay},
      {level=29,move=recover},
      {level=33,move=dreamEater},
    },
    evolutions={{method="LEVEL",level=36,species=IDS.SOLIPSDION}},
    spriteFront=ART[IDS.VESPERIS].front,
    spriteBack=ART[IDS.VESPERIS].back,
    frontSize=7, trueColor=true,
    battleScaleFront=1.0, battleScaleBack=1.0,
    icon={image=ART[IDS.VESPERIS].icon,frames=2},
    cry="HAUNTER",
    dexEntry={
      kind="GRAVEKEEPER STORM",heightFt=4,heightIn=11,weight=71.0,
      text="Its first body dissolves into a violent psychic wraith.",
      text2="It survives the space between life and death by mastering it.",
    },
  })

  pokemon:register(IDS.SOLIPSDION, {
    id=IDS.SOLIPSDION, name="SOLIPSDION", dex=d3,
    types={"PSYCHIC","DRAGON"},
    baseStats={hp=95,attack=85,defense=105,speed=105,special=125},
    catchRate=3, baseExp=220, growthRate="MEDIUM_SLOW",
    level1Moves={"IRR_CONFUSION", nightShade},
    learnset={
      {level=36,move="IRR_SOVEREIGN_RAGE"},
      {level=42,move=amnesia},
      {level=49,move=aeroblast},
      {level=57,move=hydroPump},
      {level=65,move=psychic},
      {level=75,move="IRR_SERAPHS_VERDICT"},
    },
    evolutions={},
    spriteFront=ART[IDS.SOLIPSDION].front,
    spriteBack=ART[IDS.SOLIPSDION].back,
    frontSize=7, trueColor=true,
    battleScaleFront=1.0, battleScaleBack=1.0,
    icon={image=ART[IDS.SOLIPSDION].icon,frames=2},
    cry="MEWTWO",
    dexEntry={
      kind="SOVEREIGN APEX",heightFt=7,heightIn=2,weight=269.0,
      text="Seven wings surround a body shaped by repeated transmutation.",
      text2="Its presence bends the boundary between thought and matter.",
    },
  })

  if mod.content.constants then
    mod.content.constants:patch("dexSize", d3)
  end

  -- Species-specific art routing only. No global scale or renderer mutation.
  -- Summary/Dex/menu requests receive the dedicated compact portrait.
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    if not ctx then return next(path, ctx) end
    local species = ctx.species or (ctx.mon and ctx.mon.species)
    local art = ART[species]
    if not art then return next(path, ctx) end
    ctx.trueColor = true

    local chosen
    if ctx.kind=="summary" or ctx.kind=="dex" or ctx.kind=="menu" or ctx.kind=="box" then
      chosen = art.menu
    elseif ctx.side=="back" then
      chosen = art.back
    else
      chosen = art.front
    end
    return next(chosen, ctx)
  end, 125)

  mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
    if not ctx then return next(path, ctx) end
    local species = ctx.species or (ctx.mon and ctx.mon.species)
    local art = ART[species]
    if not art then return next(path, ctx) end
    ctx.trueColor = true
    return next(art.icon, ctx)
  end, 125)

  -- Gate 1 save/load invariant audit. The engine serializes the stable species
  -- string IDs; this audit deliberately does not mutate party/box data.
  mod.events:on("game.ready", function(ev)
    local game = (ev and ev.game) or mod.game
    local save = game and game.save
    if not save then return end

    local count = 0
    local function scan(list)
      for _, mon in ipairs(list or {}) do
        if type(mon)=="table" and IRREGULAR[mon.species] then count = count + 1 end
      end
    end
    scan(save.party)
    for _, box in ipairs(save.boxes or {}) do scan(box) end
    scan(save.box)

    if count > 0 then
      mod.log:info("Gate 1 save audit: "..tostring(count).." Irregular mon(s) restored by stable species ID")
    end
  end)

  mod.exports.version = "0.1.0"
  mod.exports.species = IDS
  mod.exports.isIrregular = function(mon)
    return mon and IRREGULAR[mon.species] == true
  end
end
