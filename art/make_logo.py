"""Draws the Leboof icon into art/ (512, 256 and 128 px PNGs) and the in-game icon
Leboof/Media/Icon.tga (128 px; the game reads TGA with power-of-two sizes; the .toc's IconTexture
uses it for the AddOns list and the addon compartment).

The design: two gold chevrons pointing up (a buff) on a dark teal rounded square, with a small red
pip in the corner for the "missing" look of the keep row.

Needs Pillow. Run: python3 art/make_logo.py
"""
import pathlib

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
ART = ROOT / "art"
GAME_ICON = ROOT / "Leboof" / "Media" / "Icon.tga"
S = 2048  # draw big, downsample for smooth edges

TEAL_TOP = (36, 120, 128)
TEAL_BOT = (8, 36, 44)
RIM = (120, 210, 210)
GOLD_TOP = (255, 226, 130)
GOLD_BOT = (214, 150, 40)
GLOW = (255, 214, 110)
RED = (214, 52, 46)
RED_DARK = (110, 16, 14)


def vgrad(w, h, top, bot):
    g = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return g.resize((w, h))


def rounded_mask(box, radius):
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=radius, fill=255)
    return mask


def chevron(draw, cx, apex_y, half_w, thick):
    """An upward chevron with round ends and a round apex, as a thick polyline."""
    pts = [(cx - half_w, apex_y + half_w), (cx, apex_y), (cx + half_w, apex_y + half_w)]
    draw.line(pts, fill=255, width=thick, joint="curve")
    r = thick / 2
    for x, y in (pts[0], pts[2]):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=255)


def draw_icon():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pad, radius = 40, 360
    body = rounded_mask([pad, pad, S - pad, S - pad], radius)

    # Background: teal gradient, a soft light from the top, a thin bright rim.
    bg = vgrad(S, S, TEAL_TOP, TEAL_BOT).convert("RGBA")
    light = Image.new("L", (S, S), 0)
    ImageDraw.Draw(light).ellipse([-S * 0.2, -S * 0.75, S * 1.2, S * 0.55], fill=70)
    light = light.filter(ImageFilter.GaussianBlur(160))
    bg = Image.composite(Image.new("RGBA", (S, S), (255, 255, 255, 255)), bg, light)
    img.paste(bg, (0, 0), body)

    rim = ImageChops.subtract(body, rounded_mask([pad + 34, pad + 34, S - pad - 34, S - pad - 34], radius - 34))
    rim_col = Image.new("RGBA", (S, S), RIM + (255,))
    rim_alpha = rim.point(lambda v: v * 0.55)
    img.paste(rim_col, (0, 0), rim_alpha)

    # The chevrons: a mask, a dark drop shadow, a gold glow, then the gold fill.
    shape = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(shape)
    cx, half_w, thick = S / 2, 560, 250
    chevron(d, cx, 470, half_w, thick)
    chevron(d, cx, 930, half_w, thick)

    shadow = shape.filter(ImageFilter.GaussianBlur(40)).point(lambda v: v * 0.6)
    img.paste(Image.new("RGBA", (S, S), (0, 0, 0, 255)), (0, 50), shadow)

    glow = shape.filter(ImageFilter.GaussianBlur(120)).point(lambda v: v * 0.55)
    img.paste(Image.new("RGBA", (S, S), GLOW + (255,)), (0, 0), ImageChops.multiply(glow, body))

    gold = vgrad(S, S, GOLD_TOP, GOLD_BOT).convert("RGBA")
    img.paste(gold, (0, 0), shape)

    # A thin highlight along the top edge of each chevron.
    inner = shape.filter(ImageFilter.MinFilter(41))
    edge = ImageChops.subtract(shape, ImageChops.offset(inner, 0, 22)).point(lambda v: v * 0.5)
    img.paste(Image.new("RGBA", (S, S), (255, 248, 220, 255)), (0, 0), ImageChops.subtract(edge, ImageChops.offset(shape, 0, -30).point(lambda v: 255 - v)))

    # The red "missing" pip, bottom right.
    px, py, pr = S - pad - 330, S - pad - 330, 150
    d = ImageDraw.Draw(img)
    d.ellipse([px - pr - 22, py - pr - 22, px + pr + 22, py + pr + 22], fill=RED_DARK + (255,))
    d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=RED + (255,))
    shine = Image.new("L", (S, S), 0)
    ImageDraw.Draw(shine).ellipse([px - pr * 0.6, py - pr * 0.75, px + pr * 0.2, py - pr * 0.1], fill=110)
    shine = shine.filter(ImageFilter.GaussianBlur(18))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), shine)

    # Keep everything inside the rounded square.
    alpha = ImageChops.multiply(img.getchannel("A"), body)
    img.putalpha(alpha)
    return img


def main():
    big = draw_icon()
    for px in (512, 256, 128):
        big.resize((px, px), Image.LANCZOS).save(ART / f"leboof-icon-{px}.png")
    GAME_ICON.parent.mkdir(exist_ok=True)
    big.resize((128, 128), Image.LANCZOS).save(GAME_ICON)
    print(f"Wrote art/leboof-icon-{{512,256,128}}.png and {GAME_ICON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
