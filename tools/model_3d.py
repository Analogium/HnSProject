#!/usr/bin/env python3
"""Le modèle 3D d'un personnage (jalon 51), avant Mixamo :

    tools/model_3d.py image <id>          trois images « rendu 3D » de face, en pose A
    tools/model_3d.py back <id>           trois images de dos
    tools/model_3d.py mesh <id> <graine> [--back <graine> | --sf3d]
        le modèle, puis le .fbx pour Mixamo : Stable Fast 3D en local avec l'image de dos
        (ou sans, --sf3d), TRELLIS.2 (quota Hugging Face, un par jour) sinon
    tools/model_3d.py rig <id>            le gréage local, quand Mixamo refuse le modèle

Une image pixel art donne un modèle plat : il faut un rendu lissé, LoRA pixel art éteint, bras
écartés pour le gréage. Le prompt est `blender.model_prompt` de `tools/characters/<id>.json`."""
import argparse, json, os, subprocess, sys
import cv2
import numpy as np
from PIL import Image, ImageOps
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import character_forge as cf
import node_icons
from blender_sheet import BLENDER, win

SEEDS = (4242, 777, 1337)
# Hors de %TEMP%, que le nettoyage de Windows peut vider.
TOOLS = "/mnt/c/Generate"
TRELLIS_PYTHON = TOOLS + "/hns-trellis-venv/Scripts/python.exe"
# Stable Fast 3D : venv et sources installés à la main (LISEZMOI, « En 3D »).
LOCAL_PYTHON = TOOLS + "/hns-local3d/venv/Scripts/python.exe"
# Le squelette et les animations Mixamo que le gréage local reprend.
MIXAMO = os.path.join(cf.CHARS, "swiftblade", "3d")
SF3D_SRC = r"C:\Generate\hns-local3d\src\stable-fast-3d"


def raw(cid, seed, view="down"):
    return os.path.join(cf.RAW, f"{cid}_3d_{seed}.png" if view == "down" else f"{cid}_3d_{view}_{seed}.png")


def joints(keep):
    """Les articulations d'une silhouette en pose A, de face, en points OpenPose (1 : le cou,
    2-4 : épaule, coude, poignet droits, 8-10 : hanche, genou, cheville droites ; la droite du
    personnage à gauche de l'image). Qwen n'est pas tiré sous un squelette imposé : on les lit
    sur la forme — bras détachés du buste, jambes écartées."""
    rows = np.where(keep.any(1))[0]
    y0, y1 = rows.min(), rows.max()
    h = y1 - y0
    cx = int(np.where(keep[y0:y0 + int(0.4 * h)].any(0))[0].mean())

    def run(y, x):
        """Les bords du morceau de silhouette qui contient (x, y) sur sa rangée."""
        r = keep[y]
        left = x - np.argmin(r[x::-1]) if not r[x::-1].all() else 0
        right = x + np.argmin(r[x:]) - 1 if not r[x:].all() else len(r) - 1
        return left, right

    kp = {}
    for (sh, el, wr), outward in (((2, 3, 4), -1), ((5, 6, 7), 1)):
        # Le bout des doigts au plus loin ; de là, on remonte le long du bras tant qu'il est
        # détaché du buste : la dernière rangée détachée est l'aisselle.
        xs = np.where(keep.any(0))[0]
        tip_x = xs.min() if outward < 0 else xs.max()
        tip_y = int(np.where(keep[:, tip_x])[0].mean())
        apart = lambda y: (keep[y, :run(y, cx)[0]].any() if outward < 0 else keep[y, run(y, cx)[1] + 1:].any())
        pit = tip_y
        while apart(pit - 1):
            pit -= 1
        # L'épaule : au milieu du bras à l'aisselle, une épaisseur de bras au-dessus.
        torso = run(pit, cx)[0 if outward < 0 else 1]
        arm = run(pit, torso + outward * (np.argmax(keep[pit, torso + outward::outward]) + 1))
        shoulder = np.array([sum(arm) / 2, pit - 0.1 * h])
        tip = np.array([tip_x, tip_y])
        wrist = tip + (shoulder - tip) / np.linalg.norm(shoulder - tip) * 0.07 * h
        kp[sh], kp[wr], kp[el] = tuple(shoulder), tuple(wrist), tuple((shoulder + wrist) / 2)
    # Le cou d'OpenPose est entre les épaules.
    kp[1] = tuple((np.array(kp[2]) + np.array(kp[5])) / 2)
    crotch = y1 - np.argmax(keep[y1::-1, cx])
    for (hp, kn, an), outward in (((8, 9, 10), -1), ((11, 12, 13), 1)):
        # La cheville : dans la botte la plus proche du centre, au-dessus du pied.
        ankle_y = int(y1 - 0.05 * h)
        side = np.where(keep[ankle_y, :cx])[0].max() if outward < 0 else cx + np.where(keep[ankle_y, cx:])[0].min()
        ankle = np.array([sum(run(ankle_y, side)) / 2, ankle_y])
        hl, hr = run(int(crotch - 0.03 * h), cx)
        hip = np.array([cx + outward * (hr - hl) / 4, crotch - 0.03 * h])
        knee_y = int((hip[1] + ankle[1]) / 2)
        knee = np.array([sum(run(knee_y, int((hip[0] + ankle[0]) / 2))) / 2, knee_y])
        kp[hp], kp[kn], kp[an] = tuple(hip), tuple(knee), tuple(ankle)
    return {i: (float(x), float(y)) for i, (x, y) in kp.items()}


