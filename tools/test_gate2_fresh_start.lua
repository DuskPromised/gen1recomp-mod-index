package.path=ENGINE..'/?.lua;'..package.path
bit32={}
function bit32.band(a,b,...) local n=(a & b) & 0xffffffff; if select('#',...)>0 then return bit32.band(n,...) end; return n end
function bit32.bor(a,b,...) local n=(a | b) & 0xffffffff; if select('#',...)>0 then return bit32.bor(n,...) end; return n end
function bit32.bxor(a,b,...) local n=(a ~ b) & 0xffffffff; if select('#',...)>0 then return bit32.bxor(n,...) end; return n end
function bit32.bnot(a) return (~a) & 0xffffffff end
function bit32.lshift(a,n) return (a << n) & 0xffffffff end
function bit32.rshift(a,n) return (a & 0xffffffff) >> n end
function bit32.lrotate(a,n) n=n%32; return ((a << n) | ((a & 0xffffffff) >> (32-n))) & 0xffffffff end
package.loaded.bit=bit32
local Json=require('src.link.Json')
love=require('tests.love_stub')
local Loader=require('src.mods.Loader')
local Runtime=require('src.mods.Runtime')
local files=Json.decode(FILES_JSON)
local fs={}
function fs.read(path) return files[path] end
function fs.write(path,body) files[path]=body;return true end
function fs.load(path) if files[path] then return load(files[path],path) end end
function fs.getInfo(path)
 if files[path] then return {type='file'} end
 for k in pairs(files) do if k:sub(1,#path+1)==path..'/' then return {type='directory'} end end
end
function fs.getDirectoryItems(path)
 local out,seen={},{}
 for k in pairs(files) do
  if k:sub(1,#path+1)==path..'/' then
   local n=k:sub(#path+2):match('^[^/]+')
   if not seen[n] then seen[n]=true;out[#out+1]=n end
  end
 end
 table.sort(out);return out
end
local game={data={pokemon={},moves={TACKLE={name='TACKLE',power=35,accuracy=95,pp=35,type='NORMAL',effect='NO_ADDITIONAL_EFFECT'}},text={},items={},constants={}},save={player={name='TEST',id=123},party={},flags={EVENT_FOLLOWED_OAK_INTO_LAB=true},pokedex={seen={},owned={}},inventory={}}}
game.data.type_chart={types={NORMAL={category='physical'},PSYCHIC={category='special'},WATER={category='special'},GHOST={category='physical'},DRAGON={category='special'}},matchups={}}
game.data.audio={cries={MEW={},MEWTWO={},HAUNTER={}}}
function game.data:resolveText() return nil end
local loader=Loader.new({fs=fs,generation=1});loader.game=game;game.mods=loader
assert(loader:load(game.data),table.concat(loader.errors,'; '))
for id,mod in pairs(loader.mods) do assert(mod.state=='loaded',id..': '..tostring(mod.failure)) end
assert(loader.exports.red_earth_irregular_shiny.version=='0.2.0')
assert(loader.exports.red_earth_gate2_test_harness.version=='0.2.0')
assert(loader.exports.red_earth_gate2_presentation.version=='0.2.0')
print('PASS native Loader: packaged 0.2.0 modules and separate pixel extension loaded through sandbox')
-- Only UI presentation is replaced: preserve the native coroutine yield,
-- nickname decision and resume sequence, actual Commands and gift creation.
local boxes={}
require('src.render.TextBox').new=function(g,text,done,opts) return {text=text,done=done,opts=opts} end
game.stack={push=function(_,box) boxes[#boxes+1]=box end}
local BattleState=require('src.battle.BattleState')
local Runner=require('src.script.ScriptRunner')
local Stats=require('src.pokemon.Stats')
local Sprites=require('src.pokemon.Sprites')
local ow={map={id='OAKS_LAB',def={label='OaksLab'}}};ow.runner=Runner.new(game,ow)
local delegated=0
local function talk(text)
 Runtime.call('world.talk',function() delegated=delegated+1 end,ow,{def={text=text}})
 local n=0
 while ow.runner:isRunning() do
  n=n+1;assert(n<30,'script stalled')
  local box=table.remove(boxes,1);assert(box,'expected nickname/dialogue yield')
  if box.opts and box.opts.choice then box.opts.choice(false) else box.done() end
 end
 assert(#loader.errors==0,table.concat(loader.errors,'; '))
end
local left='TEXT_OAKSLAB_CHARMANDER_POKE_BALL'
local center='TEXT_OAKSLAB_SQUIRTLE_POKE_BALL'
local right='TEXT_OAKSLAB_BULBASAUR_POKE_BALL'
talk(left);talk(left);talk(center);talk(right)
assert(#game.save.party==4,'all four QA gifts required')
local function check(mon,shiny)
 assert(Stats.isShiny(mon.dvs)==shiny and mon.shiny==shiny,'incorrect shiny identity: '..mon.species)
 if shiny then assert(mon.dvs.attack==15 and mon.dvs.defense==10 and mon.dvs.speed==10 and mon.dvs.special==10 and mon.dvs.hp==8) end
 for _,side in ipairs({'front','back'}) do
  local path=Sprites.path(game.data,mon.species,side,{mon=mon,kind='battle'})
  if shiny and mon.species=='SOLIPSDION' and side=='back' then
   assert(path=='mods/red_earth_solipsdion_shiny_back_fix/assets/solipsdion_back_shiny.png')
  else
   assert(path:find(shiny and '_shiny.png' or (side..'.png'),1,true),path)
  end
 end
 local menu=Sprites.path(game.data,mon.species,'front',{mon=mon,kind='summary'})
 assert(menu:find(shiny and '_menu_shiny.png' or '_menu.png',1,true),menu)
 local icon=Sprites.iconPath(game.data,mon,nil)
 assert(icon:find(shiny and '_icon_shiny.png' or '_icon.png',1,true),icon)
end
for i,m in ipairs(game.save.party) do check(m,i~=2) end
print('PASS fresh native script: shiny Psydren, normal control, shiny Vesperis/Solipsdion; exact DVs and battle/menu/icon art')
talk(left);assert(delegated==1,'Kaizo handoff after all four gifts')
local Evolution=require('src.pokemon.Evolution')
for i,m in ipairs(game.save.party) do
 if m.species=='PSYDREN' then m.level=16;Evolution.apply(game,m,'VESPERIS','level');check(m,i~=2) end
 if m.species=='VESPERIS' then m.level=36;Evolution.apply(game,m,'SOLIPSDION','level');check(m,i~=2) end
end
local Serializer=require('src.core.SaveSerializer')
game.save=Serializer.decode(Serializer.encode(game.save))
Runtime.emit('save.loaded',{save=game.save})
for i,m in ipairs(game.save.party) do check(m,i~=2) end
print('PASS native evolution and serialization: identities and selected art persist; normal remains normal')

local Boxes=require('src.pokemon.Boxes')
local shinyBox=table.remove(game.save.party,1)
assert(Boxes.deposit(game.save,shinyBox))
local normalBox=table.remove(game.save.party,1)
assert(Boxes.deposit(game.save,normalBox))
game.save.party[1],game.save.party[2]=game.save.party[2],game.save.party[1]
game.save=Serializer.decode(Serializer.encode(game.save))
Runtime.emit('save.loaded',{save=game.save})
check(game.save.boxes[1][1],true);check(game.save.boxes[1][2],false)
for _,m in ipairs(game.save.party) do check(m,true) end
assert(#loader.errors==0,table.concat(loader.errors,'; '))
print('PASS native PC deposit, reorder and reload: shiny/normal state and art preserved')
