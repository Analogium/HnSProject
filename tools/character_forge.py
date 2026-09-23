#!/usr/bin/env python3
"""Les personnages joueurs, d'un prompt jusqu'aux planches du jeu. Recette :
tools/characters/LISEZMOI.md.

    tools/character_forge.py concept <id>              planche de concepts, une par graine
    tools/character_forge.py keep <id> concept <graine>  retient un concept
    tools/character_forge.py views <id>                planche face / profil / dos, une ligne par graine
    tools/character_forge.py keep <id> views <graine>    retient les trois vues
    tools/character_forge.py anim <id>                 marche et attaque générées, un GIF par geste et par graine
    tools/character_forge.py keep <id> walk <vue> <graine>   retient un cycle (walk, attack ; down, side, up)
    tools/character_forge.py build <id>                art/characters/<id>.png et .json, plus l'aperçu

Un personnage est décrit par `tools/characters/<id>.json` : prompts, graines,
recolorations, retouches à la main, main et coupures d'animation. Les images
retenues sont gardées à côté, dans `tools/characters/<id>/` : `build` n'a donc
jamais besoin de ComfyUI.

Le concept peut venir d'ailleurs — une image Leonardo, un dessin : la déposer en
`tools/characters/<id>/concept.png` et passer directement à `views`.

La marche et l'attaque sont **générées**, chaque cycle en une seule image : d'une
image à l'autre de la même génération, le personnage reste le même, ce que des
tirages séparés ne tiennent pas. Chaque image est ensuite ramenée sur la palette
de la pose validée, et reçoit les mêmes retouches. Le jeu n'anime lui-même que le
souffle du repos (`SpriteForge._draw_sheet()`) et pose l'arme à la main de chaque
image.
"""
import argparse, colorsys, io, json, os, shutil, sys, time, urllib.parse, urllib.request, uuid
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from item_icons import HOST, PROJ, WORK, post, workflow

HERE = os.path.dirname(os.path.abspath(__file__))
CHARS = os.path.join(HERE, "characters")
RAW = os.path.join(WORK, "characters")
DESKTOP = os.environ.get("HNS_DESKTOP", "/mnt/c/Users/Theo/Desktop")
DIRS = ("down", "side", "up")
GROUND = (54, 48, 54)
OUTLINE = (22, 16, 30)

TAIL = ", isolated on a plain flat neutral grey background, no ground, thick dark outline"
CONCEPT_NEG = ("text, letters, watermark, signature, blurry, photo, 3d render, realistic proportions, "
               "gradient background, scenery, multiple characters, sprite sheet, grid, frame, border, cropped")
NEG = ("text, watermark, blurry, photo, 3d render, realistic proportions, gradient background, "
       "scenery, weapon, wand, staff, sword, broom, multiple characters, sprite sheet, frame, border")
VIEW_WORDS = {"down": "front view, facing the viewer",
              "side": "side view, profile facing right",
              "up": "back view, seen from behind, back of the head"}

# --------------------------------------------------------------------------
# Squelettes OpenPose — ordre et couleurs de controlnet_aux, qu'attend le modèle.
# Proportions chibi : une tête du tiers de la hauteur. Avec un corps adulte, le
# visage retombait à quatre pixels une fois réduit à 48.
# --------------------------------------------------------------------------
POSE_COLORS = [(255,0,0),(255,85,0),(255,170,0),(255,255,0),(170,255,0),(85,255,0),(0,255,0),
               (0,255,85),(0,255,170),(0,255,255),(0,170,255),(0,85,255),(0,0,255),(85,0,255),
               (170,0,255),(255,0,255),(255,0,170),(255,0,85)]
LIMBS = [(1,2),(1,5),(2,3),(3,4),(5,6),(6,7),(1,8),(8,9),(9,10),(1,11),(11,12),(12,13),
         (1,0),(0,14),(14,16),(0,15),(15,17)]


