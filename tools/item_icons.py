#!/usr/bin/env python3
"""Les icônes d'objets, de ComfyUI jusqu'au .tres. Recette : resources/icons/LISEZMOI.md.

    tools/item_icons.py gen                  les 44 bases, trois tirages chacune
    tools/item_icons.py gen --only sword     une seule, pour la refaire
    tools/item_icons.py sheets               les planches de jugement, par famille
    tools/item_icons.py apply                pose les tirages retenus dans item_icons.json

ComfyUI doit tourner ; depuis WSL il ne répond pas sur 127.0.0.1 mais sur l'IP de
l'hôte Windows (`ip route`, la ligne `default via`), d'où la variable COMFY.
Les images intermédiaires vont dans un dossier de travail hors du dépôt : cent
trente tirages de 1024 px n'ont rien à y faire, seuls les retenus y entrent.
"""
import argparse, json, io, os, re, shutil, sys, time, urllib.request, urllib.parse
from PIL import Image, ImageDraw
import numpy as np
from scipy import ndimage

HOST = os.environ.get("COMFY", "http://172.27.128.1:8188")
HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
WORK = os.environ.get("HNS_ICON_WORK", os.path.join(os.environ.get("TMPDIR", "/tmp"), "hns-icons"))
RAW, OUT = os.path.join(WORK, "raw"), os.path.join(WORK, "out")
SEEDS = [4242, 777, 1337]

# Le gabarit partage : seul le sujet change. On ne demande pas une couleur de
# fond precise -- SDXL l'ignore -- seulement qu'il soit *plat* : le detourage se
# fait ensuite par remplissage depuis les bords, quelle que soit sa teinte.
TMPL = ("pixel art, 16-bit rpg inventory item icon, {subj}, centered, one single object, "
        "bold readable silhouette, high contrast, thick dark outline, "
        "isolated on a plain flat neutral grey background, empty background, "
        "no shadow, no ground, square game icon")
NEG = ("text, letters, watermark, signature, blurry, photo, 3d render, realistic, "
       "gradient background, scenery, room, table, wall, multiple objects, collection, "
       "sprite sheet, grid, tiled pattern, hands, person, character, "
       "drop shadow, frame, border")

SIDE = 24  # le cadre de SpriteForge.ICON
# Ecart de couleur en deca duquel un pixel de bord est encore du fond. 0,20 laisse
# passer le leger degrade que SDXL pose sur un fond « plat ».
BG_TOL = 0.20
# Le fond *enferme* par l'objet -- l'interieur d'une bague, la boucle d'une
# ceinture -- ne touche aucun bord. On le reconnait a sa couleur seule, donc a un
# ecart bien plus serre : a 0,20 l'acier gris d'un heaume partirait avec lui.
BG_TIGHT = 0.05

# Par base : le sujet du prompt, et la graine du tirage retenu. Les deux dans le
# meme fichier parce qu'ils ne veulent rien dire l'un sans l'autre -- refaire une
# icone, c'est changer l'un des deux et relancer `gen --only <base>`.
SUBJECTS = json.load(open(os.path.join(HERE, "item_icons.json"), encoding="utf-8"))


def workflow(prompt, seed, neg=None):
    """`neg` : le negatif du tirage. Par defaut celui des objets, qui refuse entre
    autres « tiled pattern » et « grid » -- a passer explicitement pour tout ce
    qui, justement, doit se repeter (les tuiles de decor)."""
    return {
      "ckpt": {"class_type": "CheckpointLoaderSimple",
               "inputs": {"ckpt_name": "sdXL_v10VAEFix.safetensors"}},
      "lora": {"class_type": "LoraLoader",
               "inputs": {"lora_name": "pixel-art-xl-v1.1.safetensors",
                          "strength_model": 1.0, "strength_clip": 1.0,
                          "model": ["ckpt", 0], "clip": ["ckpt", 1]}},
      "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["lora", 1]}},
      "neg": {"class_type": "CLIPTextEncode",
              "inputs": {"text": neg if neg is not None else NEG, "clip": ["lora", 1]}},
      "lat": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
      "ks": {"class_type": "KSampler",
             "inputs": {"seed": seed, "steps": 30, "cfg": 6.0, "sampler_name": "dpmpp_2m",
                        "scheduler": "karras", "denoise": 1.0, "model": ["lora", 0],
                        "positive": ["pos", 0], "negative": ["neg", 0], "latent_image": ["lat", 0]}},
      "vae": {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": ["ckpt", 2]}},
      "save": {"class_type": "SaveImage", "inputs": {"images": ["vae", 0], "filename_prefix": "hns_item"}},
    }


def post(path, payload):
    req = urllib.request.Request(HOST + path, json.dumps(payload).encode(),
                                 {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))


def render(prompt, seed, neg=None):
    pid = post("/prompt", {"prompt": workflow(prompt, seed, neg)})["prompt_id"]
    while True:
        h = json.load(urllib.request.urlopen(f"{HOST}/history/{pid}"))
        if pid in h:
            break
        time.sleep(1.0)
    img = h[pid]["outputs"]["save"]["images"][0]
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"],
                                "type": img["type"]})
    return Image.open(io.BytesIO(urllib.request.urlopen(f"{HOST}/view?{q}").read())).convert("RGB")


