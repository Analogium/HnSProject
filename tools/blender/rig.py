# Grée un modèle sans Mixamo, dont l'auto-rig refuse un personnage en cape (les bras ne
# sont pas détachés du buste). On reprend le squelette Mixamo d'un personnage déjà gréé, et
# ses animations : ses articulations sont posées sur les points du squelette OpenPose dont
# l'image source est tirée, recalés sur le modèle (`align.py`).
#   blender -b -P rig.py -- <modele.glb> <face.png> <pose.json> <repos.fbx> <marche.fbx> <dossier>
# Écrit <dossier>/rest.blend et walk.blend : le personnage gréé, au repos ou en marche.
import bmesh, bpy, json, math, os, sys
import numpy as np
from mathutils import Matrix, Quaternion, Vector
sys.path.insert(0, os.path.dirname(__file__))
from align import Frame, mesh_points
import stage

argv = sys.argv[sys.argv.index("--") + 1:]
glb, front, pose_json, rest_fbx, walk_fbx, out = argv


def import_rig(fbx):
    """Le squelette et l'animation d'un .fbx Mixamo ; son corps est jeté."""
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.fbx(filepath=fbx)
    new = [o for o in bpy.context.scene.objects if o not in before]
    arm = next(o for o in new if o.type == "ARMATURE")
    for o in new:
        if o is not arm:
            bpy.data.objects.remove(o)
    return arm


bpy.ops.wm.read_factory_settings(use_empty=True)
arm = import_rig(rest_fbx)
bpy.ops.import_scene.gltf(filepath=glb)
body = next(o for o in bpy.context.scene.objects if o.type == "MESH")
co = mesh_points(body)
H = co[:, 2].max() - co[:, 2].min()
fr = Frame(front, co, -1)
kp = {int(k): v for k, v in json.load(open(pose_json)).items()}
# Os Mixamo -> point OpenPose (2 : épaule droite, 3 : coude droit… ; 1 : le cou).
JOINTS = {"RightArm": 2, "RightForeArm": 3, "RightHand": 4, "LeftArm": 5, "LeftForeArm": 6, "LeftHand": 7,
          "RightUpLeg": 8, "RightLeg": 9, "RightFoot": 10, "LeftUpLeg": 11, "LeftLeg": 12, "LeftFoot": 13,
          "Neck": 1}
named = lambda bones, s: next(b for b in bones if b.name.endswith(":" + s))
STEP = 0.7          # l'amplitude des jambes dans la marche d'emprunt
FEET_BACK = 0.04    # au-delà du personnage de référence, en hauteurs tête-pieds (+ : en arrière)

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
M = arm.matrix_world
Mi = M.inverted()
heads = {b.name: np.array(M @ b.head) for b in eb}
tails = {b.name: np.array(M @ b.tail) for b in eb}
P = np.array([heads[named(eb, j).name] for j in JOINTS])
T = np.array([fr.to_model(*kp[i]) for i in JOINTS.values()])           # (x, z)
# Une similitude d'abord (échelle, place), dans le plan de face ; la profondeur suit l'échelle,
# centrée sur le buste du modèle.
Pxz = P[:, [0, 2]]
k = np.sqrt(((T - T.mean(0)) ** 2).sum() / ((Pxz - Pxz.mean(0)) ** 2).sum())
hip_z, neck_z = fr.to_model(*kp[8])[1], fr.to_model(*kp[1])[1]
y_mid = np.median(co[(co[:, 2] > hip_z) & (co[:, 2] < neck_z), 1])


def similar(p):
    q = p.copy()
    q[0], q[2] = (np.array([p[0], p[2]]) - Pxz.mean(0)) * k + T.mean(0)
    q[1] = (p[1] - P[:, 1].mean()) * k + y_mid
    return q


# Puis chaque articulation sur son point ; les autres os suivent par interpolation.
Ps = np.array([similar(p) for p in P])
resid = T - Ps[:, [0, 2]]


def placed(p):
    q = similar(p)
    d2 = ((Ps[:, [0, 2]] - q[[0, 2]]) ** 2).sum(1)
    w = 1 / (d2 + (0.002 * H) ** 2) ** 2
    q[[0, 2]] += (w[:, None] * resid).sum(0) / w.sum()
    return q