def _front(flip):
    s = -1 if flip else 1
    X = lambda dx: 512 - s * dx
    return {0:(512,370),1:(512,510),2:(X(85),520),3:(X(110),605),4:(X(115),685),
            5:(X(-85),520),6:(X(-110),605),7:(X(-115),685),8:(X(45),690),9:(X(48),800),
            10:(X(48),910),11:(X(-45),690),12:(X(-48),800),13:(X(-48),910),
            14:(X(55),335),15:(X(-55),335),16:(X(115),350),17:(X(-115),350)}


# De dos : ni nez ni yeux, sinon le modèle dessine un visage.
POSES = {
    "down": _front(False),
    "up": {k: v for k, v in _front(True).items() if k not in (0, 14, 15)},
    "side": {0:(600,380),1:(505,510),2:(500,520),3:(495,605),4:(505,685),5:(505,520),
             6:(515,605),7:(530,685),8:(500,690),9:(488,800),10:(478,910),11:(510,690),
             12:(530,800),13:(542,910),15:(570,335),17:(455,355)},
}


def skeleton(kp):
    im = Image.new("RGB", (1024, 1024)); d = ImageDraw.Draw(im)
    for i, (a, b) in enumerate(LIMBS):
        if a in kp and b in kp:
            d.line([kp[a], kp[b]], fill=tuple(int(c * 0.6) for c in POSE_COLORS[i]), width=14)
    for i, (x, y) in kp.items():
        d.ellipse([x - 8, y - 8, x + 8, y + 8], fill=POSE_COLORS[i])
    return im


# --------------------------------------------------------------------------
# ComfyUI
# --------------------------------------------------------------------------
def upload(img, name):
    buf = io.BytesIO(); img.save(buf, "PNG"); b = uuid.uuid4().hex
    body = (f"--{b}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{name}\"\r\n"
            "Content-Type: image/png\r\n\r\n").encode() + buf.getvalue() + \
           f"\r\n--{b}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n--{b}--\r\n".encode()
    req = urllib.request.Request(HOST + "/upload/image", body,
                                 {"Content-Type": f"multipart/form-data; boundary={b}"})
    return json.load(urllib.request.urlopen(req))["name"]


def run(wf):
    pid = post("/prompt", {"prompt": wf})["prompt_id"]
    while True:
        h = json.load(urllib.request.urlopen(f"{HOST}/history/{pid}"))
        if pid in h:
            break
        time.sleep(1.0)
    if "save" not in h[pid]["outputs"]:
        sys.exit("ComfyUI a refusé le graphe : %s" % json.dumps(h[pid].get("status"))[:800])
    img = h[pid]["outputs"]["save"]["images"][0]
    q = urllib.parse.urlencode({k: img[k] for k in ("filename", "subfolder", "type")})
    return Image.open(io.BytesIO(urllib.request.urlopen(f"{HOST}/view?{q}").read())).convert("RGB")


def view_graph(cfg, concept, direction, seed):
    """IPAdapter tient l'identité du concept, OpenPose impose la vue. Réglages du
    jalon 25 : c'est avec eux que face, profil et dos sont sortis cohérents."""
    wf = workflow(cfg["views"]["prompt"].format(view=VIEW_WORDS[direction]) + TAIL, seed, NEG)
    wf.update({
        "ref": {"class_type": "LoadImage", "inputs": {"image": concept}},
        "pimg": {"class_type": "LoadImage",
                 "inputs": {"image": upload(skeleton(POSES[direction]), f"hns_pose_{direction}.png")}},
        "ipm": {"class_type": "IPAdapterModelLoader",
                "inputs": {"ipadapter_file": "ip-adapter-plus_sdxl_vit-h.safetensors"}},
        "cv": {"class_type": "CLIPVisionLoader",
               "inputs": {"clip_name": "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"}},
        "ip": {"class_type": "IPAdapterAdvanced", "inputs": {
            "model": ["lora", 0], "ipadapter": ["ipm", 0], "image": ["ref", 0], "clip_vision": ["cv", 0],
            "weight": cfg["views"]["ip_weight"], "weight_type": "style transfer", "combine_embeds": "concat",
            "start_at": 0.0, "end_at": 1.0, "embeds_scaling": "V only"}},
        "cn": {"class_type": "ControlNetLoader",
               "inputs": {"control_net_name": "controlnet-openpose-sdxl-xinsir.safetensors"}},
        "cna": {"class_type": "ControlNetApplyAdvanced", "inputs": {
            "positive": ["pos", 0], "negative": ["neg", 0], "control_net": ["cn", 0], "image": ["pimg", 0],
            "strength": 0.9, "start_percent": 0.0, "end_percent": 0.8}},
    })
    wf["ks"]["inputs"].update(model=["ip", 0], positive=["cna", 0], negative=["cna", 1])
    return wf


