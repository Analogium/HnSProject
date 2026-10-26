"""Un flipbook de brume (jalon 54, essayé pour la Nova de glace, écarté sur planche — « sans brume » —
mais la chaîne tient) : une bouffée de fumée Mantaflow qui part d'un anneau vers le dehors, rendue de
dessus sur fond transparent, 16 images de 256². Les deux premières ne montrent que le tore émetteur.

    blender.exe -b -P mist_flipbook.py -- <dossier Windows>

Pièges payés : les normales d'un tore soufflent dans tous les sens et s'annulent — c'est un champ de
force qui pousse ; à 60 la fumée sortait du domaine en trois images, à 3,2 elle s'ouvre ; touchant les
parois, elle s'y écrase en carré — domaine élargi, 32 images seulement."""
import math, os, sys
import bpy

out = sys.argv[sys.argv.index("--") + 1]
os.makedirs(out, exist_ok=True)
FRAMES = 32
SHOTS = 16

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.frame_start = 1
scene.frame_end = FRAMES

# Le domaine : 4 × 4 de côté, bas.
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
domain = bpy.context.active_object
domain.scale = (6.0, 6.0, 1.2)
bpy.ops.object.transform_apply(scale=True)
mod = domain.modifiers.new("fluid", "FLUID")
mod.fluid_type = "DOMAIN"
ds = mod.domain_settings
ds.domain_type = "GAS"
ds.resolution_max = 160
ds.cache_type = "ALL"
ds.cache_frame_start = 1
ds.cache_frame_end = FRAMES
ds.cache_directory = os.path.join(out, "cache")
ds.use_adaptive_domain = False
ds.vorticity = 0.6
ds.alpha = 0.0
ds.beta = 0.0
ds.gravity = (0.0, 0.0, 0.0)
ds.use_dissolve_smoke = True
ds.dissolve_speed = 40
ds.use_dissolve_smoke_log = True

# Le flux : un anneau couché, qui souffle vers le dehors une fois.
bpy.ops.mesh.primitive_torus_add(major_radius=0.45, minor_radius=0.2, location=(0, 0, 0.2))
ring = bpy.context.active_object
fmod = ring.modifiers.new("fluid", "FLUID")
fmod.fluid_type = "FLOW"
fs = fmod.flow_settings
fs.flow_type = "SMOKE"
fs.flow_behavior = "INFLOW"
fs.flow_source = "MESH"
fs.surface_distance = 1.0
fs.smoke_color = (1, 1, 1)
for frame, density in ((1, 1.0), (4, 1.0), (5, 0.0)):
    fs.density = density
    fs.keyframe_insert("density", frame=frame)

# La matière : un volume blanc, éclairé.
mat = bpy.data.materials.new("mist")
mat.use_nodes = True
nodes = mat.node_tree.nodes
nodes.clear()
vol = nodes.new("ShaderNodeVolumePrincipled")
vol.inputs["Density"].default_value = 14.0
vol.inputs["Color"].default_value = (1, 1, 1, 1)
outn = nodes.new("ShaderNodeOutputMaterial")
mat.node_tree.links.new(vol.outputs["Volume"], outn.inputs["Volume"])
domain.data.materials.append(mat)

# Un souffle qui repousse depuis le centre, puis retombe ; une turbulence pour les volutes.
bpy.ops.object.effector_add(type="FORCE", location=(0, 0, 0.2))
push = bpy.context.active_object
push.field.shape = "POINT"
push.field.flow = 0.0
for frame, strength in ((1, 3.2), (12, 1.6), (30, 0.0)):
    push.field.strength = strength
    push.field.keyframe_insert("strength", frame=frame)
bpy.ops.object.effector_add(type="TURBULENCE", location=(0, 0, 0.5))
turb = bpy.context.active_object
turb.field.strength = 3.0
turb.field.size = 0.3

bpy.ops.object.select_all(action="DESELECT")
domain.select_set(True)
bpy.context.view_layer.objects.active = domain
bpy.ops.fluid.bake_all()
ring.hide_render = True

# De dessus, orthographique ; un soleil en biais, comme celui du jeu.
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 6.0
cam = bpy.data.objects.new("cam", cam_data)
cam.location = (0, 0, 8)
scene.collection.objects.link(cam)
scene.camera = cam
sun_data = bpy.data.lights.new("sun", "SUN")
sun_data.energy = 4.0
sun = bpy.data.objects.new("sun", sun_data)
sun.rotation_euler = (math.radians(40), 0, math.radians(-35))
scene.collection.objects.link(sun)
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
scene.world = world

scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.volume_step_rate = 2.0
scene.render.film_transparent = True
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
step = (FRAMES - 2) / (SHOTS - 1)
for i in range(SHOTS):
    scene.frame_set(2 + round(i * step))
    scene.render.filepath = os.path.join(out, f"mist_{i:02d}.png")
    bpy.ops.render.render(write_still=True)
print("FLIPBOOK OK")
