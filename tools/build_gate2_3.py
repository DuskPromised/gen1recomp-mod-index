"""Restore the accepted 0.2.0 cart and add one independent back-image repair."""
import hashlib,json,shutil,sys,zipfile,importlib.util
from pathlib import Path
from restore_shiny_back import restore_and_verify
ROOT=Path(__file__).resolve().parents[1]
BASE='https://duskpromised.github.io/gen1recomp-mod-index/'
CID='gate_2_irregular_shiny_test';VERSION='0.2.3'
MID='red_earth_solipsdion_shiny_back_fix';FOLDER='red-earth-solipsdion-shiny-back-fix'
def read(p):return json.loads((ROOT/p).read_text())
def write(p,o):
 p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
old=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-0.2.0.g1rcart'
assert sha(old)=='077ad6b493e45f6b7bb7f61c6f47c58d9a3ce3becad8f1658b018837f4d11f5d'
baseline=read('tools/fixtures/gate2_0_cart.json')
kitpath=Path(sys.argv[2]) if len(sys.argv)>2 else ROOT.parent/'engine-reference/tools/cartkit.py'
spec=importlib.util.spec_from_file_location('cartkit',kitpath);kit=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit)
assert kit.bundle_bytes(baseline,ROOT/f'cart_source/{CID}')==old.read_bytes(), 'baseline source differs from accepted cart'
out=ROOT/f'site/data/mods/DuskPromised@{MID}/{MID}-{VERSION}.zip'
cartpath=ROOT/f'site/data/carts/DuskPromised@{CID}/{CID}-{VERSION}.g1rcart'
if sys.argv[1]=='package':
 for pin in baseline['mods']:
  if not pin['id'].startswith('red_earth_'):continue
  p=ROOT/f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
  assert sha(p)==pin['sha256'], 'accepted ZIP changed'
  if pin['id'] in ['red_earth_irregular_shiny','red_earth_gate2_presentation','red_earth_gate2_test_harness']:
   folder=pin['id'].replace('_','-')
   with zipfile.ZipFile(p) as z:
    for name in z.namelist():
     if name.endswith('/'):continue
     assert (ROOT/'mods'/folder/name.split('/',1)[1]).read_bytes()==z.read(name), 'accepted source changed'
 src=ROOT/'mods'/FOLDER;assets=src/'assets';assets.mkdir(exist_ok=True)
 shutil.copyfile(ROOT/'mods/red-earth-irregular-shiny/assets/solipsdion_back_shiny.png',assets/'solipsdion_back_shiny.png')
 restore_and_verify(src)
 manifest=read(src/'manifest.json');out.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
  for p in sorted(x for x in src.rglob('*') if x.is_file()):
   info=zipfile.ZipInfo(MID+'/'+str(p.relative_to(src)),(2026,9,17,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16;z.writestr(info,p.read_bytes())
 idx=read('custom_mods/red_earth_gate2_presentation.index.json')
 idx.update(folder='DuskPromised@'+MID,id=MID,title=manifest['name'],version=VERSION,dependencies=manifest['dependencies'],permissions=manifest['permissions'],summary=manifest['description'],downloadURL=BASE+str(out.relative_to(ROOT/'site')),source_zip=out.name,sha256=sha(out))
 write(f'custom_mods/{MID}.index.json',idx)
 (ROOT/f'custom_mods/{MID}.sha256').write_text(f'{sha(out)}  {out.name}\n')
 cart=dict(baseline);cart['version']=VERSION
 cart['mods']=baseline['mods']+[dict(id=MID,source='github',repo='DuskPromised/gen1recomp-mod-index',version=VERSION,sha256=sha(out))]
 cart['load_order']=baseline['load_order']+[MID]
 write(f'cart_source/{CID}/cart.json',cart)
 # Restore feed metadata from the immutable published 0.2.0 artifacts.
 for pin in baseline['mods']:
  mid=pin['id']
  if mid not in ['red_earth_irregular_shiny','red_earth_gate2_presentation','red_earth_gate2_test_harness']:continue
  p=ROOT/f"site/data/mods/DuskPromised@{mid}/{mid}-0.2.0.zip"
  with zipfile.ZipFile(p) as z:m=json.loads(z.read(mid+'/manifest.json'))
  idx=read(f'custom_mods/{mid}.index.json');idx.update(version='0.2.0',dependencies=m['dependencies'],permissions=m['permissions'],summary=m['description'],downloadURL=BASE+str(p.relative_to(ROOT/'site')),source_zip=p.name,sha256=pin['sha256'])
  write(f'custom_mods/{mid}.index.json',idx);(ROOT/f'custom_mods/{mid}.sha256').write_text(f"{pin['sha256']}  {p.name}\n")
 print('PATCH',sha(out),out.stat().st_size)
 print('PASS: every original Gate 2.0 pin and original module file preserved')
elif sys.argv[1]=='metadata':
 cart=read(f'cart_source/{CID}/cart.json');idx=read(f'carts/{CID}.index.json')
 for k in ['id','version','mods','load_order']:idx[k]=cart[k]
 idx['latest']={'version':VERSION,'name':VERSION,'prerelease':True,'zip':{'name':cartpath.name,'url':BASE+str(cartpath.relative_to(ROOT/'site')),'size':cartpath.stat().st_size,'sha256':sha(cartpath)}}
 write(f'carts/{CID}.index.json',idx)
 feed=read('site/data/index.json');feed['carts']=[c for c in feed['carts'] if c['id']!=CID]+[idx]
 ids=['red_earth_irregular_shiny','red_earth_gate2_presentation','red_earth_gate2_test_harness',MID]
 for mid in ids:feed['mods']=[m for m in feed['mods'] if m['id']!=mid]+[read(f'custom_mods/{mid}.index.json')]
 write('site/data/index.json',feed)
 sums=[f"{p['sha256']}  {p['id']}-{p['version']}.zip" for p in cart['mods'] if p['id'].startswith('red_earth_')]
 sums.append(f'{sha(cartpath)}  {cartpath.name}')
 (ROOT/f'cart_source/{CID}/gate-2-sha256sums.txt').write_text('\n'.join(sums)+'\n')
 print('CART',sha(cartpath),cartpath.stat().st_size)
else:raise SystemExit('package or metadata')