def cut(img):
    """Detoure le fond, recadre sur l'objet, reduit a SIDE par moyenne de zone.

    Le fond se reconnait a ce qu'il touche les bords, pas a sa couleur : SDXL
    ignore la couleur demandee mais obeit a « plat ». Un remplissage depuis le
    bord garde donc l'acier gris de l'objet, qu'un simple seuil de couleur
    effacerait.

    L'alpha est premultiplie avant la reduction, sinon le fond bave dans le
    contour ; la moyenne de zone remplace le plus proche voisin, qui depuis 1024
    tire un pixel au hasard dans un bloc de 42 et transforme la trame en bruit.
    """
    a = np.asarray(img).astype(np.float32) / 255.0
    ring = np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3),
                           a[:, :4].reshape(-1, 3), a[:, -4:].reshape(-1, 3)])
    bg_color = np.median(ring, 0)
    close = np.linalg.norm(a - bg_color, axis=2) < BG_TOL
    lab, n = ndimage.label(close)
    edge = set(lab[0].tolist()) | set(lab[-1].tolist()) | set(lab[:, 0].tolist()) | set(lab[:, -1].tolist())
    edge.discard(0)
    keep = ~np.isin(lab, list(edge))

    # Le trou d'une bague : meme couleur que le fond, mais sans chemin vers le
    # bord. Un demi pour cent de l'image au minimum, sinon les creux d'ombre du
    # sujet se percent aussi.
    inner, n = ndimage.label(np.linalg.norm(a - bg_color, axis=2) < BG_TIGHT)
    if n:
        sizes = ndimage.sum(np.ones_like(inner), inner, range(1, n + 1))
        big = [i + 1 for i, v in enumerate(sizes) if v >= a.shape[0] * a.shape[1] * 0.005]
        keep &= ~np.isin(inner, big)

    # Un fond que le remplissage n'a pas mordu : l'image est a jeter, pas a
    # rattraper. Le tirage suivant coute dix secondes.
    if keep.mean() > 0.85:
        return None

    # Les miettes que le modele seme autour du sujet : tout ce qui pese moins du
    # dixieme de la piece principale part avec le fond. Un dixieme et non un
    # centieme : une ombre portee au sol pese plus qu'on ne croit, et les sujets
    # en deux morceaux (une paire de bottes) sont a moitie-moitie.
    lab, n = ndimage.label(keep)
    if n == 0:
        return None
    sizes = ndimage.sum(keep, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= sizes.max() * 0.10])

    ys, xs = np.nonzero(keep)
    if len(xs) == 0:
        return None
    box = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))
    a, m = a[box], keep[box].astype(np.float32)
    h, w = m.shape
    f = SIDE / max(h, w)
    pre = Image.fromarray((np.dstack([a * m[..., None], m]) * 255).astype(np.uint8), "RGBA")
    pre = pre.resize((max(1, round(w * f)), max(1, round(h * f))), Image.BOX)
    s = np.asarray(pre).astype(np.float32) / 255.0
    al = s[..., 3]
    rgb = np.where(al[..., None] > 0.02, s[..., :3] / np.maximum(al, 0.02)[..., None], 0.0)
    return Image.fromarray(
        (np.dstack([np.clip(rgb, 0, 1), (al >= 0.5).astype(np.float32)]) * 255).astype(np.uint8),
        "RGBA")


def quant(im, colors=24):
    """Palette reduite : c'est ce qui fait tenir l'icone avec le reste du jeu."""
    al = im.getchannel("A")
    q = im.convert("RGB").quantize(colors=colors, method=Image.MEDIANCUT).convert("RGB")
    q.putalpha(al)
    return q


