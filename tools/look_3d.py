#!/usr/bin/env python3
"""Monte en GIF les images filmées par `tools/look_3d.gd` (jalon 54) : une par caméra et par
animation, recadrée sur le personnage, dans le même dossier du Bureau.

    tools/look_3d.py <sujet>"""
import glob, os, re, sys
import numpy as np
from PIL import Image

FPS = 15  # celui de look_3d.gd
folder = f"/mnt/c/Users/Theo/Desktop/hns-captures-{sys.argv[1]}"
films = {}
for path in sorted(glob.glob(os.path.join(folder, "*-[0-9][0-9][0-9].png"))):
    films.setdefault(re.sub(r"-\d{3}\.png$", "", os.path.basename(path)), []).append(path)
for name, paths in films.items():
    frames = [Image.open(p).convert("RGB") for p in paths]
    # Le cadre : tout ce qui bouge d'une image à l'autre, plus une marge.
    a = np.stack([np.asarray(f).astype(int) for f in frames])
    moving = (np.abs(a - a[0]).max(-1) > 24).any(0)
    ys, xs = np.where(moving) if moving.any() else (np.array([0, a.shape[1] - 1]), np.array([0, a.shape[2] - 1]))
    m = 40
    box = (max(xs.min() - m, 0), max(ys.min() - m, 0), min(xs.max() + m, a.shape[2]), min(ys.max() + m, a.shape[1]))
    cropped = [f.crop(box) for f in frames]
    cropped[0].save(os.path.join(folder, name + ".gif"), save_all=True, append_images=cropped[1:],
                    duration=1000 // FPS, loop=0)
    for p in paths:
        os.remove(p)
    print(name + ".gif", len(frames), "images")
