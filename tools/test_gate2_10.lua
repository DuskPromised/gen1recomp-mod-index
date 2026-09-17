-- Static/runtime contract checks for Gate 2.10's two narrow Fennekin fixes.
local function eq(a,b,msg)
  assert(a==b,(msg or "mismatch")..": got "..tostring(a).." expected "..tostring(b))
end
local function ok(v,msg) assert(v,msg or "expected truthy") end

-- ---------------- starter shiny contract ----------------
local capturedHooks={}
local capturedEvents={}
local nicknameSawShiny=false
local resumeCount=0
local Stats={}
function Stats.isShiny(d)
  return d and d.attack==15 and d.defense==10 and d.speed==10 and d.special==10
end
function Stats.calc(def,level,dvs,statExp)
  return {hp=50,attack=20,defense=20,speed=20,special=20}
end

local PartyMenu={}
function PartyMenu.drawIcon() return "vanilla-icon" end
local Commands={}
function Commands.show_text(ctx,textId,subs,opts)
  ok(opts and opts.choice,"nickname choice missing")
  opts.choice(true)
end
local Screens={}
function Screens.push(game,id,opts)
  eq(id,"NamingScreen","wrong screen")
  ok(opts.mon and opts.mon.shiny==true,"nickname screen saw non-shiny mon")
  ok(Stats.isShiny(opts.mon.dvs),"nickname screen saw non-shiny DVs")
  nicknameSawShiny=true
  opts.onDone("FOX")
end

package.preload["src.pokemon.Stats"]=function() return Stats end
package.preload["src.ui.PartyMenu"]=function() return PartyMenu end
package.preload["src.render.Assets"]=function() return {resolve=function(p)return p end} end
package.preload["src.render.PaletteFX"]=function() return {markTrueColor=function() end} end
package.preload["src.script.Commands"]=function() return Commands end
package.preload["src.ui.Screens"]=function() return Screens end
package.preload["src.core.Strings"]=function() return setmetatable({}, {__call=function(_,s,...) return select('#',...)>0 and string.format(s,...) or s end}) end
_G.love={graphics={newImage=function() return {getDimensions=function()return 16,32 end} end,
  newQuad=function() return {} end,setColor=function()end,draw=function()end}}

local starterInstaller=dofile("mods/red-earth-gate2-starter-shiny-state-icons/main.lua")
local starterMod={
  path="/mod",
  exports={},
  hooks={wrap=function(_,name,cb,priority) capturedHooks[name]=capturedHooks[name] or {}; table.insert(capturedHooks[name],{cb=cb,priority=priority}) end},
  events={on=function(_,name,cb) capturedEvents[name]=cb end},
  log={info=function() end,warn=function() end},
}
starterInstaller(starterMod)

local function hook(name,priority)
  for _,h in ipairs(capturedHooks[name] or {}) do if h.priority==priority then return h.cb end end
end
local scriptHook=hook("script.command",-10)
local spriteHook=hook("pokemon.sprite",150)
ok(scriptHook,"post-Kaizo script hook missing")
ok(spriteHook,"sprite hook missing")

local game={data={pokemon={FENNEKIN={name="FENNEKIN"}}}}
local save={party={},boxes={},box={},flags={EVENT_FOLLOWED_OAK_INTO_LAB=true}}
local runner={resume=function() resumeCount=resumeCount+1 end}
local ctx={game=game,save=save,runner=runner,overworld={map={id="OAKS_LAB"}},lastCheck=true}

local downstreamArgs
local result=scriptHook(function(hctx,name,args)
  downstreamArgs=args
  eq(name,"give_pokemon","wrong command")
  eq(args[1],"FENNEKIN","Kaizo-selected species changed")
  eq(args[2],5,"starter level changed")
  eq(args[3],true,"native nickname was not suppressed")
  local mon={species="FENNEKIN",level=5,dvs={attack=15,defense=15,speed=15,special=15,hp=15},stats={hp=40},hp=40,statExp={}}
  table.insert(save.party,mon)
  hctx.lastCheck=true
  return "given"
end,ctx,"give_pokemon",{"FENNEKIN",5})
eq(result,"given","downstream result changed")
local fenn=save.party[1]
ok(fenn.shiny==true,"Fennekin not marked shiny")
ok(Stats.isShiny(fenn.dvs),"Fennekin DVs not shiny")
ok(fenn.redEarthGate25StarterShiny==true,"guaranteed marker missing")
eq(fenn.nickname,"FOX","nickname callback failed")
ok(nicknameSawShiny,"nickname screen never saw shiny state")
eq(resumeCount,1,"nickname runner resume count")

