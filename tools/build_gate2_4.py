"""Advance accepted Gate 2.3 by one independent gold/lilac sparkle overlay."""
import hashlib,json,sys,zipfile,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE='https://duskpromised.github.io/gen1recomp-mod-index/'
CID='gate_2_irregular_shiny_test';VERSION='0.2.4'
MID='red_earth_gate2_sparkle_gold_lilac';FOLDER='red-earth-gate2-sparkle-gold-lilac'
BASE_VERSION='0.2.3';BASE_SHA='c226d3132ed75487cb8a82192d8055747f75aed47dd98f82ff43d7606616bd83'
def read(p):return json.loads((ROOT/p).read_text())
def write(p,o):
 p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
old=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{BASE_VERSION}.g1rcart'
assert sha(old)==BASE_SHA,'accepted 0.2.3 cart changed'
baseline=read(f'cart_source/{CID}/cart.json')
assert baseline['version']==BASE_VERSION,'cart source is not accepted 0.2.3'
kitpath=Path(sys.argv[2]) if len(sys.argv)>2 else ROOT.parent/'engine-reference/tools/cartkit.py'
spec=importlib.util.spec_from_file_location('cartkit',kitpath);kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
assert kit.bundle_bytes(baseline,ROOT/f'cart_source/{CID}')==old.read_bytes(),'0.2.3 source differs from published cart'
out=ROOT/f'site/data/mods/DuskPromised@{MID}/{MID}-{VERSION}.zip'
cartpath=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{VERSION}.g1rcart'
if sys.argv[1]=='package':
 for pin in baseline['mods']:
  if not pin['id'].startswith('red_earth_'):continue
  p=ROOT/f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
  assert p.exists() and sha(p)==pin['sha256'],f"accepted ZIP changed: {pin['id']}"
 src=ROOT/'mods'/FOLDER;manifest=read(src/'manifest.json');out.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for p in sorted(x for x in src.rglob('*') if x.is_file()):
   info=zipfile.ZipInfo(MID+'/'+str(p.relative_to(src)),(2026,9,17,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16;z.writestr(info,p.read_bytes())
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
 print('SPARKLE',sha(out),out.stat().st_size)
 print('PASS: accepted Gate 2.3 pins preserved; only the standalone sparkle module was added')
elif sys.argv[1]=='metadata':
 cart=read(f'cart_source/{CID}/cart.json');idx=read(f'carts/{CID}.index.json')
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