# Chaque os garde son roulis : presque vertical, une cuisse déplacée tournait de 80° sur
# elle-même, et la marche écartait les jambes.
# Les axes se relèvent tous avant de rien bouger : un os chaîné bouge avec son parent.
new_heads = {n: placed(p) for n, p in heads.items()}
new_tails = {n: placed(p) for n, p in tails.items()}
# Le haut du crâne n'a pas de point OpenPose : interpolé, il gardait la tête chibi du squelette
# d'emprunt et dépassait le Vive lame adulte d'un tiers de sa taille. Gestes et armes se
# mesurent à lui : le bras se tendait à fond, l'épée était trop grande (jalon 54).
head, top = named(eb, "Head").name, named(eb, "HeadTop_End").name
new_heads[top] = new_tails[head] = np.array([new_heads[head][0], new_heads[head][1], co[:, 2].max()])
new_tails[top] = new_heads[top] + np.array([0.0, 0.0, 0.05 * H])
# La profondeur des jambes se lit sur le modèle : le devant de la jambe, plus son rayon. Celle
# du squelette d'emprunt laissait les chevilles 7 cm derrière les bottes, et la sorcière
# marchait pieds en avant, le dos en arrière. Ce qui pend sous un os le suit.
LEG_RADIUS = 0.035                                  # en hauteurs de modèle
for side in ("Left", "Right"):
    chain = [named(eb, side + n).name for n in ("UpLeg", "Leg", "Foot")]
    shift = []
    for n in chain:
        h = new_heads[n]
        near = co[(np.abs(co[:, 0] - h[0]) < 0.03 * H) & (np.abs(co[:, 2] - h[2]) < 0.03 * H)]
        shift.append(near[:, 1].min() + LEG_RADIUS * H - h[1] if len(near) else 0.0)
    for b in eb:
        up = [i for i, n in enumerate(chain) if b.name == n or eb[n] in b.parent_recursive]
        if up:
            i = max(up)
            new_heads[b.name][1] += shift[i]
            new_tails[b.name][1] += shift[min(i + 1, 2)] if b.name in chain else shift[i]
z_axes = {b.name: b.z_axis.copy() for b in eb}
for b in eb:
    b.head, b.tail = Mi @ Vector(new_heads[b.name]), Mi @ Vector(new_tails[b.name])
for b in eb:
    b.align_roll(z_axes[b.name])


def hand_frame(side):
    """Le poignet, l'axe de la main (du coude vers les doigts), la ligne des jointures, la paume
    et la longueur de la main, lue sur le maillage. En pose A, bras à 45°, les doigts s'étalent
    dans le plan de face : la ligne des jointures descend vers le dedans, le pouce de ce côté, la
    paume tournée vers l'arrière (mesuré sur le Vive lame de TRELLIS.2, jalon 54)."""
    wrist = new_heads[named(eb, side + "Hand").name]
    d = wrist - new_heads[named(eb, side + "ForeArm").name]
    d /= np.linalg.norm(d)
    knuckles = np.array([d[2], 0.0, -d[0]])
    knuckles = knuckles if knuckles[2] < 0 else -knuckles
    knuckles -= knuckles.dot(d) * d
    knuckles /= np.linalg.norm(knuckles)
    # Main droite : paume = pouce × doigts ; la gauche en miroir.
    palm = np.cross(knuckles, d) if side == "Right" else np.cross(d, knuckles)
    s = (co - wrist) @ d
    radial = np.linalg.norm(co - wrist - s[:, None] * d, axis=1)
    near = (s > 0) & (s < HAND_REACH * H) & (radial < HAND_RADIUS * H)
    return wrist, d, knuckles, palm, near, s, np.percentile(s[near], 99)


# Les mains sortent ouvertes, doigts écartés, sans os à eux : repliées une fois dans le maillage
# vers la paume, au-delà des jointures, elles deviennent des poings. Un os de prise, sans poids,
# marque le creux du poing : +Y le long du pouce (l'axe de la lame), +Z vers la paume.
HAND_REACH, HAND_RADIUS = 0.15, 0.08   # en hauteurs de modèle
KNUCKLES = 0.45                        # part de la main avant les doigts
CURL = math.radians(120)
prefix = named(eb, "Hips").name.removesuffix("Hips")
fists = {}
for side in ("Left", "Right"):
    wrist, d, thumb, palm, near, s, length = hand_frame(side)
    knuckle = KNUCKLES * length
    grip = wrist + d * 0.9 * knuckle + palm * 0.3 * (length - knuckle)
    bone = eb.new(prefix + side + "HandGrip")
    bone.head, bone.tail = Mi @ Vector(grip), Mi @ Vector(grip + thumb * 0.05 * H)
    bone.parent, bone.use_deform = eb[named(eb, side + "Hand").name], False
    bone.align_roll(Mi.to_3x3() @ Vector(palm))
    fingers = near & (s > knuckle)
    fists[side] = (wrist + d * knuckle, np.cross(d, palm), fingers, (s - knuckle) / (length - knuckle))
    print("poing", side, int(fingers.sum()), "sommets repliés, main", round(length / H, 3))