# --------------------------------------------------------------------------
# Nettoyage : de 1024 à la taille du jeu
# --------------------------------------------------------------------------
def silhouette(a):
    """Le fond se reconnaît à ce qu'il touche les bords (voir item_icons.cut). En
    plus : l'ombre au sol que le modèle dessine — grise, peu saturée, dans le bas.
    Laissée, elle entrait dans le cadrage et écrasait le personnage de trois pixels."""
    ring = np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3),
                           a[:, :4].reshape(-1, 3), a[:, -4:].reshape(-1, 3)])
    lab, _ = ndimage.label(np.linalg.norm(a - np.median(ring, 0), axis=2) < 0.12)
    edge = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1]); edge.discard(0)
    keep = ~np.isin(lab, list(edge))
    ys, _ = np.where(keep)
    mx, mn = a.max(2), a.min(2)
    sat = (mx - mn) / np.maximum(mx, 1e-3)
    low = np.zeros_like(keep); low[int(ys.max() - (ys.max() - ys.min()) * 0.10):] = True
    # L'ombre est un fond assombri : proche de lui, rien à voir avec des bottes.
    # Sans la seconde règle, celle des cycles, rosée, restait sous les pieds.
    shadow = ((sat < 0.22) & (mx > 0.28)) | (np.linalg.norm(a - np.median(ring, 0), axis=2) < 0.35)
    keep &= ~(low & shadow)
    keep = ndimage.binary_opening(keep, iterations=2)
    lab, n = ndimage.label(keep)
    return lab == (np.argmax(ndimage.sum(keep, lab, range(1, n + 1))) + 1)


def bbox(keep):
    ys, xs = np.where(keep)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def reduce(a, keep, scale):
    """Moyenne de zone sur l'alpha prémultiplié, puis alpha tranché : un bord à demi
    transparent se lirait gris sur le sol du jeu. `scale` est commun à toutes les
    images d'un cycle, sinon un pas jambes écartées, plus bas, serait agrandi."""
    x0, y0, x1, y1 = bbox(keep)
    rgba = np.dstack([a * keep[..., None], keep]).astype(np.float32)[y0:y1, x0:x1]
    w, height = max(1, round((x1 - x0) * scale)), max(1, round((y1 - y0) * scale))
    arr = np.asarray(Image.fromarray((rgba * 255).astype("uint8"), "RGBA")
                     .resize((w, height), Image.BOX)).astype(np.float32)
    al = arr[..., 3:] / 255
    rgb = np.where(al > 0, arr[..., :3] / np.maximum(al, 1e-3), 0)
    m = arr[..., 3] > 110
    out = np.zeros((height, w, 4), "uint8")
    out[m, :3] = np.clip(rgb[m], 0, 255); out[m, 3] = 255
    return out


def recolor(o, rule):
    """Change une teinte dans une bande de hauteur. Ce que le prompt n'obtient pas
    — SDXL ignore « peau bleue » — se repeint ici, en gardant la valeur."""
    f = o[..., :3].astype(float) / 255
    h, w = o.shape[:2]
    lo, hi = rule["hue"]
    for y in range(int(h * rule["rows"][0]), int(h * rule["rows"][1])):
        for x in range(w):
            if not o[y, x, 3]:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(*f[y, x])
            in_hue = (hh >= lo or hh <= hi) if lo > hi else lo <= hh <= hi
            if in_hue and rule["sat"][0] < ss < rule["sat"][1] and vv > rule["val_min"]:
                r, g, b = colorsys.hsv_to_rgb(rule["to_hue"], rule["to_sat"], vv)
                o[y, x, :3] = (r * 255, g * 255, b * 255)


