#!/usr/bin/env python3
"""Le decor du biome : tuiles de mur, textures du sol, arbres, buissons et rochers.

    tools/tiles.py gen                genere les candidats (3 graines par sujet)
    tools/tiles.py gen --only rock    un seul sujet
    tools/tiles.py make               ecrit art/tiles/ et art/decor/ depuis les graines retenues

Le moteur (ComfyUI, SDXL + pixel-art-xl) est celui de `tools/item_icons.py`.
Pour le mur, la generation apporte la **matiere** et la table la valeur ; le
dessus eclaire reste peint par le code. Le sol, lui, n'est pas genere : SDXL en
sort des dalles a tous les coups, et une terre marbree a quatre tons se tire
mieux d'un bruit (jalon 33).
"""
import argparse, json, os, sys
from PIL import Image, ImageDraw
import numpy as np
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from item_icons import HOST, PROJ, SEEDS, render  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.environ.get("HNS_TILE_WORK", os.path.join(os.environ.get("TMPDIR", "/tmp"), "hns-tiles"))
SUBJECTS = json.load(open(os.path.join(HERE, "tiles.json"), encoding="utf-8"))

TILE = 32

TMPL = ("pixel art texture, 16-bit rpg {subj}, seamless repeating tile, "
        "top-down orthographic view, flat even lighting, muted desaturated colors, "
        "fine detail, no objects, no characters")
# Il ne refuse **pas** « tiled pattern » ni « grid », contrairement a celui des
# objets : ici la repetition est le sujet.
#
# Il refuse en revanche toute la maconnerie, et ce n'est pas un detail de gout :
# sans ca, « dungeon stone floor » sort un mur de briques a tous les coups, et le
# sol finit par etre le mur repeint d'une autre couleur -- constate a la capture.
NEG = ("brick, brickwork, bricks, masonry, mortar lines, regular rows, running bond, "
       "wall, vertical surface, "
       "text, letters, watermark, signature, blurry, photo, 3d render, realistic, "
       "character, person, creature, weapon, furniture, door, torch, "
       "perspective, vanishing point, horizon, vignette, drop shadow, "
       "lighting gradient, spotlight, frame, border")
# Le decor, detoure ensuite : le gabarit des icones d'objets, vu de trois quarts.
PROP_TMPL = ("detailed pixel art, dark fantasy action rpg game asset, top-down three-quarter view, {subj}, "
             "one single object, centered, crisp dark outline, detailed shading, "
             "isolated on a plain flat neutral grey background, empty background, no ground, no shadow")
PROP_NEG = ("text, letters, watermark, blurry, photo, 3d render, realistic, gradient background, scenery, "
            "landscape, multiple objects, collection, sprite sheet, grid, person, character, frame, border")

# Le mur, repris de TilesetBuilder ou il est la verite : sous le sol, pour se
# lire comme un trou dans la terre.
WALL_BASE = (0.12, 0.07, 0.05)
WALL_SPREAD = 0.035
WALL_LUM = 0.070
LEVELS = 5                # autant de paliers qu'une rampe d'ArtPalette

# Le biome ocre, choisi sur planche contre trois autres (jalon 33) : terre brulee
# et taches sable, du plus sombre au plus clair. Le shader du sol choisit entre
# les deux textures par blocs de 4 px ; elles partagent le meme grain.
GROUND_BASE = ((52, 30, 20), (68, 40, 26), (80, 48, 31), (92, 56, 36))
GROUND_PATCH = ((110, 72, 48), (122, 84, 58), (136, 98, 70))
GRASS = ((90, 60, 25), (150, 110, 45), (200, 160, 80))
GROUND_SIDE = 256
# Touffes par texture : la densite de la planche, 170 pour 640 x 360 px.
GRASS_TUFTS = 48


def raw_path(name, seed):
    return os.path.join(WORK, "%s_%d.png" % (name, seed))


def subjects():
    """(nom, gabarit, sujet, negatif) : le mur est une texture, le decor un objet detoure."""
    yield "wall", TMPL, SUBJECTS["wall"][0], NEG
    for name, (subj, _, _) in SUBJECTS["decor"].items():
        yield name, PROP_TMPL, subj, PROP_NEG


