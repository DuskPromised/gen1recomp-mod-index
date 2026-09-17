"""Build Gate 2.10 from the exact published 0.2.9 cart.

Only two deliberate changes are permitted:
  * replace red_earth_gate2_starter_shiny_state_icons 0.2.6 with 0.2.10;
  * add the isolated red_earth_gate2_starter_shiny_fx 0.2.10 module.
Everything else remains byte-pinned to the device-tested 0.2.9 cart.
"""
import hashlib, importlib.util, json, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_URL = 'https://duskpromised.github.io/gen1recomp-mod-index/'
CID = 'gate_2_irregular_shiny_test'
VER = '0.2.10'
BASE_VER = '0.2.9'
BASE_SHA = 'b6bd40e32fb2373a8de685c01cf020c79df752eb62a0332f939ef4cd2ea95b7c'
STARTER_ID = 'red_earth_gate2_starter_shiny_state_icons'
STARTER_FOLDER = 'red-earth-gate2-starter-shiny-state-icons'
FX_ID = 'red_earth_gate2_starter_shiny_fx'
FX_FOLDER = 'red-earth-gate2-starter-shiny-fx'
FAILED_ID = 'red_earth_gate2_starter_preview_sparkle_fix'


def read(path):
    return json.loads((ROOT / path).read_text())


