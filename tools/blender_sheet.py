#!/usr/bin/env python3
"""La planche de jeu d'un personnage animé en 3D (jalon 51) : un modèle gréé par Mixamo,
ses animations rendues par Blender directement à la taille du jeu — sans anticrénelage,
ombrage en aplats —, ramenées sur une palette commune et cernées comme les autres
sprites. Même format que `character_forge.py build` : le jeu ne voit pas la différence,
mais la main et la lame de chaque image viennent des os.

    tools/blender_sheet.py <id>            rend tout, puis assemble la planche
    tools/blender_sheet.py <id> --cached   réutilise les rendus déjà faits

Réglages dans `tools/characters/<id>.json`, section `blender`."""
import argparse, json, os, subprocess, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import character_forge as cf

BLENDER = os.environ.get("BLENDER", "/mnt/c/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe")
WORK = "/mnt/c/Users/Theo/AppData/Local/Temp/hns-blender"
RENDER = os.path.join(os.path.dirname(__file__), "blender", "render_anim.py")
POSE = os.path.join(os.path.dirname(__file__), "blender", "pose_anim.py")
GESTURES = os.path.join(os.path.dirname(__file__), "blender", "gestes.json")
# La main du squelette est au poignet ; l'arme se tient dans la paume, un peu au-delà.
PALM = 0.3


def win(path):
    return subprocess.check_output(["wslpath", "-w", path], text=True).strip()


def render(cid, b, name, source, count, extra, height=0.0):
    """`source` : une animation (.fbx de Mixamo, .blend du gréage local), ou un geste écrit de `blender/gestes.json`,
    joué sur le personnage au repos."""
    out = os.path.join(WORK, cid)
    os.makedirs(out, exist_ok=True)
    common = ["aa=0", "toon=1"] + [f"{k}={b[k]}" for k in ("size", "elevation", "sun", "ambient")] + extra
    if height:
        common.append(f"height={height}")
    if source.endswith((".fbx", ".blend")):
        args = [win(RENDER), "--", win(os.path.join(cf.PROJ, b["source"], source)), win(out), name, str(count)]
    else:
        args = [win(POSE), "--", win(os.path.join(cf.PROJ, b["source"], b["rest"])), win(GESTURES), source,
                win(out), name, str(count)]
    log = subprocess.run([BLENDER, "-b", "-P"] + args + common, capture_output=True, text=True).stdout
    if "Traceback" in log or not os.path.exists(os.path.join(out, name + ".json")):
        sys.exit(f"Blender a échoué sur {source} :\n{log[-1500:]}")
    return next(float(l.split()[1]) for l in log.splitlines() if l.startswith("HAUTEUR"))


LIGHT_MAX = 0.88


def opaque(path):
    """Un rendu sans anticrénelage : l'alpha tranché suffit, aucun pixel n'est à demi."""
    x = np.asarray(Image.open(path).convert("RGBA")).copy()
    x[x[..., 3] <= 127] = 0
    x[..., 3] = np.where(x[..., 3] > 127, 255, 0)
    return x


def palette(images, n):
    """`n` couleurs tirées des poses de repos, imposées ensuite à toutes les images : une
    palette par image ferait scintiller les couleurs d'une image à l'autre."""
    px = np.concatenate([im[im[..., 3] > 0][:, :3] for im in images])
    q = Image.fromarray(px[None].astype("uint8")).quantize(n, method=Image.MEDIANCUT)
    pal = np.array(q.getpalette()[:n * 3]).reshape(-1, 3).astype(float)
    # Sous le seuil de glow du jeu (0,9), comme le haut de la rampe d'`ArtPalette` : les
    # reflets des lames montaient à 0,913 et débordaient comme un sort.
    lum = pal @ [0.2126, 0.7152, 0.0722] / 255
    return np.round(pal * np.minimum(1.0, LIGHT_MAX / np.maximum(lum, 1e-6))[:, None]).astype(int)


def locked(o, pal):
    m = o[..., 3] > 0
    d = ((o[m][:, None, :3].astype(int) - pal[None]) ** 2).sum(-1)
    out = o.copy()
    out[m, :3] = pal[d.argmin(1)]
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("id")
    p.add_argument("--cached", action="store_true", help="réutiliser les rendus déjà faits")
    a = p.parse_args()
    cfg = cf.load(a.id)
    build(a.id, cfg, cfg["blender"]["size"], a.cached)
    # `grown` : le même corps rendu plus grand, une planche par taille, jamais étiré en jeu (la
    # Légende du Roi des Rats, jalon 53).
    for size in cfg["blender"].get("grown", []):
        build(f"{a.id}_{size}", cfg, size, a.cached)


