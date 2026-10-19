# Exporte un personnage gréé pour le jeu en 3D (jalon 54) : le corps, une action par geste
# cuite os par os, et les armes accrochées à l'os de la main, une par type.
#   blender -b -P export_glb.py -- <spec.json>
# spec : rest (.fbx Mixamo ou .blend du gréage local), gestures (gestes.json), anims
# ({nom: source}, comme `rest`, ou un geste écrit), weapons ([type]), weapon (celle par défaut),
# guard (le gréage local : garde tenue et main gauche posée), arm_space (degrés d'écart des
# bras, hors repos), walk_leg_space (de même pour les cuisses, dans la course, négatif pour
# les resserrer), elbows (part du pli des coudes ôtée, hors repos), sheathed (les gestes sans
# arme), repeat ({nom: {strikes, gap}}, le coup de la source répété à cette cadence), size (la
# case de la planche, qui fixe la taille en jeu), out (.glb), portrait (le modèle brut de
# TRELLIS.2, vide sans lui), portrait_out (.glb des vues de face) et color (son `model.glb`
# recuit, vide sans lui).
import bpy, json, os, sys
import math
from mathutils import Matrix, Quaternion, Vector
sys.path.insert(0, os.path.dirname(__file__))
import pose_anim, stage, weapons

# 1 m = 16 px de l'ancien repère : le même chiffre que le jeu.
PX_PER_M = 16
# La lame tenue (`wield`) : le levier du bras, plus ces parts de l'avant et du haut du buste —
# sans elles, la main basse du repos pointait l'épée dans le sol.
BLADE_FORWARD, BLADE_UP = 0.7, 0.3
# Un bras qui perd plus de 2 % d'allonge en une image se replie : ce n'est pas le coup (`impact`).
RECOIL = 0.98
# Ce que `wield` peut écarter la main de celle de l'animation, en degrés : sans borne, la lame
# prolongeait le levier au prix d'un poignet cassé jusqu'à 145° (choisi sur planche, jalon 54).
WRIST = 40

spec = json.load(open(sys.argv[sys.argv.index("--") + 1], encoding="utf-8"))
gestures = json.load(open(spec["gestures"], encoding="utf-8"))
guard = gestures["rest"]["keys"][0]
arm = stage.load(spec["rest"])
scene = bpy.context.scene
# La couleur recuite de `model.glb` remplace la copie que Mixamo en garde : même dépliage
# (vérifié au jalon 54), et recuire n'oblige pas à regréer.
if spec["color"]:
    before, seen = set(bpy.data.objects), set(bpy.data.images)
    bpy.ops.import_scene.gltf(filepath=spec["color"])
    baked = next(i for i in bpy.data.images if i not in seen)
    body = bpy.data.images["couleur"]
    body.pixels.foreach_set(baked.pixels[:])
    body.pack()
    for o in set(bpy.data.objects) - before:
        bpy.data.objects.remove(o)
    bpy.data.images.remove(baked)
idle = arm.animation_data.action
pb = lambda s: next(b for b in arm.pose.bones if b.name.endswith(s))
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


def guard_target():
    return weapons.carry(None, arm, guard["hand"], weapons.local(guard["blade"]), H)


def left_hand(first, last):
    """La main gauche à sa garde (`lhand`), le balancement de l'animation d'emprunt autour : la
    pose propre de celle-ci vient d'un autre squelette, et pliait le bras devant la ceinture."""
    W = arm.matrix_world
    hips, wrist = pb("Hips"), pb("LeftHand")
    frames = range(first, last + 1)
    seen = {}
    for f in frames:
        scene.frame_set(f)
        seen[f] = (W @ hips.matrix, W @ wrist.head)
    scene.frame_set(first)
    home = W @ pb("LeftArm").head + weapons.local(guard.get("lhand", pose_anim.LHAND)) * H
    home = seen[first][0].inverted() @ home
    mean = sum((m.inverted() @ p for m, p in seen.values()), Vector()) / len(seen)
    target = bpy.data.objects.new("main_gauche", None)
    scene.collection.objects.link(target)
    for f, (m, p) in seen.items():
        target.location = m @ (home + m.inverted() @ p - mean)
        target.keyframe_insert("location", frame=f)
    ik = pb("LeftForeArm").constraints.new("IK")
    ik.target, ik.chain_count = target, 2


