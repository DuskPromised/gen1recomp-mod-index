-- Exercise the engine's real manifest parser and dependency enforcement, before
-- the existing runtime tests that invoke module entrypoints directly.
package.path=ENGINE..'/?.lua;'..package.path
-- Lua 5.4 headless runner; production supplies these through LuaJIT.
bit32={}
function bit32.band(a,b,...) local n=(a & b) & 0xffffffff; if select('#',...)>0 then return bit32.band(n,...) end; return n end
function bit32.bor(a,b,...) local n=(a | b) & 0xffffffff; if select('#',...)>0 then return bit32.bor(n,...) end; return n end
function bit32.bxor(a,b,...) local n=(a ~ b) & 0xffffffff; if select('#',...)>0 then return bit32.bxor(n,...) end; return n end
function bit32.bnot(a) return (~a) & 0xffffffff end
function bit32.lshift(a,n) return (a << n) & 0xffffffff end
function bit32.rshift(a,n) return (a & 0xffffffff) >> n end
function bit32.lrotate(a,n) n=n%32; return ((a << n) | ((a & 0xffffffff) >> (32-n))) & 0xffffffff end
local Json=require('src.link.Json')
local Manifest=require('src.mods.Manifest')
local Loader=require('src.mods.Loader')
local function resolve(regression)
  local loader=Loader.new({fs={},generation=1})
  for _,raw in ipairs(Json.decode(MANIFEST_JSON)) do
    if regression and raw.id=='red_earth_irregular_shiny' then raw.version='0.2.1' end
    if regression and (raw.id=='red_earth_gate2_test_harness'
        or raw.id=='red_earth_gate2_presentation') then
      for i,dep in ipairs(raw.dependencies) do
        if dep:match('^red_earth_irregular_shiny@') then
          raw.dependencies[i]='red_earth_irregular_shiny@0.2.0'
        end
      end
    end
    local manifest=Manifest.validate(raw,'mods/'..raw.id)
    loader.mods[raw.id]={manifest=manifest,enabled=true,state='discovered'}
  end
  loader:_enforceDependencies()
  return loader
end
local broken=resolve(true)
for _,id in ipairs({'red_earth_gate2_test_harness','red_earth_gate2_presentation'}) do
  local mod=broken.mods[id]
  assert(mod.state=='blocked_dependency')
  assert(mod.failure:find('needs red_earth_irregular_shiny@0.2.0, found 0.2.1',1,true))
end
print('PASS regression: native Loader reproduces both Gate 2.1 blocked modules')
local fixed=resolve(false)
assert(#fixed.errors==0,table.concat(fixed.errors,'; '))
for id,mod in pairs(fixed.mods) do
  assert(not mod.failed and mod.enabled,id..' must survive dependency resolution')
end
print('PASS packaged manifests: every selected Red Earth dependency is satisfied')
