-- Gate 2 presentation-only recolor of the player's shiny send-out sparkle.
-- The accepted 0.2.0 presentation module still owns timing/audio/anchoring.
-- This module draws an identically-shaped colored sparkle over Crystal's
-- black source pixels; it does not suppress or replace shiny state logic.
local unpack=table.unpack or unpack
local function pack(...) return {n=select("#",...),...} end
local FXBASE="mods/crystal_animated_sprites_with_shiny_visuals/assets/shiny_visuals/"
local SEQUENCE={{6,-8,-18,1},{14,12,-12,1},{22,18,8,1},{30,2,19,1},
                {38,-19,12,1},{46,-22,-7,1},{54,-4,-1,2}}
local GOLD={1.00,0.82,0.28,1.00}
local LILAC={0.78,0.68,1.00,1.00}

return function(mod)
  local installed=setmetatable({},{__mode="k"})
  local image,quads

  local function makeImage()
    if image then return true end
    local ok,data=pcall(love.image.newImageData,FXBASE.."gen2_sparkles.png")
    if not ok or not data then return false end
    data:mapPixel(function(x,y,r,g,b,a)
      if a<=0 then return 0,0,0,0 end
      local c=((x+y)%7==0) and LILAC or GOLD
      return c[1],c[2],c[3],a
    end)
    image=love.graphics.newImage(data)
    image:setFilter("nearest","nearest")
    quads={}
    for i=0,3 do
      quads[i+1]=love.graphics.newQuad(i*16,0,16,16,64,16)
    end
    return true
  end

  local function drawFX(fx,x,y,scale)
    if not makeImage() then return end
    local t=(love.timer.getTime()-fx.started)*60
    local g=love.graphics
    g.push("all")
    g.setColor(1,1,1,1)
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
    local shinyMod=mod:find("red_earth_irregular_shiny")
    local presentation=mod:find("red_earth_gate2_presentation")
    if not(shinyMod and presentation) then return end
    local shiny=shinyMod.exports
    local fx

    local function target(self,battler)
      if not(self and battler and battler==self.player) then return nil end
      local mon=battler.mon
      return mon and shiny.isShiny(mon) and mon or nil
    end

    local innerCry=battle.playEntranceCry
    battle.playEntranceCry=function(self,battler)
      if target(self,battler) then
        fx={mon=battler.mon,battler=battler,started=love.timer.getTime()}
      end
      return innerCry(self,battler)
    end

    local innerPic=battle.drawBattlerPic
    battle.drawBattlerPic=function(self,battler,x,y,scale,...)
      local r=pack(innerPic(self,battler,x,y,scale,...))
      if fx and fx.mon==battler.mon and battler==self.player and target(self,battler)
          and love.timer.getTime()-fx.started<1.5 then
        local img=battler.sprite
        if img then
          drawFX(fx,x+img:getWidth()*scale/2,y+img:getHeight()*scale/2,scale)
        end
      end
      return unpack(r,1,r.n)
    end

    local innerExit=battle.exit
    battle.exit=function(self,...)
      fx=nil
      return innerExit(self,...)
    end

    installed[battle]=true
  end

  mod.events:on("battle.started",function(ev) install(ev and ev.battle) end)
  mod.exports.version="0.2.4"
  mod.exports.palette={gold=GOLD,lilac=LILAC}
end
