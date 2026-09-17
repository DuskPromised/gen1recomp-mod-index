"""Online byte verification of every unique sealed cart pin, not just release sums."""
import importlib.util
import json
from pathlib import Path
import sys

spec=importlib.util.spec_from_file_location('cartkit',sys.argv[1])
kit=importlib.util.module_from_spec(spec)
spec.loader.exec_module(kit)
root=Path(__file__).resolve().parents[1]
checked={}
for path in sorted((root/'cart_source').glob('*/cart.json')):
    cart=json.loads(path.read_text())
    assert cart['seal']=='sealed+'
    for pin in cart['mods']:
        assert pin['source']=='github'
        key=(pin['repo'],pin['version'],pin['id'])
        if key not in checked:
            release,_=kit.github_release(pin['repo'],pin['version'],kit.github_token())
            asset=kit.pick_asset(release,pin['id'],pin['version'])
            sha,size=kit.stream_digest(asset['browser_download_url'])
            checked[key]=sha
            print('DOWNLOADED',pin['id'],pin['version'],size,sha,flush=True)
        assert checked[key]==pin['sha256'],(path,key,checked[key],pin['sha256'])
    print('SEALED PINS PASS',cart['id'],cart['version'],flush=True)
print('ALL UNIQUE PINS VERIFIED',len(checked))
