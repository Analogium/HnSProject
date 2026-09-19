#!/usr/bin/env python3
"""Les icones de competences, de ComfyUI jusqu'au .tres. Recette : resources/icons/LISEZMOI.md.

    tools/skill_icons.py gen                  toute la table, trois tirages chacune
    tools/skill_icons.py gen --only ignition  une seule, pour la refaire
    tools/skill_icons.py apply                pose les tirages retenus

Meme moteur que les objets — `tools/item_icons.py`, dont ce script importe le
rendu, la quantification et les reglages du jalon 11. Deux differences, et elles
sont la raison de ce second fichier : une icone de competence est une **tuile
pleine**, donc pas de detourage mais un recadrage au centre ; et son fond suit la
nature du sort.
"""
import argparse, json, io, os, re, shutil, sys, time
from PIL import Image, ImageDraw
from item_icons import HOST, PROJ, SEEDS, SIDE, WORK, render, quant

HERE = os.path.dirname(os.path.abspath(__file__))
RAW, OUT = os.path.join(WORK, "skill_raw"), os.path.join(WORK, "skill_out")

# Le gabarit du jalon 11, mot pour mot : seuls le sujet et le fond changent.
TMPL = ("pixel art, 16-bit rpg ability icon, {subj}, centered, single subject, "
        "bold readable silhouette, high contrast, simple solid {bg} background, "
        "square game icon")
NEG = ("text, letters, watermark, signature, blurry, photo, 3d render, realistic, "
       "scenery, multiple subjects, sprite sheet, grid, frame, border")

# Le fond suit la nature : violet pour la foudre, cramoisi pour le feu, bleu pour
# le froid. Sans entree, l'ardoise du chevalier, qui n'a pas d'element.
BACKGROUNDS = {"flame_dash": "dark crimson", "ignition": "dark crimson",
               "storm_dash": "dark violet", "static_electricity": "dark violet",
               "ice_spike": "dark blue", "ice_nova": "dark blue",
               "frost_tomb": "dark blue", "winter_disaster": "dark blue"}

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
        for seed in SEEDS:
            tag = "%s_%d" % (name, seed)
            raw = os.path.join(RAW, tag + ".png")
            if os.path.exists(raw) and not args.redo:
                img = Image.open(raw).convert("RGB")
            else:
                start = time.time()
                prompt = TMPL.format(subj=SUBJECTS[name][0], bg=BACKGROUNDS.get(name, "slate blue"))
                img = render(prompt, seed)
                img.save(raw)
                print("  %s  %.1fs" % (tag, time.time() - start), flush=True)
            quant(shrink(img).convert("RGBA")).save(os.path.join(OUT, tag + ".png"))
    build_sheet()


def cmd_apply(args):
    """Le PNG dans resources/icons/, le champ `icon` dans le .tres."""
    dest = os.path.join(PROJ, "resources/icons")
    for stem, (_, seed) in SUBJECTS.items():
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
    print("posees :", len(SUBJECTS))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen"); g.set_defaults(run=cmd_gen)
    g.add_argument("--only", default="", help="competences a refaire, separees par des virgules")
    g.add_argument("--redo", action="store_true", help="ignorer les tirages deja en cache")
    sub.add_parser("apply").set_defaults(run=cmd_apply)
    args = ap.parse_args()
    print("travail :", WORK)
    args.run(args)
