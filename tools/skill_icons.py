#!/usr/bin/env python3
"""Les icones de competences, de ComfyUI jusqu'au .tres. Recette : resources/icons/LISEZMOI.md.

    tools/skill_icons.py gen                  toute la table, trois tirages chacune
    tools/skill_icons.py gen --only ice_nova  une seule, pour la refaire
    tools/skill_icons.py apply                pose les tirages retenus
    tools/skill_icons.py apply --only ice_nova  n'en pose qu'une

Une entree marquee `qwen` passe par le tuyau des noeuds (`tools/node_icons.py`).

Meme moteur que les objets — `tools/item_icons.py`, dont ce script importe le
rendu, la quantification et les reglages du jalon 11. Deux differences, et elles
sont la raison de ce second fichier : une icone de competence est une **tuile
pleine**, donc pas de detourage mais un recadrage au centre ; et son fond suit la
nature du sort.
"""
import argparse, json, io, os, re, shutil, sys, time
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
from item_icons import HOST, PROJ, SEEDS, WORK, BG_TOL, render, quant
from icon_layouts import BG as VIOLET, layout

SIDE = 24  # le cadre de SkillIcon

HERE = os.path.dirname(os.path.abspath(__file__))
RAW, OUT = os.path.join(WORK, "skill_raw"), os.path.join(WORK, "skill_out")

# Le gabarit du jalon 11, mot pour mot : seuls le sujet et le fond changent.
TMPL = ("pixel art, 16-bit rpg ability icon, {subj}, centered, single subject, "
        "bold readable silhouette, high contrast, simple solid {bg} background, "
        "square game icon")
NEG = ("text, letters, watermark, signature, blurry, photo, 3d render, realistic, "
       "scenery, multiple subjects, sprite sheet, grid, frame, border")

# Le fond suit la nature : violet pour la foudre, cramoisi pour le feu, bleu pour
# le froid, vert croupi pour la necrose, prune pour le sacre — un fond dore noierait la lumiere du sujet. Sans
# entree, l'ardoise du chevalier, qui n'a pas d'element.
BACKGROUNDS = {"storm_dash": "dark violet", "static_electricity": "dark violet",
               "ice_spike": "dark blue", "ice_nova": "dark blue",
               "frost_tomb": "dark blue", "winter_disaster": "dark blue",
               "holy_strike": "dark plum", "sacred_pillar": "dark plum",
               "holy_pulse": "dark plum", "holy_light": "dark plum",
               "plague": "dark murky green", "rise": "dark murky green",
               "toxic_unleash": "dark murky green", "rotting_gate": "dark murky green",
               "putrid_curse": "dark murky green", "advanced_necrosis": "dark murky green",
               # La sorcière : le violet de la foudre, même pour le trait qui change d'élément.
               "elemental_projectile": "dark violet", "spell_amplification": "dark violet",
               "trinity": "dark violet", "catalysis": "dark violet", "rag_doll": "dark violet",
               "familiar": "dark violet"}

# Le sujet occupe rarement plus que ce centre ; reduite entiere, la tuile noie sa
# silhouette dans le fond.
CROP = 0.70
ZOOM = 5

SUBJECTS = json.load(open(os.path.join(HERE, "skill_icons.json"), encoding="utf-8"))


def shrink(img):
    """Recadre au centre puis reduit a SIDE par moyenne de zone.

    Au plus proche voisin depuis 1024, chaque pixel est tire au hasard dans un
    bloc de 42 et la trame devient du bruit.
    """
    side = int(min(img.size) * CROP)
    left = (img.width - side) // 2
    top = (img.height - side) // 2
    return img.crop((left, top, left + side, top + side)).resize((SIDE, SIDE), Image.BOX)


def crisp(img, colors=14):
    """Recadre au centre puis reduit a SIDE par la couleur **dominante** de chaque bloc
    (jalon 41) : la moyenne de zone melangeait deux couleurs voisines en une troisieme,
    et l'icone sortait floue. Le bord de chaque bloc, ou deux pixels du dessin se
    touchent, n'est pas compte.
    """
    side = int(min(img.size) * CROP)
    left = (img.width - side) // 2
    top = (img.height - side) // 2
    q = img.crop((left, top, left + side, top + side)).quantize(colors=colors, method=Image.MEDIANCUT)
    a, pal = np.asarray(q), q.getpalette()
    step, margin = side / SIDE, side / SIDE * 0.2
    out = Image.new("RGBA", (SIDE, SIDE))
    for y in range(SIDE):
        for x in range(SIDE):
            block = a[int(y * step + margin):int((y + 1) * step - margin),
                      int(x * step + margin):int((x + 1) * step - margin)]
            v = int(np.bincount(block.ravel()).argmax())
            out.putpixel((x, y), tuple(pal[v * 3:v * 3 + 3]) + (255,))
    return out


def to_violet(img):
    """Le fond qui touche les bords ramene au violet de la sorciere : SDXL sortait le
    corbeau sur du blanc ou du gris, qui jurait avec le reste du manuel."""
    a = np.asarray(img).astype(np.float32) / 255.0
    ring = np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3),
                           a[:, :4].reshape(-1, 3), a[:, -4:].reshape(-1, 3)])
    lab, _ = ndimage.label(np.linalg.norm(a - np.median(ring, 0), axis=2) < BG_TOL)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    out = np.asarray(img).copy()
    out[np.isin(lab, list(edge))] = VIOLET
    return Image.fromarray(out)