bpy.ops.object.mode_set(mode="OBJECT")
for pivot, axis, fingers, along in fists.values():
    for i in np.nonzero(fingers)[0]:
        turn = Matrix.Rotation(CURL * min(float(along[i]), 1.0) ** 0.7, 3, Vector(axis))
        co[i] = pivot + np.array(turn @ Vector(co[i] - pivot))
local = np.c_[co, np.ones(len(co))] @ np.array(body.matrix_world.inverted()).T
body.data.vertices.foreach_set("co", local[:, :3].astype(np.float32).ravel())
body.data.update()

# Les poids : par distance aux os du corps (pas aux doigts), deux os au plus par sommet.
# Ce qui est loin de tout membre — la cape, son ourlet — ne suit que le buste : par la
# seule distance, l'ourlet suivait la jambe d'arrière et partait à l'horizontale.
# Ce qui est au-dessus du cou suit la tête : le bord du chapeau descend au niveau des
# épaules, et les bras l'auraient emporté.
TORSO = ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "LeftShoulder", "RightShoulder"]
MAIN = TORSO + [s + p for s in ("Left", "Right") for p in ("Arm", "ForeArm", "Hand", "UpLeg", "Leg", "Foot", "ToeBase")]
# D'un membre à la cape, en hauteurs de modèle. Le haut d'une botte est large : à la mesure
# d'un bras, il suivait à moitié le bassin, et la botte s'étirait à chaque pas. Les doigts
# écartés d'une main adulte aussi (jalon 54) : ils restaient au bassin, à l'horizontale.
LIMB_NEAR = {"Leg": 0.07, "Foot": 0.07, "ToeBase": 0.07, "Hand": 0.12}
LIMB_FAR = {"Leg": 0.10, "Foot": 0.10, "ToeBase": 0.10, "Hand": 0.16}
bones = [named(arm.pose.bones, n) for n in MAIN]
A = np.array([np.array(arm.matrix_world @ b.bone.head_local) for b in bones])
B = np.array([np.array(arm.matrix_world @ b.bone.tail_local) for b in bones])
AB = B - A
t = np.clip((((co[:, None] - A[None]) * AB[None]).sum(-1) / (AB ** 2).sum(-1)[None]), 0, 1)
dist = np.linalg.norm(co[:, None] - (A[None] + t[..., None] * AB[None]), axis=-1)


SIDE = np.array([1 if n.startswith("Left") else -1 if n.startswith("Right") else 0 for n in MAIN])


def nearest_two(raw):
    """Jamais la gauche et la droite ensemble : un sommet entre les jambes, partagé, était
    écartelé à chaque pas."""
    raw = raw.copy()
    first = SIDE[raw.argmax(1)]
    raw[(first[:, None] * SIDE[None]) < 0] = 0
    raw[raw < np.sort(raw, 1)[:, -2:-1]] = 0
    return raw / raw.sum(1, keepdims=True)


raw = 1 / (dist + 0.02 * H) ** 4
torso_only = raw.copy()
torso_only[:, len(TORSO):] = 0
part = [n.removeprefix("Left").removeprefix("Right") for n in MAIN[len(TORSO):]]
near = np.array([LIMB_NEAR.get(n, 0.05) for n in part])
far = np.array([LIMB_FAR.get(n, 0.09) for n in part])
cape = np.clip((dist[:, len(TORSO):] / H - near) / (far - near), 0, 1).min(1)[:, None]
w = (1 - cape) * nearest_two(raw) + cape * nearest_two(torso_only)
head = co[:, 2] > A[MAIN.index("Neck"), 2]
w[head] = 0
w[head, MAIN.index("Head")] = 1
# Stable Fast 3D soude l'espace entre les bottes : une membrane qu'un pas étirait en barre.
# Partent les faces qui relient la gauche à la droite et, sous les genoux, où il n'y a que
# les bottes et l'ourlet de la cape, celles qui relient une botte au reste.
side = SIDE[w.argmax(1)]
knee_z = A[MAIN.index("LeftLeg"), 2]
bm = bmesh.new()
bm.from_mesh(body.data)
cut = [f for f in bm.faces if {side[v.index] for v in f.verts} >= {1, -1}
       or (len({side[v.index] for v in f.verts}) > 1 and min(co[v.index, 2] for v in f.verts) < knee_z)]
