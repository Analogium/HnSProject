#!/usr/bin/env python3
"""Les textures du relief (jalon 54, étape 3), pour `world/terrain.gdshader` : des scans de
Poly Haven (CC0, sans territoire), leur couleur recalée à mi-chemin sur la palette du biome.

    tools/terrain_textures.py     écrit art/tiles/<nom>.png et <nom>_nr.png (relief en RGB,
                                  rugosité en alpha)

Choisis sur planche contre des textures peintes par Qwen-Image, que l'utilisateur trouvait
« trop dessinées » ; le relief et la rugosité des scans font le semi-réaliste."""
import io, json, os, re, sys, urllib.request
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import character_forge as cf

TILES = os.path.join(cf.PROJ, "art", "tiles")
# Matière du shader → scan de Poly Haven.
SCANS = {"ground": "dry_ground_rocks", "grass": "burned_ground_01", "road": "gravelly_sand",
         "rock": "cliff_side", "top": "rocks_ground_02"}
# La couleur moyenne de chaque matière, recalée sur la palette du jeu (`TilesetBuilder`, une
# constante et sa part), à mi-chemin (GRADE) : en entier, un scan devenait un aplat orange.
PALETTE = {"ground": ("FLOOR_BASE", 1.0), "grass": ("FLOOR_BASE", 1.25), "road": ("FLOOR_BASE", 1.5),
           "rock": ("ROCK_BASE", 1.0), "top": ("ROCK_BASE", 0.85)}
GRADE = 0.5
# L'API refuse le client sans nom (403) : elle demande qu'on se présente.
AGENT = {"User-Agent": "HnSProject-decor/1.0"}


def graded(img, name):
    constant, share = PALETTE[name]
    builder = open(os.path.join(cf.PROJ, "world", "tileset_builder.gd"), encoding="utf-8").read()
    target = np.array(re.search(r"^const %s := Color\(([^)]*)\)" % constant, builder, re.M).group(1).split(", "),
                      np.float32)[:3] * share
    a = np.asarray(img, np.float32) / 255.0
    # Un gain par canal et non un décalage : décalée, la moyenne laissait sa teinte dans les clairs.
    gain = (target / a.mean((0, 1))) ** GRADE
    return Image.fromarray((np.clip(a * gain, 0.0, 1.0) * 255).astype(np.uint8))


def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=AGENT)).read()


def main():
    os.makedirs(TILES, exist_ok=True)
    for name, asset in SCANS.items():
        files = json.loads(fetch("https://api.polyhaven.com/files/" + asset))
        image = lambda kind: Image.open(io.BytesIO(fetch(files[kind]["1k"]["jpg"]["url"])))
        graded(image("Diffuse").convert("RGB"), name).save(os.path.join(TILES, name + ".png"))
        relief = image("nor_gl").convert("RGB")
        relief.putalpha(image("Rough").convert("L"))
        relief.save(os.path.join(TILES, name + "_nr.png"))
        print(name, asset)


if __name__ == "__main__":
    main()
