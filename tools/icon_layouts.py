"""Les calques des icones composees a la main (jalon 41).

SDXL de base ignore la composition : « une flamme, un flocon et un eclair en
triangle » sortait sans flocon ni eclair, la poupee de chiffon en fillette. Le
calque pose donc chaque symbole a sa place, en grandes formes plates eclairees en
haut a gauche (`PixelCanvas.LIGHT`), et SDXL ne fait que l'habiller en pixel art
(img2img, `denoise` de l'entree dans skill_icons.json). Tout se joue dans les 70 %
du centre que garde la reduction.
"""
import math
from PIL import Image, ImageDraw

SIDE = 1024
BG = (52, 30, 74)  # le violet sombre de la sorciere


def _orb(d, cx, cy, r, base, light, core):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=base)
    d.ellipse([cx - r * 0.75, cy - r * 0.8, cx + r * 0.35, cy + r * 0.3], fill=light)
    d.ellipse([cx - r * 0.5, cy - r * 0.55, cx - r * 0.1, cy - r * 0.15], fill=core)


def trinity(d, c):
    """Une flamme, un flocon, un eclair, aux sommets d'un triangle."""
    pts = [(c, 330), (345, 650), (679, 650)]
    d.polygon(pts, outline=(150, 100, 210), width=26)
    x, y = pts[0]
    d.polygon([(x, y - 150), (x + 105, y + 10), (x + 70, y + 100), (x - 70, y + 100), (x - 105, y + 10)],
              fill=(225, 75, 25))
    d.polygon([(x, y - 60), (x + 50, y + 40), (x, y + 95), (x - 50, y + 40)], fill=(255, 200, 70))
    x, y = pts[1]
    for k in range(3):
        a = k * math.pi / 3 + math.pi / 2
        dx, dy = math.cos(a) * 135, math.sin(a) * 135
        d.line([(x - dx, y - dy), (x + dx, y + dy)], fill=(120, 190, 250), width=44)
    d.ellipse([x - 45, y - 45, x + 45, y + 45], fill=(235, 248, 255))
    x, y = pts[2]
    d.polygon([(x + 30, y - 150), (x - 90, y + 20), (x - 5, y + 20), (x - 45, y + 150),
               (x + 100, y - 35), (x + 15, y - 35), (x + 75, y - 150)], fill=(255, 220, 60))


def rag_doll(d, c):
    """Jute, yeux-boutons, bouche cousue, une epingle en travers."""
    tan, shade, dark = (195, 150, 90), (150, 105, 60), (30, 20, 20)
    d.rounded_rectangle([c - 120, 470, c + 120, 790], 50, fill=shade)
    d.rounded_rectangle([c - 110, 460, c + 100, 770], 50, fill=tan)
    d.rounded_rectangle([c - 250, 500, c - 100, 590], 40, fill=tan)
    d.rounded_rectangle([c + 100, 500, c + 250, 590], 40, fill=shade)
    d.rounded_rectangle([c - 115, 760, c - 25, 900], 35, fill=tan)
    d.rounded_rectangle([c + 25, 760, c + 115, 900], 35, fill=shade)
    d.ellipse([c - 200, 130, c + 200, 500], fill=shade)
    d.ellipse([c - 200, 120, c + 180, 480], fill=tan)
    for ex in (c - 90, c + 90):
        d.ellipse([ex - 62, 230, ex + 62, 354], fill=(235, 230, 220))
        d.ellipse([ex - 46, 246, ex + 46, 338], fill=dark)
    for k in range(5):
        x = c - 100 + k * 50
        d.line([(x - 18, 395), (x + 18, 430)], fill=dark, width=14)
        d.line([(x + 18, 395), (x - 18, 430)], fill=dark, width=14)
    d.line([(c - 60, 610), (c + 330, 330)], fill=(225, 225, 235), width=22)
    d.ellipse([c + 290, 280, c + 380, 370], fill=(230, 50, 60))


def catalysis(d, c):
    """Un orbe de feu et un orbe de glace qui se heurtent dans un eclat blanc."""
    _orb(d, c - 170, c + 40, 210, (200, 60, 30), (245, 120, 50), (255, 210, 120))
    _orb(d, c + 170, c + 40, 210, (50, 120, 210), (110, 180, 250), (220, 245, 255))
    for k in range(8):
        a = k * math.pi / 4 + math.pi / 8
        r = 300 if k % 2 == 0 else 200
        d.polygon([(c, c + 40),
                   (c + math.cos(a - 0.12) * r * 0.4, c + 40 + math.sin(a - 0.12) * r * 0.4),
                   (c + math.cos(a) * r, c + 40 + math.sin(a) * r),
                   (c + math.cos(a + 0.12) * r * 0.4, c + 40 + math.sin(a + 0.12) * r * 0.4)],
                  fill=(255, 250, 225))
    d.ellipse([c - 95, c - 55, c + 95, c + 135], fill=(255, 255, 255))


def brazier(d, c):
    """Une coupe de fer sur trepied, sa flamme, et la boule qu'elle crache (jalon 42)."""
    iron, iron_light, iron_dark = (95, 85, 90), (150, 140, 140), (45, 38, 44)
    for x0, x1 in ((c - 40, c - 220), (c, c), (c + 40, c + 220)):
        d.line([(x0, 600), (x1, 900)], fill=iron_dark, width=34)
    d.pieslice([c - 270, 380, c + 270, 700], 0, 180, fill=iron)
    d.pieslice([c - 250, 400, c + 150, 660], 90, 180, fill=iron_light)
    d.rectangle([c - 290, 520, c + 290, 560], fill=iron_light)
    d.polygon([(c - 230, 530), (c - 150, 240), (c - 60, 380), (c, 120), (c + 70, 360),
               (c + 160, 260), (c + 230, 530)], fill=(225, 75, 25))
    d.polygon([(c - 120, 530), (c - 40, 330), (c, 260), (c + 50, 340), (c + 120, 530)],
              fill=(255, 190, 60))
    d.polygon([(c - 40, 530), (c, 400), (c + 40, 530)], fill=(255, 245, 200))
    d.line([(c + 130, 330), (c + 260, 260)], fill=(200, 70, 25), width=36)
    d.ellipse([c + 220, 190, c + 330, 300], fill=(245, 120, 40))
    d.ellipse([c + 243, 208, c + 298, 263], fill=(255, 225, 140))


LAYOUTS = {"trinity": trinity, "rag_doll": rag_doll, "catalysis": catalysis, "brazier": brazier}
## Le fond de chaque calque : le violet de la sorciere, le cramoisi du feu.
BACKGROUNDS = {"brazier": (70, 18, 24)}


def layout(name):
    im = Image.new("RGB", (SIDE, SIDE), BACKGROUNDS.get(name, BG))
    LAYOUTS[name](ImageDraw.Draw(im), SIDE // 2)
    return im
