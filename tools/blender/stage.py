# La scène commune des rendus de personnages (jalon 51) : caméra fixe à l'angle du jeu,
# lumière en haut à gauche de l'écran, ombrage en aplats, rendu sans anticrénelage, et la
# place à l'écran des os qui comptent pour le jeu. `render_anim.py` (animations Mixamo) et
# `pose_anim.py` (gestes écrits en poses-clés) passent par ici, pour sortir pareil.
import bpy, json, math
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

LIGHT = (-0.6, 0.8)  # d'où vient la lumière, en repère écran : à gauche, en haut
# (vue, azimut, retournée). Le profil se rend du côté gauche du personnage, puis se
# retourne pour regarder à droite : vue du côté de la main armée, la lame passait sur le
# corps ; de l'autre côté, le corps la masque là où elle passe derrière lui.
VIEWS = (("down", 0, False), ("side", 90, True), ("up", 180, False))
# La case de rendu fait 1,5 fois la hauteur du personnage : `size` / FRAMING est sa taille en
# pixels de jeu, que `export_glb.py` reprend pour le .glb.
FRAMING = 1.5


def options(argv):
    return dict(a.split("=", 1) for a in argv)


def fcurves(action):
    """Les courbes d'une action, à plat ou rangées par emplacement (Blender 4.4 et après)."""
    if getattr(action, "fcurves", None):
        return action.fcurves
    return action.layers[0].strips[0].channelbag(action.slots[0]).fcurves


def load(path):
    """Un .fbx de Mixamo, ou un .blend du gréage local (blender/rig.py)."""
    if path.endswith(".blend"):
        bpy.ops.wm.open_mainfile(filepath=path)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=path)
    return next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")


