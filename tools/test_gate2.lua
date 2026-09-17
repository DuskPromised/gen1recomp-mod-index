package.path=ENGINE..'/?.lua;'..package.path
package.loaded['src.core.Logger']={warn=function(...) error('hook warning') end}
local Hooks=require('src.mods.Hooks')
local hooks=Hooks.new()
local listeners={}
local function emit(name,ev) for _,fn in ipairs(listeners[name] or {}) do fn(ev) end end
package.loaded['src.mods.Runtime']={emit=emit,wantsHook=function() return false end}
for _,n in ipairs({'src.core.Music','src.ui.Screens','src.render.TextBox','src.core.Strings','src.core.RomText'}) do package.loaded[n]={} end
local Stats=require('src.pokemon.Stats')
local Pokemon=require('src.pokemon.Pokemon')
local Evolution=require('src.pokemon.Evolution')
local Boxes=require('src.pokemon.Boxes')
local Serializer=require('src.core.SaveSerializer')
local game={data={pokemon={},moves={}},save={party={},flags={EVENT_FOLLOWED_OAK_INTO_LAB=true},pokedex={seen={},owned={}}}}
local function registry(t)
  return {register=function(_,id,v) t[id]=v end,get=function(_,id) return t[id] end,each=function() return pairs(t) end}
end
local mods={}
local function make(id,folder)
  local m={id=id,path='mods/'..id,game=game,exports={},hooks=hooks,
    events={on=function(_,n,fn) listeners[n]=listeners[n] or {};table.insert(listeners[n],fn) end},
    log={info=function() end,warn=function() end}}
  function m:find(n) return mods[n] end
  mods[id]=m
  m.content={pokemon=registry(game.data.pokemon),moves=registry(game.data.moves),text=registry({}),constants={patch=function() end}}
  assert(loadfile(ROOT..'/mods/'..folder..'/main.lua'))()(m)
  return m
end
local core=make('red_earth_irregular_core','red-earth-irregular-core')
local normalSource=Serializer.encode(game.data.pokemon)
local shiny=make('red_earth_irregular_shiny','red-earth-irregular-shiny').exports
assert(normalSource==Serializer.encode(game.data.pokemon),'shiny module must not mutate species records')
game.data.pokemon.SQUIRTLE=game.data.pokemon.PSYDREN
local function mon(s,l) return Pokemon.new(game.data,s,l,function() return 15 end) end
local a=mon('PSYDREN',15);local b=mon('PSYDREN',15)
assert(shiny.makeShiny(a,game) and not shiny.isShiny(b))
assert(a.dvs.hp==8 and a.dvs.attack==15 and a.dvs.defense==10 and a.dvs.speed==10 and a.dvs.special==10 and a.shiny)
local unrelated=mon('SQUIRTLE',5);local before=Serializer.encode(unrelated)
assert(not shiny.makeShiny(unrelated,game) and Serializer.encode(unrelated)==before)
local function path(m,kind,side,species)
  local ctx={species=species or m.species,mon=m,kind=kind,side=side}
  local p=hooks:call('pokemon.sprite',function(p) return p end,'vanilla',ctx)
  assert(ctx.trueColor)
  return p
end
for _,s in ipairs({'PSYDREN','VESPERIS','SOLIPSDION'}) do
  local sm=mon(s,50);shiny.makeShiny(sm,game)
  local nm=mon(s,50)
  for _,side in ipairs({'front','back'}) do
    assert(path(sm,'battle',side)==shiny.art[s][side])
    assert(not path(nm,'battle',side):find('shiny'))
  end
  for _,kind in ipairs({'summary','menu','box','dex'}) do assert(path(sm,kind,'front')==shiny.art[s].menu) end
  assert(hooks:call('pokemon.icon',function(p) return p end,'vanilla',{species=s,mon=sm})==shiny.art[s].icon)
end
assert(path(a,'evolution','front','VESPERIS')==shiny.art.VESPERIS.front)
a.level=16;Evolution.apply(game,a,'VESPERIS','LEVEL');assert(shiny.isShiny(a) and a.shiny)
a.level=36;Evolution.apply(game,a,'SOLIPSDION','LEVEL');assert(shiny.isShiny(a) and a.shiny)
b.level=16;Evolution.apply(game,b,'VESPERIS','LEVEL');assert(not shiny.isShiny(b) and b.shiny==false)
game.save.party={b,a};Boxes.deposit(game.save,table.remove(game.save.party,2))
local save=assert(Serializer.decode(Serializer.encode(game.save)))
save.boxes[1][1].shiny=nil;emit('save.loaded',{save=save})
assert(save.boxes[1][1].shiny and save.boxes[1][1].dvs.hp==8 and save.party[1].shiny==false)
table.insert(save.party,table.remove(save.boxes[1],1));save.party[1],save.party[2]=save.party[2],save.party[1]
assert(shiny.isShiny(save.party[1]) and not shiny.isShiny(save.party[2]))
print('PASS state: native DVs, evolution, serializer, PC boxes, reorder, normal controls, authored routing')