def spread(action, limb, degrees):
    """Écarte `Left<limb>` et `Right<limb>` du buste de `degrees` (négatif : les resserre),
    autour de l'axe avant du personnage, sur toute l'animation : celles de Mixamo sont faites
    pour un acteur plus mince, et les bras du Vive lame rentraient dans son gilet — le curseur
    « Character Arm-Space » n'y suffisait pas."""
    W = arm.matrix_world.to_3x3()
    forward = (W.inverted() @ weapons.FORWARD).normalized()
    middle = (arm.matrix_world @ pb("Hips").bone.head_local).x
    curves = stage.fcurves(action)
    for side in ("Left", "Right"):
        bone = pb(side + limb)
        rest = bone.bone.matrix_local.to_3x3()
        axis = rest.inverted() @ forward
        along = lambda q: (W @ rest @ q.to_matrix() @ Vector((0, 1, 0))).x
        outward = (arm.matrix_world @ bone.bone.head_local).x - middle
        turn = Quaternion(axis, math.radians(abs(degrees)))
        if (along(turn) - along(Quaternion())) * outward < 0:
            turn = turn.inverted()
        if degrees < 0:
            turn = turn.inverted()
        path = f'pose.bones["{bone.name}"].rotation_quaternion'
        quad = sorted((c for c in curves if c.data_path == path), key=lambda c: c.array_index)
        for k in range(len(quad[0].keyframe_points)):
            q = turn @ Quaternion([c.keyframe_points[k].co[1] for c in quad])
            for c, value in zip(quad, q):
                c.keyframe_points[k].co[1] = value
        for c in quad:
            c.update()


def straighten(action, share):
    """Déplie les coudes de `share` de leur pli, sur toute l'animation : la course de Mixamo est
    un sprint, ses avant-bras montaient au menton."""
    curves = stage.fcurves(action)
    for side in ("Left", "Right"):
        path = f'pose.bones["{pb(side + "ForeArm").name}"].rotation_quaternion'
        quad = sorted((c for c in curves if c.data_path == path), key=lambda c: c.array_index)
        for k in range(len(quad[0].keyframe_points)):
            q = Quaternion([c.keyframe_points[k].co[1] for c in quad]).slerp(Quaternion(), share)
            for c, value in zip(quad, q):
                c.keyframe_points[k].co[1] = value
        for c in quad:
            c.update()


def wield(action, first, last, grip_name):
    """Oriente la main droite, image par image, pour que la lame prolonge le levier épaule →
    main, penchée vers l'avant et le haut du buste, à `WRIST` au plus de la main d'origine :
    les attaques de Mixamo sont à mains nues, et l'épée suivait un poing qui ne tient rien
    (vers le dos, le sol, à rebours du coup)."""
    use(action)
    hand, grip, spine = pb("RightHand"), arm.pose.bones[grip_name], pb("Spine2")
    to_body = arm.matrix_world.to_3x3().inverted()
    rest = spine.bone.matrix_local.to_3x3().inverted()
    forward = rest @ (to_body @ weapons.FORWARD).normalized()
    up = rest @ (to_body @ weapons.UP).normalized()
    offset = (hand.bone.matrix_local.inverted() @ grip.bone.matrix_local).to_3x3()
    palm = None
    for f in range(first, last + 1):
        scene.frame_set(f)
        body = spine.matrix.to_3x3()
        lever = (hand.head - pb("RightArm").head).normalized()
        blade = (lever + body @ forward * BLADE_FORWARD + body @ up * BLADE_UP).normalized()
        # Le plat de la lame garde celui de l'image d'avant : pas de volte d'une image à l'autre.
        if palm is None:
            palm = grip.matrix.to_3x3() @ Vector((0, 0, 1))
        palm = (palm - blade * palm.dot(blade)).normalized()
        turned = (Matrix((blade.cross(palm), blade, palm)).transposed() @ offset.inverted()).to_quaternion()
        own = hand.matrix.to_quaternion()
        bend = own.rotation_difference(turned).angle
        if bend > math.radians(WRIST):
            turned = own.slerp(turned, math.radians(WRIST) / bend)
        hand.matrix = Matrix.LocRotScale(hand.matrix.translation, turned, None)
        hand.keyframe_insert("rotation_quaternion", frame=f)
    arm.animation_data.action = None


