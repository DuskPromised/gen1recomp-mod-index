"""Run Gate 2 integration tests against a pinned engine checkout."""
import ctypes
import ctypes.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

root=Path(__file__).resolve().parents[1]
engine=Path(sys.argv[1]).resolve()
commands=(engine/'src/script/Commands.lua').read_text()
names=set(re.findall(r'function Commands\.(\w+)\(',commands))
names.update(['label','jump'])
source='ENGINE='+json.dumps(str(engine))+'\nROOT='+json.dumps(str(root))+'\n'
source+='COMMANDS={'+','.join('['+json.dumps(x)+']=true' for x in sorted(names))+'}\n'
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
