-- Red Earth — Gate 1 Test Harness v0.1.0
-- TEST-ONLY. Never merge this acquisition behavior into the production core.

local IDS={
  PSYDREN="IRR_PSYDREN",
  VESPERIS="IRR_VESPERIS",
  SOLIPSDION="IRR_SOLIPSDION",
}

local TESTS={
  TEXT_OAKSLAB_BULBASAUR_POKE_BALL={
    species=IDS.PSYDREN,level=15,flag="MOD_RE_G1_TEST_PSYDREN",
    name="PSYDREN",label="PSYDREN Lv.15",
  },
  TEXT_OAKSLAB_CHARMANDER_POKE_BALL={
    species=IDS.VESPERIS,level=35,flag="MOD_RE_G1_TEST_VESPERIS",
    name="VESPERIS",label="VESPERIS Lv.35",
  },
  TEXT_OAKSLAB_SQUIRTLE_POKE_BALL={
    species=IDS.SOLIPSDION,level=50,flag="MOD_RE_G1_TEST_SOLIPSDION",
    name="SOLIPSDION",label="SOLIPSDION Lv.50",
  },
}

local FLAGS={
  "MOD_RE_G1_TEST_PSYDREN",
  "MOD_RE_G1_TEST_VESPERIS",
  "MOD_RE_G1_TEST_SOLIPSDION",
}

return function(mod)
  local function allDone(flags)
    if type(flags)~="table" then return false end
    for _,f in ipairs(FLAGS) do
      if flags[f]~=true then return false end
    end
    return true
  end

  local function runText(ow,target,text)
    target.frozen=true
    ow.runner:run({
      {"show_text",text},
    },{
      npc=target,
      onDone=function() if target then target.frozen=false end end,
      source={modId=mod.id,strict=true,mapId="OAKS_LAB",hook="world.talk"},
    })
  end

  mod.hooks:wrap("world.talk",function(next,ow,target)
    local game=mod.game
    local save=game and game.save
    local flags=save and save.flags
    local def=target and target.def
    local test=def and TESTS[def.text]

    if not (ow and ow.map and ow.map.id=="OAKS_LAB"
        and flags and flags.EVENT_FOLLOWED_OAK_INTO_LAB==true
        and flags.EVENT_GOT_STARTER~=true
        and test) then
      return next(ow,target)
    end

    -- Once all three QA gifts have been collected, restore the balls completely
    -- to Kaizo so the player can make the real regional starter choice.
    if allDone(flags) then
      return next(ow,target)
    end

    if flags[test.flag]==true then
      runText(ow,target,
        "GATE 1 TEST:\nThis ball already dispensed\n"..test.label..
        ".\fUse one of the other\nballs to continue QA.")
      return
    end

    target.frozen=true
    ow.runner:run({
      {"show_text","GATE 1 TEST HARNESS\fPreviewing "..test.name..
        ".\nThis is QA only."},
      {"push_screen","DexEntryMenu",{species=test.species,forceOwned=true}},
      {"give_pokemon",test.species,test.level},
      {"jump_if_false","no_room"},
      {"set_flag",test.flag},
      {"show_text",test.name.." Lv."..tostring(test.level)..
        " was added.\fCheck battle, PARTY,\nSUMMARY and save/reload."},
      {"jump","end"},
      {"label","no_room"},
      {"show_text","No room for the test\nPOKéMON. Make space\nand touch this ball again."},
      {"label","end"},
    },{
      npc=target,
      onDone=function() if target then target.frozen=false end end,
      source={modId=mod.id,strict=true,mapId="OAKS_LAB",hook="world.talk"},
    })
    return
  end)

  mod.exports.version="0.1.0"
  mod.exports.testOnly=true
end
