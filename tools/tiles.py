#!/usr/bin/env python3
"""Les tuiles de decor, de ComfyUI jusqu'a l'atlas du TileSet.

    tools/tiles.py gen                genere les candidats (3 graines par sujet)
    tools/tiles.py gen --only floor   un seul sujet
    tools/tiles.py make               assemble art/tiles/atlas.png depuis les graines retenues

Le moteur (ComfyUI, SDXL + pixel-art-xl) est celui de `tools/item_icons.py`.
Ce que la generation apporte ici, c'est la **matiere** : le grain, les fissures,
la distribution des valeurs. Ce qu'elle ne decide pas, c'est la **regle** : la
valeur du sol reste plus basse que celle des acteurs (jalon 24, §9), et le dessus
eclaire du mur reste peint par le code -- c'est lui qui fait lire une masse de
murs comme des blocs et non comme un empilement de briques.
"""
import argparse, json, os, sys
from PIL import Image
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

# La regle du jeu, pas celle du modele. Reprises de TilesetBuilder, ou elles sont
# la verite : le sol descendu d'un cran sous les acteurs, les murs sous le sol.
FLOOR_BASE = (0.21, 0.19, 0.21)
FLOOR_SPREAD = 0.075      # amplitude des valeurs autour de la base
WALL_BASE = (0.09, 0.08, 0.12)
WALL_SPREAD = 0.035

# La luminance visee, plus basse que celle de la couleur de base. Ce n'est pas un
# detail de reglage : **a moyenne egale, une texture se lit plus claire qu'un
# aplat**, parce que ses joints clairs accrochent l'oeil. Le sol procedural
# tenait a 0,196 de moyenne ; la meme moyenne en pierre appareillee noyait les
# ennemis dedans (constate a la capture). 0,150 rend l'ecart mesure au jalon 24,
# §9 -- 95 % des pixels d'un acteur sont a 0,316.
FLOOR_LUM = 0.150
WALL_LUM = 0.070

# Nombre d'amas de pierre par tuile de sol, dans l'ordre des variantes. **La
# premiere est nue** : c'est elle qui domine la carte, et quatre tuiles toutes
# marquees se repetent visiblement des qu'on en voit trente. La regle vient du
# dessin procedural, ou elle etait deja ecrite -- « tuile neutre, celle qui
# domine ». Le mur, lui, passe None : il est couvert, et c'est ce qui fait que
# les deux ne sont pas le meme materiau a deux valeurs.
FLOOR_PATCHES = (0, 3, 4, 5)
LEVELS = 5                # autant de paliers qu'une rampe d'ArtPalette


def raw_path(name, seed):
    return os.path.join(WORK, "%s_%d.png" % (name, seed))


def cmd_gen(args):
    os.makedirs(WORK, exist_ok=True)
    for name, (subj, _) in SUBJECTS.items():
        if args.only and name != args.only:
            continue
        for seed in SEEDS:
            out = raw_path(name, seed)
            if os.path.exists(out) and not args.force:
                print("  deja la :", os.path.basename(out))
                continue
            img = render(TMPL.format(subj=subj), seed, NEG)
            img.save(out)
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


