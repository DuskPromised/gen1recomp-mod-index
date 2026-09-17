-- Separate Gate 2 compatibility: shiny paths retain Gate 1 back framing,
-- and the player's send-out uses Crystal's standard Gen 2 sparkle + audio.
local unpack=table.unpack or unpack
local function pack(...) return {n=select("#",...),...} end
local FACTOR={PSYDREN=1,VESPERIS=1.18,SOLIPSDION=1.30}
local FXBASE="mods/crystal_animated_sprites_with_shiny_visuals/assets/shiny_visuals/"
local SEQUENCE={{6,-8,-18,1},{14,12,-12,1},{22,18,8,1},{30,2,19,1},
                {38,-19,12,1},{46,-22,-7,1},{54,-4,-1,2}}
return function(mod)
  local installed=setmetatable({},{__mode="k"})
  local image,quads
  local function drawFX(fx,x,y,scale)
    if not image then
      image=love.graphics.newImage(FXBASE.."gen2_sparkles.png")
      image:setFilter("nearest","nearest");quads={}
      for i=0,3 do quads[i+1]=love.graphics.newQuad(i*16,0,16,16,64,16) end
    end
    local t=(love.timer.getTime()-fx.started)*60
    local g=love.graphics
    g.push("all");g.setColor(1,1,1,1)
    for _,v in ipairs(SEQUENCE) do
      local age=t-v[1]
      if age>=0 and age<24 then
        local frame=age<4 and 1 or age<9 and 2 or age<15 and 3 or age<20 and 4 or 1
        g.draw(image,quads[frame],math.floor(x+v[2]*scale),math.floor(y+v[3]*scale),0,v[4],v[4],8,8)
      end
    end
    g.pop()
  end
  local function install(battle)
    if not battle or installed[battle] then return end
    local shiny=mod:find("red_earth_irregular_shiny")
    local potato=mod:find("potato_voxel")
    if not(shiny and potato and potato.exports.lib) then return end
    shiny=shiny.exports
    local ow=potato.exports.lib.require("OverworldBattle")
    local state=require("src.battle.BattleState")
    local fx
    local function target(self)
      local mon=self.player and self.player.mon
      return mon and shiny.isShiny(mon) and mon or nil
    end
    local innerDraw=battle.drawPicsLayer
    battle.drawPicsLayer=function(self,slide,sx,sy,onlySide,skipMenuClip)
      local mon=target(self)
      if not(mon and self.dramaticShapeShot and ow.backPinned() and onlySide~="enemy") then
        return innerDraw(self,slide,sx,sy,onlySide,skipMenuClip)
      end
      local prior=state.resolveBattleScale
      state.resolveBattleScale=function(data,side,path,species)
        if data==self.data and side=="back" and species==mon.species
            and path==shiny.art[species].back then
          return data.pokemon[species].battleScaleBack*FACTOR[species]
        end
        return prior(data,side,path,species)
      end
      local r=pack(pcall(innerDraw,self,slide,sx,sy,onlySide,skipMenuClip))
      state.resolveBattleScale=prior
      if not r[1] then error(r[2],0) end
      return unpack(r,2,r.n)
    end
    -- drawBattlerPic supplies the actual final coordinates and effective scale;
    -- no guessed screen/player position or permanent renderer replacement.
    local innerPic=battle.drawBattlerPic
    battle.drawBattlerPic=function(self,battler,x,y,scale,...)
      local r=pack(innerPic(self,battler,x,y,scale,...))
      if fx and fx.mon==battler.mon and battler==self.player and target(self)
          and love.timer.getTime()-fx.started<1.5 then
        local img=battler.sprite
        drawFX(fx,x+img:getWidth()*scale/2,y+img:getHeight()*scale/2,scale)
      end
      return unpack(r,1,r.n)
    end
    local innerCry=battle.playEntranceCry
    battle.playEntranceCry=function(self,battler)
      if battler~=self.player or not target(self) then return innerCry(self,battler) end
      local ok,source=pcall(love.audio.newSource,FXBASE.."gen2_shiny_sparkle.mp3","static")
      if not ok then return innerCry(self,battler) end
      if fx and fx.source then fx.source:stop() end
      fx={mon=battler.mon,battler=battler,source=source,started=love.timer.getTime()}
      source:setLooping(false);source:play()
      return source
    end
    local innerUpdate=battle.update
    battle.update=function(self,dt)
      local r=pack(innerUpdate(self,dt))
      if fx and not fx.cried and not fx.source:isPlaying() then
        fx.cried=true
        if self.player and self.player.mon==fx.mon then innerCry(self,fx.battler) end
      end
      return unpack(r,1,r.n)
    end
    local innerExit=battle.exit
    battle.exit=function(self,...)
      if fx then fx.source:stop();fx=nil end
      return innerExit(self,...)
    end
    installed[battle]=true
  end
  mod.events:on("battle.started",function(ev) install(ev and ev.battle) end)
  mod.exports.version="0.2.2"
end
