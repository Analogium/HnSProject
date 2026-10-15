#!/usr/bin/env python3
"""Le modèle 3D d'un personnage (jalon 51), avant Mixamo :

    tools/model_3d.py image <id>          trois images « rendu 3D » de face, en pose A
    tools/model_3d.py back <id> <graine>  trois images de dos, d'après celle de face retenue
    tools/model_3d.py mesh <id> <graine> [--back <graine>]
        le modèle, puis le .fbx pour Mixamo : Stable Fast 3D en local avec l'image de dos,
        TRELLIS.2 (quota Hugging Face, un par jour) sans elle
    tools/model_3d.py rig <id>            le gréage local, quand Mixamo refuse le modèle

Une image pixel art donne un modèle plat : TRELLIS a besoin d'un rendu lissé. On le tire
de la vue de face retenue (IPAdapter), LoRA pixel art éteint, bras écartés pour le gréage.
Le prompt est `blender.model_prompt` de `tools/characters/<id>.json`."""
import argparse, copy, json, os, subprocess, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import character_forge as cf
from blender_sheet import BLENDER, win

SEEDS = (4242, 777, 1337)
TEMP = "/mnt/c/Users/Theo/AppData/Local/Temp"
TRELLIS_PYTHON = TEMP + "/hns-trellis-venv/Scripts/python.exe"
# Stable Fast 3D : venv et sources installés à la main (LISEZMOI, « En 3D »).
LOCAL_PYTHON = TEMP + "/hns-local3d/venv/Scripts/python.exe"
# Le squelette et les animations Mixamo que le gréage local reprend.
MIXAMO = os.path.join(cf.CHARS, "swiftblade", "3d")
SF3D_SRC = r"C:\Users\Theo\AppData\Local\Temp\hns-local3d\src\stable-fast-3d"
NEG = ", pixel art, pixelated, sprite, flat colors, 2d, holding, weapon"


def raw(cid, seed, view="down"):
    return os.path.join(cf.RAW, f"{cid}_3d_{seed}.png" if view == "down" else f"{cid}_3d_{view}_{seed}.png")


def a_pose(view):
    """Le squelette OpenPose des images sources : la pose A, mains loin des hanches, pour
    que le gréage sépare les bras du buste."""
    kp = dict(cf.POSES[view])
    s = 1 if view == "down" else -1
    X = lambda dx: 512 - s * dx
    kp[3], kp[4], kp[6], kp[7] = (X(150), 590), (X(205), 660), (X(-150), 590), (X(-205), 660)
    return kp


def renders(cid, view, ref, label):
    """Trois images « rendu 3D » en pose A, vue `view` (down : de face, up : de dos)."""
    cfg = copy.deepcopy(cf.load(cid))
    cf.POSES[view] = a_pose(view)
    prompt = cfg["blender"]["model_prompt"]
    if view == "up":
        prompt = prompt.replace("front view, facing the viewer", cf.VIEW_WORDS["up"])
    cfg["views"].update(prompt=prompt, ip_weight=0.45)
    cfg["neg"] = cfg.get("neg", "") + NEG + (", face, eyes" if view == "up" else "")
    os.makedirs(cf.RAW, exist_ok=True)
    row = []
    for seed in SEEDS:
        wf = cf.view_graph(cfg, ref, view, seed)
        wf["lora"]["inputs"]["strength_model"] = wf["lora"]["inputs"]["strength_clip"] = 0.0
        cf.run(wf).save(raw(cid, seed, view))
        row.append(Image.open(raw(cid, seed, view)))
    cf.sheet_of([row], [label + ", graines " + " ".join(map(str, SEEDS))],
                os.path.join(cf.DESKTOP, f"hns-{cid}-modele{'' if view == 'down' else '-dos'}.png"))


def cmd_image(a):
    ref = cf.upload(Image.open(os.path.join(cf.CHARS, a.id, "down.png")).convert("RGB"), f"hns_{a.id}_down.png")
    renders(a.id, "down", ref, "rendu 3D")


