#!/usr/bin/env python3
"""Les textures des effets 3D (jalon 54), choisies sur planche, 512², raccordables :

    tools/fx_textures.py cracks     fx/burnt_cracks.png, la terre craquelée de la Ruée ardente
                                    (`BurntPath`) : un scan de Poly Haven (CC0), clarté en R,
                                    fissures en G
    tools/fx_textures.py serpent    fx/serpent_skin.png (albédo) et fx/serpent_skin_n.png (relief
                                    en RG, joints en B), la peau du Serpent infernal
                                    (`SerpentBody`) : un tirage de Qwen-Image
    tools/fx_textures.py fire       fx/fire_ball.png, fire_puff.png, fire_blast.png (atlas de
                                    cases de 256²) et fire_smoke.png, les photos de feu de
                                    `FlameFx` : des tirages de Qwen-Image sur fond noir (la fumée
                                    sur fond blanc, sa densité en R)

Une texture vraie et non un bruit de shader : une Ruée toute en shader était « cheap »."""
import io, json, os, sys, urllib.request
import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import character_forge as cf
import node_icons

FX = os.path.join(cf.PROJ, "fx")
SIDE = 512
CRACKS = "mud_cracked_dry_03"
# « Écailles B » sur la planche : le second des deux tirages.
SKIN_PROMPT = ("macro photograph of black snake skin, overlapping diamond scales, seamless tileable texture, "
               "flat even lighting, top-down orthographic view, high detail, fills the whole frame")
SKIN_SEED = 22
# « Photo » sur la planche de la boule : trois boules, deux explosions dont on garde le nuage (le
# champignon et sa colonne ne se lisent pas d'en haut), découpé aussi en volutes pour la traînée.
FIRE_PROMPTS = {
    "ball": "a photograph of a round ball of fire, swirling flames wrapped into a sphere, isolated on a pure "
            "black background, realistic fire, glowing yellow core, orange body, red wispy edges, VFX stock "
            "footage, centered",
    "blast": "a photograph of a fiery explosion, a billowing burst of flame expanding outward, isolated on a "
             "pure black background, realistic fire, bright yellow core, orange and dark red edges, VFX stock "
             "footage, centered",
    "smoke": "a photograph of a single puff of dark grey smoke, isolated on a pure white background, realistic, "
             "soft billowing edges, VFX stock footage, centered",
}
CELL = 256
# L'API refuse le client sans nom (403) : elle demande qu'on se présente.
AGENT = {"User-Agent": "HnSProject-decor/1.0"}


def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=AGENT)).read()


def square(img):
    return np.asarray(img.convert("RGB").resize((SIDE, SIDE), Image.LANCZOS), np.float32) / 255.0


def blurred(gray, radius):
    """Flouté en mosaïque 3×3 : le bord reprend le bord opposé, et le résultat se raccorde."""
    tiled = Image.fromarray((np.tile(gray, (3, 3)) * 255).astype(np.uint8))
    out = np.asarray(tiled.filter(ImageFilter.GaussianBlur(radius)), np.float32) / 255.0
    return out[SIDE:2 * SIDE, SIDE:2 * SIDE]


def joints(gray):
    """Les fissures et les joints, sombres et fins : ce que le flou garde plus clair qu'eux."""
    return np.clip((blurred(gray, 6) - gray) * 6.0, 0.0, 1.0)