-- Compose actual accepted Gate 1 patch with the new presentation module.
local state={resolveBattleScale=function() return 1 end}
package.loaded['src.battle.BattleState']=state
local filled=function(img) return 'filled:'..tostring(img) end
local pics={filled=filled};local pinned=true
mods.potato_voxel={exports={lib={require=function(n)
  if n=='BattlePics' then return pics end
  assert(n=='OverworldBattle');return {backPinned=function() return pinned end}
end}}}
local g1=make('red_earth_irregular_potato_compat','red-earth-irregular-potato-compat')
local now=0;local draws={};local sounds=0
love={timer={getTime=function() return now end},graphics={},audio={}}
local g=love.graphics
function g.newImage(p) assert(p:find('gen2_sparkles.png'));return {setFilter=function() end} end
function g.newQuad(...) return {...} end
function g.push() end;function g.pop() end;function g.setColor() end
function g.draw(_,_,x,y) draws[#draws+1]={x=x,y=y} end
function love.audio.newSource(p)
  assert(p:find('gen2_shiny_sparkle.mp3'))
  return {setLooping=function() end,play=function(self) self.playing=true;sounds=sounds+1 end,
    stop=function(self) self.playing=false end,isPlaying=function(self) return self.playing end}
end
make('red_earth_gate2_presentation','red-earth-gate2-presentation')
for s,expected in pairs({PSYDREN=.94,VESPERIS=1.18,SOLIPSDION=1.365}) do
  local sm=mon(s,50);shiny.makeShiny(sm,game)
  local img={getWidth=function() return 48 end,getHeight=function() return 48 end}
  local battle={data=game.data,player={mon=sm,sprite=img},dramaticShapeShot={},cries=0}
  function battle:picImage(image) return pics.filled(image) end
  function battle:drawPicsLayer()
    assert(self:picImage(self.player.sprite)==self.player.sprite,'authored alpha bypass must survive')
    if self.fail then error('intentional failure') end
    return state.resolveBattleScale(self.data,'back',self.path or shiny.art[s].back,self.player.mon.species)
  end
  function battle:drawBattlerPic() end
  function battle:playEntranceCry() self.cries=self.cries+1 end
  function battle:update() end;function battle:exit() end
  local prior=state.resolveBattleScale;emit('battle.started',{battle=battle})
  assert(math.abs(battle:drawPicsLayer()-expected)<1e-9)
  battle.fail=true;assert(not pcall(battle.drawPicsLayer,battle));battle.fail=false
  assert(state.resolveBattleScale==prior and pics.filled==filled)
  local src=battle:playEntranceCry(battle.player);assert(src and battle.cries==0)
  now=now+.2;draws={};battle:drawBattlerPic(battle.player,8,96-48*expected,expected)
  assert(#draws>0)
  for _,d in ipairs(draws) do assert(d.x<90 and d.y>0 and d.y<105,'sparkles anchored to back picture') end
  src:stop();battle:update(1/60);battle:update(1/60);assert(battle.cries==1)
  local beforeSounds=sounds;battle.player.mon=mon(s,50)
  battle.path=game.data.pokemon[s].spriteBack
  battle:playEntranceCry(battle.player);assert(sounds==beforeSounds)
  assert(math.abs(battle:drawPicsLayer()-expected)<1e-9,'normal framing still owned by Gate 1')
  battle.player.mon=sm;src=battle:playEntranceCry(battle.player);battle:exit();assert(not src:isPlaying())
end
print('PASS presentation: accepted normal/alpha patch composition, shiny scales, actual anchors, sound/cry, error cleanup')

-- Exercise the QA script flow with real Pokemon.new and Boxes.deposit.
game.save={party={},flags={EVENT_FOLLOWED_OAK_INTO_LAB=true},inventory={}}
make('red_earth_gate2_test_harness','red-earth-gate2-test-harness')
local ow={map={id='OAKS_LAB'},runner={}}
function ow.runner:run(script,opts)
  local ctx={game=game,save=game.save,source=opts.source};local labels={}
  for i,row in ipairs(script) do assert(COMMANDS[row[1]],'unknown command '..row[1]);if row[1]=='label' then labels[row[2]]=i end end
  local i=1
  while i<=#script do
    local row=script[i];local name=row[1];local args={table.unpack(row,2)}
    local jump=hooks:call('script.command',function(c,n,ar)
      if n=='give_pokemon' then
        local m=mon(ar[1],ar[2]);c.lastCheck=true
        if #c.save.party<6 then table.insert(c.save.party,m) else c.lastCheck=Boxes.deposit(c.save,m)~=nil end
      elseif n=='set_flag' then c.save.flags[ar[1]]=true
      elseif n=='check_flag' then c.lastCheck=c.save.flags[ar[1]]
      elseif n=='give_item' then c.save.inventory[ar[1]]=(c.save.inventory[ar[1]] or 0)+ar[2];c.lastCheck=true
      elseif n=='jump_if_false' and not c.lastCheck then return ar[1]
      elseif n=='jump_if_true' and c.lastCheck then return ar[1]
      elseif n=='jump' then return ar[1] end
    end,ctx,name,args)
    if jump=='end' then break end
    i=jump and assert(labels[jump]) or i+1
  end
  opts.onDone()
end
local delegated=0
local function talk(key) hooks:call('world.talk',function() delegated=delegated+1 end,ow,{def={text=key}}) end
local left='TEXT_OAKSLAB_CHARMANDER_POKE_BALL';local center='TEXT_OAKSLAB_SQUIRTLE_POKE_BALL';local right='TEXT_OAKSLAB_BULBASAUR_POKE_BALL'
talk(left);talk(left);talk(center);talk(right)
assert(#game.save.party==4 and shiny.isShiny(game.save.party[1]) and not shiny.isShiny(game.save.party[2]))
assert(game.save.party[3].species=='VESPERIS' and game.save.party[4].species=='SOLIPSDION')
assert(game.save.inventory.RARE_CANDY==50)
talk(left);assert(delegated==1 and #game.save.party==4,'restore Kaizo and prevent duplicate QA gifts')
game.save.flags={EVENT_FOLLOWED_OAK_INTO_LAB=true}
while #game.save.party<6 do table.insert(game.save.party,mon('PSYDREN',5)) end
talk(center);assert(shiny.isShiny(game.save.boxes[1][1]),'overflow gift must get shiny state in box')
print('PASS harness: four gifts, physical order, normal control, one candy grant, duplicate flags, Kaizo handoff, overflow box')
