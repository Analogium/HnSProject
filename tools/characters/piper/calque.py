# Calque chibi du joueur de flûte de Hamelin, en aplats, calé sur le squelette de face
# de character_forge (cou 510, hanches 690, chevilles 910).
import sys
from PIL import Image, ImageDraw
W = 1024
im = Image.new("RGB", (W, W), (198, 198, 198)); d = ImageDraw.Draw(im)
O = (40, 28, 30); OW = 7
SKIN, SKIN_D = (236, 196, 160), (205, 160, 128)
HAIR = (58, 36, 26); WHITE = (238, 232, 218); WHITE_D = (196, 188, 172)
VEST, VEST_D = (124, 74, 40), (92, 52, 28); RED, RED_D = (196, 52, 40), (150, 36, 30)
GREEN, GREEN_D = (70, 128, 54), (44, 88, 36); FEATHER = (196, 160, 70)
cx = 512
def poly(pts, fill): d.polygon(pts, fill=fill, outline=O, width=OW)
def ell(box, fill): d.ellipse(box, fill=fill, outline=O, width=OW)
# Souliers verts pointus
poly([(cx-90, 905), (cx-20, 905), (cx-20, 955), (cx-150, 955), (cx-110, 935)], GREEN)
poly([(cx+20, 905), (cx+90, 905), (cx+110, 935), (cx+150, 955), (cx+20, 955)], GREEN)
# Chausses rouges
poly([(cx-78, 690), (cx-8, 690), (cx-24, 910), (cx-80, 910)], RED)
poly([(cx+8, 690), (cx+78, 690), (cx+80, 910), (cx+24, 910)], RED_D)
# Bras : manches blanches bouffantes, mains
ell((cx-178, 525, cx-82, 700), WHITE); ell((cx+82, 525, cx+178, 700), WHITE_D)
ell((cx-160, 680, cx-104, 736), SKIN); ell((cx+104, 680, cx+160, 736), SKIN_D)
# Buste : chemise blanche, gilet brun ouvert, basque
poly([(cx-100, 520), (cx+100, 520), (cx+96, 730), (cx-96, 730)], WHITE)
poly([(cx-100, 520), (cx-22, 520), (cx-30, 760), (cx-104, 760)], VEST)
poly([(cx+22, 520), (cx+100, 520), (cx+104, 760), (cx+30, 760)], VEST_D)
d.rectangle((cx-102, 680, cx+102, 708), fill=RED, outline=O, width=OW)  # ceinture rouge
ell((cx+70, 690, cx+160, 790), GREEN)  # besace
# Col
poly([(cx-40, 500), (cx+40, 500), (cx+20, 545), (cx-20, 545)], WHITE)
# Tête : cheveux, visage
ell((cx-150, 230, cx+150, 520), HAIR)
ell((cx-125, 270, cx+125, 515), SKIN)
for sx in (-1, 1):
    ell((cx + sx*55 - 18, 370, cx + sx*55 + 18, 410), (30, 24, 28))  # yeux
d.line([(cx-45, 455), (cx-8, 445), (cx+8, 445), (cx+45, 455)], fill=HAIR, width=12)  # moustache
# Chapeau tyrolien : bord, calotte pincée, ruban, plume
ell((cx-185, 255, cx+185, 315), GREEN_D)
poly([(cx-110, 285), (cx-80, 150), (cx-10, 125), (cx+70, 140), (cx+110, 285)], GREEN)
d.rectangle((cx-108, 255, cx+108, 285), fill=RED, outline=O, width=OW)
poly([(cx+80, 260), (cx+95, 250), (cx+240, 40), (cx+250, 52), (cx+110, 268)], FEATHER)
im.save(sys.argv[1])