def cmd_back(a):
    """Le dos, d'après l'image de face retenue : même rendu, mêmes couleurs."""
    ref = cf.upload(Image.open(raw(a.id, a.seed)).convert("RGB"), f"hns_{a.id}_3d.png")
    renders(a.id, "up", ref, "rendu 3D de dos")


def cutout(cid, seed, view, dest):
    """L'image détourée (alpha). De face, la peau repeinte : ce que SDXL ignore (la peau
    bleue de la sorcière) doit être dans la texture. Pas de dos : la règle, écrite pour la
    face, y repeignait le gris rosé de la cape."""
    im = np.asarray(Image.open(raw(cid, seed, view)).convert("RGBA")).copy()
    for rule in cf.load(cid)["blender"].get("model_recolor", []) if view == "down" else []:
        cf.recolor(im, rule)
    im[..., 3] = cf.silhouette(im[..., :3].astype(np.float32) / 255) * 255
    Image.fromarray(im).save(dest)


def cmd_mesh(a):
    d = os.path.join(cf.CHARS, a.id, "3d")
    os.makedirs(d, exist_ok=True)
    front, back = os.path.join(d, "model_front.png"), os.path.join(d, "model_back.png")
    glb, fbx = os.path.join(d, "model.glb"), os.path.join(d, a.id + ".fbx")
    here = os.path.dirname(os.path.abspath(__file__))
    blender = lambda script, *args: subprocess.run(
        [BLENDER, "-b", "-P", win(os.path.join(here, "blender", script)), "--", *args],
        check=True, capture_output=True)
    cutout(a.id, a.seed, "down", front)
    if a.back is None:
        subprocess.run([TRELLIS_PYTHON, "-I", win(os.path.join(here, "trellis_client.py")), win(front), win(glb),
                        str(a.seed)], check=True)
    else:
        # Stable Fast 3D ne voit que la face et devine le reste : face et dos sont ensuite
        # repeints d'après leurs images (blender/project.py).
        cutout(a.id, a.back, "up", back)
        guess = os.path.join(d, "model_sf3d.glb")
        subprocess.run([LOCAL_PYTHON, "-I", win(os.path.join(here, "sf3d_client.py")), SF3D_SRC, win(front),
                        win(guess)], check=True)
        blender("project.py", win(guess), win(front), win(back), win(glb))
    shown = os.path.join(cf.DESKTOP, f"hns-{a.id}-modele-3d")
    os.makedirs(shown, exist_ok=True)
    blender("turntable.py", win(glb), win(shown))
    blender("to_fbx.py", win(glb), win(fbx))
    print(shown, fbx, sep="\n")


def cmd_rig(a):
    """Le gréage local : le squelette et les animations du Vive lame, gréé par Mixamo,
    posés sur ce personnage (blender/rig.py)."""
    d = os.path.join(cf.CHARS, a.id, "3d")
    pose = os.path.join(d, "pose.json")
    json.dump(a_pose("down"), open(pose, "w"))
    here = os.path.dirname(os.path.abspath(__file__))
    subprocess.run([BLENDER, "-b", "-P", win(os.path.join(here, "blender", "rig.py")), "--",
                    win(os.path.join(d, "model.glb")), win(os.path.join(d, "model_front.png")), win(pose),
                    win(os.path.join(MIXAMO, "Breathing Idle.fbx")), win(os.path.join(MIXAMO, "Walking.fbx")), win(d)],
                   check=True)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("image").add_argument("id")
    b = sub.add_parser("back"); b.add_argument("id"); b.add_argument("seed", type=int)
    m = sub.add_parser("mesh"); m.add_argument("id"); m.add_argument("seed", type=int)
    m.add_argument("--back", type=int, help="graine de l'image de dos : Stable Fast 3D en local, sinon TRELLIS.2")
    sub.add_parser("rig").add_argument("id")
    a = p.parse_args()
    {"image": cmd_image, "back": cmd_back, "mesh": cmd_mesh, "rig": cmd_rig}[a.cmd](a)


if __name__ == "__main__":
    main()