def reach(f):
    """La main à l'image `f` (repère du monde) et l'allonge du bras armé."""
    scene.frame_set(f)
    hand, shoulder = pb("RightHand").head, pb("RightArm").head
    return arm.matrix_world @ hand, (hand - shoulder).length


def repeat(action, first, last, at, strikes, gap):
    """Le coup de `action` (à `at`, en part du geste) porté `strikes` fois, à `gap` du geste
    l'un de l'autre, la cadence du jeu : entre deux, la main revient d'où le coup est parti,
    l'animation rejouée à rebours, puis frappe à la vitesse d'origine. La Rafale est trois
    estocs ; Mixamo n'en a qu'un. Rend le nouvel impact, en part du geste."""
    use(action)
    # Du bras le plus replié avant le coup au bras le plus tendu.
    peak = cocked = first + round(at * (last - first))
    while peak < last and reach(peak + 1)[1] > reach(peak)[1]:
        peak += 1
    while cocked > first and reach(cocked - 1)[1] < reach(cocked)[1]:
        cocked -= 1
    arm.animation_data.action = None
    windup, recovery, thrust = peak - first, last - peak, peak - cocked
    step = gap * (windup + recovery) / (1 - (strikes - 1) * gap)
    # Le temps du nouveau geste → celui de la source, point par point.
    keys = [(0, first), (windup, peak)]
    for i in range(1, strikes):
        keys += [(windup + i * step - thrust, cocked), (windup + i * step, peak)]
    keys.append((keys[-1][0] + recovery, last))
    end = keys[-1][0]
    source = lambda t: next(s0 + (s1 - s0) * (t - t0) / (t1 - t0)
                            for (t0, s0), (t1, s1) in zip(keys, keys[1:]) if t <= t1)
    for c in stage.fcurves(action):
        values = [c.evaluate(source(min(t, end))) for t in range(round(end) + 1)]
        c.keyframe_points.clear()
        c.keyframe_points.add(len(values))
        for t, (point, value) in enumerate(zip(c.keyframe_points, values)):
            point.co = (first + t, value)
            point.interpolation = "LINEAR"
        c.update()
    return round(windup / end, 2)


def world_box(o):
    dg = bpy.context.evaluated_depsgraph_get()
    e = o.evaluated_get(dg)
    pts = [e.matrix_world @ v.co for v in e.data.vertices]
    return (Vector([min(p[i] for p in pts) for i in range(3)]),
            Vector([max(p[i] for p in pts) for i in range(3)]))


def portrait(raw, out):
    """Le corps des vues de face, sélection et inventaire : le modèle brut de TRELLIS.2, net,
    là où la réduction du jeu fendait le visage (jalon 54). Même forme que le corps de jeu : il
    en reprend les poids, calé sur lui, sans repasser par Mixamo. Seul le repos l'anime."""
    body, = [o for o in arm.children if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)]
    arm.data.pose_position = "REST"
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=raw)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    sharp = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    for o in new:
        if o.name in bpy.data.objects and o is not sharp:
            bpy.data.objects.remove(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    (blo, bhi), (slo, shi) = world_box(body), world_box(sharp)
    k = (bhi.z - blo.z) / (shi.z - slo.z)
    sharp.scale = (k, k, k)
    sharp.location = (blo + bhi) / 2 - (slo + shi) / 2 * k
    sharp.location.z = blo.z - slo.z * k
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    weights = sharp.modifiers.new("poids", "DATA_TRANSFER")
    weights.object, weights.use_vert_data = body, True
    weights.data_types_verts, weights.vert_mapping = {"VGROUP_WEIGHTS"}, "POLYINTERP_NEAREST"
    bpy.ops.object.datalayout_transfer(modifier=weights.name)
    bpy.ops.object.modifier_apply(modifier=weights.name)
    sharp.parent = arm
    sharp.matrix_parent_inverse = arm.matrix_world.inverted()
    sharp.modifiers.new("os", "ARMATURE").object = arm
    bpy.data.objects.remove(body)
    for track in list(arm.animation_data.nla_tracks):
        if track.name != "rest":
            arm.animation_data.nla_tracks.remove(track)
    arm.data.pose_position = "POSE"
    export(out)


def export(out):
    bpy.ops.object.select_all(action="DESELECT")
    for o in [arm] + list(arm.children_recursive):
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True,
                              export_animation_mode="NLA_TRACKS", export_anim_slide_to_zero=True,
                              export_extras=True)


