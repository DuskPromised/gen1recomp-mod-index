-- Real upstream fill algorithm + actual 48x48 assets, with headless GPU readback.
local unpack = table.unpack
local function data(src)
  local d={w=src.w,h=src.h,pixels={}}
  for i,p in ipairs(src.pixels) do d.pixels[i]={unpack(p)} end
  function d:getDimensions() return self.w,self.h end
  function d:getPixel(x,y) return unpack(self.pixels[y*self.w+x+1]) end
  function d:setPixel(x,y,...) self.pixels[y*self.w+x+1]={...} end
  function d:setFilter() end
  return d
end
local current
love={graphics={}}
local g=love.graphics
function g.getCanvas() return current end
function g.setCanvas(c) current=c end
function g.getBlendMode() return "alpha","alphamultiply" end
function g.setBlendMode() end
function g.getColor() return 1,1,1,1 end
function g.setColor() end
function g.clear() end
function g.newCanvas(w,h,opts)
  assert(opts.dpiscale==1)
  return {newImageData=function(self) return data(self.image) end,release=function() end}
end
function g.draw(img) current.image=img end
function g.newImage(d) return data(d) end
local pics=assert(loadfile(POTATO_PICS))({})
local pinned=true
local ow={backPinned=function() return pinned end}
local state={}
local originalScale=function(d,side,path,species)
  local def=d.pokemon[species]
  local value=def and def[side=="back" and "battleScaleBack" or "battleScaleFront"] or 2
  return math.max(1,math.floor(value+0.5))
end
state.resolveBattleScale=originalScale
package.loaded['src.battle.BattleState']=state
local events={}
local mod={exports={},events={on=function(_,name,fn) events[name]=fn end}}
function mod:find(id)
  assert(id=='potato_voxel')
  return {exports={lib={require=function(name)
    if name=='BattlePics' then return pics else assert(name=='OverworldBattle');return ow end
  end}}}
end
assert(loadfile(PATCH))()(mod)
local inputs={}
for s,f in pairs(fixture) do inputs[s]=data(f) end
local filledCount={}
for s,img in pairs(inputs) do
  local out=pics.filled(img,true)
  local count=0
  for i,p in ipairs(img.pixels) do
    if p[4]==0 and out.pixels[i][4]>0 then count=count+1 end
  end
  filledCount[s]=count
  print('upstream filled transparent pixels',s,count)
end
assert(filledCount.PSYDREN>0 and filledCount.SOLIPSDION>0,'must reproduce actual leg-gap bug')
local defs={}
for s,scale in pairs({PSYDREN=.94,VESPERIS=1,SOLIPSDION=1.05}) do
  defs[s]={trueColor=true,spriteBack=s..'_back',battleScaleBack=scale,battleScaleFront=1}
end
defs.SQUIRTLE={spriteBack='squirtle',battleScaleBack=2}
local d={pokemon=defs}
local trainer=data(fixture.PSYDREN)
local function newBattle(species)
  local b={data=d,dramaticShapeShot={},player={mon={species=species},sprite=inputs[species] or trainer}}
  function b:picImage(img)
    if self.picError then error('intentional pic failure') end
    return pics.filled(self.variant or img,true)
  end
  function b:drawPicsLayer(slide,sx,sy,side)
    if self.drawError then error('intentional draw failure') end
    local s=self.player.mon.species
    return state.resolveBattleScale(self.data,'back',self.path or defs[s].spriteBack,s),
      state.resolveBattleScale(self.data,'back','squirtle','SQUIRTLE'),
      state.resolveBattleScale(self.data,'front','front',s)
  end
  events['battle.started']({battle=b})
  return b
end
local originalFill=pics.filled
for s,expected in pairs({PSYDREN=.94,VESPERIS=1.18,SOLIPSDION=1.365}) do
  local b=newBattle(s)
  local pic=b.picImage
  events['battle.started']({battle=b})
  assert(pic==b.picImage,'installation must be idempotent')
  assert(b:picImage(inputs[s])==inputs[s],'all authored alpha and RGB preserved')
  assert(b:picImage(trainer)==originalFill(trainer,true),'trainer must retain original fill')
  local a,u,f=b:drawPicsLayer(0,0,0,'player')
  assert(math.abs(a-expected)<1e-9 and u==2 and f==1)
  assert(state.resolveBattleScale==originalScale and pics.filled==originalFill)
  b.path='other-provider';assert(b:drawPicsLayer()==1);b.path=nil
  pinned=false;assert(b:drawPicsLayer()==1);assert(b:picImage(inputs[s])==originalFill(inputs[s],true));pinned=true
  b.dramaticShapeShot=nil;assert(b:drawPicsLayer()==1);b.dramaticShapeShot={}
  b.variant=data(fixture[s]);assert(b:picImage(inputs[s])==b.variant,'engine palette variant preserved');b.variant=nil
  b.picError=true;assert(not pcall(b.picImage,b,inputs[s]));b.picError=false
  assert(pics.filled==originalFill,'fill restored after exception')
  b.drawError=true;assert(not pcall(b.drawPicsLayer,b));b.drawError=false
  assert(state.resolveBattleScale==originalScale,'scale restored after exception')
  b.player.mon.species='SQUIRTLE';b.player.sprite=trainer
  assert(b:drawPicsLayer()==2,'switching to another species delegates')
  assert(b:picImage(trainer)==originalFill(trainer,true))
  b.player.mon.species=s;b.player.sprite=inputs[s]
  assert(math.abs(b:drawPicsLayer()-expected)<1e-9,'switching back retains correction')
end
print('PASS: authored alpha, stage scale, palette variants, unrelated species/trainers, switching, restoration')
