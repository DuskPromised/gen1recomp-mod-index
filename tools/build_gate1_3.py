"""Deterministic Gate 1.3 compatibility package and cart metadata. No core rebuild."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.3'
MID = 'red_earth_irregular_potato_compat'
BASE = 'https://duskpromised.github.io/gen1recomp-mod-index/'

def read(p): return json.loads((ROOT/p).read_text())
def write(p, obj):
    p=ROOT/p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj,indent=2)+'\n')
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()

if sys.argv[1]=='package':
    # Do not silently replace the user's already-tested core or harness.
    pins={'red_earth_irregular_core':'287f761dc2826b67fb8d1b3ef8364c0333dd3170d6fa4846f5b35df8e8b097b0',
          'red_earth_gate1_test_harness':'78f5c62ac31abc7057ab0ea723175d0f7c6a9e6a52a8ddd00128256438d62a42'}
    for mid, sha in pins.items():
        assert digest(ROOT/f'site/data/mods/DuskPromised@{mid}/{mid}-0.1.2.zip')==sha
    src=ROOT/'mods/red-earth-irregular-potato-compat'
    manifest=read(src/'manifest.json')
    assert manifest['version']==VERSION
    files=sorted(src.iterdir())
    assert {p.name for p in files}=={'main.lua','manifest.json','README.md','LICENSE'}
    out=ROOT/f'site/data/mods/DuskPromised@{MID}/{MID}-{VERSION}.zip'
    out.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in files:
            info=zipfile.ZipInfo(MID+'/'+p.name,(2026,9,17,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=0o100644<<16
            z.writestr(info,p.read_bytes())
    with zipfile.ZipFile(out) as z: assert z.testzip() is None
    sha=digest(out)
    (ROOT/f'custom_mods/{MID}.sha256').write_text(f'{sha}  {out.name}\n')
    idx={
        'folder':f'DuskPromised@{MID}','id':MID,'title':manifest['name'],
        'author':manifest['author'],'version':VERSION,'categories':['GRAPHICS','COMPATIBILITY','DEVELOPMENT'],
        'tags':['red earth','gate 1','potato voxel','compatibility'],
        'api':2,'profile':'content','game_version':manifest['game_version'],
        'permissions':manifest['permissions'],'dependencies':manifest['dependencies'],
        'optional_dependencies':[],'conflicts':[], 'affects_link':False,'experimental':True,
        'repo':'https://github.com/DuskPromised/gen1recomp-mod-index','github':'DuskPromised/gen1recomp-mod-index',
        'license':'MIT','downloadURL':BASE+str(out.relative_to(ROOT/'site')),
        'source_zip':out.name,'summary':manifest['description'],
        'source_scope':'DuskPromised standalone compatibility patch','update_check':'off','sha256':sha}
    write(f'custom_mods/{MID}.index.json',idx)
    cart=read('cart_source/gate_1_irregular_test/cart.json')
    cart['mods']=[m for m in cart['mods'] if m['id']!=MID]
    cart['load_order']=[m for m in cart['load_order'] if m!=MID]
    for m in cart['mods']:
        if m['id'] in pins: assert m['sha256']==pins[m['id']] and m['version']=='0.1.2'
    entry={'id':MID,'source':'github','repo':'DuskPromised/gen1recomp-mod-index','version':VERSION,'sha256':sha}
    cart['mods'].insert(-1,entry)
    cart['load_order'].insert(-1,MID)
    cart['version']=VERSION
    cart['summary']='Gate 1.3 retest: unchanged Core/Harness 0.1.2 plus separate Irregular/Potato compatibility for back alpha and stage sizes.'
    write('cart_source/gate_1_irregular_test/cart.json',cart)
    print('COMPAT',sha,out.stat().st_size)
elif sys.argv[1]=='metadata':
    cart=read('cart_source/gate_1_irregular_test/cart.json')
    out=ROOT/f'site/data/carts/DuskPromised@gate_1_irregular_test/gate_1_irregular_test-{VERSION}.g1rcart'
    sha=digest(out)
    idx=read('carts/gate_1_irregular_test.index.json')
    for key in ('version','summary','mods','load_order'): idx[key]=cart[key]
    idx['latest']={'version':VERSION,'name':VERSION,'prerelease':True,
        'zip':{'name':out.name,'url':BASE+str(out.relative_to(ROOT/'site')),'size':out.stat().st_size,'sha256':sha}}
    write('carts/gate_1_irregular_test.index.json',idx)
    feed=read('site/data/index.json')
    feed['carts']=[idx if c['id']==idx['id'] else c for c in feed['carts']]
    compat=read(f'custom_mods/{MID}.index.json')
    feed['mods']=[m for m in feed['mods'] if m['id']!=MID]+[compat]
    write('site/data/index.json',feed)
    sums=(ROOT/f'custom_mods/{MID}.sha256').read_text()+f'{sha}  {out.name}\n'
    (ROOT/'cart_source/gate_1_irregular_test/gate-1.3-sha256sums.txt').write_text(sums)
    print('CART',sha,out.stat().st_size)
else:
    raise SystemExit('expected package or metadata')
