"""Advance accepted Gate 2.4 with one independent regional shiny menu/icon repair."""
import hashlib,json,sys,zipfile,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE='https://duskpromised.github.io/gen1recomp-mod-index/'
CID='gate_2_irregular_shiny_test';VERSION='0.2.5'
MID='red_earth_gate2_regional_menu_icon_fix';FOLDER='red-earth-gate2-regional-menu-icon-fix'
BASE_VERSION='0.2.4';BASE_SHA='a1072127f11d9b13bff34a61edb371c8ed8851a5f938fe24e891b12870b59978'
ICON_DIR=Path('/tmp/gate25-icons')
def read(p):return json.loads((ROOT/p).read_text())
def write(p,o):
 p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
out=ROOT/f'site/data/mods/DuskPromised@{MID}/{MID}-{VERSION}.zip'
cartpath=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{VERSION}.g1rcart'
mode=sys.argv[1]
if mode=='package':
 old=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{BASE_VERSION}.g1rcart'
 assert old.exists() and sha(old)==BASE_SHA,'accepted 0.2.4 cart changed'
 baseline=read(f'cart_source/{CID}/cart.json')
 assert baseline['version']==BASE_VERSION,'cart source is not accepted 0.2.4'
 kitpath=Path(sys.argv[2]) if len(sys.argv)>2 else ROOT.parent/'engine-reference/tools/cartkit.py'
 spec=importlib.util.spec_from_file_location('cartkit',kitpath);kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
 assert kit.bundle_bytes(baseline,ROOT/f'cart_source/{CID}')==old.read_bytes(),'0.2.4 source differs from published cart'
 for pin in baseline['mods']:
  if not pin['id'].startswith('red_earth_'):continue
  p=ROOT/f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
  assert p.exists() and sha(p)==pin['sha256'],f"accepted ZIP changed: {pin['id']}"
 src=ROOT/'mods'/FOLDER;manifest=read(src/'manifest.json');out.parent.mkdir(parents=True,exist_ok=True)
 expected={1,2,3,152,153,154,252,253,254,387,388,389,495,496,497,650,651,652,653,654,655,722,723,724,810,811,812,906,907,908}
 actual={int(p.name[:3]) for p in ICON_DIR.glob('*_shiny.png')}
 assert actual==expected,(sorted(expected-actual),sorted(actual-expected))
 with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for p in sorted(x for x in src.rglob('*') if x.is_file()):
   info=zipfile.ZipInfo(MID+'/'+str(p.relative_to(src)),(2026,9,17,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16;z.writestr(info,p.read_bytes())
  for p in sorted(ICON_DIR.glob('*_shiny.png')):
   info=zipfile.ZipInfo(MID+'/assets/icons/'+p.name,(2026,9,17,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16;z.writestr(info,p.read_bytes())
 idx=read('custom_mods/red_earth_gate2_presentation.index.json')
 idx.update(folder='DuskPromised@'+MID,id=MID,title=manifest['name'],version=VERSION,
            dependencies=manifest['dependencies'],permissions=manifest['permissions'],
            summary=manifest['description'],downloadURL=BASE+str(out.relative_to(ROOT/'site')),
            source_zip=out.name,sha256=sha(out))
 write(f'custom_mods/{MID}.index.json',idx)
 (ROOT/f'custom_mods/{MID}.sha256').write_text(f'{sha(out)}  {out.name}\n')
 cart=dict(baseline);cart['version']=VERSION
 cart['mods']=baseline['mods']+[dict(id=MID,source='github',repo='DuskPromised/gen1recomp-mod-index',version=VERSION,sha256=sha(out))]
 cart['load_order']=baseline['load_order']+[MID]
 write(f'cart_source/{CID}/cart.json',cart)
 print('REGIONAL_ICON_FIX',sha(out),out.stat().st_size)
 print('PASS: accepted Gate 2.4 pins preserved; only regional shiny menu/icon repair added')
elif mode=='metadata':
 cart=read(f'cart_source/{CID}/cart.json')
 assert cart['version']==VERSION,'metadata expects the just-packed 0.2.5 cart source'
 idx=read(f'carts/{CID}.index.json')
 for k in ['id','version','mods','load_order']:idx[k]=cart[k]
 idx['latest']={'version':VERSION,'name':VERSION,'prerelease':True,'zip':{'name':cartpath.name,'url':BASE+str(cartpath.relative_to(ROOT/'site')),'size':cartpath.stat().st_size,'sha256':sha(cartpath)}}
 write(f'carts/{CID}.index.json',idx)
 feed=read('site/data/index.json');feed['carts']=[c for c in feed['carts'] if c['id']!=CID]+[idx]
 feed['mods']=[m for m in feed['mods'] if m['id']!=MID]+[read(f'custom_mods/{MID}.index.json')]
 write('site/data/index.json',feed)
 sums=[f"{p['sha256']}  {p['id']}-{p['version']}.zip" for p in cart['mods'] if p['id'].startswith('red_earth_')]
 sums.append(f'{sha(cartpath)}  {cartpath.name}')
 (ROOT/f'cart_source/{CID}/gate-2-sha256sums.txt').write_text('\n'.join(sums)+'\n')
 print('CART',sha(cartpath),cartpath.stat().st_size)
else:raise SystemExit('package or metadata')