def tileable(rgb):
    """Un tirage ne se raccorde pas : sa moitié décalée le recouvre, fondue vers les bords."""
    shifted = np.roll(rgb, (SIDE // 2, SIDE // 2), (0, 1))
    x = np.abs(np.arange(SIDE) - SIDE / 2) / (SIDE / 2)
    w = np.clip(np.maximum(x[:, None], x[None, :]) * 1.6 - 0.6, 0.0, 1.0)[..., None]
    return rgb * (1.0 - w) + shifted * w


def relief(gray, strength=3.0):
    """Les normales (GL, en RG) d'un relief lu dans la clarté."""
    h = blurred(gray, 1.5)
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    n = np.stack([-dx, dy, np.ones_like(h)], -1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True) * 0.5 + 0.5


def save(rgb, name):
    Image.fromarray((np.clip(rgb, 0.0, 1.0) * 255).astype(np.uint8)).save(os.path.join(FX, name))
    print(os.path.join(FX, name))


def cmd_cracks():
    files = json.loads(fetch("https://api.polyhaven.com/files/" + CRACKS))
    gray = square(Image.open(io.BytesIO(fetch(files["Diffuse"]["1k"]["jpg"]["url"])))).mean(-1)
    save(np.stack([gray, joints(gray), np.zeros_like(gray)], -1), "burnt_cracks.png")


def cmd_serpent():
    skin = tileable(square(Image.fromarray((qwen(SKIN_PROMPT, SKIN_SEED) * 255).astype(np.uint8))))
    gray = skin.mean(-1)
    save(skin, "serpent_skin.png")
    save(np.concatenate([relief(gray)[..., :2], joints(gray)[..., None]], -1), "serpent_skin_n.png")


def qwen(prompt, seed):
    wf = node_icons.workflow(prompt, seed)
    wf["pix"]["inputs"]["strength_model"] = 0.0
    wf["lat"]["inputs"].update(width=1024, height=1024)
    return np.asarray(cf.run(wf), np.float32) / 255.0


def cell(rgb, box, fade):
    """Une case : le cadre `box` (en part de l'image), le noir de fond ramené à 0, et un fondu
    rond dès `fade` du rayon, qu'aucune case ne coupe net en tournant."""
    h, w = rgb.shape[:2]
    x0, y0, x1, y1 = int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)
    c = Image.fromarray((rgb[y0:y1, x0:x1] * 255).astype(np.uint8)).resize((CELL, CELL), Image.LANCZOS)
    c = np.clip((np.asarray(c, np.float32) / 255.0 - 0.03) / 0.97, 0.0, 1.0)
    y, x = np.mgrid[0:CELL, 0:CELL] / (CELL - 1) * 2.0 - 1.0
    return c * np.clip((1.0 - np.sqrt(x * x + y * y)) / (1.0 - fade), 0.0, 1.0)[..., None]


def cmd_fire():
    balls = [qwen(FIRE_PROMPTS["ball"], seed) for seed in (11, 22, 33)]
    save(np.concatenate([cell(b, (0.03, 0.03, 0.97, 0.97), 0.8) for b in balls], 1), "fire_ball.png")
    b11, b22 = (qwen(FIRE_PROMPTS["blast"], seed) for seed in (11, 22))
    save(np.concatenate([cell(b11, (0.05, 0.0, 0.95, 0.62), 0.6), cell(b22, (0.02, 0.0, 0.98, 0.66), 0.6)], 1),
         "fire_blast.png")
    save(np.concatenate([cell(b11, (0.1, 0.02, 0.5, 0.42), 0.4), cell(b11, (0.45, 0.05, 0.85, 0.45), 0.4),
                         cell(b22, (0.05, 0.15, 0.45, 0.55), 0.4), cell(b22, (0.5, 0.1, 0.9, 0.5), 0.4)], 1),
         "fire_puff.png")
    # Sur fond blanc : la densité est ce qui l'assombrit.
    dense = np.clip((1.0 - qwen(FIRE_PROMPTS["smoke"], 11).mean(-1, keepdims=True) - 0.08) / 0.7, 0.0, 1.0)
    save(cell(np.repeat(dense, 3, -1), (0.3, 0.0, 1.0, 0.65), 0.45), "fire_smoke.png")


if __name__ == "__main__":
    {"cracks": cmd_cracks, "serpent": cmd_serpent, "fire": cmd_fire}[sys.argv[1]]()
