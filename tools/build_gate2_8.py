"""Build Gate 2.8 directly from the device-green 0.2.6 cart."""
import hashlib,json,sys,zipfile,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE='https://duskpromised.github.io/gen1recomp-mod-index/'
CID='gate_2_irregular_shiny_test'; VER='0.2.8'
MID='red_earth_gate2_starter_preview_sparkle_fix'; FOLDER='red-earth-gate2-starter-preview-sparkle-fix'
BASE_VER='0.2.6'; BASE_SHA='daf4eb2e728a44c8a7049b4836e60a292a009d64e37368f561efc34e3b82c69e'
def read(p): return json.loads((ROOT/p).read_text())
def write(p,o):
 p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
out=ROOT/f'site/data/mods/DuskPromised@{MID}/{MID}-{VER}.zip'
cartpath=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{VER}.g1rcart'
mode=sys.argv[1]
if mode=='package':
 old=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{BASE_VER}.g1rcart'
 assert old.exists() and sha(old)==BASE_SHA,'device-green 0.2.6 cart changed'
 base=read(f'cart_source/{CID}/cart.json')
 assert base['version']==BASE_VER,'branch is not exact 0.2.6 baseline'
 kitpath=Path(sys.argv[2]);spec=importlib.util.spec_from_file_location('cartkit',kitpath);kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
 assert kit.bundle_bytes(base,ROOT/f'cart_source/{CID}')==old.read_bytes(),'0.2.6 source differs from published cart'
 for pin in base['mods']:
  if pin['id'].startswith('red_earth_'):
   p=ROOT/f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
   assert p.exists() and sha(p)==pin['sha256'],f"accepted ZIP changed: {pin['id']}"
 src=ROOT/'mods'/FOLDER; manifest=read(src/'manifest.json'); out.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for p in sorted(x for x in src.rglob('*') if x.is_file()):
   info=zipfile.ZipInfo(MID+'/'+str(p.relative_to(src)),(2026,9,17,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16;z.writestr(info,p.read_bytes())
 idx=read('custom_mods/red_earth_gate2_presentation.index.json')
 idx.update(folder='DuskPromised@'+MID,id=MID,title=manifest['name'],version=VER,dependencies=manifest['dependencies'],permissions=manifest['permissions'],summary=manifest['description'],downloadURL=BASE+str(out.relative_to(ROOT/'site')),source_zip=out.name,sha256=sha(out),experimental=True)
 write(f'custom_mods/{MID}.index.json',idx);(ROOT/f'custom_mods/{MID}.sha256').write_text(f'{sha(out)}  {out.name}\n')
 cart=dict(base);cart['version']=VER;cart['mods']=base['mods']+[dict(id=MID,source='github',repo='DuskPromised/gen1recomp-mod-index',version=VER,sha256=sha(out))];cart['load_order']=base['load_order']+[MID]
 write(f'cart_source/{CID}/cart.json',cart)
 print('MODULE',sha(out));print('PASS: exact 0.2.6 baseline preserved; failed 0.2.7 is absent')
elif mode=='metadata':
 cart=read(f'cart_source/{CID}/cart.json');assert cart['version']==VER
 idx=read(f'carts/{CID}.index.json')
 for k in ['id','version','mods','load_order']: idx[k]=cart[k]
 idx['latest']={'version':VER,'name':'0.2.8-preview-sparkle-rebuild','prerelease':True,'zip':{'name':cartpath.name,'url':BASE+str(cartpath.relative_to(ROOT/'site')),'size':cartpath.stat().st_size,'sha256':sha(cartpath)}}
 write(f'carts/{CID}.index.json',idx)
 feed=read('site/data/index.json');feed['carts']=[c for c in feed['carts'] if c['id']!=CID]+[idx];feed['mods']=[m for m in feed['mods'] if m['id']!=MID]+[read(f'custom_mods/{MID}.index.json')];write('site/data/index.json',feed)
 sums=[f"{p['sha256']}  {p['id']}-{p['version']}.zip" for p in cart['mods'] if p['id'].startswith('red_earth_')];sums.append(f'{sha(cartpath)}  {cartpath.name}');(ROOT/f'cart_source/{CID}/gate-2-sha256sums.txt').write_text('\n'.join(sums)+'\n')
 print('CART',sha(cartpath))
else: raise SystemExit('package or metadata')
