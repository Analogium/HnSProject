# Les armes tenues en main, modélisées en quelques volumes (jalon 51). Chacune est posée
# sous un parent : la poignée à l'origine, la lame (ou le manche) le long de +Y. `L` est la
# hauteur du personnage : à 36 px, ce qui fait moins de deux pixels de large disparaît.
import bpy, math
from mathutils import Matrix, Vector

RIGHT, FORWARD, UP = Vector((-1, 0, 0)), Vector((0, -1, 0)), Vector((0, 0, 1))
# À 36 px, avec des bras chibi, une arme à l'échelle se lit mal : on l'exagère, comme Hero Siege.
OVERSIZE = 1.4

STEEL, GOLD, LEATHER = (0.80, 0.83, 0.90, 1), (0.86, 0.64, 0.22, 1), (0.36, 0.20, 0.12, 1)
WOOD, DARK, BONE, CRYSTAL = (0.45, 0.27, 0.14, 1), (0.30, 0.30, 0.34, 1), (0.86, 0.82, 0.68, 1), (0.35, 0.75, 1.0, 1)


def _material(label, color, glow=False):
    m = bpy.data.materials.new(label)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = color
    if glow:
        # Une source de lumière ne prend pas l'ombrage : elle reste au plus clair (voir `stage.toon`).
        m["glow"] = True
    return m


def _add(kind, label, scale, at, color, glow=False, rot=(0, 0, 0), **kw):
    getattr(bpy.ops.mesh, "primitive_" + kind + "_add")(**kw)
    o = bpy.context.object
    o.name, o.scale, o.location, o.rotation_euler = label, scale, at, rot
    o["prop"] = True
    o.data.materials.append(_material(label, color, glow))
    return o


def cube(label, size, at, color, **kw):
    return _add("cube", label, size, at, color, size=1, **kw)


def rod(label, radius, length, at, color, **kw):
    """Un cylindre le long de Y."""
    return _add("cylinder", label, (radius, radius, length / 2), at, color, vertices=8,
                rot=(math.pi / 2, 0, 0), **kw)


def tip(label, width, length, at, color):
    """La pointe d'une lame : une pyramide à quatre faces, aplatie, le long de Y."""
    return _add("cone", label, (width / 2, length / 2, width / 6), at, color, vertices=4,
                radius1=1, depth=2, rot=(-math.pi / 2, 0, math.pi / 4))


def ball(label, radius, at, color, glow=False):
    return _add("ico_sphere", label, (radius,) * 3, at, color, glow, subdivisions=1)


def local(v):
    """Une direction (droite, avant, haut) du personnage, en repère du monde."""
    return RIGHT * v[0] + FORWARD * v[1] + UP * v[2]


def orient(blade):
    """La rotation qui couche la lame (+Y) le long de `blade`, à plat de face si possible."""
    y = Vector(blade).normalized()
    flat = UP if abs(y.dot(UP)) < 0.8 else FORWARD
    x = flat.cross(y).normalized()
    return Matrix((x, y, x.cross(y))).transposed().to_quaternion()


def carry(root, arm, hand, blade, H):
    """La main armée en garde : une cible portée par le bassin, à `hand` (droite, avant,
    haut, en hauteurs de personnage) de l'épaule ; le bras s'y plie, l'arme (`root`, ou
    aucune pour la passe du corps) y est fixée."""
    pb = lambda s: next(b for b in arm.pose.bones if b.name.endswith(s))
    bpy.context.view_layer.update()
    at = arm.matrix_world @ pb("RightArm").head + local(hand) * H
    target = bpy.data.objects.new("garde", None)
    bpy.context.scene.collection.objects.link(target)
    hips = pb("Hips")
    target.parent, target.parent_type, target.parent_bone = arm, "BONE", hips.name
    bpy.context.view_layer.update()
    target.matrix_world = Matrix.LocRotScale(at, orient(blade), (1, 1, 1))
    ik = pb("RightForeArm").constraints.new("IK")
    ik.target, ik.chain_count = target, 2
    if root is not None:
        root.parent = target


