-- Asset-only extension of the accepted Gate 2.0 module's exported art table.
return function(mod)
  local shiny=assert(mod:find("red_earth_irregular_shiny"),"Gate 2.0 shiny module required")
  assert(shiny.version=="0.2.0","This repair is pinned to the accepted Gate 2.0 module")
  local art=assert(shiny.exports.art.SOLIPSDION,"Solipsdion authored art unavailable")
  -- Both the existing sprite router and presentation sizing read this table.
  -- No new sprite hooks, state changes, renderer wrappers or gift behavior.
  art.back=mod.path.."/assets/solipsdion_back_shiny.png"
  mod.exports.version="0.2.3"
end
