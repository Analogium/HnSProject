#!/usr/bin/env python3
"""Les icones des noeuds d'arbre, de ComfyUI jusqu'au .tres du manuel (jalon 42).
Recette : resources/icons/LISEZMOI.md, « Icones de noeuds ».

    tools/node_icons.py gen                          toute la table, trois tirages chacun
    tools/node_icons.py gen --only fireball_meteor   un seul, pour le refaire
    tools/node_icons.py apply                        pose les tirages retenus
    tools/node_icons.py apply --only fireball_meteor n'en pose qu'un

Pas SDXL mais **Qwen-Image 2512** (fp8), avec le LoRA Lightning 8 pas et un LoRA pixel
art : SDXL ignorait la composition et sortait une bouillie rouge a 24 px. Meme transport
que `tools/item_icons.py`.
"""
import argparse, io, json, os, re, sys, time, urllib.parse, urllib.request
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
import item_icons as ii
import skill_icons as si

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(ii.WORK, "node_raw")
SUBJECTS = json.load(open(os.path.join(HERE, "node_icons.json"), encoding="utf-8"))

# Le cote de l'icone selon le role du noeud : `ManualPanel.NODE_ICONS`, que le test des
# icones compare a chaque PNG.
SIDES = {"basic": 24, "suite": 28, "major": 32}
# « Gros pixels, deux ou trois formes » : a la reduction, le detail d'un tirage ordinaire
# devenait une boue (le bouclier de la Perforation).
TMPL = ("Pixel Art, a tiny 32x32 pixel game icon, extremely low resolution with huge chunky square pixels. "
        "{d} Very simple: two or three large bold shapes only, minimal detail, thick black outline, "
        "flat colors with a single shade, palette of {pal}, plain flat {bg} background, no text, no frame, no border.")
FIRE, ICE = (46, 14, 18), (14, 22, 48)
# Ce qui devient de glace (la conversion du Givre et sa suite) prend le fond bleu.
COLD = {"fireball_frost", "fireball_deep_frost"}
# Ecart de couleur en deca duquel un pixel qui touche le bord est du fond : Qwen pose un
# leger degrade, que 0,16 avale sans manger le contour noir.
BG_TOL = 0.16


def workflow(prompt, seed):
    return {
        "unet": {"class_type": "UNETLoader",
                 "inputs": {"unet_name": "qwen_image_2512_fp8_e4m3fn.safetensors", "weight_dtype": "default"}},
        # **Sur le CPU** : modele (19,5 Go) et encodeur (7,9 Go) ne tiennent pas ensemble sur
        # la carte de 24 Go, et apres un dechargement partiel le processus ComfyUI ne rendait
        # plus que du bruit, SDXL compris, jusqu'a son redemarrage.
        "clip": {"class_type": "CLIPLoader",
                 "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image",
                            "device": "cpu"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "fast": {"class_type": "LoraLoaderModelOnly",
                 "inputs": {"lora_name": "Qwen-Image-2512-Lightning-8steps-V1.0-bf16.safetensors",
                            "strength_model": 1.0, "model": ["unet", 0]}},
        "pix": {"class_type": "LoraLoaderModelOnly",
                "inputs": {"lora_name": "Qwen-Image-2512-Master-Pixel-Art-LoRA.safetensors",
                           "strength_model": 1.0, "model": ["fast", 0]}},
        "shift": {"class_type": "ModelSamplingAuraFlow", "inputs": {"shift": 3.1, "model": ["pix", 0]}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["clip", 0]}},
        "neg": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["clip", 0]}},
        "lat": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 768, "height": 768, "batch_size": 1}},
        "ks": {"class_type": "KSampler",
               "inputs": {"seed": seed, "steps": 8, "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple",
                          "denoise": 1.0, "model": ["shift", 0], "positive": ["pos", 0],
                          "negative": ["neg", 0], "latent_image": ["lat", 0]}},
        "dec": {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["dec", 0], "filename_prefix": "hns_node"}},
    }


def render(prompt, seed):
    pid = ii.post("/prompt", {"prompt": workflow(prompt, seed)})["prompt_id"]
    while True:
        h = json.load(urllib.request.urlopen(f"{ii.HOST}/history/{pid}"))
        if pid in h:
            break
        time.sleep(1.0)
    img = h[pid]["outputs"]["save"]["images"][0]
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
    img = Image.open(io.BytesIO(urllib.request.urlopen(f"{ii.HOST}/view?{q}").read())).convert("RGB")
    # Le bruit pur, signe du processus casse ci-dessus : mieux vaut s'arreter que le poser.
    if np.abs(np.diff(np.asarray(img).astype(float), axis=1)).mean() > 50:
        sys.exit("ComfyUI rend du bruit : le redemarrer")
    return img


def prompt(node):
    return sentence(SUBJECTS[node][0], node in COLD)


def sentence(subject, cold=False):
    return TMPL.format(d=subject, pal="icy blues and white" if cold else "oranges, reds and warm yellows",
                       bg="dark navy blue" if cold else "dark crimson")


def mask(role, side):
    """La silhouette du cadre, que l'icone remplit : rond, ou octogone pour un majeur."""
    m = Image.new("L", (side, side), 0)
    d = ImageDraw.Draw(m)
    if role == "major":
        h, cut = side / 2, 7
        d.polygon([(cut, 0), (side - cut, 0), (side, cut), (side, side - cut), (side - cut, side),
                   (cut, side), (0, side - cut), (0, cut)], fill=255)
    else:
        inset = 0 if role == "basic" else 1
        d.ellipse([inset, inset, side - 1 - inset, side - 1 - inset], fill=255)
    return m


