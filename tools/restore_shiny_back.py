"""Compile the reviewed, species-specific alpha repair; no runtime masking."""
import hashlib
import json
from PIL import Image


def restore_and_verify(source):
    record = json.loads((source / 'back-alpha-restoration.json').read_text())
    path = source / 'assets' / record['asset']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == record['source_sha256']
    before = Image.open(path).convert('RGBA')
    after = before.copy()
    for x, y, r, g, b, a in record['pixels']:
        assert before.getpixel((x, y))[3] == 0
        assert 18 <= x <= 34 and 26 <= y <= 45 and a == 255
        after.putpixel((x, y), (r, g, b, a))
    # Preserve the complete existing drawing, dimensions and seven-wing silhouette.
    assert before.size == after.size == (48, 48)
    assert before.getbbox() == after.getbbox()
    for y in range(48):
        for x in range(48):
            if before.getpixel((x, y))[3]:
                assert before.getpixel((x, y)) == after.getpixel((x, y))
    # Reproduce the reported missing torso, then verify it is opaque.
    for y in range(29, 33):
        for x in range(21, 26):
            assert before.getpixel((x, y))[3] == 0
            assert after.getpixel((x, y))[3] == 255
    # Keep the real leg opening, under-tail space, and gaps beside the arms clear.
    for x, y in [(23, 40), (23, 42), (23, 44), (23, 46), (30, 44), (17, 35), (29, 36)]:
        assert before.getpixel((x, y))[3] == after.getpixel((x, y))[3] == 0
    after.save(path)
    print('PASS: shiny Solipsdion torso opacity, existing pixels and anatomical gaps')
