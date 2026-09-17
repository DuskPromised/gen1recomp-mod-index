"""Run Gate 2 integration tests against a pinned engine checkout."""
import ctypes
import ctypes.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import zipfile

root=Path(__file__).resolve().parents[1]
engine=Path(sys.argv[1]).resolve()
commands=(engine/'src/script/Commands.lua').read_text()
names=set(re.findall(r'function Commands\.(\w+)\(',commands))
names.update(['label','jump'])
source='ENGINE='+json.dumps(str(engine))+'\nROOT='+json.dumps(str(root))+'\n'
source+='COMMANDS={'+','.join('['+json.dumps(x)+']=true' for x in sorted(names))+'}\n'
if '--fresh-start' in sys.argv:
    cart=json.loads((root/'cart_source/gate_2_irregular_shiny_test/cart.json').read_text())
    files={}
    for pin in cart['mods']:
        mid=pin['id']
        if mid.startswith('red_earth_'):
            with zipfile.ZipFile(root/f"site/data/mods/DuskPromised@{mid}/{mid}-{pin['version']}.zip") as z:
                for name in z.namelist():
                    if name.endswith(('.lua','.json')):files['mods/'+name]=z.read(name).decode()
        else:
            files[f'mods/{mid}/manifest.json']=json.dumps(dict(id=mid,name=mid,version=pin['version'],entry='main.lua'))
            files[f'mods/{mid}/main.lua']='return function(mod) end'
    source+='FILES_JSON='+json.dumps(json.dumps(files))+'\n'
    source+=(root/'tools/test_gate2_fresh_start.lua').read_text()
elif '--dependencies' in sys.argv:
    cart=json.loads((root/'cart_source/gate_2_irregular_shiny_test/cart.json').read_text())
    manifests=[]
    for pin in cart['mods']:
        if pin['id'].startswith('red_earth_'):
            path=root/f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
            with zipfile.ZipFile(path) as z:
                manifest=json.loads(z.read(pin['id']+'/manifest.json'))
            assert manifest['version']==pin['version']
            manifests.append(manifest)
        else:
            # Accepted upstream pin records: only Red Earth manifests are under test.
            manifests.append(dict(id=pin['id'],name=pin['id'],version=pin['version'],entry='main.lua'))
    source+='MANIFEST_JSON='+json.dumps(json.dumps(manifests))+'\n'
    source+=(root/'tools/test_gate2_dependencies.lua').read_text()
else:
    source+=(root/'tools/test_gate2.lua').read_text()
with tempfile.TemporaryDirectory() as td:
    p=Path(td)/'test.lua';p.write_text(source)
    lib=ctypes.util.find_library('lua5.4')
    if not lib:
        subprocess.run(['lua',str(p)],check=True)
    else:
        lua=ctypes.CDLL(lib)
        lua.luaL_newstate.restype=ctypes.c_void_p
        lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
        lua.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
        lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
        lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lua.lua_tolstring.restype=ctypes.c_char_p
        lua.lua_close.argtypes=[ctypes.c_void_p]
        state=lua.luaL_newstate();lua.luaL_openlibs(state)
        try:
            rc=lua.luaL_loadfilex(state,str(p).encode(),None)
            if not rc:rc=lua.lua_pcallk(state,0,-1,0,0,None)
            if rc:raise RuntimeError(lua.lua_tolstring(state,-1,None).decode())
        finally:lua.lua_close(state)
