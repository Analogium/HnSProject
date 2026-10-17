# Joue un geste écrit en poses-clés (gestes.json) sur un personnage gréé, arme en main,
# et le rend comme render_anim.py.
#   blender -b -P pose_anim.py -- <perso.fbx> <gestes.json> <geste> <dossier> <nom> <images> [cle=valeur…]
# On n'écrit pas les rotations d'os : on pose la main et la direction de la lame, la
# cinématique inverse plie le bras ; le buste tourne et s'incline, les hanches fléchissent,
# les pieds restent au sol.
import bpy, json, math, os, sys
from mathutils import Euler, Matrix, Vector
sys.path.insert(0, os.path.dirname(__file__))
import stage, weapons

argv = sys.argv[sys.argv.index("--") + 1:]
fbx, gfile, gname, out, name, count = argv[0], argv[1], argv[2], argv[3], argv[4], int(argv[5])
opt = stage.options(argv[6:])
arm = stage.load(fbx)
scene = bpy.context.scene
scene.frame_set(1)
# La base est la première image de l'animation fournie (le repos), pas la pose de liaison
# du fichier : vidée, l'animation laisse les os où ils sont ; on n'y ajoute que le geste.
arm.animation_data_clear()
bpy.context.view_layer.update()

pb = lambda s: next(b for b in arm.pose.bones if b.name.endswith(s))
RIGHT, FORWARD, UP = Vector((-1, 0, 0)), Vector((0, -1, 0)), Vector((0, 0, 1))
H = (arm.matrix_world @ pb("HeadTop_End").head).z
shoulder = arm.matrix_world @ pb("RightArm").head
lshoulder = arm.matrix_world @ pb("LeftArm").head


def place(v, origin):
    return origin + (RIGHT * v[0] + FORWARD * v[1] + UP * v[2]) * H


def empty(label, at=None):
    e = bpy.data.objects.new(label, None)
    scene.collection.objects.link(e)
    if at is not None:
        e.location = at
    return e


def ik(bone, target):
    c = pb(bone).constraints.new("IK")
    c.target, c.chain_count = target, 2
    return c


hand_t = empty("main")
hand_t.rotation_mode = "QUATERNION"
L = H
# `weapon` : le type d'arme du jeu (sword, dagger, mace, wand, runeblade, flute), « none » pour le corps seul.
if opt.get("weapon", "sword") != "none":
    weapons.build(opt.get("weapon", "sword"), L).parent = hand_t

lhand_t = empty("main_gauche")
ik("RightForeArm", hand_t)
ik("LeftForeArm", lhand_t)
feet = {}
for side in ("Left", "Right"):
    rest_at = arm.matrix_world @ pb(side + "Foot").head
    feet[side] = (empty("pied_" + side, rest_at), rest_at.copy())
    ik(side + "Leg", feet[side][0])
pivot = arm.matrix_world @ pb("Spine").head


keys = json.load(open(gfile, encoding="utf-8"))[gname]["keys"]
spine = [pb("Spine"), pb("Spine1"), pb("Spine2")]
rest_rot = {b.name: b.rotation_quaternion.copy() for b in spine}
base = arm.location.copy()
for k in keys:
    f = 1 + round(k["t"] * 100)
    # Les épaules suivent le corps : déplacé (pas, flexion) et tourné (torsion).
    body = (FORWARD * k.get("forward", 0) + UP * k.get("crouch", 0)) * H
    turn_z = Matrix.Rotation(math.radians(k.get("twist", 0)), 3, "Z")
    moved = lambda p: pivot + turn_z @ (p - pivot) + body
    hand_t.location = place(k["hand"], moved(shoulder))
    hand_t.rotation_quaternion = weapons.orient(weapons.local(k["blade"]))
    # `lhand` : la main gauche, ou "grip" pour tenir l'arme à deux mains.
    lh = k.get("lhand", [0.02, 0.06, -0.23])
    lhand_t.location = hand_t.location.copy() if lh == "grip" else place(lh, moved(lshoulder))
    for o, path in ((hand_t, "location"), (hand_t, "rotation_quaternion"), (lhand_t, "location")):
        o.keyframe_insert(path, frame=f)
    for side, key in (("Left", "lfoot"), ("Right", "rfoot")):
        target, rest_at = feet[side]
        o = k.get(key, [0, 0, 0])
        target.location = rest_at + (RIGHT * o[0] + FORWARD * o[1] + UP * o[2]) * H
        target.keyframe_insert("location", frame=f)
    # Os du buste : Y local vertical, X local vers la gauche du personnage (repère Mixamo).
    turn = Euler((math.radians(k.get("lean", 0)) / 3, math.radians(k.get("twist", 0)) / 3, 0)).to_quaternion()
    for b in spine:
        b.rotation_quaternion = rest_rot[b.name] @ turn
        b.keyframe_insert("rotation_quaternion", frame=f)
    # Fléchir, se fendre : tout le corps bouge, les pieds restent sur leurs cibles.
    arm.location = base + (FORWARD * k.get("forward", 0) + UP * k.get("crouch", 0)) * H
    arm.keyframe_insert("location", frame=f)

st = stage.Stage(arm, opt)
# Sur [0, 1[ : la dernière clé est le repos, que le jeu rejoue déjà après le geste.
frames = [1 + round(i * 100 / count) for i in range(count)]
tip = lambda: {"grip": hand_t.matrix_world.translation.copy(), "tip": hand_t.matrix_world @ Vector((0, 0.34 * L, 0))}
st.render(out, name, frames, opt["views"].split(",") if "views" in opt else None, tip)
