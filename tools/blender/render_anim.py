# Rend une animation Mixamo (.fbx « With Skin ») en images fixes, caméra du jeu.
#   blender -b -P render_anim.py -- <anim.fbx> <dossier> <nom> <images> [cle=valeur…]
# Réglages : size (512), height (hauteur de référence), elevation (35), sun (4), ambient
# (0,55), frames (indices à rendre, « 0,2 »), views (« down,side,up »), toon (1 : ombrage en
# aplats), aa (0 : pas d'anticrénelage, pour rendre directement à la taille du jeu), weapon
# (le type d'arme, tenue en garde), layer (weapon : l'arme seule, le corps en masque).
# Écrit <dossier>/<nom>_<vue>_<i>.png et <nom>.json, la place des os à chaque image.
import bpy, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import json, stage, weapons

argv = sys.argv[sys.argv.index("--") + 1:]
fbx, out, name, count = argv[0], argv[1], argv[2], int(argv[3])
opt = stage.options(argv[4:])
arm = stage.load(fbx)
action = arm.animation_data.action
f0, f1 = int(action.frame_range[0]), int(action.frame_range[1])
bpy.context.scene.frame_set(f0)
# Le bras armé en garde, la pose `rest` des gestes écrits, dans toutes les passes — celle du
# corps seul comprise, sinon l'arme de sa couche flotterait à côté de la main. Laissée au
# balancement de la marche, la lame passait sur le buste.
rest = json.load(open(os.path.join(os.path.dirname(__file__), "gestes.json"), encoding="utf-8"))["rest"]["keys"][0]
height = max(o.dimensions.z for o in bpy.context.scene.objects if o.type == "MESH")
kind = opt.get("weapon", "none")
weapons.carry(None if kind == "none" else weapons.build(kind, height), arm, rest["hand"],
              weapons.local(rest["blade"]), height)
st = stage.Stage(arm, opt)
only = [int(i) for i in opt["frames"].split(",")] if "frames" in opt else range(count)
st.render(out, name, [f0 + round(i * (f1 - f0) / count) for i in only],
          opt["views"].split(",") if "views" in opt else None)
