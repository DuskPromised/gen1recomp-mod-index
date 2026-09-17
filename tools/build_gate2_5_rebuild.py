"""Build the Gate 2.5 replacement cleanly from the accepted device-green Gate 2.4 cart.

The feature gate remains Gate 2.5, but the published package/cart version is 0.2.6
because failed 0.2.5 installs already exist and must receive a higher updater version.
"""
import hashlib, json, sys, zipfile, importlib.util
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
BASE='https://duskpromised.github.io/gen1recomp-mod-index/'
CID='gate_2_irregular_shiny_test'
CART_VERSION='0.2.6'
MOD_VERSION='0.2.6'
MID='red_earth_gate2_starter_shiny_state_icons'
FOLDER='red-earth-gate2-starter-shiny-state-icons'
BASE_VERSION='0.2.4'
BASE_SHA='a1072127f11d9b13bff34a61edb371c8ed8851a5f938fe24e891b12870b59978'
LEGACY=ROOT/'site/data/mods/DuskPromised@red_earth_regional_shiny_art/red_earth_regional_shiny_art-1.0.5.zip'
DEX=(1,2,3,152,153,154,252,253,254,387,388,389,495,496,497,650,651,652,653,654,655,722,723,724)

def read(p): return json.loads((ROOT/p).read_text())
def write(p,o):
    p=ROOT/p; p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(o,indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def legacy_asset(z, suffix):
    hits=[n for n in z.namelist() if n.endswith(suffix) and not n.endswith('/')]
    assert len(hits)==1, f'expected exactly one legacy asset {suffix}, got {hits}'
    return z.read(hits[0])

out=ROOT/f'site/data/mods/DuskPromised@{MID}/{MID}-{MOD_VERSION}.zip'
cartpath=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{CART_VERSION}.g1rcart'
mode=sys.argv[1]

if mode=='package':
    old=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{BASE_VERSION}.g1rcart'
    assert old.exists() and sha(old)==BASE_SHA, 'accepted device-green 0.2.4 cart changed'
    baseline=read(f'cart_source/{CID}/cart.json')
    assert baseline['version']==BASE_VERSION, 'cart source is not accepted 0.2.4'
    kitpath=Path(sys.argv[2]) if len(sys.argv)>2 else ROOT.parent/'engine-reference/tools/cartkit.py'
    spec=importlib.util.spec_from_file_location('cartkit',kitpath)
    kit=importlib.util.module_from_spec(spec); spec.loader.exec_module(kit)
    assert kit.bundle_bytes(baseline,ROOT/f'cart_source/{CID}')==old.read_bytes(), '0.2.4 source differs from published green cart'
    for pin in baseline['mods']:
        if not pin['id'].startswith('red_earth_'): continue
        p=ROOT/f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
        assert p.exists() and sha(p)==pin['sha256'], f"accepted ZIP changed: {pin['id']}"

    assert LEGACY.exists(), 'proven regional shiny-art v1.0.5 source ZIP missing'
    src=ROOT/'mods'/FOLDER
    manifest=read(src/'manifest.json')
    assert manifest['version']==MOD_VERSION
    out.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(LEGACY) as legacy, zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(x for x in src.rglob('*') if x.is_file()):
            info=zipfile.ZipInfo(MID+'/'+str(p.relative_to(src)),(2026,9,17,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED; info.external_attr=0o100644<<16
            z.writestr(info,p.read_bytes())
        for dex in DEX:
            pfx=f'{dex:03d}'
            for side in ('front','back'):
                name=f'{pfx}_{side}_shiny.png'
                data=legacy_asset(legacy,'/assets/battlers/'+name)
                info=zipfile.ZipInfo(MID+'/assets/battlers/'+name,(2026,9,17,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED; info.external_attr=0o100644<<16
                z.writestr(info,data)
            name=f'{pfx}_shiny.png'
            data=legacy_asset(legacy,'/assets/icons/'+name)
            info=zipfile.ZipInfo(MID+'/assets/icons/'+name,(2026,9,17,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED; info.external_attr=0o100644<<16
            z.writestr(info,data)

    idx=read('custom_mods/red_earth_gate2_presentation.index.json')
    idx.update(folder='DuskPromised@'+MID,id=MID,title=manifest['name'],version=MOD_VERSION,
               dependencies=manifest['dependencies'],permissions=manifest['permissions'],
               summary=manifest['description'],downloadURL=BASE+str(out.relative_to(ROOT/'site')),
               source_zip=out.name,sha256=sha(out),experimental=True)
    write(f'custom_mods/{MID}.index.json',idx)
    (ROOT/f'custom_mods/{MID}.sha256').write_text(f'{sha(out)}  {out.name}\n')

    cart=dict(baseline); cart['version']=CART_VERSION
    cart['mods']=baseline['mods']+[dict(id=MID,source='github',repo='DuskPromised/gen1recomp-mod-index',version=MOD_VERSION,sha256=sha(out))]
    cart['load_order']=baseline['load_order']+[MID]
    write(f'cart_source/{CID}/cart.json',cart)
    print('MODULE',sha(out),out.stat().st_size)
    print('PASS: exact 0.2.4 baseline preserved; one rebuilt Gate 2.5 starter shiny module appended as 0.2.6')

elif mode=='metadata':
    cart=read(f'cart_source/{CID}/cart.json')
    assert cart['version']==CART_VERSION
    idx=read(f'carts/{CID}.index.json')
    for k in ['id','version','mods','load_order']: idx[k]=cart[k]
    idx['latest']={'version':CART_VERSION,'name':'0.2.6-gate2.5-rebuild','prerelease':True,
                   'zip':{'name':cartpath.name,'url':BASE+str(cartpath.relative_to(ROOT/'site')),
                          'size':cartpath.stat().st_size,'sha256':sha(cartpath)}}
    write(f'carts/{CID}.index.json',idx)
    feed=read('site/data/index.json')
    feed['carts']=[c for c in feed['carts'] if c['id']!=CID]+[idx]
    feed['mods']=[m for m in feed['mods'] if m['id']!=MID]+[read(f'custom_mods/{MID}.index.json')]
    write('site/data/index.json',feed)
    sums=[f"{p['sha256']}  {p['id']}-{p['version']}.zip" for p in cart['mods'] if p['id'].startswith('red_earth_')]
    sums.append(f'{sha(cartpath)}  {cartpath.name}')
    (ROOT/f'cart_source/{CID}/gate-2-sha256sums.txt').write_text('\n'.join(sums)+'\n')
    print('CART',sha(cartpath),cartpath.stat().st_size)
else:
    raise SystemExit('package or metadata')
