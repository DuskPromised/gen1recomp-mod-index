"""Build Gate 2.9 from the exact device-green 0.2.6 cart.

0.2.8 is deliberately excluded.  The only changed accepted pin is the QA test
harness, whose 0.2.9 build fixes shiny state ordering before its nickname UI.
"""
import hashlib, json, sys, zipfile, importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://duskpromised.github.io/gen1recomp-mod-index/'
CID = 'gate_2_irregular_shiny_test'
VER = '0.2.9'
BASE_VER = '0.2.6'
BASE_SHA = 'daf4eb2e728a44c8a7049b4836e60a292a009d64e37368f561efc34e3b82c69e'
MID = 'red_earth_gate2_test_harness'
FOLDER = 'red-earth-gate2-test-harness'
FAILED_MID = 'red_earth_gate2_starter_preview_sparkle_fix'


def read(p):
    return json.loads((ROOT / p).read_text())


def write(p, obj):
    p = ROOT / p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, indent=2) + '\n')


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def base_026_from_current():
    current = read(f'cart_source/{CID}/cart.json')
    base = dict(current)
    base['version'] = BASE_VER
    base['mods'] = [p for p in current['mods'] if p['id'] != FAILED_MID]
    base['load_order'] = [m for m in current['load_order'] if m != FAILED_MID]
    return base


out = ROOT / f'site/data/mods/DuskPromised@{MID}/{MID}-{VER}.zip'
cartpath = ROOT / f'site/data/carts/DuskPromised@{CID}/{CID}-{VER}.g1rcart'
mode = sys.argv[1]

if mode == 'package':
    old = ROOT / f'site/data/carts/DuskPromised@{CID}/{CID}-{BASE_VER}.g1rcart'
    assert old.exists() and sha(old) == BASE_SHA, 'device-green 0.2.6 cart changed'

    kitpath = Path(sys.argv[2])
    spec = importlib.util.spec_from_file_location('cartkit', kitpath)
    kit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(kit)

    base = base_026_from_current()
    assert all(p['id'] != FAILED_MID for p in base['mods']), '0.2.8 patch survived rollback'
    assert kit.bundle_bytes(base, ROOT / f'cart_source/{CID}') == old.read_bytes(), \
        'reconstructed source is not byte-identical to published 0.2.6'

    # Every accepted Red Earth pin from 0.2.6 must still match its immutable ZIP.
    for pin in base['mods']:
        if not pin['id'].startswith('red_earth_'):
            continue
        p = ROOT / f"site/data/mods/DuskPromised@{pin['id']}/{pin['id']}-{pin['version']}.zip"
        assert p.exists() and sha(p) == pin['sha256'], f"accepted ZIP changed: {pin['id']}"

    src = ROOT / 'mods' / FOLDER
    manifest = read(src / 'manifest.json')
    assert manifest['id'] == MID and manifest['version'] == VER
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in sorted(x for x in src.rglob('*') if x.is_file()):
            info = zipfile.ZipInfo(MID + '/' + str(p.relative_to(src)), (2026, 9, 17, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, p.read_bytes())

    idx = read(f'custom_mods/{MID}.index.json')
    idx.update(
        folder='DuskPromised@' + MID,
        id=MID,
        title=manifest['name'],
        version=VER,
        dependencies=manifest['dependencies'],
        permissions=manifest['permissions'],
        summary=manifest['description'],
        downloadURL=BASE + str(out.relative_to(ROOT / 'site')),
        source_zip=out.name,
        sha256=sha(out),
        experimental=True,
    )
    write(f'custom_mods/{MID}.index.json', idx)
    (ROOT / f'custom_mods/{MID}.sha256').write_text(f'{sha(out)}  {out.name}\n')

    cart = dict(base)
    cart['version'] = VER
    newmods = []
    replaced = False
    for pin in base['mods']:
        if pin['id'] == MID:
            newmods.append(dict(
                id=MID,
                source='github',
                repo='DuskPromised/gen1recomp-mod-index',
                version=VER,
                sha256=sha(out),
            ))
            replaced = True
        else:
            newmods.append(pin)
    assert replaced, '0.2.6 test-harness pin missing'
    cart['mods'] = newmods
    cart['load_order'] = list(base['load_order'])
    write(f'cart_source/{CID}/cart.json', cart)
    print('MODULE', sha(out))
    print('PASS: exact 0.2.6 base reconstructed; only QA harness pin replaced; 0.2.8 absent')

elif mode == 'metadata':
    cart = read(f'cart_source/{CID}/cart.json')
    assert cart['version'] == VER
    assert all(p['id'] != FAILED_MID for p in cart['mods'])

    idx = read(f'carts/{CID}.index.json')
    for k in ['id', 'version', 'mods', 'load_order']:
        idx[k] = cart[k]
    idx['latest'] = {
        'version': VER,
        'name': '0.2.9-nickname-timing-rebuild',
        'prerelease': True,
        'zip': {
            'name': cartpath.name,
            'url': BASE + str(cartpath.relative_to(ROOT / 'site')),
            'size': cartpath.stat().st_size,
            'sha256': sha(cartpath),
        },
    }
    write(f'carts/{CID}.index.json', idx)

    feed = read('site/data/index.json')
    feed['carts'] = [c for c in feed['carts'] if c['id'] != CID] + [idx]
    feed['mods'] = [m for m in feed['mods'] if m['id'] not in {MID, FAILED_MID}]
    feed['mods'].append(read(f'custom_mods/{MID}.index.json'))
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