def build(kind, L):
    """Rend le parent ; ses enfants sont marqués `prop`, hors du cadrage du personnage."""
    L *= OVERSIZE
    parts = {
        "sword": lambda: [cube("lame", (0.06 * L, 0.33 * L, 0.02 * L), (0, 0.21 * L, 0), STEEL),
                          tip("pointe", 0.06 * L, 0.07 * L, (0, 0.41 * L, 0), STEEL),
                          cube("garde", (0.13 * L, 0.025 * L, 0.03 * L), (0, 0.035 * L, 0), GOLD),
                          rod("poignee", 0.016 * L, 0.08 * L, (0, -0.01 * L, 0), LEATHER),
                          ball("pommeau", 0.025 * L, (0, -0.06 * L, 0), GOLD)],
        "dagger": lambda: [cube("lame", (0.045 * L, 0.15 * L, 0.016 * L), (0, 0.11 * L, 0), STEEL),
                           tip("pointe", 0.045 * L, 0.05 * L, (0, 0.21 * L, 0), STEEL),
                           cube("garde", (0.09 * L, 0.02 * L, 0.025 * L), (0, 0.03 * L, 0), GOLD),
                           rod("poignee", 0.014 * L, 0.06 * L, (0, -0.005 * L, 0), LEATHER)],
        "mace": lambda: [rod("manche", 0.016 * L, 0.30 * L, (0, 0.08 * L, 0), WOOD),
                         ball("tete", 0.06 * L, (0, 0.26 * L, 0), DARK),
                         cube("ailette_a", (0.15 * L, 0.05 * L, 0.025 * L), (0, 0.26 * L, 0), DARK),
                         cube("ailette_b", (0.025 * L, 0.05 * L, 0.15 * L), (0, 0.26 * L, 0), DARK),
                         ball("pommeau", 0.022 * L, (0, -0.07 * L, 0), DARK)],
        "wand": lambda: [rod("manche", 0.014 * L, 0.24 * L, (0, 0.06 * L, 0), WOOD),
                         cube("collier", (0.04 * L, 0.02 * L, 0.04 * L), (0, 0.18 * L, 0), GOLD),
                         _add("ico_sphere", "cristal", (0.03 * L, 0.05 * L, 0.03 * L), (0, 0.23 * L, 0),
                              CRYSTAL, True, subdivisions=1)],
        # Les armes des ennemis : le hachoir du grunt, le bâton du caster.
        "cleaver": lambda: [rod("manche", 0.018 * L, 0.12 * L, (0, 0.0, 0), WOOD),
                            cube("lame", (0.12 * L, 0.20 * L, 0.018 * L), (0.035 * L, 0.16 * L, 0), STEEL)],
        "staff": lambda: [rod("baton", 0.016 * L, 0.62 * L, (0, 0.12 * L, 0), WOOD),
                          ball("orbe", 0.045 * L, (0, 0.47 * L, 0), CRYSTAL, glow=True)],
        "flute": lambda: [rod("tube", 0.018 * L, 0.34 * L, (0, 0.10 * L, 0), BONE),
                          _add("cone", "pavillon", (0.035 * L, 0.035 * L, 0.03 * L), (0, 0.28 * L, 0), BONE,
                               vertices=8, rot=(-math.pi / 2, 0, 0)),
                          *[cube(f"trou{i}", (0.012 * L, 0.012 * L, 0.012 * L), (0, (0.04 + 0.05 * i) * L, 0.016 * L),
                                 (0.15, 0.10, 0.08, 1)) for i in range(3)]],
    }
    root = bpy.data.objects.new("arme", None)
    bpy.context.scene.collection.objects.link(root)
    for o in parts[kind]():
        o.parent = root
    return root