def bounds(scene):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in scene.objects:
        if o.type == "MESH" and not o.get("prop"):
            e = o.evaluated_get(dg)
            pts += [e.matrix_world @ Vector(c) for c in e.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def toon(materials):
    """La lumière découpée en trois tons, multipliée par la couleur : des aplats, comme un
    pixel art, au lieu d'un dégradé que la réduction brouille."""
    for mat in materials:
        nt = mat.node_tree
        if nt is None:
            continue
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        outn = next((n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"), None)
        if bsdf is None or outn is None:
            continue
        base = bsdf.inputs["Base Color"]
        color = base.links[0].from_socket if base.links else None
        if mat.get("glow"):
            # Une source de lumière (le cristal d'une baguette) reste au plus clair.
            emit = nt.nodes.new("ShaderNodeEmission")
            emit.inputs[0].default_value = base.default_value
            nt.links.new(emit.outputs[0], outn.inputs["Surface"])
            continue
        diff = nt.nodes.new("ShaderNodeBsdfDiffuse")
        torgb = nt.nodes.new("ShaderNodeShaderToRGB")
        bw = nt.nodes.new("ShaderNodeRGBToBW")
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.interpolation = "CONSTANT"
        el = ramp.color_ramp.elements
        el[0].position, el[0].color = 0.0, (0.42, 0.40, 0.48, 1)
        el[1].position, el[1].color = 0.18, (0.72, 0.70, 0.74, 1)
        el.new(0.45).color = (1.0, 0.97, 0.92, 1)
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        emit = nt.nodes.new("ShaderNodeEmission")
        nt.links.new(diff.outputs[0], torgb.inputs[0])
        nt.links.new(torgb.outputs[0], bw.inputs[0])
        nt.links.new(bw.outputs[0], ramp.inputs[0])
        nt.links.new(ramp.outputs[0], mix.inputs["A"])
        if color is not None:
            nt.links.new(color, mix.inputs["B"])
        else:
            mix.inputs["B"].default_value = base.default_value
        nt.links.new(mix.outputs["Result"], emit.inputs[0])
        nt.links.new(emit.outputs[0], outn.inputs["Surface"])


def flip(path):
    """Retourne une image rendue de gauche à droite, en place."""
    import numpy as np
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:]).reshape(h, w, 4)[:, ::-1]
    img.pixels[:] = px.ravel()
    img.save()
    bpy.data.images.remove(img)


class Stage:
    """Caméra et lumière posées sur le personnage au repos : `height` fixe l'échelle pour
    toutes les animations, sinon un bras levé rapetisserait le personnage."""

    def __init__(self, arm, opt):
        self.arm, self.opt = arm, opt
        scene = self.scene = bpy.context.scene
        self.size = int(opt.get("size", 512))
        lo, hi = bounds(scene)
        self.height = float(opt.get("height", 0)) or (hi.z - lo.z)
        print("HAUTEUR", self.height)
        self.center = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z + self.height * 0.5))
        scene.render.engine = "BLENDER_EEVEE"
        scene.render.resolution_x = scene.render.resolution_y = self.size
        scene.render.film_transparent = True
        # AgX, la transformation par défaut, écrase les tons et éteint les visages.
        scene.view_settings.view_transform = "Standard"
        if opt.get("aa") == "0":
            scene.render.filter_size = 0.0
            scene.eevee.taa_render_samples = 1
        amb = float(opt.get("ambient", 0.55))
        scene.world = bpy.data.worlds.new("w"); scene.world.color = (amb, amb, amb)
        if opt.get("toon") == "1":
            toon(bpy.data.materials)
        # `layer=weapon` : l'arme seule, le corps en masque (elle passe derrière lui quand il
        # le faut) ; le jeu la pose sur la planche du corps, rendue sans arme.
        if opt.get("layer") == "weapon":
            for o in scene.objects:
                if o.type == "MESH" and not o.get("prop"):
                    o.is_holdout = True
        self.target = bpy.data.objects.new("target", None); scene.collection.objects.link(self.target)
        self.target.location = self.center
        cam = self.cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam)
        cam.data.type = "ORTHO"; cam.data.ortho_scale = self.height * FRAMING
        cam.constraints.new("TRACK_TO").target = self.target
        scene.camera = cam
        sun = self.sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); scene.collection.objects.link(sun)
        sun.data.energy = float(opt.get("sun", 4))
        sun.constraints.new("TRACK_TO").target = self.target

        def bone(suffix):
            return next(b for b in arm.pose.bones if b.name.endswith(suffix))
        # La main armée, l'avant-bras (l'axe de la lame), et ce qui donne les repères du jeu.
        self.bones = {"hand": bone("RightHand"), "forearm": bone("RightForeArm"), "head": bone("Head"),
                      "neck": bone("Neck"), "hips": bone("Hips"), "foot_l": bone("LeftFoot"),
                      "foot_r": bone("RightFoot")}

    def screen(self, p):
        v = world_to_camera_view(self.scene, self.cam, p)
        return [round(v.x * self.size, 2), round((1 - v.y) * self.size, 2)]

    def render(self, out, name, frames, views=None, extra=None):
        """`frames` : les images de la scène à rendre. `extra(view)` ajoute à chaque image
        des points de plus (la lame d'une arme posée à la main)."""
        marks = {}
        e = math.radians(float(self.opt.get("elevation", 35)))
        for view, az, mirror in VIEWS:
            if views and view not in views:
                continue
            a = math.radians(az)
            d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
            self.cam.location = self.center + d * self.height * 4
            right = -d.cross(Vector((0, 0, 1))).normalized()
            up = right.cross(-d).normalized()
            lx = -LIGHT[0] if mirror else LIGHT[0]
            self.sun.location = self.center + (d + right * lx * 1.5 + up * LIGHT[1] * 1.5) * self.height * 4
            for i, f in enumerate(frames):
                self.scene.frame_set(f)
                path = f"{out}/{name}_{view}_{i}.png"
                self.scene.render.filepath = path
                bpy.ops.render.render(write_still=True)
                m = {k: self.screen(self.arm.matrix_world @ b.head) for k, b in self.bones.items()}
                if extra:
                    m.update({k: self.screen(p) for k, p in extra().items()})
                if mirror:
                    flip(path)
                    m = {k: [round(self.size - x, 2), y] for k, (x, y) in m.items()}
                marks.setdefault(view, []).append(m)
        json.dump(marks, open(f"{out}/{name}.json", "w"), indent=1)