def patch(o, p, colors, dx0=0):
    """Une retouche à la main : une grille posée par-dessus, `.` laisse passer.
    `at` est en coordonnées de la case, celles qu'on lit sur la planche."""
    x0, y0 = p["at"][0] + dx0, p["at"][1]
    for dy, row in enumerate(p["grid"]):
        for dx, ch in enumerate(row):
            if ch != ".":
                o[y0 + dy, x0 + dx, :3] = [int(colors[ch][i:i + 2], 16) for i in (0, 2, 4)]
                o[y0 + dy, x0 + dx, 3] = 255


def outline(o):
    m = o[..., 3] > 0
    pad = np.pad(m, 1)
    edge = ~m & (pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:])
    o[edge] = OUTLINE + (255,)


def framed(o):
    """Contour sur une marge : il déborde d'un pixel de chaque côté de la silhouette."""
    out = np.zeros((o.shape[0] + 2, o.shape[1] + 2, 4), "uint8")
    out[1:-1, 1:-1] = o
    outline(out)
    return out


def recolored(cfg, o, direction):
    for rule in cfg.get("recolor", []):
        if direction in rule.get("views", DIRS):
            recolor(o, rule)
    return o


def place(cell, o, x0, y0):
    h, w = o.shape[:2]
    for y in range(h):
        for x in range(w):
            if o[y, x, 3] and 0 <= y + y0 < cell.shape[0] and 0 <= x + x0 < cell.shape[1]:
                cell[y + y0, x + x0] = o[y, x]


def slimmed(cfg, a, keep, direction):
    """Affine (`slim`, la part de largeur gardée) et raccourcit (`squash`, la part de
    hauteur gardée) ce qui est sous la tête, sur l'image source : réduite ensuite,
    elle reste nette. La tête ne bouge pas de taille, le visage retouché à la main
    y reste juste. Rend aussi de quoi déplacer un point de la source pareil."""
    k, q = cfg.get("slim", 1.0), cfg.get("squash", 1.0)
    x0, y0, x1, y1 = bbox(keep)
    cut = y0 + (y1 - y0) * cfg["anchors"][direction]["head"] / cfg["height"]
    cx = (x0 + x1) / 2
    move = lambda x, y: (cx + (x - cx) * k, y1 - (y1 - y) * q) if y >= cut else (x, y + (y1 - cut) * (1 - q))
    if k >= 1 and q >= 1:
        return a, keep, move
    h, w = keep.shape
    xs = np.clip(np.round(cx + (np.arange(w) - cx) / k).astype(int), 0, w - 1)
    # Chaque rangée d'arrivée lit sa rangée de départ : le corps se tasse vers les
    # pieds, la tête descend d'autant sans changer.
    ys = np.arange(h, dtype=float)
    body = y1 - (y1 - ys) / q
    head = ys - (y1 - cut) * (1 - q)
    src_y = np.where(ys >= y1 - (y1 - cut) * q, body, head)
    inside = (src_y >= 0) & (src_y < h)
    src_y = np.clip(np.round(src_y).astype(int), 0, h - 1)
    below = src_y >= cut
    out_a = np.where(below[:, None, None], a[src_y][:, xs], a[src_y])
    out_k = np.where(below[:, None], keep[src_y][:, xs], keep[src_y]) & inside[:, None]
    return out_a, out_k, move


def reshape_point(cfg, direction, x, y):
    """Le même changement, en coordonnées de case : pour les repères et les retouches,
    écrits sur la silhouette d'origine."""
    F, feet = cfg["frame"], cfg["feet"]
    k, q = cfg.get("slim", 1.0), cfg.get("squash", 1.0)
    cut = cfg["anchors"][direction]["head"]
    if y >= cut:
        return F / 2 + (x - F / 2) * k, feet - (feet - y) * q
    return x, y + (feet - cut) * (1 - q)


