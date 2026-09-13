-- Take the Last Starter v1.0.0
-- Red/Blue: after the normal Oak's Lab choice and rival pick, the one
-- remaining starter ball can be claimed once as a second starter.
--
-- The gift intentionally goes through the engine's normal give_pokemon
-- command. That means compatibility mods listening to pokemon.before_give
-- or script.command -- including Shiny Gifts & Starters -- see it normally.

return function(mod)
  local BALLS = {
    TEXT_OAKSLAB_CHARMANDER_POKE_BALL = {
      species = "CHARMANDER",
      object = "OAKSLAB_CHARMANDER_POKE_BALL",
    },
    TEXT_OAKSLAB_SQUIRTLE_POKE_BALL = {
      species = "SQUIRTLE",
      object = "OAKSLAB_SQUIRTLE_POKE_BALL",
    },
    TEXT_OAKSLAB_BULBASAUR_POKE_BALL = {
      species = "BULBASAUR",
      object = "OAKSLAB_BULBASAUR_POKE_BALL",
    },
  }

  local CLAIMED_FLAG = "MOD_TAKE_LAST_STARTER_CLAIMED"

  mod.hooks:wrap("world.talk", function(next, ow, target)
    local game = mod.game
    local save = game and game.save
    local flags = save and save.flags
    local def = target and target.def
    local info = def and BALLS[def.text]

    -- Not one of Oak's three starter balls, not in Oak's Lab, or the normal
    -- first-starter sequence has not happened yet: preserve the engine/mod
    -- stack exactly as-is.
    if not (ow and ow.map and ow.map.id == "OAKS_LAB"
        and info and flags and flags.EVENT_GOT_STARTER) then
      return next(ow, target)
    end

    -- Normally the claimed ball is already hidden persistently. This guard
    -- also prevents a duplicate gift if another mod restores the object.
    if flags[CLAIMED_FLAG] then
      return next(ow, target)
    end

    target.frozen = true
    local function done()
      if target then target.frozen = false end
    end

    local rows = {
      { "show_text", "The last POKéMON\nis {RAM}!", { RAM = info.species } },
      { "ask", "Take it with you?" },
      { "jump_if_false", "end" },

      { "text_sound", "Get_Key_Item" },
      { "show_text", "_OaksLabReceivedMonText", { RAM = info.species } },

      -- This is the important compatibility seam. Shiny Gifts & Starters
      -- wraps this command, recognizes Bulbasaur/Charmander/Squirtle as
      -- starters, and applies real shiny DVs when SHINY STARTERS is enabled.
      { "give_pokemon", info.species, 5 },
      { "jump_if_false", "no_room" },

      { "hide_object", "OAKS_LAB", info.object },
      { "set_flag", CLAIMED_FLAG },
      { "show_text", "Take good care of\nboth POKéMON!" },
      { "jump", "end" },

      { "label", "no_room" },
      { "show_text", "There's no room for\nanother POKéMON!" },
      { "label", "end" },
    }

    ow.runner:run(rows, {
      npc = target,
      onDone = done,
      source = {
        modId = mod.id,
        strict = true,
        mapId = "OAKS_LAB",
        hook = "world.talk",
      },
    })

    -- Deliberately do not call next(): for the one remaining ball, this mod
    -- replaces vanilla's "That's PROF.OAK's last Pokémon!" response.
    return
  end)

  mod.exports.version = "1.0.0"
end
