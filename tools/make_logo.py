"""Generate the HealthTrackMe brand logo (gradient squircle + heart with ECG knockout).

Renders at high resolution with supersampling, then downsamples for crisp edges.
Palette matches lib/config/theme.dart / ai_assistant.dart (blue -> violet accent).
"""
import math
from PIL import Image, ImageDraw

# --- palette (from the app theme) ---
BLUE = (74, 124, 232)      # slightly deeper 0xFF5B8DEF for richer gradient
VIOLET = (124, 74, 240)    # slightly deeper 0xFF8B5CF6
WHITE = (255, 255, 255)

SS = 4  # supersampling factor


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def diagonal_gradient(size, c0, c1):
    """Top-left c0 -> bottom-right c1 diagonal gradient."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    maxd = (size - 1) * 2.0
    for y in range(size):
        for x in range(size):
            t = (x + y) / maxd
            px[x, y] = lerp(c0, c1, t)
    return img


def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def heart_polygon(cx, cy, scale):
    """Parametric heart curve, returns list of (x, y) points."""
    pts = []
    steps = 400
    for i in range(steps + 1):
        t = math.pi * 2 * i / steps
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * scale, cy - y * scale))
    return pts


def ecg_points(size):
    """ECG / heartbeat polyline across the icon (normalized -> pixels)."""
    norm = [
        (0.04, 0.50), (0.32, 0.50), (0.385, 0.40), (0.45, 0.66),
        (0.52, 0.255), (0.60, 0.60), (0.66, 0.50), (0.96, 0.50),
    ]
    return [(x * size, y * size) for x, y in norm]


def build_icon(size, with_bg=True):
    S = size * SS
    radius = int(S * 0.235)  # iOS-ish squircle corner

    # base layer (gradient squircle, or transparent for glyph-only)
    if with_bg:
        grad = diagonal_gradient(S, BLUE, VIOLET).convert("RGBA")
        mask = rounded_mask(S, radius)
        base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        base.paste(grad, (0, 0), mask)
        # soft top-left sheen
        sheen = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sheen)
        sd.ellipse([-S * 0.25, -S * 0.45, S * 0.85, S * 0.55], fill=(255, 255, 255, 28))
        base = Image.alpha_composite(base, _clip(sheen, mask))
    else:
        base = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # heart layer (white, opaque) on its own RGBA layer
    heart = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(heart)
    cx, cy = S * 0.5, S * 0.49
    hd.polygon(heart_polygon(cx, cy, S * 0.0242), fill=WHITE + (255,))

    # knock the ECG line OUT of the heart so the background shows through
    knock = Image.new("L", (S, S), 0)
    kd = ImageDraw.Draw(knock)
    lw = int(S * 0.052)
    pts = ecg_points(S)
    kd.line(pts, fill=255, width=lw, joint="curve")
    for p in pts:
        kd.ellipse([p[0] - lw / 2, p[1] - lw / 2, p[0] + lw / 2, p[1] + lw / 2], fill=255)
    # erase: where knock==255, set heart alpha to 0
    ha = heart.split()[3]
    ha = Image.composite(Image.new("L", (S, S), 0), ha, knock)
    heart.putalpha(ha)

    out = Image.alpha_composite(base, heart)
    if with_bg:
        out = _clip(out, mask)  # keep within squircle
    out = out.resize((size, size), Image.LANCZOS)
    return out


def _clip(img, mask):
    r, g, b, a = img.split()
    a = Image.composite(a, Image.new("L", img.size, 0), mask)
    return Image.merge("RGBA", (r, g, b, a))


def build_banner(w, h):
    """Horizontal lockup: gradient bg + icon left-center + wordmark + tagline."""
    sw, sh = w * SS, h * SS

    # gradient background (same diagonal as the icon, but landscape crop)
    long = max(sw, sh)
    grad = diagonal_gradient(long, BLUE, VIOLET).convert("RGBA")
    grad = grad.crop((0, 0, sw, sh))

    # soft sheen
    vign = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vign)
    vd.ellipse([-sw * 0.3, -sh * 0.6, sw * 0.6, sh * 1.6], fill=(255, 255, 255, 20))
    banner = Image.alpha_composite(grad, vign)

    # icon at 46 % of height, left margin 6 %
    icon_px = int(sh * 0.46)
    icon = build_icon(icon_px // SS, with_bg=True).resize((icon_px, icon_px), Image.LANCZOS)
    ix = int(sw * 0.06)
    iy = (sh - icon_px) // 2
    banner.paste(icon, (ix, iy), icon)

    # text column starts right of icon with a gap
    tx = ix + icon_px + int(sw * 0.05)
    avail_w = sw - tx - int(sw * 0.03)

    try:
        from PIL import ImageFont
        import os
        font_path = None
        for fc in ["C:/Windows/Fonts/arialbd.ttf",
                   "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
            if os.path.exists(fc):
                font_path = fc
                break

        def fit_font(text, max_w, start_size):
            sz = start_size
            while sz > 12:
                f = ImageFont.truetype(font_path, sz) if font_path else ImageFont.load_default()
                bb = ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), text, font=f)
                if (bb[2] - bb[0]) <= max_w:
                    return f, sz
                sz -= 4
            return ImageFont.load_default(), sz

        font_bold, _ = fit_font("HealthTrackMe", avail_w, int(sh * 0.13))
        font_small, _ = fit_font("Your health, one place.", avail_w, int(sh * 0.072))
    except Exception:
        from PIL import ImageFont
        font_bold = ImageFont.load_default()
        font_small = font_bold

    td = ImageDraw.Draw(banner)
    wordmark = "HealthTrackMe"
    tagline = "Your health, one place."

    bb = td.textbbox((0, 0), wordmark, font=font_bold)
    wh = bb[3] - bb[1]
    sb = td.textbbox((0, 0), tagline, font=font_small)
    th = sb[3] - sb[1]
    gap = int(sh * 0.045)
    ty = (sh - (wh + gap + th)) // 2

    td.text((tx, ty), wordmark, fill=(255, 255, 255, 255), font=font_bold)
    td.text((tx, ty + wh + gap), tagline, fill=(255, 255, 255, 175), font=font_small)

    return banner.resize((w, h), Image.LANCZOS)


if __name__ == "__main__":
    import os
    out_dir = os.path.join(os.path.dirname(__file__), "..", "apps", "mobile_flutter", "assets", "images")
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)

    master = build_icon(1024, with_bg=True)
    for sz in (1024, 512, 256):
        master.resize((sz, sz), Image.LANCZOS).save(os.path.join(out_dir, f"logo_{sz}.png"))
        print("wrote", os.path.join(out_dir, f"logo_{sz}.png"))

    glyph = build_icon(512, with_bg=False)
    glyph.save(os.path.join(out_dir, "logo_glyph_512.png"))
    print("wrote", os.path.join(out_dir, "logo_glyph_512.png"))

    banner = build_banner(700, 500)
    banner.save(os.path.join(out_dir, "logo_banner_700x500.png"))
    print("wrote", os.path.join(out_dir, "logo_banner_700x500.png"))