def build(sheet_id, cfg, size, cached):
    b = dict(cfg["blender"], size=size)
    F, feet = cfg["frame"], cfg["feet"]
    out = os.path.join(WORK, sheet_id)
    kinds = [k for k in cf.ANIMS if k in b["anims"]]
    # Le corps sans arme, puis chaque arme seule, le corps en masque : le jeu pose la couche
    # de l'arme équipée sur la planche du corps.
    passes = {"body": ["weapon=none"]}
    passes.update({w: [f"weapon={w}", "layer=weapon"] for w in b["weapons"]})

    if not (cached and os.path.exists(os.path.join(out, "body_rest.json"))):
        height = 0.0
        for layer, extra in passes.items():
            height = render(sheet_id, b, f"{layer}_rest", b["rest"], 1, extra, height)
            for kind in kinds:
                source, count = b["anims"][kind]
                render(sheet_id, b, f"{layer}_{kind}", source, count, extra, height)

    path = lambda layer, name, d, i: os.path.join(out, f"{layer}_{name}_{d}_{i}.png")
    marks_of = lambda name: json.load(open(os.path.join(out, f"body_{name}.json")))
    rest_body = [opaque(path("body", "rest", d, 0)) for d in cf.DIRS]
    # Les pieds du repos de face sur `feet` ; la caméra est fixe, le calage vaut pour tout.
    oy = feet - np.where((rest_body[0][..., 3] > 0).any(1))[0].max()
    ox = F // 2 - size // 2

    def sheet_of(layer, pal):
        def cell(p):
            c = np.zeros((F + 2, F + 2, 4), "uint8")
            cf.place(c, locked(opaque(p), pal), ox + 1, oy + 1)
            cf.outline(c)
            return c[1:-1, 1:-1]
        rows = [[cell(path(layer, "rest", d, 0)) for d in cf.DIRS]]
        for kind in kinds:
            for d in cf.DIRS:
                rows.append([cell(path(layer, kind, d, i)) for i in range(b["anims"][kind][1])])
        width = max(len(r) for r in rows)
        sheet = np.zeros((F * len(rows), F * width, 4), "uint8")
        for r, cells in enumerate(rows):
            for c, one in enumerate(cells):
                sheet[r * F:(r + 1) * F, c * F:(c + 1) * F] = one
        return sheet

    def at(p):
        return [round(p[0] + ox, 1), round(p[1] + oy, 1)]

    def hand(m):
        h, f = np.array(m["hand"]), np.array(m["forearm"])
        return at(h + (h - f) * PALM)

    gestures = json.load(open(GESTURES, encoding="utf-8"))
    rest = marks_of("rest")
    views = {}
    for d in cf.DIRS:
        m = rest[d][0]
        views[d] = {"hand": hand(m), "head": round(at(m["neck"])[1]), "waist": round(at(m["hips"])[1]),
                    "legs": round(min(at(m["foot_l"])[1], at(m["foot_r"])[1]))}
    anims, row = {}, 1
    for kind in kinds:
        count = b["anims"][kind][1]
        marks = marks_of(kind)
        entry = {"count": count, "rows": {}, "hands": {}}
        strike = kind in cf.STRIKES or kind in cf.STRIKES_3D
        if strike:
            entry["blades"] = {}
            source = b["anims"][kind][0]
            if source in gestures:
                # Un geste écrit dit où part son coup ; le lancer part de la main gauche.
                entry["impact"] = min(max(round(gestures[source]["impact"] * count), 1), count - 1)
            else:
                # Mixamo : le coup tombe quand la main va le plus vite.
                m = marks["side"]
                speed = [np.hypot(*np.subtract(m[i]["hand"], m[i - 1]["hand"])) for i in range(1, count)]
                entry["impact"] = int(np.argmax(speed)) + 1
        for d in cf.DIRS:
            entry["rows"][d] = row
            row += 1
            entry["hands"][d] = [hand(m) for m in marks[d]]
            if strike:
                blades = []
                for i, m in enumerate(marks[d]):
                    v = np.subtract(m["hand"], m["forearm"])
                    v = v / max(np.linalg.norm(v), 1e-6)
                    if i == count - 1:
                        v = np.array(cf.REST_BLADE)
                    # De dos, le jeu retourne la lame : on l'annule d'avance (voir `cf.anim_cells`).
                    blades.append([round(float(v[0]) * (-1 if d == "up" else 1), 2), round(float(v[1]), 2)])
                entry["blades"][d] = blades
        anims[kind] = entry

    dest = os.path.join(cf.PROJ, "art", "characters", sheet_id)
    body = sheet_of("body", palette(rest_body, b["colors"]))
    Image.fromarray(body).save(dest + ".png")
    preview = Image.new("RGBA", (body.shape[1], body.shape[0]), cf.GROUND + (255,))
    preview.alpha_composite(Image.fromarray(body))
    for w in b["weapons"]:
        # Sa propre palette : dans celle du corps, la garde dorée ou le cristal se perdaient.
        sample = [opaque(path(w, k, d, i)) for k in kinds for d in cf.DIRS for i in range(0, b["anims"][k][1], 3)]
        layer = sheet_of(w, palette([s for s in sample if s[..., 3].any()], b["weapon_colors"]))
        Image.fromarray(layer).save(f"{dest}_{w}.png")
        if w == cfg["weapon"]:
            preview.alpha_composite(Image.fromarray(layer))
    meta = {"frame": F, "feet": feet, "palette": cfg["palette"], "weapon": cfg["weapon"],
            "weapons": b["weapons"], "views": views, "anims": anims,
            # L'ombre au sol suit la taille rendue.
            "scale": round(cfg.get("scale", 1.0) * size / cfg["blender"]["size"], 3)}
    json.dump(meta, open(dest + ".json", "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    shown = os.path.join(cf.DESKTOP, f"hns-{sheet_id}-planche.png")
    preview.resize((preview.width * 4, preview.height * 4), Image.NEAREST).save(shown)
    print(shown)


if __name__ == "__main__":
    main()