# Qwen-Image, LoRA pixel art éteint (jalon 54) : il tient au prompt seul la direction choisie
# sur planche et la pose A, que SDXL n'obtenait que par IPAdapter et OpenPose. Sur fond vert,
# pour le détourage (`silhouette`).
BACKDROP = ", isolated on a solid flat pure chroma key green background (#00FF00), no floor, no shadow, no text"
VIEW_WORDS = {"down": "front view, facing the viewer",
              "up": "back view, seen from behind, back of the head, face not visible"}


def renders(cid, view, label):
    """Trois images source en pose A, vue `view` (down : de face, up : de dos), d'après
    `blender.model_prompt`, dont `{view}` dit la vue."""
    prompt = cf.load(cid)["blender"]["model_prompt"].format(view=VIEW_WORDS[view]) + BACKDROP
    os.makedirs(cf.RAW, exist_ok=True)
    row = []
    for seed in SEEDS:
        wf = node_icons.workflow(prompt, seed)
        wf["pix"]["inputs"]["strength_model"] = 0.0
        wf["lat"]["inputs"].update(width=832, height=1216)
        cf.run(wf).save(raw(cid, seed, view))
        row.append(ImageOps.pad(Image.open(raw(cid, seed, view)), (1216, 1216)))
    cf.sheet_of([row], [label + ", graines " + " ".join(map(str, SEEDS))],
                os.path.join(cf.DESKTOP, f"hns-{cid}-modele{'' if view == 'down' else '-dos'}.png"))


def cmd_image(a):
    renders(a.id, "down", "rendu 3D")


def cmd_back(a):
    """Le dos, au même prompt : sans référence d'image, il peut s'écarter de la face (l'écharpe
    du Vive lame pendait dans le dos) ; on garde celui qui s'en écarte le moins."""
    renders(a.id, "up", "rendu 3D de dos")


def cutout(cid, seed, view, dest):
    """L'image détourée (alpha)."""
    im = np.asarray(Image.open(raw(cid, seed, view)).convert("RGBA")).copy()
    keep = silhouette(raw(cid, seed, view))
    im[..., 3] = keep * 255
    # Le vert qui déborde sur les bords (les cheveux argentés), ramené au plus fort du rouge et du bleu.
    spill = keep & (im[..., 1] > np.maximum(im[..., 0], im[..., 2]))
    im[spill, 1] = np.maximum(im[spill, 0], im[spill, 2])
    Image.fromarray(im).save(dest)