-- Custom QA gifts must remain untouched by this production-starter seam.
local passArgs
local pass=scriptHook(function(hctx,name,args) passArgs=args; return "pass" end,
  ctx,"give_pokemon",{"PSYDREN",15})
eq(pass,"pass","custom gift pass-through result")
eq(passArgs[1],"PSYDREN","custom gift species changed")
eq(passArgs[3],nil,"custom gift nickname behavior changed")

-- Preview art uses only a transient marker around the native push_screen.
local previewPath
scriptHook(function(hctx,name,args)
  eq(name,"push_screen","wrong preview command")
  eq(args[2].species,"FENNEKIN","preview species changed")
  previewPath=spriteHook(function(path) return path end,"normal.png",
    {species="FENNEKIN",kind="dex",side="front"})
  return "preview"
end,ctx,"push_screen",{"DexEntryMenu",{species="FENNEKIN",forceOwned=true}})
eq(previewPath,"/mod/assets/battlers/653_front_shiny.png","starter preview did not use shiny art")
local after=spriteHook(function(path) return path end,"normal.png",
  {species="FENNEKIN",kind="dex",side="front"})
eq(after,"normal.png","preview marker leaked outside push_screen")

local froakie
scriptHook(function(hctx,name,args)
  froakie=spriteHook(function(path) return path end,"froakie-normal.png",
    {species="FROAKIE",kind="dex",side="front"})
end,ctx,"push_screen",{"DexEntryMenu",{species="FROAKIE",forceOwned=true}})
eq(froakie,"froakie-normal.png","non-guaranteed starter preview changed")

-- ---------------- starter shiny FX ----------------
local fxEvents={}
local sourceCount=0
local now=0
local lastSource
_G.love={
  timer={getTime=function() return now end},
  audio={newSource=function(path,kind)
    sourceCount=sourceCount+1
    local s={playing=false}
    function s:setLooping() end
    function s:play() self.playing=true end
    function s:isPlaying() return self.playing end
    function s:stop() self.playing=false end
    lastSource=s
    return s
  end},
  image={newImageData=function()
    return {mapPixel=function() end}
  end},
  graphics={
    newImage=function() return {setFilter=function()end,getWidth=function()return 48 end,getHeight=function()return 48 end} end,
    newQuad=function() return {} end,push=function()end,pop=function()end,setColor=function()end,draw=function()end,
  },
}
local fxInstaller=dofile("mods/red-earth-gate2-starter-shiny-fx/main.lua")
local fxMod={
  exports={},
  find=function(self,id)
    if id=="red_earth_gate2_starter_shiny_state_icons" then
      return {exports={isGuaranteed=function(mon) return mon and mon.redEarthGate25StarterShiny==true end}}
    end
  end,
  events={on=function(_,name,cb) fxEvents[name]=cb end},
}
fxInstaller(fxMod)
ok(fxEvents["battle.started"],"battle.started FX hook missing")

local marked={redEarthGate25StarterShiny=true}
local cries=0
local updates=0
local exits=0
local battle={player={mon=marked,sprite={getWidth=function()return 48 end,getHeight=function()return 48 end}}}
battle.drawBattlerPic=function(self,battler,x,y,scale) return "drawn" end
battle.playEntranceCry=function(self,battler) cries=cries+1; return "cry" end
battle.update=function(self,dt) updates=updates+1; return "updated" end
battle.exit=function(self) exits=exits+1; return "exited" end
fxEvents["battle.started"]({battle=battle})
local src=battle:playEntranceCry(battle.player)
ok(src==lastSource and src.playing,"guaranteed starter did not start sparkle audio")
eq(cries,0,"cry played before sparkle completed")
src.playing=false
battle:update(0.016)
eq(cries,1,"cry did not play after sparkle audio")
battle:drawBattlerPic(battle.player,10,10,1)
battle:exit()
eq(exits,1,"battle exit delegation failed")

local normal={}
local normalCries=0
local battle2={player={mon=normal,sprite={getWidth=function()return 48 end,getHeight=function()return 48 end}}}
battle2.drawBattlerPic=function() end
battle2.playEntranceCry=function() normalCries=normalCries+1; return "normal-cry" end
battle2.update=function() end
battle2.exit=function() end
fxEvents["battle.started"]({battle=battle2})
eq(battle2:playEntranceCry(battle2.player),"normal-cry","normal player cry changed")
eq(normalCries,1,"normal mon incorrectly delayed")

print("PASS: Gate 2.10 Fennekin/Grass preview, pre-nickname shiny state, and isolated player sparkle contract")
