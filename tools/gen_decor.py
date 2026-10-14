"""Generate decorative sprites for World of Bloop levels.
Run from world-of-bloop/: python tools/gen_decor.py
Output: assets/textures/decor/
"""
import os
import math
from PIL import Image, ImageDraw

OUT = "assets/textures/decor"
S = 3  # supersample for antialiasing


def _save(img, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    img.save(path)
    print(f"  -> {path}")


def _canvas(w, h):
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _done(img, w, h, name):
    img = img.resize((w, h), Image.LANCZOS)
    _save(img, name)


# ── Grass tuft ────────────────────────────────────────────────────────────────

def gen_grass_tuft():
    W, H = 48, 64
    img, d = _canvas(W, H)

    blades = [
        # (base_x, tip_x, tip_y, half_width, green)
        (W//2 - 10, W//2 - 20, 8,  5, (22, 82, 10)),
        (W//2,      W//2 + 3,  2,  6, (30, 95, 14)),
        (W//2 + 11, W//2 + 22, 10, 4, (18, 68, 8)),
    ]

    for bx, tx, ty, bw, col in blades:
        bxs, txs, tys, bws = bx*S, tx*S, ty*S, bw*S
        bys = H * S
        pts = [
            (bxs - bws, bys),
            (bxs + bws, bys),
            (txs + S,   tys + S),
            (txs,       tys),
            (txs - S,   tys + S),
        ]
        d.polygon(pts, fill=(*col, 255))

    _done(img, W, H, "grass_tuft.png")


# ── Bush (lobes = list of (cx_frac, cy_frac, r_frac, color)) ─────────────────

def gen_bush(name, W, H, lobes):
    img, d = _canvas(W, H)
    for cx_f, cy_f, r_f, col in lobes:
        cx = int(cx_f * W * S)
        cy = int(cy_f * H * S)
        r  = int(r_f  * min(W, H) * S)
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(*col, 255))
    _done(img, W, H, name)


# ── Flower ────────────────────────────────────────────────────────────────────

def gen_flower():
    W, H = 40, 56
    img, d = _canvas(W, H)

    # Stem
    sx, sw = W // 2, 3
    d.rectangle([(sx-sw)*S, (H//2)*S, (sx+sw)*S, H*S], fill=(18, 65, 8, 255))

    # Petals
    pr       = int(0.22 * W * S)
    pcx, pcy = (W//2)*S, (H//2 - 6)*S
    pdist    = int(0.19 * W * S)
    for i in range(5):
        a  = math.radians(i * 72 - 90)
        px = pcx + int(math.cos(a) * pdist)
        py = pcy + int(math.sin(a) * pdist)
        d.ellipse([px-pr, py-pr, px+pr, py+pr], fill=(185, 75, 115, 230))

    # Center
    cr = int(0.14 * W * S)
    d.ellipse([pcx-cr, pcy-cr, pcx+cr, pcy+cr], fill=(228, 195, 20, 255))

    _done(img, W, H, "flower.png")


# ── Rock ──────────────────────────────────────────────────────────────────────

def gen_rock():
    W, H = 80, 48
    img, d = _canvas(W, H)

    outline = [
        (0.08, 0.72), (0.18, 0.42), (0.34, 0.18), (0.54, 0.12),
        (0.72, 0.20), (0.88, 0.40), (0.95, 0.68), (0.90, 0.94),
        (0.10, 0.94),
    ]
    poly = [(int(x * W * S), int(y * H * S)) for x, y in outline]
    d.polygon(poly, fill=(68, 58, 45, 255))

    highlight = [
        (0.28, 0.26), (0.46, 0.16), (0.66, 0.22), (0.56, 0.40), (0.34, 0.44)
    ]
    hl = [(int(x * W * S), int(y * H * S)) for x, y in highlight]
    d.polygon(hl, fill=(92, 80, 62, 210))

    _done(img, W, H, "rock_small.png")


# ── Mushroom ──────────────────────────────────────────────────────────────────

def gen_mushroom():
    W, H = 44, 60
    img, d = _canvas(W, H)

    # Stem
    sx, sw = W//2, 7
    d.rectangle([(sx-sw)*S, (H//2+4)*S, (sx+sw)*S, H*S], fill=(210, 185, 155, 255))

    # Cap (ellipse)
    cr, cy = W//2, H//2
    d.ellipse([2*S, (cy-16)*S, (W-2)*S, (cy+14)*S], fill=(185, 42, 32, 255))

    # White dots on cap
    for dx, dy in [(-10, -2), (0, -8), (10, -2), (-6, 6), (6, 6)]:
        px = (cr + dx)*S
        py = (cy + dy)*S
        r  = 3*S
        d.ellipse([px-r, py-r, px+r, py+r], fill=(255, 255, 255, 220))

    _done(img, W, H, "mushroom.png")


if __name__ == "__main__":
    print("Generating decor sprites...")

    gen_grass_tuft()

    gen_bush("bush_small.png", 80, 72, [
        (0.50, 0.65, 0.33, (22, 75, 12)),
        (0.28, 0.74, 0.25, (17, 62, 9)),
        (0.72, 0.72, 0.26, (26, 82, 14)),
        (0.50, 0.43, 0.27, (30, 90, 16)),
    ])

    gen_bush("bush_large.png", 128, 100, [
        (0.50, 0.68, 0.30, (22, 75, 12)),
        (0.24, 0.74, 0.23, (16, 60, 8)),
        (0.76, 0.72, 0.24, (26, 82, 14)),
        (0.50, 0.44, 0.25, (30, 90, 16)),
        (0.34, 0.54, 0.21, (20, 70, 10)),
        (0.66, 0.52, 0.22, (25, 78, 13)),
    ])

    gen_flower()
    gen_rock()
    gen_mushroom()

    print("Done. 6 sprites generated.")