def silhouette(path):
    """Le personnage. Sur fond vert d'incrustation (les sources adultes de Qwen-Image, jalon 54),
    à la couleur : GrabCut y bouchait l'entrejambe et gardait l'ombre au sol. Sinon par GrabCut
    (OpenCV) dans un cadre qui ne laisse que les bords au fond : les méthodes par couleur
    prenaient le fond d'un rendu « studio » pour du corps (le joueur de flûte sortait avec une
    plaque au-dessus du chapeau), ou un corps gris pâle pour du fond (le Roi des Rats, jalon 53)."""
    img = cv2.imread(path)
    h, w = img.shape[:2]
    b, g, r = (img[..., i].astype(int) for i in range(3))
    green = g - np.maximum(r, b) > 25
    if green[0].mean() > 0.9:
        keep = ndimage.binary_opening(~green)
        lab, n = ndimage.label(keep)
        return ndimage.binary_fill_holes(lab == (np.argmax(ndimage.sum(keep, lab, range(1, n + 1))) + 1))
    mask = np.zeros((h, w), np.uint8)
    frame = (w // 25, h // 34, w - 2 * (w // 25), h - h // 34 - h // 50)
    cv2.grabCut(img, mask, frame, np.zeros((1, 65)), np.zeros((1, 65)), 6, cv2.GC_INIT_WITH_RECT)
    keep = (mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)
    keep = ndimage.binary_fill_holes(ndimage.binary_opening(keep, iterations=2))
    lab, n = ndimage.label(keep)
    return lab == (np.argmax(ndimage.sum(keep, lab, range(1, n + 1))) + 1)


def cmd_mesh(a):
    d = os.path.join(cf.CHARS, a.id, "3d")
    os.makedirs(d, exist_ok=True)
    front, back = os.path.join(d, "model_front.png"), os.path.join(d, "model_back.png")
    glb, fbx = os.path.join(d, "model.glb"), os.path.join(d, a.id + ".fbx")
    here = os.path.dirname(os.path.abspath(__file__))
    blender = lambda script, *args: subprocess.run(
        [BLENDER, "-b", "-P", win(os.path.join(here, "blender", script)), "--", *args],
        check=True, capture_output=True)
    # Le tirage vit dans un temporaire que Windows vide ; le détourage, lui, reste à côté du modèle.
    if os.path.exists(raw(a.id, a.seed, "down")):
        cutout(a.id, a.seed, "down", front)
    elif os.path.exists(front):
        print("tirage disparu : détourage gardé,", front)
    else:
        sys.exit("ni tirage ni détourage : relancer `image " + a.id + "`")
    if a.back is None and not a.sf3d:
        # TRELLIS.2 sort près de 200 000 faces : réduit au compte du jeu, sa texture recuite sur la
        # version réduite (blender/bake_color.py). Son modèle brut est gardé : il coûte le quota du jour.
        raw_glb = os.path.join(d, "model_trellis.glb")
        if not os.path.exists(raw_glb):
            subprocess.run([TRELLIS_PYTHON, "-I", win(os.path.join(here, "trellis_client.py")), win(front),
                            win(raw_glb), str(a.seed)], check=True)
        blender("bake_color.py", win(raw_glb), win(raw_glb), win(glb))
    else:
        # Stable Fast 3D cuit une texture floue et devine le dos : la face, et le dos s'il y a
        # son image, sont repeints d'après elles (blender/project.py). Sans image de dos (le
        # champignon, que SDXL ne sait pas tourner), on garde le dos qu'il devine.
        guess = os.path.join(d, "model_sf3d.glb")
        subprocess.run([LOCAL_PYTHON, "-I", win(os.path.join(here, "sf3d_client.py")), SF3D_SRC, win(front),
                        win(guess)], check=True)
        if a.back is not None:
            cutout(a.id, a.back, "up", back)
        blender("project.py", win(guess), win(front), win(back) if a.back is not None else "-", win(glb))
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
    front = np.asarray(Image.open(os.path.join(d, "model_front.png")))[..., 3] > 0
    json.dump(joints(front), open(pose, "w"))
    here = os.path.dirname(os.path.abspath(__file__))
    subprocess.run([BLENDER, "-b", "-P", win(os.path.join(here, "blender", "rig.py")), "--",
                    win(os.path.join(d, "model.glb")), win(os.path.join(d, "model_front.png")), win(pose),
                    win(os.path.join(MIXAMO, "Breathing Idle.fbx")), win(os.path.join(MIXAMO, "Walking.fbx")), win(d)],
                   check=True)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("image").add_argument("id")
    sub.add_parser("back").add_argument("id")
    m = sub.add_parser("mesh"); m.add_argument("id"); m.add_argument("seed", type=int)
    m.add_argument("--back", type=int, help="graine de l'image de dos : Stable Fast 3D en local, sinon TRELLIS.2")
    m.add_argument("--sf3d", action="store_true", help="Stable Fast 3D sans image de dos")
    sub.add_parser("rig").add_argument("id")
    a = p.parse_args()
    {"image": cmd_image, "back": cmd_back, "mesh": cmd_mesh, "rig": cmd_rig}[a.cmd](a)


if __name__ == "__main__":
    main()
