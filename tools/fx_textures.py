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
    tools/fx_textures.py nova       fx/nova_ice.png, la glace craquelée en étoile du sol gelé
                                    (`FrostGroundFx`, un décal : couleur et alpha ; tirée pour la Nova),
                                    et fx/frost_wind.png, le vent de givre de l'onde de choc de la Nova
                                    (`IceNovaFx`, bande raccordable en x) : des tirages de Qwen-Image
    tools/fx_textures.py fire_wind  fx/fire_wind.png, la bande de flammes de l'onde de feu (`FireBlastFx`,
                                    le liseré de `FireRing`), raccordable en x : un tirage de Qwen-Image
                                    sur fond noir
    tools/fx_textures.py vortex     fx/frost_vortex.png, la spirale de lames de glace vue de dessus du Désastre
                                    hivernal (`IceVortexFx`) : un tirage de Qwen-Image sur fond noir
    tools/fx_textures.py orb        fx/frozen_orb_mist.png, la brume de givre derrière l'Orbe gelée
                                    (`FrozenOrbFx`) : un tirage de Qwen-Image sur fond noir
    tools/fx_textures.py holy       fx/holy_shaft.png (une colonne de lumière, raccordée en x : le Pilier sacré,
                                    `SacredPillarFx`), fx/holy_wave.png (une bande de lumière : l'onde, les rayons,
                                    le marteau et les chaînes, `HolyBlastFx`) et fx/holy_glyph.png (le sol consacré,
                                    un décal) et fx/holy_flare.png (l'éclat au cœur du souffle) : des tirages
                                    de Qwen-Image sur fond noir
    tools/fx_textures.py rot        le manuel nécrotique : fx/rot_gas.png (une bande de gaz, raccordée en x : le
                                    mur de `RotBlastFx`), fx/rot_puff.png (deux volutes en atlas), fx/plague_skull.png
                                    (le crâne de la Peste), fx/curse_eye.png
                                    et fx/curse_sigil.png (l'œil et le sceau de la Malédiction), fx/rot_sludge.png (la
                                    boue du Marais, un décal), fx/rot_flesh.png (la peau des créatures, raccordable) :
                                    des tirages de Qwen-Image sur fond noir
    tools/fx_textures.py steel      le manuel du chevalier (`SteelFx`) : fx/steel_slash.png (une traînée de taille en
                                    bande, pointe à droite : le ruban d'un coup), fx/steel_dust.png (une bande de
                                    poussière, raccordée en x : l'onde d'un coup au sol), fx/steel_crater.png et
                                    fx/steel_blood.png (le sol frappé, le sang de la Gerbe : des décals),
                                    fx/steel_furrow.png (le Sillon d'acier, un décal en long) et fx/steel_glint.png
                                    (l'éclat sur l'acier) : des tirages de Qwen-Image sur fond noir
    tools/fx_textures.py witch      le manuel de la sorcière : fx/witch_glyph.png et fx/witch_seal.png (le cercle
                                    runique des Glyphes, `GlyphFx`, et le Sceau aux trois logements), fx/witch_thread.png
                                    (un fil de lumière en bande raccordée en x : l'Entrelacs, le triangle), fx/witch_brew.png (ce qui bout
                                    dans le Chaudron, raccordable) et fx/witch_vapor.png (sa vapeur) : des tirages de
                                    Qwen-Image, en clarté seule — la rampe de l'élément les colore
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
# « Vitrine sans brume » sur la planche de la Nova (qualité Last Epoch) : la glace « A », contre une glace aux
# fissures plus fines ; deux tirages de givre au sol sortaient en feuilles de fougère.
NOVA_ICE = ("top-down photograph of a frozen puddle surface, cracked clear ice with white frost along the cracks and air "
            "bubbles, seamless tileable texture, flat even lighting, orthographic view, high detail, fills the whole "
            "frame", 31)
FROST_WIND = ("a photograph of a horizontal streak of swirling icy wind, white and pale blue frost mist wisps and tiny "
              "ice crystals blowing from left to right, isolated on a pure black background, VFX stock footage", 7)
# « Lames » sur la planche du Désastre hivernal, contre un blizzard en spirale (graine 7 : « top-down photograph of
# a swirling blizzard vortex ») qui, tenu sur 52 px, couvrait le sol d'un disque presque blanc.
VORTEX = ("top-down view of a spiral whirlwind of ice shards and snow, a cyclone of frost seen from above with curved "
          "spiral arms, pale blue and white, isolated on a pure black background, VFX stock footage, centered", 21)
# « Oursin, brume légère » sur la planche de l'Orbe gelée : la brume derrière les cristaux, contre la même photo seule,
# en grand, et l'orbe du Trait de glace en grand.
ORB_MIST = ("a photograph of a frozen orb, a glowing sphere of pale blue ice with sharp frost crystals growing out of it "
            "and swirling frost mist around it, isolated on a pure black background, VFX stock footage, centered", 11)
# « Pile rouge » sur la planche du manuel des flammes à la barre de Last Epoch : la bande de l'onde de feu
# (l'explosion, le liseré de l'Immolation), contre la graine 21, la même flamme en biais.
FIRE_WIND = ("a photograph of a horizontal band of roaring flames blowing from left to right, a wall of fire swept by "
             "strong wind, bright yellow and orange tongues of flame with dark red edges, isolated on a pure black "
             "background, realistic fire, VFX stock footage", 7)
HOLY = {
    "shaft": ("a photograph of a single vertical column of divine light falling from the sky, a bright beam of warm "
              "golden white light with soft god rays and glowing dust motes, from the top of the frame to the bottom, "
              "isolated on a pure black background, realistic, VFX stock footage, centered", 7),
    "wave": ("a photograph of a horizontal band of radiant holy light, streaks of warm golden and pale pink light energy "
             "with tiny glittering motes blowing from left to right, isolated on a pure black background, VFX stock "
             "footage", 7),
    "flare": ("a photograph of a burst of divine light rays radiating outward from one bright point in the center, "
              "a starburst of sharp golden white light beams, lens flare, isolated on a pure black background, VFX stock "
              "footage, centered", 7),
    "glyph": ("top-down view of a glowing golden sacred circle engraved with holy runes and a radiant star pattern, "
              "ornate celestial sigil made of light, isolated on a pure black background, VFX stock footage, centered", 7),
}
BLACK = ", isolated on a pure black background, VFX stock footage"
ROT = {
    "gas": ("a photograph of a horizontal band of thick toxic green gas and sickly yellow-green smoke billowing from "
            "left to right, poisonous miasma wisps" + BLACK, 7),
    "puff": ("a photograph of a single billowing cloud of thick toxic green smoke, a round poisonous gas puff" + BLACK
             + ", centered", (7, 21)),
    "skull": ("a photograph of a ghostly skull made of swirling toxic green smoke, a plague spirit with smoke wisps "
              "trailing behind it" + BLACK + ", centered", 7),
    "eye": ("a photograph of a single evil eye wide open, sickly yellow iris with a black slit pupil, veined bloodshot "
            "white, dark rotting eyelids" + BLACK + ", centered", 7),
    "sigil": ("top-down view of a glowing sickly green cursed circle of necromantic runes around a skull sigil, ornate "
              "occult seal made of toxic light" + BLACK + ", centered", 7),
    "sludge": ("top-down photograph of a puddle of bubbling toxic green sludge, poisonous slime pool with bubbles and "
               "foam" + BLACK + ", centered", 7),
    "flesh": ("macro photograph of rotting pustulent grey-green flesh, boils, dark veins and wet skin, seamless tileable "
              "texture, flat even lighting, fills the whole frame, high detail", 7),
}
STEEL = {
    "slash": ("a photograph of a single horizontal streak of a sword slash, a sharp bright white and pale silver motion "
              "blur trail of a blade cutting through the air, thick on the left and tapering to a fine point on the right, "
              "thin wispy air streaks" + BLACK, 7),
    "dust": ("a photograph of a horizontal band of billowing light brown dust and sand cloud blowing from left to right, "
             "a dusty shockwave with small flying grit" + BLACK, 7),
    "crater": ("top-down photograph of a small impact crater in dry ocher earth, the ground shattered by a heavy blow, "
               "deep radial cracks spreading outward from the center, broken clods of dirt" + BLACK + ", centered", 7),
    "glint": ("a photograph of a sharp glint of light on polished steel, a bright white four-pointed star sparkle with a "
              "thin horizontal lens flare streak" + BLACK + ", centered", 7),
    # « Par une lame géante » : Qwen posait l'épée en travers du sillon.
    "furrow": ("top-down photograph of a long straight trench ploughed into cracked dry ocher earth, a deep groove with "
               "crumbling broken edges and loose grit, seen from directly above, running from left to right, nothing "
               "else in the frame" + BLACK, 7),
    "blood": ("top-down photograph of a splatter of dark red blood on the ground, a radial burst of droplets and streaks "
              "spraying outward from the center" + BLACK + ", centered", 7),
}
# Une graine chacun (7) : ComfyUI tournait à 25 s le pas l'éditeur ouvert. Le Sceau, tiré pour voir, avait
# ses trois logements aux coins du triangle, sur l'anneau : `GlyphFx.SOCKETS` les y suit, mesurés.
WITCH = {
    "glyph": ("top-down view of a glowing witch's magic circle, a ring of arcane runes and occult symbols around an "
              "inner triangle sigil, thin lines drawn in pure white light" + BLACK + ", centered", 7),
    "seal": ("top-down view of a large glowing occult seal, three small empty circles placed at the corners of a "
             "triangle inside a ring of arcane witch runes, drawn in pure white light" + BLACK + ", centered", 7),
    "thread": ("a photograph of a horizontal thin strand of glowing white magical energy, a twisted thread of light "
               "with tiny sparkles, running from left to right across the frame" + BLACK, 7),
    "brew": ("top-down photograph of the surface of a boiling magic potion, glowing liquid with many round bubbles "
             "bursting and swirling foam, seamless tileable texture, fills the whole frame, high detail", 7),
    "vapor": ("a photograph of a single wisp of glowing magical vapor rising and curling, soft swirling white steam"
              + BLACK + ", centered", 7),
}
# Les images sources des deux corps de la sorcière, tirées une fois pour un modèle (tools/characters/LISEZMOI.md,
# « Un corps qui n'est pas un personnage ») : graine 7 chacune.
WITCH_BODIES = {
    "crow": ("polished stylized 3d game creature render in the style of Torchlight Infinite, hand-painted textures, "
             "saturated colors, clean readable shapes, soft rim light, front view, facing the viewer, a black raven "
             "familiar flying with its wings spread wide open to both sides, symmetrical, glossy blue-black feathers, "
             "sharp grey beak, small glowing violet eyes, tail fanned out, isolated on a solid flat pure chroma key "
             "green background (#00FF00), no floor, no shadow, no text", 7),
    "cauldron": ("polished stylized 3d game prop render in the style of Torchlight Infinite, hand-painted textures, "
                 "saturated colors, clean readable shapes, soft rim light, three-quarter view from slightly above, an "
                 "empty witch's cauldron, a round pot-bellied black cast iron cauldron standing on three short clawed "
                 "legs, thick rolled rim, two small ring handles, dark empty inside, isolated on a solid flat pure "
                 "chroma key green background (#00FF00), no floor, no shadow, no text", 7),
}
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


def nova_ice(rgb):
    """Un décal : la glace en couleur et en alpha, bord rond cassé le long des fissures de la Ruée. Éclairé
    par le soleil du jeu, un albédo presque blanc sortait en disque blanc : il reste au cyan."""
    gray = square(Image.fromarray((rgb * 255).astype(np.uint8))).mean(-1)
    lum = (gray - gray.min()) / (gray.max() - gray.min())
    color = np.array([0.18, 0.42, 0.68]) * (1.0 - lum[..., None]) + np.array([0.55, 0.8, 0.95]) * lum[..., None]
    cracks = np.asarray(Image.open(os.path.join(FX, "burnt_cracks.png")).convert("RGB"), np.float32)[..., 1] / 255.0
    y, x = np.mgrid[0:SIDE, 0:SIDE] / (SIDE - 1) * 2.0 - 1.0
    edge = np.clip((0.92 - np.sqrt(x * x + y * y) - cracks * 0.18) / 0.12, 0.0, 1.0)
    alpha = np.clip((lum - 0.25) / 0.6, 0.0, 1.0) * 0.75 * edge
    return np.concatenate([color, alpha[..., None]], -1)


def frost_wind(rgb):
    """La bande du milieu, en 512 × 256, raccordée en x : elle fait le tour de l'onde."""
    h = rgb.shape[0]
    cut = Image.fromarray((rgb[int(h * 0.25):int(h * 0.75)] * 255).astype(np.uint8)).resize((SIDE, SIDE // 2), Image.LANCZOS)
    b = np.asarray(cut, np.float32) / 255.0
    x = np.abs(np.arange(SIDE) - SIDE / 2) / (SIDE / 2)
    w = np.clip(x * 1.6 - 0.6, 0.0, 1.0)[None, :, None]
    return b * (1.0 - w) + np.roll(b, SIDE // 2, 1) * w


def cmd_nova():
    save(nova_ice(qwen(*NOVA_ICE)), "nova_ice.png")
    save(frost_wind(qwen(*FROST_WIND)), "frost_wind.png")


def vortex(rgb):
    """Le tourbillon entier en 512², le noir de fond ramené à 0 et un fondu rond au bord : il tourne."""
    img = Image.fromarray((rgb * 255).astype(np.uint8)).resize((SIDE, SIDE), Image.LANCZOS)
    c = np.clip((np.asarray(img, np.float32) / 255.0 - 0.03) / 0.97, 0.0, 1.0)
    y, x = np.mgrid[0:SIDE, 0:SIDE] / (SIDE - 1) * 2.0 - 1.0
    return c * np.clip((1.0 - np.sqrt(x * x + y * y)) / 0.15, 0.0, 1.0)[..., None]


def holy_shaft(rgb):
    """Le milieu de la colonne, en 512², raccordé en x : il fait le tour du cylindre."""
    w = rgb.shape[1]
    cut = Image.fromarray((rgb[:, int(w * 0.2):int(w * 0.8)] * 255).astype(np.uint8)).resize((SIDE, SIDE), Image.LANCZOS)
    b = np.asarray(cut, np.float32) / 255.0
    x = np.abs(np.arange(SIDE) - SIDE / 2) / (SIDE / 2)
    k = np.clip(x * 1.6 - 0.6, 0.0, 1.0)[None, :, None]
    return b * (1.0 - k) + np.roll(b, SIDE // 2, 1) * k


def holy_wave(rgb):
    """La bande de `frost_wind`, sans le soleil où elle naît, à droite : raccordée, il faisait une tache."""
    return frost_wind(rgb[:, :int(rgb.shape[1] * 0.72)])


def holy_glyph(rgb):
    """Un décal : le cercle en couleur et en alpha (sa clarté), le noir de fond ramené à rien."""
    img = Image.fromarray((rgb * 255).astype(np.uint8)).resize((SIDE, SIDE), Image.LANCZOS)
    c = np.clip((np.asarray(img, np.float32) / 255.0 - 0.04) / 0.96, 0.0, 1.0)
    lum = c.max(-1)
    return np.concatenate([c / np.maximum(lum[..., None], 1e-3) * np.sqrt(lum[..., None]), lum[..., None]], -1)


def cmd_holy():
    save(holy_shaft(qwen(*HOLY["shaft"])), "holy_shaft.png")
    save(holy_wave(qwen(*HOLY["wave"])), "holy_wave.png")
    save(holy_glyph(qwen(*HOLY["glyph"])), "holy_glyph.png")
    save(cell(qwen(*HOLY["flare"]), (0.1, 0.1, 0.9, 0.9), 0.6), "holy_flare.png")


def cmd_rot():
    save(frost_wind(qwen(*ROT["gas"])), "rot_gas.png")
    prompt, seeds = ROT["puff"]
    # Qwen les sort en champignon : la tête seule.
    save(np.concatenate([cell(qwen(prompt, seed), (0.08, 0.04, 0.92, 0.68), 0.6) for seed in seeds], 1), "rot_puff.png")
    save(cell(qwen(*ROT["skull"]), (0.2, 0.02, 0.95, 0.92), 0.75), "plague_skull.png")
    save(cell(qwen(*ROT["eye"]), (0.0, 0.15, 1.0, 0.85), 0.9), "curse_eye.png")
    save(cell(qwen(*ROT["sigil"]), (0.0, 0.0, 1.0, 1.0), 0.9), "curse_sigil.png")
    save(holy_glyph(qwen(*ROT["sludge"])), "rot_sludge.png")
    save(tileable(square(Image.fromarray((qwen(*ROT["flesh"]) * 255).astype(np.uint8)))), "rot_flesh.png")


def steel_slash(rgb):
    """La traînée sans le noir autour, en 512 × 256, pointe à droite ; sa queue coupée nette, fondue."""
    h, w = rgb.shape[:2]
    cut = Image.fromarray((rgb[int(h * 0.2):int(h * 0.8), :int(w * 0.95)] * 255).astype(np.uint8))
    b = np.asarray(cut.resize((SIDE, SIDE // 2), Image.LANCZOS), np.float32) / 255.0
    return b * np.clip(np.linspace(0.0, 1.0, SIDE) / 0.15, 0.0, 1.0)[None, :, None]


def ground_decal(rgb, long=False, solid=True, shade=0.42):
    """Un décal du sol frappé, assombri (sous le soleil, un albédo clair sort blanc). `solid` : l'alpha est
    la silhouette remplie, qui garde ses fissures noires au lieu d'y laisser voir le sol, pesée par l'ombre ; sinon la clarté
    (le sang, dont le fond passe entre les gouttes). `long` : la bande du milieu, fondue aux bouts."""
    h = rgb.shape[0]
    if long:
        rgb = rgb[int(h * 0.3):int(h * 0.7)]
    size = (SIDE, SIDE // 2) if long else (SIDE, SIDE)
    c = np.asarray(Image.fromarray((rgb * 255).astype(np.uint8)).resize(size, Image.LANCZOS), np.float32) / 255.0
    lum = c.max(-1)
    if solid:
        body = Image.fromarray(((lum > 0.12) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(5))
        # Ses ombres seules (fissures, creux) : en entier, sa terre claire sortait en autocollant.
        a = np.clip(np.asarray(body, np.float32) / 255.0 * 1.4, 0.0, 1.0) * (0.2 + 0.8 * np.clip(1.0 - lum / 0.7, 0.0, 1.0))
    else:
        a = np.clip((lum - 0.04) * 3.0, 0.0, 1.0)
    y, x = np.mgrid[0:size[1], 0:size[0]]
    x = x / (size[0] - 1) * 2.0 - 1.0
    y = y / (size[1] - 1) * 2.0 - 1.0
    if long:
        a *= np.clip((1.0 - np.abs(x)) / 0.2, 0.0, 1.0) * np.clip((1.0 - np.abs(y)) / 0.3, 0.0, 1.0)
    else:
        a *= np.clip((1.0 - np.sqrt(x * x + y * y)) / 0.25, 0.0, 1.0)
    return np.concatenate([c * shade, a[..., None]], -1)


def cmd_steel():
    save(steel_slash(qwen(*STEEL["slash"])), "steel_slash.png")
    save(frost_wind(qwen(*STEEL["dust"])), "steel_dust.png")
    save(cell(qwen(*STEEL["glint"]), (0.1, 0.1, 0.9, 0.9), 0.6), "steel_glint.png")
    save(ground_decal(qwen(*STEEL["crater"])), "steel_crater.png")
    save(ground_decal(qwen(*STEEL["furrow"]), long=True), "steel_furrow.png")
    save(ground_decal(qwen(*STEEL["blood"]), solid=False, shade=0.6), "steel_blood.png")


def clarity(rgb):
    """La clarté seule, le noir de fond ramené à 0 : la rampe de l'élément colore."""
    lum = np.clip((rgb.max(-1) - 0.04) / 0.96, 0.0, 1.0)
    return np.repeat(lum[..., None], 3, -1)


def sigil(rgb):
    """Un cercle en 512², fondu à son bord : il tourne."""
    c = clarity(np.asarray(Image.fromarray((rgb * 255).astype(np.uint8)).resize((SIDE, SIDE), Image.LANCZOS),
                           np.float32) / 255.0)
    y, x = np.mgrid[0:SIDE, 0:SIDE] / (SIDE - 1) * 2.0 - 1.0
    return c * np.clip((1.0 - np.sqrt(x * x + y * y)) / 0.04, 0.0, 1.0)[..., None]


def cmd_witch():
    save(sigil(qwen(*WITCH["glyph"])), "witch_glyph.png")
    save(sigil(qwen(*WITCH["seal"])), "witch_seal.png")
    save(frost_wind(clarity(qwen(*WITCH["thread"]))), "witch_thread.png")
    save(clarity(tileable(square(Image.fromarray((qwen(*WITCH["brew"]) * 255).astype(np.uint8))))), "witch_brew.png")
    save(clarity(cell(qwen(*WITCH["vapor"]), (0.1, 0.05, 0.9, 0.85), 0.6)), "witch_vapor.png")


def cmd_fire_wind():
    save(frost_wind(qwen(*FIRE_WIND)), "fire_wind.png")


def cmd_vortex():
    save(vortex(qwen(*VORTEX)), "frost_vortex.png")


def cmd_orb():
    save(cell(qwen(*ORB_MIST), (0.05, 0.05, 0.95, 0.95), 0.75), "frozen_orb_mist.png")


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
     "frost": cmd_frost, "streak": cmd_streak, "storm": cmd_storm, "ice": cmd_ice,
     "nova": cmd_nova, "fire_wind": cmd_fire_wind, "vortex": cmd_vortex, "orb": cmd_orb, "holy": cmd_holy, "rot": cmd_rot,
     "steel": cmd_steel, "witch": cmd_witch}[sys.argv[1]]()