def impact(first, last):
    """L'image où la main armée va le plus vite sans que le bras se replie, en part du geste :
    le coup d'une animation Mixamo, qu'aucune clé n'annonce. Le retrait de l'estoc est aussi
    vif que le coup : sans la condition, l'impact tombait sur le bras qui revient."""
    seen = [reach(f) for f in range(first, last + 1)]
    speed = [(b[0] - a[0]).length if b[1] >= a[1] * RECOIL else 0.0 for a, b in zip(seen, seen[1:])]
    return round(speed.index(max(speed)) / (last - first), 2)


# L'arme dans le poing, sur l'os de prise : la poignée au creux, la lame le long du pouce. Sans
# arme (le Roi des Rats, que Mixamo gréé sans doigts), ni prise ni main tournée.
grip_name = weapons.grip_bone(arm) if spec["weapons"] else ""
scene.frame_set(int(idle.frame_range[0]))
grip = arm.matrix_world @ arm.pose.bones[grip_name].matrix if grip_name else None
for kind in spec["weapons"]:
    root = weapons.build(kind, H, 1.0)
    root.name = "weapon_" + kind
    root.parent, root.parent_type, root.parent_bone = arm, "BONE", grip_name
    bpy.context.view_layer.update()
    root.matrix_world = Matrix.LocRotScale(grip.translation, grip.to_quaternion(), (1, 1, 1))

# Un geste écrit dure une seconde : l'impact se lit en secondes, le jeu règle la vitesse.
fps = scene.render.fps
impacts, baked = {}, []
for name, source in [("rest", idle)] + list(spec["anims"].items()):
    extra = set(bpy.data.objects)
    if isinstance(source, str) and source in gestures:
        use(idle)
        pose_anim.play(arm, gestures[source]["keys"], "none", fps)
        first, last = 1, 1 + fps
        if "impact" in gestures[source]:
            impacts[name] = gestures[source]["impact"]
    else:
        action = source if name == "rest" else borrow(source)
        use(action)
        first, last = int(action.frame_range[0]), int(action.frame_range[1])
        scene.frame_set(first)
        # Le gréage local tient la garde et pose la main gauche : ses animations d'emprunt viennent
        # d'un autre squelette. Gréé par Mixamo, le personnage joue les siennes telles quelles.
        if spec["guard"]:
            guard_target()
            left_hand(first, last)
        elif name not in ("rest", "walk"):
            impacts[name] = impact(first, last)
    baked.append(bake(name, first, last))
    if name != "rest" and spec["arm_space"]:
        spread(baked[-1], "Arm", spec["arm_space"])
    if name == "walk" and spec["walk_leg_space"]:
        spread(baked[-1], "UpLeg", spec["walk_leg_space"])
    if name != "rest" and spec["elbows"]:
        straighten(baked[-1], spec["elbows"])
    # Sans arme montrée (`ActorModel.SHEATHED`), la main reste la sienne.
    if grip_name and not spec["guard"] and name not in spec["sheathed"]:
        wield(baked[-1], first, last, grip_name)
    if name in spec["repeat"]:
        impacts[name] = repeat(baked[-1], first, last, impacts[name], **spec["repeat"][name])
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
# La hauteur du corps, en mètres : les vues de face le cadrent d'après elle (`ActorPortrait`) ;
# Godot ne déforme pas la boîte englobante d'un maillage gréé.
arm["height"] = round((hi.z - lo.z) * s, 3)
# Celle qu'il tient sans équipement : `ActorModel` la montre quand on ne lui en donne pas.
arm["weapon"] = spec["weapon"]
# La case de planche à laquelle il est mis à l'échelle : un corps « grandi » (`<id>_<case>`, la
# Légende du Roi des Rats) en est le rapport (`ActorModel`).
arm["size"] = spec["size"]
export(spec["out"])
print("EXPORT", spec["out"], round(hi.z - lo.z, 3), "->", round((hi.z - lo.z) * s, 3), "m")
if spec["portrait"]:
    portrait(spec["portrait"], spec["portrait_out"])
    print("PORTRAIT", spec["portrait_out"])
