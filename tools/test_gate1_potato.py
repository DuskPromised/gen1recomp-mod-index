"""Run Lua behavior tests against the SHA-pinned PotatoVoxel release and real PNGs."""
import ctypes
import ctypes.util
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
archive = Path(sys.argv[1])
assert hashlib.sha256(archive.read_bytes()).hexdigest() == 'f57c83e24fd8252fdc936bc7420ea2bc0439ec253d8a0f9ba11ffa9a06ea9846'
with tempfile.TemporaryDirectory() as td:
    td = Path(td)
    with zipfile.ZipFile(archive) as z:
        z.extractall(td / 'potato')
    lines = ['fixture = {}']
    for species in ('psydren', 'vesperis', 'solipsdion'):
        im = Image.open(ROOT / 'mods/red-earth-irregular-core/assets' / f'{species}_back.png').convert('RGBA')
        pixels = ','.join('{' + ','.join(str(c/255) for c in p) + '}' for p in im.getdata())
        lines.append(f'fixture.{species.upper()} = {{w={im.width},h={im.height},pixels={{{pixels}}}}}')
    lines.append('POTATO_PICS = ' + json.dumps(str(td/'potato/lib/BattlePics.lua')))
    lines.append('PATCH = ' + json.dumps(str(ROOT/'mods/red-earth-irregular-potato-compat/main.lua')))
    lines.append((ROOT/'tools/test_gate1_potato.lua').read_text())
    source = td/'run.lua'
    source.write_text('\n'.join(lines))
    # Use the installed Lua shared library locally; ordinary lua on Actions.
    lib = ctypes.util.find_library('lua5.4')
    if not lib:
        subprocess.run(['lua', str(source)], check=True)
    else:
        lua = ctypes.CDLL(lib)
        lua.luaL_newstate.restype = ctypes.c_void_p
        lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
        lua.luaL_loadfilex.argtypes = [ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
        lua.lua_pcallk.argtypes = [ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
        lua.lua_tolstring.argtypes = [ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = [ctypes.c_void_p]
        state = lua.luaL_newstate()
        lua.luaL_openlibs(state)
        try:
            status = lua.luaL_loadfilex(state, str(source).encode(), None)
            if not status: status = lua.lua_pcallk(state,0,-1,0,0,None)
            if status: raise RuntimeError(lua.lua_tolstring(state,-1,None).decode())
        finally:
            lua.lua_close(state)