def reduce(img, node):
    """La vignette d'un noeud : au cote de son role, decoupee a sa silhouette."""
    role = SUBJECTS[node][2]
    out = fit(img, SIDES[role], ICE if node in COLD else FIRE)
    out.putalpha(mask(role, SIDES[role]))
    return out


def fit(img, side, bg_color):
    """Recadre sur le sujet, ramene le fond a une teinte, reduit par couleur dominante.

    Qwen remplit le cadre : le recadrage au centre des competences coupait le sujet. Le
    fond se reconnait a ce qu'il touche le bord, comme pour les objets.
    """
    a = np.asarray(img).astype(np.float32) / 255.0
    ring = np.concatenate([a[:6].reshape(-1, 3), a[-6:].reshape(-1, 3),
                           a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    lab, _ = ndimage.label(np.linalg.norm(a - np.median(ring, 0), axis=2) < BG_TOL)
    bg = np.isin(lab, list(set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}))
    flat = np.asarray(img).copy()
    flat[bg] = bg_color
    ys, xs = np.where(~bg)
    y0, y1, x0, x1 = (ys.min(), ys.max() + 1, xs.min(), xs.max() + 1) if len(xs) else (0, a.shape[0], 0, a.shape[1])
    s = int(max(y1 - y0, x1 - x0) * 1.12)
    canvas = Image.new("RGB", (s, s), bg_color)
    canvas.paste(Image.fromarray(flat), (s // 2 - (x0 + x1) // 2, s // 2 - (y0 + y1) // 2))
    si.SIDE, si.CROP = side, 1.0
    return si.crisp(canvas)


def raw_path(node, seed):
    return os.path.join(RAW, "%s_%d.png" % (node, seed))


def cmd_gen(args):
    os.makedirs(RAW, exist_ok=True)
    nodes = args.only.split(",") if args.only else list(SUBJECTS)
    for node in nodes:
        # Les graines a la suite : ComfyUI garde le texte encode, qui coute ~100 s sur le CPU.
        for seed in ii.SEEDS:
            if os.path.exists(raw_path(node, seed)) and not args.redo:
                continue
            start = time.time()
            render(prompt(node), seed).save(raw_path(node, seed))
            print("  %s_%d  %.0fs" % (node, seed, time.time() - start), flush=True)
    cell = 32 * 5 + 10
    sheet = Image.new("RGBA", (260 + cell * len(ii.SEEDS), 18 + cell * len(nodes)), (40, 40, 46, 255))
    draw = ImageDraw.Draw(sheet)
    for col, seed in enumerate(ii.SEEDS):
        draw.text((262 + col * cell, 4), str(seed), fill=(200, 200, 200))
    for row, node in enumerate(nodes):
        draw.text((4, 18 + row * cell + cell // 2), node, fill=(230, 230, 230))
        for col, seed in enumerate(ii.SEEDS):
            if os.path.exists(raw_path(node, seed)):
                im = reduce(Image.open(raw_path(node, seed)).convert("RGB"), node)
                sheet.alpha_composite(im.resize((im.width * 5, im.height * 5), Image.NEAREST),
                                      (262 + col * cell, 23 + row * cell))
    out = os.path.join(ii.WORK, "sheet_nodes.png")
    sheet.save(out)
    print(out)


def manual_of(node):
    folder = os.path.join(ii.PROJ, "resources/manuals")
    for name in sorted(os.listdir(folder)):
        path = os.path.join(folder, name)
        if name.endswith(".tres") and ('id = "%s"' % node) in open(path, encoding="utf-8").read():
            return path
    sys.exit("aucun manuel ne porte " + node)


def cmd_apply(args):
    """Le PNG dans resources/icons/nodes/, le champ `icon` du noeud dans son manuel."""
    dest = os.path.join(ii.PROJ, "resources/icons/nodes")
    os.makedirs(dest, exist_ok=True)
    nodes = args.only.split(",") if args.only else list(SUBJECTS)
    for node in nodes:
        src = raw_path(node, SUBJECTS[node][1])
        if not os.path.exists(src):
            sys.exit("manquant : " + src)
        reduce(Image.open(src).convert("RGB"), node).save(os.path.join(dest, node + ".png"))

        tres = manual_of(node)
        s = open(tres, encoding="utf-8").read()
        ref = "icon_" + node
        if ('id="%s"' % ref) not in s:
            s = re.sub(r'(\[ext_resource [^\n]*\n)(?!\[ext_resource)',
                       r'\1[ext_resource type="Texture2D" path="res://resources/icons/nodes/%s.png" id="%s"]\n'
                       % (node, ref), s, count=1)
            # Apres le nom, dans le bloc du noeud.
            s = re.sub(r'(\nid = "%s"\nname = [^\n]*\n)' % re.escape(node),
                       r'\1icon = ExtResource("%s")\n' % ref, s, count=1)
        open(tres, "w", encoding="utf-8").write(s)
    print("posees :", len(nodes))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen"); g.set_defaults(run=cmd_gen)
    g.add_argument("--only", default="", help="noeuds a refaire, separes par des virgules")
    g.add_argument("--redo", action="store_true", help="ignorer les tirages deja en cache")
    a = sub.add_parser("apply"); a.set_defaults(run=cmd_apply)
    a.add_argument("--only", default="", help="noeuds a poser, separes par des virgules")
    args = ap.parse_args()
    print("travail :", ii.WORK)
    args.run(args)