def static_cells(cfg, cid):
    """Les trois poses validées, une case chacune, pieds sur `feet`, retouches posées."""
    F, feet = cfg["frame"], cfg["feet"]
    cells = []
    for d in DIRS:
        a = np.asarray(Image.open(os.path.join(CHARS, cid, d + ".png")).convert("RGB")).astype(np.float32) / 255
        keep = silhouette(a)
        # L'échelle se prend avant de tasser le corps, sinon elle le rallongerait.
        scale = cfg["height"] / (bbox(keep)[3] - bbox(keep)[1])
        a, keep, _ = slimmed(cfg, a, keep, d)
        o = framed(recolored(cfg, reduce(a, keep, scale), d))
        cell = np.zeros((F, F, 4), "uint8")
        place(cell, o, F // 2 - o.shape[1] // 2, feet + 2 - o.shape[0])
        for p in cfg.get("patches", {}).get(d, []):
            x, y = reshape_point(cfg, d, *p["at"])
            patch(cell, dict(p, at=[round(x), round(y)]), cfg["colors"])
        cells.append(cell)
    return cells


# --------------------------------------------------------------------------
# Animations générées : un cycle entier en une seule image
# --------------------------------------------------------------------------
ANIMS = {"walk": 4, "attack": 3}
STRIP = (1536, 640)
MOTION = {"walk": "walking, walk cycle", "attack": "casting a spell, attack animation"}
ANIM_PROMPT = ("pixel art, game sprite sheet, {motion}, {n} frames of the same character in a row, "
               "{view}, {who}, full body, evenly spaced, identical character")
ANIM_NEG = ("text, watermark, blurry, photo, 3d render, realistic proportions, gradient background, "
            "scenery, weapon, wand, staff, broom, different characters, frame, border, grid lines")
# Le bras qui tient l'arme en jeu (épaule, coude, poignet) : 5, 6, 7 dans les trois
# vues, celui qui passe du côté de `anchors.hand`. À la marche il reste le long du
# corps, sinon l'arme, posée à son poignet, battrait comme un fléau.
ARMED = (5, 6, 7)
# Profil : genou et cheville de chaque jambe, en quatre temps.
SIDE_STRIDE = [((560, 800), (620, 905), (450, 795), (400, 900)),
               ((530, 770), (500, 850), (500, 800), (490, 910)),
               ((450, 795), (400, 900), (560, 800), (620, 905)),
               ((500, 800), (490, 910), (530, 770), (500, 850))]
# Coude et poignet armés : armé, lancé, retour. De dos, le miroir de face.
ATTACK_ARM = {"down": [((640, 450), (610, 380)), ((680, 515), (760, 510)), ((650, 580), (680, 640))],
              "side": [((470, 450), (440, 380)), ((590, 500), (680, 490)), ((560, 580), (600, 630))]}


def anim_pose(kind, direction, k):
    kp = dict(POSES[direction])
    if kind == "walk":
        if direction == "side":
            kp[9], kp[10], kp[12], kp[13] = SIDE_STRIDE[k]
            swing = (45, 0, -45, 0)[k]
            kp[3], kp[4] = (495 - swing // 2, 605), (505 - swing, 685)
        else:
            lift = ((45, -25), (15, 0), (-25, 45), (0, 15))[k]
            for knee, ankle, dy in ((9, 10, lift[0]), (12, 13, lift[1])):
                kp[knee] = (kp[knee][0], kp[knee][1] - dy * 0.4)
                kp[ankle] = (kp[ankle][0], kp[ankle][1] - dy)
            kp[4] = (kp[4][0], kp[4][1] + (-25, 0, 25, 0)[k])
    else:
        arm = ATTACK_ARM["down" if direction == "up" else direction][k]
        if direction == "up":
            arm = tuple((1024 - x, y) for x, y in arm)
        kp[ARMED[1]], kp[ARMED[2]] = arm
    return kp


def columns(n):
    return STRIP[0] // n


def strip_skeleton(kind, direction):
    n = ANIMS[kind]; cw = columns(n)
    im = Image.new("RGB", STRIP)
    for k in range(n):
        one = skeleton(anim_pose(kind, direction, k)).resize((round(1024 * 0.6), STRIP[1]))
        im.paste(one, (k * cw + (cw - one.width) // 2, 0), one.convert("L").point(lambda v: 255 if v else 0))
    return im


def strip_to_column(kind, x, y, k):
    """Un point du squelette (repère 1024) dans la colonne k du cycle."""
    cw = columns(ANIMS[kind])
    return (cw - round(1024 * 0.6)) / 2 + x * 0.6, y * STRIP[1] / 1024


def anim_graph(cfg, cid, kind, direction, seed):
    ref = upload(Image.open(os.path.join(CHARS, cid, direction + ".png")).convert("RGB"), f"hns_{cid}_{direction}.png")
    wf = view_graph(cfg, ref, direction, seed)
    wf["pos"]["inputs"]["text"] = ANIM_PROMPT.format(
        motion=MOTION[kind], n=ANIMS[kind], view=VIEW_WORDS[direction], who=cfg["anim"]["who"]) + TAIL
    wf["neg"]["inputs"]["text"] = ANIM_NEG
    wf["pimg"]["inputs"]["image"] = upload(strip_skeleton(kind, direction), f"hns_{kind}_{direction}.png")
    wf["lat"]["inputs"].update(width=STRIP[0], height=STRIP[1])
    return wf


def palette_lock(o, ref):
    """Chaque pixel sur la couleur la plus proche de la pose validée : sans ça, la
    dominante du tirage dérive (vers le magenta, sur la sorcière)."""
    pal = np.unique(ref[ref[..., 3] > 0][:, :3].astype(int), axis=0)
    m = o[..., 3] > 0
    px = o[m][:, :3].astype(int)
    o[m, :3] = pal[((px[:, None, :] - pal[None]) ** 2).sum(2).argmin(1)]
    return o


def head_centroid(cell, rows):
    ys, xs = np.nonzero(cell[:rows, :, 3])
    return xs.mean(), ys.mean()


def head_offset(cell, ref, rows):
    """Le décalage qui pose la tête d'une image sur celle de la pose validée, par
    recouvrement des silhouettes : c'est là que les retouches (le visage) se posent."""
    a, b = cell[:rows, :, 3] > 0, ref[:rows, :, 3] > 0
    best, at = -1, (0, 0)
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            score = (np.roll(np.roll(b, dy, 0), dx, 1) & a).sum()
            if score > best:
                best, at = score, (dx, dy)
    return at


def anim_cells(cfg, path, kind, direction, ref):
    """Les images d'un cycle, prêtes pour le jeu, et la main armée de chacune."""
    F, feet, n = cfg["frame"], cfg["feet"], ANIMS[kind]
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32) / 255
    cw = columns(n)
    cols, keeps, sources, moves = [], [], [], []
    for k in range(n):
        col = a[:, k * cw:(k + 1) * cw]
        keep = silhouette(col)
        sources.append(bbox(keep))
        col, keep, move = slimmed(cfg, col, keep, direction)
        cols.append(col); keeps.append(keep); moves.append(move)
    scale = cfg["height"] / max(b[3] - b[1] for b in sources)
    # La tête dans la case, après le tassement du corps.
    rows = round(reshape_point(cfg, direction, 0, cfg["anchors"][direction]["head"])[1])
    cells, hands = [], []
    for k, (c, keep, move) in enumerate(zip(cols, keeps, moves)):
        o = framed(palette_lock(recolored(cfg, reduce(c, keep, scale), direction), ref))
        cell = np.zeros((F, F, 4), "uint8")
        # Pieds au sol, tête sur celle de la pose validée.
        cx, _ = head_centroid(o, rows - (feet + 2 - o.shape[0]))
        rx, _ = head_centroid(ref, rows)
        x0, y0 = round(rx - cx), feet + 2 - o.shape[0]
        place(cell, o, x0, y0)
        dx, dy = head_offset(cell, ref, rows)
        for p in cfg.get("patches", {}).get(direction, []):
            x, y = reshape_point(cfg, direction, *p["at"])
            patch(cell, dict(p, at=[round(x) + dx, round(y) + dy]), cfg["colors"])
        bx0, by0, _, _ = bbox(keep)
        wx, wy = move(*strip_to_column(kind, *anim_pose(kind, direction, k)[ARMED[2]], k))
        hands.append([round((wx - bx0) * scale + 1 + x0, 1), round((wy - by0) * scale + 1 + y0, 1)])
        cells.append(cell)
    return cells, hands


def anim_gif(cells_by_dir, hands_by_dir, out):
    n = len(cells_by_dir[0]); frames = []
    for i in range(n):
        c = Image.new("RGBA", (len(cells_by_dir) * 52, 52), GROUND + (255,))
        for j, (cells, hands) in enumerate(zip(cells_by_dir, hands_by_dir)):
            c.alpha_composite(Image.fromarray(cells[i]), (j * 52 + 2, 2))
            x, y = hands[i]
            c.putpixel((j * 52 + 2 + round(x), 2 + round(y)), (255, 230, 60, 255))
        frames.append(c.resize((c.width * 5, c.height * 5), Image.NEAREST).convert("RGB"))
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=140, loop=0)
    print(out)


# --------------------------------------------------------------------------
# Commandes
# --------------------------------------------------------------------------
def load(cid):
    return json.load(open(os.path.join(CHARS, cid + ".json"), encoding="utf-8"))


def sheet_of(rows, labels, out):
    T = 300
    sheet = Image.new("RGB", (T * max(len(r) for r in rows), (T + 18) * len(rows)), GROUND)
    d = ImageDraw.Draw(sheet)
    for r, (row, label) in enumerate(zip(rows, labels)):
        for c, im in enumerate(row):
            sheet.paste(im.resize((T, T), Image.LANCZOS), (c * T, r * (T + 18)))
        d.text((6, r * (T + 18) + T + 3), label, fill=(220, 210, 190))
    sheet.save(out)
    print(out)


def cmd_concept(a):
    cfg = load(a.id)
    os.makedirs(RAW, exist_ok=True)
    row = []
    for seed in cfg["concept"]["seeds"]:
        f = os.path.join(RAW, f"{a.id}_concept_{seed}.png")
        if not os.path.exists(f):
            run(workflow(cfg["concept"]["prompt"] + TAIL, seed, CONCEPT_NEG)).save(f)
        row.append(Image.open(f))
    sheet_of([row], ["graines " + " ".join(map(str, cfg["concept"]["seeds"]))],
             os.path.join(DESKTOP, f"hns-{a.id}-concepts.png"))


def cmd_views(a):
    cfg = load(a.id)
    os.makedirs(RAW, exist_ok=True)
    concept = upload(Image.open(os.path.join(CHARS, a.id, "concept.png")).convert("RGB"),
                     f"hns_{a.id}_concept.png")
    rows, labels = [], []
    for seed in cfg["views"]["seeds"]:
        row = [Image.open(os.path.join(CHARS, a.id, "concept.png"))]
        for d in DIRS:
            f = os.path.join(RAW, f"{a.id}_{d}_{seed}.png")
            if not os.path.exists(f):
                run(view_graph(cfg, concept, d, seed)).save(f)
            row.append(Image.open(f))
        rows.append(row); labels.append(f"graine {seed}")
    sheet_of(rows, labels, os.path.join(DESKTOP, f"hns-{a.id}-vues.png"))


def cmd_anim(a):
    """Tous les cycles, pour chaque graine ; un GIF par geste et par graine, les trois
    vues côte à côte, la main armée marquée d'un point jaune."""
    cfg = load(a.id)
    os.makedirs(RAW, exist_ok=True)
    refs = static_cells(cfg, a.id)
    for kind in ANIMS:
        for seed in cfg["anim"]["seeds"]:
            by_dir, hands = [], []
            for d, ref in zip(DIRS, refs):
                f = os.path.join(RAW, f"{a.id}_{kind}_{d}_{seed}.png")
                if not os.path.exists(f):
                    run(anim_graph(cfg, a.id, kind, d, seed)).save(f)
                cells, h = anim_cells(cfg, f, kind, d, ref)
                by_dir.append(cells); hands.append(h)
            anim_gif(by_dir, hands, os.path.join(DESKTOP, f"hns-{a.id}-{kind}-{seed}.gif"))


def cmd_keep(a):
    os.makedirs(os.path.join(CHARS, a.id), exist_ok=True)
    if a.what == "concept":
        shutil.copy(os.path.join(RAW, f"{a.id}_concept_{a.seed}.png"),
                    os.path.join(CHARS, a.id, "concept.png"))
    elif a.what == "views":
        for d in DIRS:
            shutil.copy(os.path.join(RAW, f"{a.id}_{d}_{a.seed}.png"), os.path.join(CHARS, a.id, d + ".png"))
    else:
        dirs = DIRS if a.direction == "all" else (a.direction,)
        for d in dirs:
            shutil.copy(os.path.join(RAW, f"{a.id}_{a.what}_{d}_{a.seed}.png"),
                        os.path.join(CHARS, a.id, f"{a.what}_{d}.png"))


def cmd_build(a):
    """Rangée 0 : les trois poses — face, profil, dos. Puis une rangée par geste et par
    vue, dans l'ordre de `ANIMS` et de `DIRS`, pour les cycles retenus."""
    cfg = load(a.id)
    F, feet = cfg["frame"], cfg["feet"]
    refs = static_cells(cfg, a.id)
    rows = [refs]
    anims = {}
    for kind, n in ANIMS.items():
        paths = [os.path.join(CHARS, a.id, f"{kind}_{d}.png") for d in DIRS]
        if not all(os.path.exists(p) for p in paths):
            continue
        anims[kind] = {"count": n, "rows": {}, "hands": {}}
        for d, p, ref in zip(DIRS, paths, refs):
            cells, hands = anim_cells(cfg, p, kind, d, ref)
            anims[kind]["rows"][d] = len(rows)
            anims[kind]["hands"][d] = hands
            rows.append(cells)
    width = max(len(r) for r in rows)
    sheet = np.zeros((F * len(rows), F * width, 4), "uint8")
    for r, cells in enumerate(rows):
        for c, cell in enumerate(cells):
            sheet[r * F:(r + 1) * F, c * F:(c + 1) * F] = cell
    out = os.path.join(PROJ, "art", "characters")
    os.makedirs(out, exist_ok=True)
    Image.fromarray(sheet).save(os.path.join(out, a.id + ".png"))
    views = {}
    for d, v in cfg["anchors"].items():
        hx, hy = reshape_point(cfg, d, *v["hand"])
        views[d] = dict(v, hand=[round(hx, 1), round(hy, 1)],
                        **{r: round(reshape_point(cfg, d, 0, v[r])[1]) for r in ("head", "waist", "legs")})
    meta = {"frame": F, "feet": feet, "palette": cfg["palette"], "views": views, "anims": anims}
    json.dump(meta, open(os.path.join(out, a.id + ".json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    # L'aperçu : la planche entière à côté du guerrier en grilles, agrandie.
    warrior = Image.open(os.path.join(PROJ, "art", "generated", "player_v0.png")).convert("RGBA").crop((0, 0, 32, 32))
    prev = Image.new("RGBA", (40 + sheet.shape[1] + 8, sheet.shape[0] + 8), GROUND + (255,))
    prev.alpha_composite(warrior, (4, 4 + feet - 27))
    prev.alpha_composite(Image.fromarray(sheet), (40, 4))
    path = os.path.join(DESKTOP, f"hns-{a.id}-planche.png")
    prev.resize((prev.width * 4, prev.height * 4), Image.NEAREST).save(path)
    print(path)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("concept", "views", "anim", "build"):
        sub.add_parser(name).add_argument("id")
    k = sub.add_parser("keep"); k.add_argument("id")
    k.add_argument("what", choices=["concept", "views", *ANIMS])
    k.add_argument("rest", nargs="+", help="<graine>, ou <vue|all> <graine> pour un geste")
    a = p.parse_args()
    if a.cmd == "keep":
        a.direction, a.seed = (None, int(a.rest[0])) if len(a.rest) == 1 else (a.rest[0], int(a.rest[1]))
    {"concept": cmd_concept, "views": cmd_views, "anim": cmd_anim, "keep": cmd_keep, "build": cmd_build}[a.cmd](a)


if __name__ == "__main__":
    main()