GROUPS = {
  "armes": "sword broadsword war_blade dagger misericorde mace battle_mace war_hammer wand scepter runic_scepter",
  "tetes": "shield kite_shield pavise helmet great_helm armet hood masters_hood",
  "torses": "breastplate chainmail full_plate tunic jerkin gloves reinforced_gloves masters_gloves",
  "pieds": "boots studded_boots travel_boots belt girdle baldric",
  "bijoux": "amulet talisman pendentif ring ornate_ring signet_ring",
  "livres": "grimoire codex manual_lightning manual_fire manual_weapons",
}
ZOOM = 5


def build_sheet(name, stems):
    cw = SIDE * ZOOM + 10
    sh = Image.new("RGBA", (130 + cw * len(SEEDS), 18 + cw * len(stems)), (40, 40, 46, 255))
    d = ImageDraw.Draw(sh)
    for col, seed in enumerate(SEEDS):
        d.text((132 + col * cw, 4), str(seed), fill=(200, 200, 200))
    for row, stem in enumerate(stems):
        y = 18 + row * cw
        d.text((4, y + cw // 2), stem, fill=(230, 230, 230))
        for col, seed in enumerate(SEEDS):
            p = os.path.join(OUT, "%s_%d.png" % (stem, seed))
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGBA")
            sh.alpha_composite(im.resize((im.width * ZOOM, im.height * ZOOM), Image.NEAREST),
                               (130 + col * cw + 5, y + 5))
    path = os.path.join(WORK, "sheet_%s.png" % name)
    sh.save(path)
    print(path)


def cmd_apply(args):
    """Pose les tirages retenus : le PNG dans resources/icons/items/, le champ
    `icon` dans le .tres, pour la graine retenue dans item_icons.json."""
    dest = os.path.join(PROJ, "resources/icons/items")
    os.makedirs(dest, exist_ok=True)
    for stem, (_, seed) in SUBJECTS.items():
        src = os.path.join(OUT, "%s_%d.png" % (stem, seed))
        if not os.path.exists(src):
            sys.exit("manquant : " + src)
        shutil.copy(src, os.path.join(dest, stem + ".png"))

        tres = os.path.join(PROJ, "resources/items", stem + ".tres")
        s = open(tres, encoding="utf-8").read()
        if "2_icon" in s:
            continue
        s = re.sub(r"^\[gd_resource ([^\]]*?)( load_steps=\d+)?( format=3\])",
                   r"[gd_resource \1 load_steps=3\3", s, count=1, flags=re.M)
        s = re.sub(r'^(\[ext_resource type="Script".*\n)',
                   r'\1[ext_resource type="Texture2D" path="res://resources/icons/items/'
                   + stem + r'.png" id="2_icon"]\n', s, count=1, flags=re.M)
        # Dans l'ordre de declaration d'ItemBase : avant l'encombrement, qu'une
        # base sans grille (bague, amulette) n'a pas.
        line = 'icon = ExtResource("2_icon")\n'
        if "grid_size = " in s:
            s = s.replace("grid_size = ", line + "grid_size = ", 1)
        else:
            s = s.rstrip("\n") + "\n" + line
        open(tres, "w", encoding="utf-8").write(s)
    print("posees :", len(SUBJECTS))


def cmd_sheets(args):
    for name, stems in GROUPS.items():
        build_sheet(name, stems.split())


def cmd_gen(args):
    os.makedirs(RAW, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    names = args.only.split(",") if args.only else list(SUBJECTS)
    for name in names:
        for seed in SEEDS:
            tag = "%s_%d" % (name, seed)
            raw_path = os.path.join(RAW, tag + ".png")
            if os.path.exists(raw_path) and not args.redo:
                img = Image.open(raw_path).convert("RGB")
            else:
                t0 = time.time()
                img = render(TMPL.format(subj=SUBJECTS[name][0]), seed)
                img.save(raw_path)
                print("  %s  %.1fs" % (tag, time.time() - t0), flush=True)
            im = cut(img)
            # Un fond que le remplissage n'a pas mordu ne se rattrape pas : le
            # tirage manque a la planche, on en choisit un autre.
            if im is not None:
                quant(im).save(os.path.join(OUT, tag + ".png"))
    cmd_sheets(args)


# Sous garde : `skill_icons.py` importe `render()`, `quant()` et les reglages, qui
# sont les memes depuis le jalon 11. Sans elle, l'import lancerait la ligne de
# commande des objets.
if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen"); g.set_defaults(run=cmd_gen)
    g.add_argument("--only", default="", help="bases a refaire, separees par des virgules")
    g.add_argument("--redo", action="store_true", help="ignorer les tirages deja en cache")
    sub.add_parser("sheets").set_defaults(run=cmd_sheets)
    sub.add_parser("apply").set_defaults(run=cmd_apply)
    args = ap.parse_args()
    print("travail :", WORK)
    args.run(args)
