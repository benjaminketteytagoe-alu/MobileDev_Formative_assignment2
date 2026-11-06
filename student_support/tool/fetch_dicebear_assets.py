"""Downloads the DiceBear SVGs that ship inside the app.

Category icons and empty-state mascots are bundled, not fetched at runtime:
they are functional UI, so they must render instantly and offline (the
"could not load" mascot is most likely to appear with no connection).
User avatars are different: they depend on the user, so the app fetches and
caches those at runtime (lib/core/dicebear.dart).

Run from the student_support folder after changing anything below:

    python3 tool/fetch_dicebear_assets.py

Licences: the `icons` style is MIT (Bootstrap Icons), `voxel-bot` is CC0.
The notices are in assets/images/dicebear/LICENSE.txt.
"""

import os
import re
import urllib.parse
import urllib.request

BASE = "https://api.dicebear.com/10.x"
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "dicebear")

# category: (icon, background). Keep colors in sync with AppColors.category*.
CATEGORY_ICONS = {
    "facility": ("building", "ff7a1a"),
    "water": ("droplet", "00a8e8"),
    "electricity": ("lightningCharge", "f5b014"),
    "furniture": ("lamp", "8b5cf6"),
    "sanitation": ("bucket", "12b76a"),
    "safety": ("bandaid", "e4312b"),
}

# Empty-state mascots. The animated CSS stays inside the file.
MASCOTS = {
    # These seeds pick the artwork. They are not the app name: changing one
    # changes that mascot.
    "mascot_empty": "campusfix-empty",
    "mascot_search": "campusfix-search",
    "mascot_error": "campusfix-error",
}


def fetch(url, path):
    request = urllib.request.Request(url, headers={"User-Agent": "campussupport-tool"})
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read()
    if b"<svg" not in body:
        raise ValueError(f"not an SVG: {url}")
    # flutter_svg warns about <metadata>. The notices are in LICENSE.txt.
    body = re.sub(rb"<metadata.*?</metadata>", b"", body, flags=re.S)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as out:
        out.write(body)
    print("wrote", os.path.normpath(path), len(body))


def main():
    for category, (icon, color) in CATEGORY_ICONS.items():
        query = urllib.parse.urlencode(
            {
                "seed": category,
                "iconVariant": icon,
                "backgroundColor": color,
                "iconColor": "ffffff",
                "scale": 0.7,
            }
        )
        fetch(f"{BASE}/icons/svg?{query}", os.path.join(OUT, "icons", f"{category}.svg"))

    for name, seed in MASCOTS.items():
        query = urllib.parse.urlencode({"seed": seed, "animationVariant": "medium"})
        fetch(f"{BASE}/voxel-bot/svg?{query}", os.path.join(OUT, f"{name}.svg"))


if __name__ == "__main__":
    main()