def write(path, obj):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, indent=2) + '\n')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package_module(mid, folder):
    src = ROOT / 'mods' / folder
    manifest = read(src / 'manifest.json')
    assert manifest['id'] == mid and manifest['version'] == VER
    out = ROOT / f'site/data/mods/DuskPromised@{mid}/{mid}-{VER}.zip'
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in sorted(x for x in src.rglob('*') if x.is_file()):
            info = zipfile.ZipInfo(mid + '/' + str(p.relative_to(src)), (2026, 9, 17, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, p.read_bytes())
    return manifest, out


def update_mod_index(mid, manifest, out, template=None):
    idx_path = ROOT / f'custom_mods/{mid}.index.json'
    if idx_path.exists():
        idx = json.loads(idx_path.read_text())
    else:
        idx = dict(template or {})
        idx.pop('latest', None)
    idx.update(
        folder='DuskPromised@' + mid,
        id=mid,
        title=manifest['name'],
        author=manifest.get('author', 'Adam M. Aguilera'),
        version=VER,
        categories=[manifest.get('category', 'GRAPHICS'), 'DEVELOPMENT'],
        tags=['red earth', 'gate 2', 'standalone'],
        api=manifest.get('api', 2),
        profile=manifest.get('profile', 'content'),
        game_version=manifest.get('game_version', '>=0.2.24 <2.0.0'),
        permissions=manifest.get('permissions', []),
        dependencies=manifest.get('dependencies', []),
        conflicts=manifest.get('conflicts', []),
        experimental=True,
        repo='https://github.com/DuskPromised/gen1recomp-mod-index',
        github='DuskPromised/gen1recomp-mod-index',
        license='MIT',
        downloadURL=BASE_URL + str(out.relative_to(ROOT / 'site')),
        source_zip=out.name,
        summary=manifest['description'],
        source_scope='DuskPromised standalone Gate 2 module',
        update_check='off',
        sha256=sha(out),
    )
    write(f'custom_mods/{mid}.index.json', idx)
    (ROOT / f'custom_mods/{mid}.sha256').write_text(f'{sha(out)}  {out.name}\n')
    return idx


cartpath = ROOT / f'site/data/carts/DuskPromised@{CID}/{CID}-{VER}.g1rcart'
mode = sys.argv[1]

if mode == 'package':
    old = ROOT / f'site/data/carts/DuskPromised@{CID}/{CID}-{BASE_VER}.g1rcart'
    assert old.exists() and sha(old) == BASE_SHA, 'published 0.2.9 cart changed'

    kitpath = Path(sys.argv[2])
    spec = importlib.util.spec_from_file_location('cartkit', kitpath)
    kit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(kit)

    base = read(f'cart_source/{CID}/cart.json')
    assert base['version'] == BASE_VER, 'cart_source is not the published 0.2.9 baseline'
    assert FAILED_ID not in [p['id'] for p in base['mods']], 'failed 0.2.8 patch returned'
    assert FX_ID not in [p['id'] for p in base['mods']], 'starter FX already present in baseline'
    assert kit.bundle_bytes(base, ROOT / f'cart_source/{CID}') == old.read_bytes(), \
        'cart_source no longer reproduces published 0.2.9 byte-for-byte'

    # Freeze every accepted Red Earth ZIP in the 0.2.9 cart before changing pins.
    for pin in base['mods']:
        if not pin['id'].startswith('red_earth_'):
            continue
        p = ROOT / f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
        assert p.exists() and sha(p) == pin['sha256'], f"accepted ZIP changed: {pin['id']}"

    starter_manifest, starter_zip = package_module(STARTER_ID, STARTER_FOLDER)
    fx_manifest, fx_zip = package_module(FX_ID, FX_FOLDER)
    starter_idx = update_mod_index(STARTER_ID, starter_manifest, starter_zip)
    update_mod_index(FX_ID, fx_manifest, fx_zip, template=starter_idx)

    cart = json.loads(json.dumps(base))
    cart['version'] = VER
    newmods = []
    replaced = False
    for pin in base['mods']:
        if pin['id'] == STARTER_ID:
            newmods.append({
                'id': STARTER_ID,
                'source': 'github',
                'repo': 'DuskPromised/gen1recomp-mod-index',
                'version': VER,
                'sha256': sha(starter_zip),
            })
            replaced = True
        else:
            newmods.append(pin)
    assert replaced, '0.2.9 starter shiny contract pin missing'
    newmods.append({
        'id': FX_ID,
        'source': 'github',
        'repo': 'DuskPromised/gen1recomp-mod-index',
        'version': VER,
        'sha256': sha(fx_zip),
    })
    cart['mods'] = newmods
    cart['load_order'] = list(base['load_order']) + [FX_ID]
    write(f'cart_source/{CID}/cart.json', cart)

    print('STARTER', sha(starter_zip))
    print('FX', sha(fx_zip))
    print('PASS: exact 0.2.9 baseline preserved except starter contract replacement + isolated starter FX')

elif mode == 'metadata':
    cart = read(f'cart_source/{CID}/cart.json')
    assert cart['version'] == VER
    ids = [p['id'] for p in cart['mods']]
    assert FAILED_ID not in ids
    assert ids.count(STARTER_ID) == 1 and ids.count(FX_ID) == 1

    idx = read(f'carts/{CID}.index.json')
    for key in ['id', 'version', 'mods', 'load_order']:
        idx[key] = cart[key]
    idx['latest'] = {
        'version': VER,
        'name': '0.2.10-fennekin-contract-fx',
        'prerelease': True,
        'zip': {
            'name': cartpath.name,
            'url': BASE_URL + str(cartpath.relative_to(ROOT / 'site')),
            'size': cartpath.stat().st_size,
            'sha256': sha(cartpath),
        },
    }
    write(f'carts/{CID}.index.json', idx)

    feed = read('site/data/index.json')
    feed['carts'] = [c for c in feed['carts'] if c['id'] != CID] + [idx]
    feed['mods'] = [m for m in feed['mods'] if m['id'] not in {STARTER_ID, FX_ID, FAILED_ID}]
    feed['mods'].append(read(f'custom_mods/{STARTER_ID}.index.json'))
    feed['mods'].append(read(f'custom_mods/{FX_ID}.index.json'))
    write('site/data/index.json', feed)

    sums = [
        f"{p['sha256']}  {p['id']}-{p['version']}.zip"
        for p in cart['mods'] if p['id'].startswith('red_earth_')
    ]
    sums.append(f'{sha(cartpath)}  {cartpath.name}')
    (ROOT / f'cart_source/{CID}/gate-2-sha256sums.txt').write_text('\n'.join(sums) + '\n')
    print('CART', sha(cartpath))
else:
    raise SystemExit('package or metadata')
