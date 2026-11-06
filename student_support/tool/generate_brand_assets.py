"""Draws the CampusSupport "CS" mark: assets/images/logo.svg plus the PNGs used
by the launcher icon and the native splash.

The colors must match lib/core/theme/app_colors.dart, so if you change them
there, change them here too and run, from the student_support folder:

    python3 tool/generate_brand_assets.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

To use a designed logo instead, replace the four files this script writes and
run the two dart commands.

Requires Pillow and fontTools (pip install pillow fonttools) and the Inter
font. Set INTER_BOLD if yours is somewhere else. The letters are stored as
outlines, so the app does not need the font.
"""

import os

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

# ALU brand colors. Keep in sync with AppColors.aluNavy/aluGold.
NAVY = "#0B2A5B"
GOLD = "#F5B014"
WHITE = "#FFFFFF"

FONT = os.environ.get("INTER_BOLD", "/usr/share/fonts/opentype/inter/Inter-Bold.otf")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "images")
SUPERSAMPLE = 4

# Design units, on a 200 x 200 square.
TEXT = "CS"
TEXT_WIDTH = 132
TEXT_CENTER_Y = 90
BAR = (56, 146, 88, 12)  # x, y, width, height
TILE_INSET = 6
TILE_RADIUS = 44
TILE_BORDER = 8


def svg_letters():
    """The letters as one SVG path, fitted to TEXT_WIDTH and centred."""
    font = TTFont(FONT)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    names = [cmap[ord(c)] for c in TEXT]

    advance = sum(glyphs[n].width for n in names)
    scale = TEXT_WIDTH / advance
    cap_height = font["OS/2"].sCapHeight

    pen = SVGPathPen(glyphs, ntos=lambda v: f"{v:.2f}".rstrip("0").rstrip("."))
    x = (200 - TEXT_WIDTH) / 2
    baseline = TEXT_CENTER_Y + cap_height * scale / 2
    for name in names:
        glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, x, baseline)))
        x += glyphs[name].width * scale
    return pen.getCommands()


def write_svg():
    inset, radius, border = TILE_INSET, TILE_RADIUS, TILE_BORDER
    side = 200 - inset * 2
    bx, by, bw, bh = BAR
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <!-- CampusSupport mark. Written by tool/generate_brand_assets.py. -->
  <rect x="{inset}" y="{inset}" width="{side}" height="{side}" rx="{radius}" fill="{NAVY}" stroke="{GOLD}" stroke-width="{border}"/>
  <path d="{svg_letters()}" fill="{WHITE}"/>
  <rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="{bh / 2}" fill="{GOLD}"/>
</svg>
"""
    path = os.path.normpath(os.path.join(OUT_DIR, "logo.svg"))
    with open(path, "w") as f:
        f.write(svg)
    print("wrote", path)


def draw_mark(size, scale):
    """The letters and bar on a transparent image, centred, at `scale` px per
    design unit. There is no tile: the icon and splash backgrounds are navy."""
    ss = SUPERSAMPLE
    img = Image.new("RGBA", (size * ss, size * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    unit = scale * ss
    origin = (size * ss - 200 * unit) / 2

    def px(v):
        return origin + v * unit

    font = ImageFont.truetype(FONT, 1000)
    font = ImageFont.truetype(FONT, 1000 * TEXT_WIDTH * unit / font.getlength(TEXT))
    d.text((px(100), px(TEXT_CENTER_Y)), TEXT, font=font, fill=WHITE, anchor="mm")

    bx, by, bw, bh = BAR
    d.rounded_rectangle(
        [px(bx), px(by), px(bx + bw), px(by + bh)], radius=bh * unit / 2, fill=GOLD
    )
    return img.resize((size, size), Image.LANCZOS)


def save(img, name):
    path = os.path.normpath(os.path.join(OUT_DIR, name))
    img.save(path)
    print("wrote", path)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    write_svg()

    # Full launcher icon: navy tile with the mark. 1024 px.
    icon = Image.new("RGBA", (1024, 1024), NAVY)
    icon.alpha_composite(draw_mark(1024, 3.6))
    save(icon, "app_icon.png")

    # Adaptive icon foreground: the mark inside the central 66% safe zone.
    save(draw_mark(1024, 2.9), "app_icon_foreground.png")

    # Native splash logo. Android 12 crops the splash icon to a circle about
    # two thirds of the image, so the mark stays well inside it.
    save(draw_mark(1152, 2.4), "logo_splash.png")


if __name__ == "__main__":
    main()
