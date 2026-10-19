#!/usr/bin/env python3
"""Le décor du monde en 3D (jalon 54, étape 3) : des modèles de Poly Haven (CC0, sans
territoire), réduits pour être posés par centaines (`blender/decor.py`), et des arbres morts
générés (`blender/dead_tree.py`).

    tools/decor_3d.py [nom…]     télécharge, réduit, écrit art/decor/<nom>.glb

Le jeu pose chaque modèle à l'échelle de son scan, en mètres (×16 px)."""
import json, os, subprocess, sys, urllib.request

sys.path.insert(0, os.path.dirname(__file__))
import character_forge as cf
from blender_sheet import BLENDER, win

API = "https://api.polyhaven.com/files/"
# L'API refuse le client sans nom (403) : elle demande qu'on se présente.
AGENT = {"User-Agent": "HnSProject-decor/1.0"}
RAW = os.path.join(cf.WORK, "decor")
OUT = os.path.join(cf.PROJ, "art", "decor")
# Nom dans le jeu → (modèle de Poly Haven, triangles gardés, plus grande dimension en jeu en
# mètres, pièce gardée d'un lot). Un rocher se lit en peu de faces ; branches et feuillage en
# demandent plus, sans quoi ils se trouent. Les tailles dépassent le réel, comme les armes :
# un caillou de 30 cm ne se voit pas d'où regarde la caméra.
DECOR = {
    "rock_a": ("rock_07", 1500, 1.0, None),
    "rock_b": ("rock_09", 1500, 0.8, None),
    "stone": ("stone_01", 1500, 0.7, None),
    "boulder": ("namaqualand_boulder_04", 3000, 2.6, None),
    "log": ("dead_tree_trunk_02", 3000, 3.0, None),
    "branch": ("dead_quiver_branch_01", 1500, 1.4, None),
    "twigs": ("dry_branches_medium_01", 2000, 1.4, "dry_branches_medium_01_a"),
    "stump": ("tree_stump_01", 2500, 1.3, None),
    "bush": ("shrub_04", 4000, 1.6, None),
}
# Les arbres morts debout, que Poly Haven n'a pas : générés (`blender/dead_tree.py`), une forme
# par graine, sous une écorce de Poly Haven. Leur hauteur en jeu, en mètres.
TREES = {"dead_tree_a": 11, "dead_tree_b": 23, "dead_tree_c": 37}
TREE_HEIGHT = 4.5
BARK = "jolcham_oak_bark_01"


def fetch(asset):
    """Le glTF 1k du modèle et ce qu'il inclut, une fois."""
    folder = os.path.join(RAW, asset)
    files = json.load(get(API + asset))["gltf"]["1k"]["gltf"]
    main = os.path.join(folder, os.path.basename(files["url"]))
    for rel, url in [(os.path.basename(files["url"]), files["url"])] + [(k, v["url"]) for k, v in files["include"].items()]:
        path = os.path.join(folder, rel)
        if not os.path.exists(path):
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as f:
                f.write(get(url).read())
    return main


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=AGENT))


def bark():
    """La couleur et le relief de l'écorce, une fois."""
    folder = os.path.join(RAW, BARK)
    files = json.load(get(API + BARK))
    out = []
    for kind in ("Diffuse", "nor_gl"):
        path = os.path.join(folder, kind + ".jpg")
        if not os.path.exists(path):
            os.makedirs(folder, exist_ok=True)
            with open(path, "wb") as f:
                f.write(get(files[kind]["1k"]["jpg"]["url"]).read())
        out.append(path)
    return out


def blender(script, *args):
    log = subprocess.run([BLENDER, "-b", "-P", win(os.path.join(os.path.dirname(__file__), "blender", script)),
                          "--", *args], capture_output=True, text=True).stdout
    print(next((l for l in log.splitlines() if l.startswith(("DECOR", "ARBRE"))), log[-800:]))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in sys.argv[1:] or list(DECOR) + list(TREES):
        target = win(os.path.join(OUT, name + ".glb"))
        if name in TREES:
            diffuse, normal = bark()
            blender("dead_tree.py", str(TREES[name]), str(TREE_HEIGHT), win(diffuse), win(normal), target)
            continue
        asset, faces, size, piece = DECOR[name]
        blender("decor.py", win(fetch(asset)), str(faces), str(size), piece or "-", target)


if __name__ == "__main__":
    main()
