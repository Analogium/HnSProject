# Rend un modèle .glb sous plusieurs angles, caméra orthographique, fond transparent.
#   blender -b -P turntable.py -- <modele.glb> <dossier de sortie> [taille]
# Pour juger un modèle avant de le gréer : face, profil, dos, puis l'angle plongeant.
import bpy, sys, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
glb, out = argv[0], argv[1]
size = int(argv[2]) if len(argv) > 2 else 512

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
center, height = (lo + hi) / 2, hi.z - lo.z

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = scene.render.resolution_y = size
scene.render.film_transparent = True
scene.world = bpy.data.worlds.new("w")
scene.world.color = (0.35, 0.35, 0.35)

target = bpy.data.objects.new("target", None); scene.collection.objects.link(target)
target.location = center
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam)
cam.data.type = "ORTHO"; cam.data.ortho_scale = height * 1.15
cam.constraints.new("TRACK_TO").target = target
scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); scene.collection.objects.link(sun)
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(50), 0, math.radians(-35))

# (nom, azimut depuis la face, élévation)
for name, az, el in [("1-face", 0, 0), ("2-profil", 90, 0), ("3-dos", 180, 0),
                     ("4-plongee-face", 0, 35), ("5-plongee-profil", 90, 35), ("6-plongee-biais", 45, 35)]:
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    cam.location = center + d * height * 3
    scene.render.filepath = f"{out}/{name}.png"
    bpy.ops.render.render(write_still=True)
