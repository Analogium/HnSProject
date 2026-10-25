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
    tools/fx_textures.py lightning  fx/lightning_bolt.png (le tronc d'un éclair, en bande),
                                    fx/lightning_spark.png et fx/lightning_orb.png, l'Éclair vif
                                    (`BoltFx`) : des tirages de Qwen-Image sur fond noir
    tools/fx_textures.py frost      fx/frost_orb.png, fx/frost_streak.png (une traînée de givre, en
                                    bande) et fx/frost_burst.png, le Trait de glace (`BoltFx` en
                                    froid) : des tirages de Qwen-Image sur fond noir
    tools/fx_textures.py streak     fx/fire_streak.png, la traînée du trait passé au feu (`BoltFx`
                                    en feu), en bande : un tirage de Qwen-Image sur fond noir
    tools/fx_textures.py storm      fx/storm_puff.png (trois bosses de cumulus, relief en RGB et densité
                                    en A) et fx/storm_bolt.png (le tronc d'un éclair qui tombe, pied en
                                    bas), le Nuage d'orage (`StormCloudFx`) : des tirages de Qwen-Image
                                    sur fond noir
    tools/fx_textures.py ice        fx/ice_veins.png, la glace veinée des Pics de glace (`IceSpikesFx`) :
                                    un tirage de Qwen-Image, raccordable
    tools/fx_textures.py iron       fx/brazier_iron.png et fx/brazier_iron_n.png, le fer rouillé
                                    du Brasero (`BrazierFx`) : un scan de Poly Haven (CC0),
                                    couleur et relief (convention OpenGL, celle de Godot)

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
# « Trépied, flammes » sur la planche : un fer brun, contre un fer peint moucheté de rouille.
IRON = "rust_coarse_01"
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
# « Dents de scie » sur la planche de l'Éclair vif (façon Kinetic Bolt) : la photo donne le tronc,
# cœur blanc et halo, à la traînée et aux arcs ; le zigzag, c'est le dessin qui le trace. Qwen sort
# des arcs plumeux au tronc presque droit, même quand on lui demande des angles vifs.
BOLT_PROMPT = ("a photograph of a single thin jagged lightning bolt, sharp angular zigzag bends, crossing the whole frame "
               "horizontally from left to right, very few short branches, blinding white core, intense violet glow around "
               "it, isolated on a pure black background, realistic, VFX stock footage")
BOLT_SEED = 33
SPARK_PROMPT = ("a photograph of an electric spark burst, a small star of crackling lightning arcs radiating from one "
                "bright point, white core, violet and blue glow, centered, isolated on a pure black background, realistic, "
                "VFX stock footage")
SPARK_SEED = 11
ORB_PROMPT = ("a photograph of ball lightning, a glowing sphere of electric plasma wrapped in thin crackling arcs, "
              "bright white core, violet glow, centered, isolated on a pure black background, realistic, VFX stock footage")
ORB_SEED = 11
FROST = {
    "orb": ("a photograph of a glowing sphere of solid blue ice, a frozen orb covered in frost crystals and spikes, cold "
            "cyan glow, centered, isolated on a pure black background, realistic, VFX stock footage", 11),
    "streak": ("a photograph of a long horizontal band of glittering ice dust and frost particles with motion blur, a "
               "straight comet tail of frozen mist crossing the whole frame from left to right, icy cyan, no snowflake, "
               "isolated on a pure black background, realistic, VFX stock footage", 44),
    "burst": ("a photograph of an explosion of small sharp ice shards and glittering frost powder radiating outward in "
              "every direction from one bright point in the center, a starburst of ice splinters, icy cyan, no block, no "
              "cube, isolated on a pure black background, realistic, VFX stock footage", 44),
}
STREAK = ("a photograph of a long horizontal streak of fire, a straight comet tail of flames and glowing embers crossing "
          "the whole frame from left to right, bright yellow head on the right, orange and red flames trailing to the left, "
          "isolated on a pure black background, realistic, VFX stock footage", 11)
# « Volutes » sur la deuxième planche du Nuage d'orage : des bosses blanches sur noir, dont la
# clarté donne la densité ; le nuage prend sa couleur et sa lumière dans le jeu.
STORM_PUFF = ("a photograph of a single small round puff of cumulus cloud, one billowing ball of white cloud with "
              "soft cauliflower bulges, lit from above, isolated on a pure black background, realistic, VFX stock "
              "footage, centered")
STORM_PUFF_SEEDS = (11, 22, 33)
STORM_BOLT = ("a photograph of a single lightning bolt striking straight down vertically from the top of the frame to "
              "the bottom, jagged angular bends, blinding white core, intense violet glow, isolated on a pure black "
              "background, realistic, VFX stock footage, centered", 11)
# « Sobre » sur la deuxième planche des Pics de glace : Poly Haven n'a que de la neige, pas de glace.
ICE = ("macro photograph of clear blue glacier ice, deep cracks and trapped air bubbles, seamless tileable texture, flat "
       "even lighting, fills the whole frame, high detail", 11)
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


def cmd_iron():
    files = json.loads(fetch("https://api.polyhaven.com/files/" + IRON))
    for kind, name in (("Diffuse", "brazier_iron.png"), ("nor_gl", "brazier_iron_n.png")):
        save(square(Image.open(io.BytesIO(fetch(files[kind]["1k"]["jpg"]["url"])))), name)


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


def band(rgb, top, bottom, name):
    """La bande de `top` à `bottom` (en part de la hauteur), en 512 × 256 : une traînée, un tronc."""
    cut = Image.fromarray((rgb[int(top * rgb.shape[0]):int(bottom * rgb.shape[0])] * 255).astype(np.uint8))
    save(np.asarray(cut.resize((SIDE, SIDE // 2), Image.LANCZOS), np.float32) / 255.0, name)


def cmd_lightning():
    band(qwen(BOLT_PROMPT, BOLT_SEED), 0.3, 0.7, "lightning_bolt.png")
    save(cell(qwen(SPARK_PROMPT, SPARK_SEED), (0.0, 0.0, 1.0, 1.0), 0.75), "lightning_spark.png")
    save(cell(qwen(ORB_PROMPT, ORB_SEED), (0.1, 0.1, 0.9, 0.9), 0.75), "lightning_orb.png")


def cmd_frost():
    save(cell(qwen(*FROST["orb"]), (0.1, 0.1, 0.9, 0.9), 0.75), "frost_orb.png")
    band(qwen(*FROST["streak"]), 0.25, 0.75, "frost_streak.png")
    save(cell(qwen(*FROST["burst"]), (0.0, 0.0, 1.0, 1.0), 0.75), "frost_burst.png")


def cmd_ice():
    save(tileable(square(Image.fromarray((qwen(*ICE) * 255).astype(np.uint8)))), "ice_veins.png")


def cmd_streak():
    band(qwen(*STREAK), 0.3, 0.7, "fire_streak.png")


def puff(rgb):
    """Une bosse : la densité tirée de la clarté, fondue en rond ; le relief, un dôme flou de cette
    densité plus le détail de la photo (sans le dôme, la bosse sortait plate sous le soleil)."""
    gray = np.asarray(Image.fromarray((rgb * 255).astype(np.uint8)).resize((CELL, CELL), Image.LANCZOS),
                      np.float32).mean(-1) / 255.0
    y, x = np.mgrid[0:CELL, 0:CELL] / (CELL - 1) * 2.0 - 1.0
    a = np.clip((gray - 0.06) / 0.5, 0.0, 1.0) * np.clip((1.0 - np.sqrt(x * x + y * y)) / 0.35, 0.0, 1.0)
    soft = lambda g, r: np.asarray(Image.fromarray((np.clip(g, 0, 1) * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(r)), np.float32) / 255.0
    h = soft(a, 14) * 1.6 + soft(gray, 1.5) * 0.5
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 20.0
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 20.0
    n = np.stack([-dx, dy, np.ones_like(h)], -1)
    return np.concatenate([n / np.linalg.norm(n, axis=-1, keepdims=True) * 0.5 + 0.5, a[..., None]], -1)


def cmd_storm():
    puffs = np.concatenate([puff(qwen(STORM_PUFF, seed)) for seed in STORM_PUFF_SEEDS], 1)
    path = os.path.join(FX, "storm_puff.png")
    Image.fromarray((puffs * 255).astype(np.uint8), "RGBA").save(path)
    print(path)
    # Le tronc seul : le voile violet coupé (la rampe du jeu le refait), le haut fondu, d'où il naît.
    rgb = qwen(*STORM_BOLT)
    w = rgb.shape[1]
    trunk = rgb[:, int(w * 0.15):int(w * 0.85)].max(-1)
    trunk = np.asarray(Image.fromarray((trunk * 255).astype(np.uint8)).resize((int(CELL * 0.7), CELL * 2),
                                                                              Image.LANCZOS), np.float32) / 255.0
    trunk = np.clip((trunk - 0.4) / 0.6, 0.0, 1.0) ** 0.8
    y = np.linspace(0, 1, trunk.shape[0])[:, None]
    x = np.abs(np.linspace(-1, 1, trunk.shape[1]))[None, :]
    trunk = trunk * np.clip(y / 0.12, 0.0, 1.0) * np.clip((1.0 - x) / 0.25, 0.0, 1.0)
    save(np.repeat(trunk[..., None], 3, -1), "storm_bolt.png")


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
    {"cracks": cmd_cracks, "serpent": cmd_serpent, "fire": cmd_fire, "iron": cmd_iron, "lightning": cmd_lightning,
     "frost": cmd_frost, "streak": cmd_streak, "storm": cmd_storm, "ice": cmd_ice}[sys.argv[1]]()
