"""Deterministic, separately packaged Gate 2 modules and QA cart."""
import hashlib
import json
from pathlib import Path
import shutil
import sys
import zipfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
BASE='https://duskpromised.github.io/gen1recomp-mod-index/'
VERSION='0.2.0'
MODULES=['red-earth-irregular-shiny','red-earth-gate2-presentation','red-earth-gate2-test-harness']
CID='gate_2_irregular_shiny_test'
def read(p):return json.loads((ROOT/p).read_text())
def write(p,obj):
    p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(obj,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

if sys.argv[1]=='package':
    frozen=ROOT/'site/data/carts/DuskPromised@gate_1_irregular_test/gate_1_irregular_test-0.1.3.g1rcart'
    assert sha(frozen)=='c02e65b22113d821b189157d45794b8efcfc76cb4eefda9b7287bdd74b96a707'
    for mid,ver,digest in [
        ('red_earth_irregular_core','0.1.2','287f761dc2826b67fb8d1b3ef8364c0333dd3170d6fa4846f5b35df8e8b097b0'),
        ('red_earth_irregular_potato_compat','0.1.3','3fcafd38926ca2f37cfde091cbbaa9ee5d43c6d60b8001cd7ad0557e68f6a9ba')]:
        assert sha(ROOT/f'site/data/mods/DuskPromised@{mid}/{mid}-{ver}.zip')==digest
    source=ROOT/'mods/red-earth-irregular-shiny'
    sources=read(source/'art-sources.json')
    assets=source/'assets';assets.mkdir(exist_ok=True)
    assert len(sources)==12
    for name,rec in sources.items():
        original=ROOT/rec['source'];assert sha(original)==rec['sha256']
        with Image.open(original) as im:
            im.load();assert im.mode=='RGBA' and list(im.size)==rec['size']
            assert im.getchannel('A').getextrema()==(0,255)
        shutil.copyfile(original,assets/name)
    assert {p.name for p in assets.iterdir()}==set(sources)
    pins=[]
    for folder in MODULES:
        src=ROOT/'mods'/folder;manifest=read(src/'manifest.json');mid=manifest['id']
        assert manifest['version']==VERSION
        out=ROOT/f'site/data/mods/DuskPromised@{mid}/{mid}-{VERSION}.zip'
        out.parent.mkdir(parents=True,exist_ok=True)
        with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
            for path in sorted(p for p in src.rglob('*') if p.is_file()):
                info=zipfile.ZipInfo(mid+'/'+str(path.relative_to(src)),(2026,9,17,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
                z.writestr(info,path.read_bytes())
        with zipfile.ZipFile(out) as z:assert z.testzip() is None
        digest=sha(out)
        idx={'folder':f'DuskPromised@{mid}','id':mid,'title':manifest['name'],
            'author':manifest['author'],'version':VERSION,'categories':[manifest['category'],'DEVELOPMENT'],
            'tags':['red earth','gate 2','standalone'],'api':2,'profile':'content',
            'game_version':manifest['game_version'],'permissions':manifest['permissions'],
            'dependencies':manifest['dependencies'],'conflicts':manifest.get('conflicts',[]),
            'experimental':True,'repo':'https://github.com/DuskPromised/gen1recomp-mod-index',
            'github':'DuskPromised/gen1recomp-mod-index','license':'MIT',
            'downloadURL':BASE+str(out.relative_to(ROOT/'site')),'source_zip':out.name,
            'summary':manifest['description'],'source_scope':'DuskPromised standalone Gate 2 module',
            'update_check':'off','sha256':digest}
        write(f'custom_mods/{mid}.index.json',idx)
        (ROOT/f'custom_mods/{mid}.sha256').write_text(f'{digest}  {out.name}\n')
        pins.append({'id':mid,'source':'github','repo':'DuskPromised/gen1recomp-mod-index','version':VERSION,'sha256':digest})
        print('MODULE',mid,digest,out.stat().st_size)
    cart=read('cart_source/gate_1_irregular_test/cart.json')
    cart.update(id=CID,title='Gate 2 — Irregular Shiny Test',version=VERSION,
        summary='Gate 2 QA: authored shiny art/state, player sparkle, three shiny gifts and a normal control on accepted Gate 1.')
    cart['mods']=[m for m in cart['mods'] if m['id']!='red_earth_gate1_test_harness']+pins
    cart['load_order']=['gen1_kaizo','potato_voxel','crystal_animated_sprites_with_shiny_visuals',
        'red_earth_irregular_core','red_earth_irregular_shiny','red_earth_irregular_potato_compat',
        'red_earth_gate2_presentation','red_earth_gate2_test_harness','performance_monitor']
    assert len(cart['summary'])<=120
    write(f'cart_source/{CID}/cart.json',cart)
    shutil.copyfile(ROOT/'cart_source/gate_1_irregular_test/label.png',ROOT/f'cart_source/{CID}/label.png')
    (ROOT/f'site/data/carts/DuskPromised@{CID}').mkdir(parents=True,exist_ok=True)
elif sys.argv[1]=='metadata':
    cart=read(f'cart_source/{CID}/cart.json')
    out=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{VERSION}.g1rcart'
    digest=sha(out)
    idx=read('carts/gate_1_irregular_test.index.json')
    for key in ('id','title','version','summary','mods','load_order'):idx[key]=cart[key]
    idx['folder']='DuskPromised@'+CID;idx['tags']=['gate 2','red earth','qa','shiny','development']
    idx['latest']={'version':VERSION,'name':VERSION,'prerelease':True,'zip':{'name':out.name,
        'url':BASE+str(out.relative_to(ROOT/'site')),'size':out.stat().st_size,'sha256':digest}}
    idx['thumbnail']=f'data/carts/DuskPromised@{CID}/label.png'
    shutil.copyfile(ROOT/f'cart_source/{CID}/label.png',out.parent/'label.png')
    write(f'carts/{CID}.index.json',idx)
    feed=read('site/data/index.json')
    feed['carts']=[c for c in feed['carts'] if c['id']!=CID]+[idx]
    sums=[]
    for folder in MODULES:
        mid=read(f'mods/{folder}/manifest.json')['id'];meta=read(f'custom_mods/{mid}.index.json')
        feed['mods']=[m for m in feed['mods'] if m['id']!=mid]+[meta]
        sums.append(f"{meta['sha256']}  {mid}-{VERSION}.zip")
    sums.append(f'{digest}  {out.name}')
    write('site/data/index.json',feed)
    (ROOT/f'cart_source/{CID}/gate-2-sha256sums.txt').write_text('\n'.join(sums)+'\n')
    print('CART',digest,out.stat().st_size)
else:raise SystemExit('expected package or metadata')