def build_sheet():
    cell = SIDE * ZOOM + 10
    sheet = Image.new("RGBA", (150 + cell * len(SEEDS), 18 + cell * len(SUBJECTS)), (40, 40, 46, 255))
    draw = ImageDraw.Draw(sheet)
    for col, seed in enumerate(SEEDS):
        draw.text((152 + col * cell, 4), str(seed), fill=(200, 200, 200))
    for row, stem in enumerate(SUBJECTS):
        y = 18 + row * cell
        draw.text((4, y + cell // 2), stem, fill=(230, 230, 230))
        for col, seed in enumerate(SEEDS):
            path = os.path.join(OUT, "%s_%d.png" % (stem, seed))
            if not os.path.exists(path):
                continue
            im = Image.open(path).convert("RGBA")
            sheet.alpha_composite(
                im.resize((im.width * ZOOM, im.height * ZOOM), Image.NEAREST),
                (150 + col * cell + 5, y + 5)
            )
    out = os.path.join(WORK, "sheet_skills.png")
    sheet.save(out)
    print(out)


def cmd_gen(args):
    os.makedirs(RAW, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    for name in (args.only.split(",") if args.only else list(SUBJECTS)):
        # Le troisieme champ, facultatif (jalon 41) : `layout` et `denoise` pour un
        # calque d'`icon_layouts.py`, `crisp` pour la reduction nette, `violet` pour
        # ramener le fond.
        opts = SUBJECTS[name][2] if len(SUBJECTS[name]) > 2 else {}
        for seed in SEEDS:
            tag = "%s_%d" % (name, seed)
            raw = os.path.join(RAW, tag + ".png")
            if os.path.exists(raw) and not args.redo:
                img = Image.open(raw).convert("RGB")
            else:
                start = time.time()
                prompt = TMPL.format(subj=SUBJECTS[name][0], bg=BACKGROUNDS.get(name, "slate blue"))
                if opts.get("qwen"):
                    # Le tuyau des noeuds (jalon 42) : le sujet y est une phrase entiere.
                    import node_icons
                    img = node_icons.render(node_icons.sentence(SUBJECTS[name][0]), seed)
                elif opts.get("layout"):
                    img = render(prompt, seed, layout=layout(name), denoise=opts["denoise"])
                else:
                    img = render(prompt, seed)
                img.save(raw)
                print("  %s  %.1fs" % (tag, time.time() - start), flush=True)
            if opts.get("violet"):
                img = to_violet(img)
            if opts.get("qwen"):
                import node_icons
                small = node_icons.fit(img, SIDE, node_icons.FIRE).convert("RGBA")
            else:
                small = crisp(img) if opts.get("crisp") else quant(shrink(img).convert("RGBA"))
            small.save(os.path.join(OUT, tag + ".png"))
    build_sheet()


def cmd_apply(args):
    """Le PNG dans resources/icons/, le champ `icon` dans le .tres."""
    dest = os.path.join(PROJ, "resources/icons")
    only = args.only.split(",") if args.only else list(SUBJECTS)
    for stem in only:
        seed = SUBJECTS[stem][1]
        src = os.path.join(OUT, "%s_%d.png" % (stem, seed))
        if not os.path.exists(src):
            sys.exit("manquant : " + src)
        shutil.copy(src, os.path.join(dest, stem + ".png"))

        tres = os.path.join(PROJ, "resources/skills", stem + ".tres")
        s = open(tres, encoding="utf-8").read()
        if "2_icone" in s:
            continue
        steps = s.count("[ext_resource") + s.count("[sub_resource") + 2
        s = re.sub(r"^\[gd_resource ([^\]]*?)( load_steps=\d+)?( format=3\])",
                   r"[gd_resource \1 load_steps=%d\3" % steps, s, count=1, flags=re.M)
        s = re.sub(r'^(\[ext_resource type="Script".*\n)',
                   r'\1[ext_resource type="Texture2D" path="res://resources/icons/'
                   + stem + r'.png" id="2_icone"]\n', s, count=1, flags=re.M)
        # En derniere ligne, comme les autres competences.
        s = s.rstrip("\n") + '\nicon = ExtResource("2_icone")\n'
        open(tres, "w", encoding="utf-8").write(s)
    print("posees :", len(only))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen"); g.set_defaults(run=cmd_gen)
    g.add_argument("--only", default="", help="competences a refaire, separees par des virgules")
    g.add_argument("--redo", action="store_true", help="ignorer les tirages deja en cache")
    a = sub.add_parser("apply"); a.set_defaults(run=cmd_apply)
    # Le cache des tirages vit dans un dossier temporaire : poser une seule icône
    # ne doit pas exiger qu'il contienne encore toutes les autres.
    a.add_argument("--only", default="", help="competences a poser, separees par des virgules")
    args = ap.parse_args()
    print("travail :", WORK)
    args.run(args)