bmesh.ops.delete(bm, geom=cut, context="FACES_ONLY")
bm.to_mesh(body.data)
bm.free()
for j, b in enumerate(bones):
    vg = body.vertex_groups.new(name=b.name)
    for i in np.nonzero(w[:, j])[0]:
        vg.add([int(i)], float(w[i, j]), "REPLACE")
world = body.matrix_world.copy()
body.parent = arm
body.matrix_world = world
body.modifiers.new("squelette", "ARMATURE").object = arm


def feet_under_neck():
    """Les chevilles ramenées sous le cou, à la place qu'elles ont chez le personnage dont on
    reprend le squelette (de profil, en hauteurs tête-pieds), plus FEET_BACK : chaque cuisse
    pivote ce qu'il faut, le pied reste à plat, et cette pose devient le repos. Stable Fast 3D
    pose les bottes en avant, la droite plus que la gauche : la sorcière marchait pieds devant."""
    idle = arm.animation_data.action
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.location, pb.rotation_quaternion, pb.scale = (0, 0, 0), (1, 0, 0, 0), (1, 1, 1)
    bpy.context.view_layer.update()
    at = lambda n: np.array(arm.matrix_world @ named(arm.pose.bones, n).bone.head_local)
    ref = lambda n: next(v for k, v in heads.items() if k.endswith(":" + n))   # avant placement
    for side in ("Left", "Right"):
        ref_h = ref("Head")[2] - ref(side + "Foot")[2]
        goal = (ref(side + "Foot")[1] - ref("Neck")[1]) / ref_h + FEET_BACK
        hip, ankle, neck = at(side + "UpLeg"), at(side + "Foot"), at("Neck")
        vy, vz = ankle[1] - hip[1], ankle[2] - hip[2]
        r = math.hypot(vy, vz)
        want = neck[1] + goal * (at("Head")[2] - ankle[2]) - hip[1]
        # Angle depuis la verticale, positif vers +Y (l'arrière) ; +X fait pivoter vers +Y.
        angle = math.asin(max(-1.0, min(1.0, want / r))) - math.atan2(vy, -vz)
        for part, sign in (("UpLeg", 1), ("Foot", -1)):
            pb = named(arm.pose.bones, side + part)
            rest = (arm.matrix_world.to_3x3() @ pb.bone.matrix_local.to_3x3()).normalized()
            turn = Matrix.Rotation(sign * angle, 3, "X")
            pb.rotation_quaternion = (rest.inverted() @ turn @ rest).to_quaternion()
        print("cuisse", side, round(math.degrees(angle), 1), "°")
    bpy.context.view_layer.update()
    for o in (body, arm):
        o.select_set(o is body)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier="squelette")
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    body.modifiers.new("squelette", "ARMATURE").object = arm
    arm.animation_data.action = idle


feet_under_neck()


def save(action, name):
    arm.animation_data.action = action
    if hasattr(arm.animation_data, "action_slot") and action.slots:
        arm.animation_data.action_slot = action.slots[0]
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, name))


def shorter_steps(action, amount):
    """Les jambes à `amount` de leur rotation : en cape longue, le pas d'un épéiste
    étirait la cape, faite d'un seul tenant avec les bottes."""
    curves = {}
    for fc in stage.fcurves(action):
        if fc.data_path.endswith("rotation_quaternion") and any(
                ":" + side + n + '"' in fc.data_path for side in ("Left", "Right") for n in ("UpLeg", "Leg", "Foot")):
            curves.setdefault(fc.data_path, [None] * 4)[fc.array_index] = fc
    for quad in curves.values():
        for k in range(len(quad[0].keyframe_points)):
            q = Quaternion([fc.keyframe_points[k].co[1] for fc in quad])
            q = Quaternion().slerp(q, amount)
            for c, fc in enumerate(quad):
                fc.keyframe_points[k].co[1] = q[c]
        for fc in quad:
            fc.update()


save(arm.animation_data.action, "rest.blend")
walk_arm = import_rig(walk_fbx)
walk = walk_arm.animation_data.action
bpy.data.objects.remove(walk_arm)
shorter_steps(walk, STEP)
save(walk, "walk.blend")
print("gréé", len(co), "sommets,", len(cut), "faces entre les jambes retirées, échelle", round(float(k), 3))