def to_palette(a, base, spread, window, target, patches=None):
    """Ramene la texture dans la fourchette de valeurs du jeu, puis la quantifie
    en LEVELS paliers. C'est ici que la generation cesse de decider : le modele
    donne le grain, la table donne la valeur.

    `window` est mesuree **une fois sur le rendu entier** et partagee par les
    quatre variantes. Normalisee chacune sur ses propres extremes, une decoupe
    sombre et une claire ressortent a la meme valeur moyenne, et le sol devient
    un patchwork des qu'elles se touchent."""
    lum = a @ np.array([0.2126, 0.7152, 0.0722])
    lo, hi = window
    k = np.clip((lum - lo) / max(hi - lo, 1e-6), 0.0, 1.0)
    k = np.round(k * (LEVELS - 1)) / (LEVELS - 1)          # paliers francs
    shift = (k - 0.5) * 2.0 * spread

    # Combien de **taches** la tuile porte, et non quelle part de sa surface.
    #
    # C'est le reglage qui separe un sol d'un mur, et il ne se voit sur aucun
    # rendu isole : une texture qui couvre son cadre d'un bord a l'autre est une
    # paroi, quelle que soit sa couleur -- le sol ressortait comme « le mur
    # repeint ». Baisser seulement l'amplitude ne suffit pas : ca garde le
    # contour de chaque caillou, donc le quadrillage. Il faut que la pierre soit
    # **rare dans l'espace** : quelques amas, du sol nu entre eux.
    if patches is not None:
        marked = np.abs(shift) >= np.percentile(np.abs(shift), 72)
        labels, found = ndimage.label(marked)
        if found:
            sizes = ndimage.sum(marked, labels, range(1, found + 1))
            biggest = np.argsort(-sizes)[:patches] + 1 if patches else np.zeros(0)
            # Le reste ne disparait pas tout a fait : un sol parfaitement plat
            # se lit comme un trou dans l'image.
            shift = np.where(np.isin(labels, biggest), shift, shift * 0.16)

    out = np.array(base)[None, None, :] + shift[:, :, None]
    # Recentree sur la valeur voulue : la quantification en paliers ne tombe pas
    # symetriquement autour de la base, et le sol finissait a 0,17 la ou le jeu
    # le veut a 0,21 -- c'est ce chiffre qui tient l'ecart avec les acteurs.
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


def tile_from(img, window, base, spread, target, at, patches=None):
    """`at` : le coin de la decoupe en pixels, choisi par `best_offsets`."""
    side = min(img.size) * CROP // 100
    a = np.asarray(img.crop((at[0], at[1], at[0] + side, at[1] + side)).resize((TILE, TILE), Image.BOX),
                   dtype=float) / 255.0
    return to_palette(a, base, spread, window, target, patches)


def cmd_make(args):
    atlas = Image.new("RGB", (TILE * 6, TILE))

    # Quatre sols : le meme materiau a quatre endroits, pour que la repetition ne
    # saute pas aux yeux. Faire varier leur **position** et non leur taille --
    # quatre tailles voisines donnent quatre echelles de pierre, ce qui se voit
    # des qu'elles se touchent.
    floor = Image.open(raw_path("floor", SUBJECTS["floor"][1])).convert("RGB")
    side = min(floor.size) * CROP // 100
    window = window_of(floor)
    for i, at in enumerate(best_offsets(floor, side, len(FLOOR_PATCHES))):
        t = tile_from(floor, window, FLOOR_BASE, FLOOR_SPREAD, FLOOR_LUM, at, FLOOR_PATCHES[i])
        atlas.paste(Image.fromarray((t * 255).astype(np.uint8)), (i * TILE, 0))

    wall_img = Image.open(raw_path("wall", SUBJECTS["wall"][1])).convert("RGB")
    wall = tile_from(wall_img, window_of(wall_img), WALL_BASE, WALL_SPREAD, WALL_LUM,
                     best_offsets(wall_img, min(wall_img.size) * CROP // 100, 1)[0])
    atlas.paste(Image.fromarray((wall * 255).astype(np.uint8)), (4 * TILE, 0))

    # Le dessus eclaire : la **regle**, pas la generation. Sept rangees, comme
    # dans TilesetBuilder, sur la meme pierre que l'interieur.
    edge = wall.copy()
    edge[:7] = np.clip(edge[:7] + 0.085, 0.0, 1.0)
    edge[7] = np.clip(edge[7] + 0.045, 0.0, 1.0)
    atlas.paste(Image.fromarray((edge * 255).astype(np.uint8)), (5 * TILE, 0))

    dest = os.path.join(PROJ, "art", "tiles")
    os.makedirs(dest, exist_ok=True)
    out = os.path.join(dest, "atlas.png")
    atlas.save(out)
    print("atlas ->", out)


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
