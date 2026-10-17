# Exporte un personnage gréé pour le jeu en 3D (jalon 54) : le corps, une action par geste
# cuite os par os, et les armes accrochées à l'os de la main, une par type.
#   blender -b -P export_glb.py -- <spec.json>
# spec : rest (.fbx Mixamo ou .blend du gréage local), gestures (gestes.json), anims
# ({nom: source}, comme `rest`, ou un geste écrit), weapons ([type]), size (la case de la
# planche, qui fixe la taille en jeu), out (.glb).
import bpy, json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import pose_anim, stage, weapons

# 1 m = 16 px de l'ancien repère : le même chiffre que le jeu.
PX_PER_M = 16

spec = json.load(open(sys.argv[sys.argv.index("--") + 1], encoding="utf-8"))
gestures = json.load(open(spec["gestures"], encoding="utf-8"))
guard = gestures["rest"]["keys"][0]
arm = stage.load(spec["rest"])
scene = bpy.context.scene
idle = arm.animation_data.action
pb = lambda s: next(b for b in arm.pose.bones if b.name.endswith(s))
hand = pb("RightHand")
scene.frame_set(int(idle.frame_range[0]))
lo, hi = stage.bounds(scene)
H = (arm.matrix_world @ pb("HeadTop_End").head).z


def borrow(path):
    """L'action d'un autre fichier de la même ossature."""
    before = set(bpy.data.objects)
    if path.endswith(".blend"):
        with bpy.data.libraries.load(path) as (src, dst):
            dst.objects = list(src.objects)
    else:
        bpy.ops.import_scene.fbx(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    action = next(o for o in new if o.type == "ARMATURE").animation_data.action
    for o in new:
        bpy.data.objects.remove(o)
    return action


def use(action):
    arm.animation_data.action = action
    arm.animation_data.action_slot = action.slots[0]


def grip(target, hold):
    """La main tourne avec l'arme : elle garde sur sa cible l'orientation qu'elle a en garde,
    et l'arme accrochée à l'os suit la lame des gestes."""
    wrist = bpy.data.objects.new("poignet", None)
    scene.collection.objects.link(wrist)
    wrist.parent = target
    wrist.rotation_mode = "QUATERNION"
    wrist.rotation_quaternion = hold
    hand.constraints.new("COPY_ROTATION").target = wrist


def bake(name, first, last):
    """Cuit la pose vue (contraintes comprises) en une action d'os."""
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.nla.bake(frame_start=first, frame_end=last, only_selected=False, visual_keying=True,
                     clear_constraints=True, use_current_action=False, bake_types={"POSE"})
    bpy.ops.object.mode_set(mode="OBJECT")
    action = arm.animation_data.action
    action.name = name
    arm.animation_data.action = None
    return action


def quaternion(m):
    return m.to_3x3().normalized().to_quaternion()


def guard_target():
    return weapons.carry(None, arm, guard["hand"], weapons.local(guard["blade"]), H)


# La garde du repos fixe la prise : l'orientation de la main sur la cible, et l'arme sur l'os.
target = guard_target()
bpy.context.view_layer.update()
hold = quaternion(target.matrix_world).inverted() @ quaternion(arm.matrix_world @ hand.matrix)
for kind in spec["weapons"]:
    root = weapons.build(kind, H, 1.0)
    root.name = "weapon_" + kind
    root.parent, root.parent_type, root.parent_bone = arm, "BONE", hand.name
    bpy.context.view_layer.update()
    root.matrix_world = target.matrix_world.copy()
forearm = pb("RightForeArm")
forearm.constraints.remove(forearm.constraints[-1])
bpy.data.objects.remove(target)

# Un geste écrit dure une seconde : l'impact se lit en secondes, le jeu règle la vitesse.
fps = scene.render.fps
impacts, baked = {}, []
for name, source in [("rest", idle)] + list(spec["anims"].items()):
    extra = set(bpy.data.objects)
    if isinstance(source, str) and source in gestures:
        use(idle)
        hand_t, _ = pose_anim.play(arm, gestures[source]["keys"], "none", fps)
        grip(hand_t, hold)
        first, last = 1, 1 + fps
        if "impact" in gestures[source]:
            impacts[name] = gestures[source]["impact"]
    else:
        action = source if name == "rest" else borrow(source)
        use(action)
        first, last = int(action.frame_range[0]), int(action.frame_range[1])
        scene.frame_set(first)
        grip(guard_target(), hold)
    baked.append(bake(name, first, last))
    for o in set(bpy.data.objects) - extra:
        bpy.data.objects.remove(o)

# Une animation par piste NLA à l'export. Posées à la fin : `pose_anim.play` vide l'`animation_data`.
for action in baked:
    track = arm.animation_data.nla_tracks.new()
    track.name = action.name
    track.strips.new(action.name, int(action.frame_range[0]), action)

# À la taille du jeu, les pieds sur le sol.
s = spec["size"] / stage.FRAMING / PX_PER_M / (hi.z - lo.z)
arm.scale *= s
arm.location.z -= lo.z * s
# `prop` ne sert qu'au cadrage des planches (`stage.bounds`).
for o in arm.children_recursive:
    o.pop("prop", None)
arm["impacts"] = impacts
bpy.ops.object.select_all(action="DESELECT")
for o in [arm] + list(arm.children_recursive):
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=spec["out"], export_format="GLB", use_selection=True,
                          export_animation_mode="NLA_TRACKS", export_anim_slide_to_zero=True,
                          export_extras=True)
print("EXPORT", spec["out"], round(hi.z - lo.z, 3), "->", round((hi.z - lo.z) * s, 3), "m")