def cmd_gen(args):
    os.makedirs(WORK, exist_ok=True)
    for name, tmpl, subj, neg in subjects():
        if args.only and name != args.only:
            continue
        for seed in SEEDS:
            out = raw_path(name, seed)
            if os.path.exists(out) and not args.force:
                print("  deja la :", os.path.basename(out))
                continue
            render(tmpl.format(subj=subj), seed, neg).save(out)
            print("  %-8s graine %-5d -> %s" % (name, seed, out))


def seam_error(t):
    """Ce que coute le raccord d'une tuile avec sa voisine : l'ecart entre son
    bord gauche et son bord droit, et entre le haut et le bas."""
    return float(np.abs(t[:, 0] - t[:, -1]).mean() + np.abs(t[0, :] - t[-1, :]).mean())


def best_offsets(img, side, count, spread=0.76):
    """Cherche les `count` decoupes qui se raccordent le mieux, au lieu de forcer
    le raccord par un fondu.

    Le fondu etait la premiere methode : decaler puis fondre la derniere bande
    dans la premiere. Il ferme bien la couture, mais il **bave sur cinq pixels
    de chaque bord**, et cette bavure redessine la grille de tuiles a l'ecran.
    Chercher un bon raccord ne coute rien -- quelques centaines de decoupes
    evaluees sur une image deja en memoire -- et ne touche pas un pixel.
    """
    free_x, free_y = img.width - side, img.height - side
    margin = (1.0 - spread) / 2.0
    scored = []
    for iy in range(12):
        for ix in range(12):
            x = int(free_x * (margin + spread * ix / 11.0))
            y = int(free_y * (margin + spread * iy / 11.0))
            t = np.asarray(img.crop((x, y, x + side, y + side)).resize((TILE, TILE), Image.BOX),
                           dtype=float) / 255.0
            scored.append((seam_error(t), x, y))
    scored.sort()
    # Espacees d'au moins une demi-decoupe : quatre variantes prises au meme
    # endroit a deux pixels pres sont quatre fois la meme tuile.
    kept = []
    for err, x, y in scored:
        if all(abs(x - kx) > side // 2 or abs(y - ky) > side // 2 for kx, ky in kept):
            kept.append((x, y))
        if len(kept) == count:
            break
    return kept


def to_palette(a, base, spread, window, target):
    """Ramene la texture dans la fourchette de valeurs du jeu, puis la quantifie
    en LEVELS paliers. C'est ici que la generation cesse de decider : le modele
    donne le grain, la table donne la valeur. `window` est mesuree sur le rendu
    entier, pas sur la decoupe, qui ressortirait sinon toujours a la meme valeur."""
    lum = a @ np.array([0.2126, 0.7152, 0.0722])
    lo, hi = window
    k = np.clip((lum - lo) / max(hi - lo, 1e-6), 0.0, 1.0)
    k = np.round(k * (LEVELS - 1)) / (LEVELS - 1)          # paliers francs
    shift = (k - 0.5) * 2.0 * spread

    out = np.array(base)[None, None, :] + shift[:, :, None]
    # Recentree sur la valeur voulue : la quantification en paliers ne tombe pas
    # symetriquement autour de la base.
    weights = np.array([0.2126, 0.7152, 0.0722])
    out += target - float((out @ weights).mean())
    return np.clip(out, 0.0, 1.0)


# Part du rendu de 1024 px qu'une tuile couvre. C'est **l'echelle de la pierre**,
# le seul reglage qui decide si le sol se lit ou part en bruit : a 10 %, un pave
# du rendu fait six pixels dans la tuile ; a 30 %, il en fait un, et il ne reste
# qu'un grain gris. Mesure sur planche, six decoupes comparees.
CROP = 10


def window_of(img):
    """Les extremes du rendu entier, en luminance : la reference commune des
    decoupes. 3 et 97 centiles, pour qu'un eclat isole n'ecrase pas l'echelle."""
    lum = np.asarray(img, dtype=float) / 255.0 @ np.array([0.2126, 0.7152, 0.0722])
    # 10 et 90 et non 3 et 97 : avec les extremes, une decoupe ordinaire n'occupe
    # qu'une partie des paliers et ressort plate.
    return float(np.percentile(lum, 10)), float(np.percentile(lum, 90))


def tile_from(img, window, base, spread, target, at):
    """`at` : le coin de la decoupe en pixels, choisi par `best_offsets`."""
    side = min(img.size) * CROP // 100
    a = np.asarray(img.crop((at[0], at[1], at[0] + side, at[1] + side)).resize((TILE, TILE), Image.BOX),
                   dtype=float) / 255.0
    return to_palette(a, base, spread, window, target)


def cmd_make(args):
    # Une tuile de sol unie : elle ne dit que « ici on marche », c'est le shader
    # qui peint la terre.
    atlas = Image.new("RGB", (TILE * 3, TILE), GROUND_BASE[1])

    wall_img = Image.open(raw_path("wall", SUBJECTS["wall"][1])).convert("RGB")
    wall = tile_from(wall_img, window_of(wall_img), WALL_BASE, WALL_SPREAD, WALL_LUM,
                     best_offsets(wall_img, min(wall_img.size) * CROP // 100, 1)[0])
    atlas.paste(Image.fromarray((wall * 255).astype(np.uint8)), (1 * TILE, 0))

    # Le dessus eclaire : la **regle**, pas la generation. Sept rangees, comme
    # dans TilesetBuilder, sur la meme pierre que l'interieur.
    edge = wall.copy()
    edge[:7] = np.clip(edge[:7] + 0.085, 0.0, 1.0)
    edge[7] = np.clip(edge[7] + 0.045, 0.0, 1.0)
    atlas.paste(Image.fromarray((edge * 255).astype(np.uint8)), (2 * TILE, 0))

    dest = os.path.join(PROJ, "art", "tiles")
    os.makedirs(dest, exist_ok=True)
    atlas.save(os.path.join(dest, "atlas.png"))
    for name, img in zip(("ground_base", "ground_patch"), ground_textures()):
        img.save(os.path.join(dest, name + ".png"))

    dest = os.path.join(PROJ, "art", "decor")
    os.makedirs(dest, exist_ok=True)
    for name, (_, seed, frame) in SUBJECTS["decor"].items():
        prop = keyed(Image.open(raw_path(name, seed)).convert("RGB"), frame)
        with_shadow(prop, name.startswith("tree")).save(os.path.join(dest, name + ".png"))
    print("art/tiles et art/decor ecrits")


BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def fbm(h, w, rng, scales, weights):
    """Bruit de valeur a plusieurs octaves, qui boucle : chaque echelle divise le cote."""
    n = 0
    for s, wt in zip(scales, weights):
        g = rng.random((h // s, w // s))
        n = n + wt * ndimage.zoom(np.pad(g, 1, mode="wrap"), s, order=3)[s:s + h, s:s + w]
    n -= n.min()
    return n / n.max()


def ground_textures(seed=4242):
    """La terre et ses taches claires, sur **le meme grain** : le shader passe de
    l'une a l'autre case a case sans que le motif saute. Raccordables : le bruit
    boucle sur GROUND_SIDE, la trame sur 4, les touffes par modulo."""
    rng = np.random.default_rng(seed)
    side = GROUND_SIDE
    fine = fbm(side, side, rng, (16, 8, 2), (1, .7, .5))
    dither = np.tile(BAYER, (side // 4, side // 4))
    out = []
    for pal in (GROUND_BASE, GROUND_PATCH):
        k = np.clip(fine * len(pal) + (dither - .5) * .9, 0, len(pal) - 1e-6).astype(int)
        out.append(np.array(pal, np.uint8)[k])
    # Brins isoles, puis touffes : les memes places sur les deux textures.
    for y, x in zip(*np.nonzero(rng.random((side, side)) < 0.012)):
        for img in out:
            img[(y - np.arange(3)) % side, x] = GROUND_BASE[-1]
    for _ in range(GRASS_TUFTS):
        x0, y0 = rng.integers(0, side, 2)
        for _ in range(rng.integers(4, 7)):
            x = int(rng.integers(1, 8)); h = int(rng.integers(3, 7)); lean = int(rng.choice([-1, 0, 1]))
            for k in range(h):
                c = GRASS[2] if k >= h - 2 else (GRASS[1] if k > 0 else GRASS[0])
                xx = (x0 + x + (lean if k > h // 2 else 0)) % side
                for img in out:
                    img[(y0 + 6 - k) % side, xx] = c
    return [Image.fromarray(img) for img in out]


def keyed(img, frame, tol=0.10):
    """Detoure par couleur **sur toute l'image**, pas depuis les bords comme
    `item_icons.cut` : le fond pris entre deux branches ne touche aucun bord, et
    restait en taches grises dans l'arbre (constate sur planche)."""
    a = np.asarray(img).astype(np.float32) / 255.0
    ring = np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3),
                           a[:, :4].reshape(-1, 3), a[:, -4:].reshape(-1, 3)])
    keep = np.linalg.norm(a - np.median(ring, 0), axis=2) > tol
    keep &= ~cast_shadow(a, keep)
    lab, n = ndimage.label(keep)
    sizes = ndimage.sum(keep, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, v in enumerate(sizes) if v >= sizes.max() * 0.10])
    ys, xs = np.nonzero(keep)
    box = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))
    a, m = a[box], keep[box].astype(np.float32)
    h, w = m.shape
    f = min(frame[0] / w, frame[1] / h)
    pre = Image.fromarray((np.dstack([a * m[..., None], m]) * 255).astype(np.uint8), "RGBA")
    q = np.asarray(pre.resize((max(1, round(w * f)), max(1, round(h * f))), Image.BOX),
                   dtype=np.float32) / 255.0
    al = q[..., 3]
    rgb = np.where(al[..., None] > .02, q[..., :3] / np.maximum(al, .02)[..., None], 0)
    out = Image.fromarray((np.dstack([np.clip(rgb, 0, 1), al >= .5]) * 255).astype(np.uint8), "RGBA")
    # 16 couleurs, comme la planche choisie : le rendu reduit en garde des
    # centaines, qui se lisent comme du flou.
    return out.quantize(16, dither=0).convert("RGBA")


def cast_shadow(a, keep):
    """L'ombre que SDXL pose au pied de l'objet malgre « no shadow, no ground » :
    un gris sans teinte, plus clair que l'ecorce, qui restait en tache grise sur
    la terre ocre. Retiree dans le bas de la silhouette seulement -- l'ecorce est
    grise elle aussi --, et partout au-dessus de 0,55, ou ce n'est que du reflet."""
    lum = a @ np.array([0.2126, 0.7152, 0.0722])
    grey = (a.max(2) - a.min(2)) < 0.045
    rows = np.nonzero(keep.any(1))[0]
    low = np.zeros_like(keep)
    low[rows.max() - (rows.max() - rows.min()) * 30 // 100:] = True
    return grey & ((low & (lum > 0.30)) | (lum > 0.55))


def with_shadow(prop, is_tree):
    """L'ombre au sol dans l'alpha, comme les sprites de la forge : un noir a 22 %
    sous le pied. Pas sous un arbre, qui pousse sur le bord d'un mur sombre."""
    if is_tree:
        return prop
    w, h = prop.size
    out = Image.new("RGBA", (w, h + 3), (0, 0, 0, 0))
    r = min(w * .3, 14)
    ImageDraw.Draw(out).ellipse((w / 2 - r, h - 2, w / 2 + r, h + 2), fill=(0, 0, 0, 56))
    out.alpha_composite(prop, (0, 0))
    return out


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen"); g.add_argument("--only"); g.add_argument("--force", action="store_true")
    g.set_defaults(func=cmd_gen)
    m = sub.add_parser("make"); m.set_defaults(func=cmd_make)
    a = ap.parse_args()
    a.func(a)


if __name__ == "__main__":
    main()
