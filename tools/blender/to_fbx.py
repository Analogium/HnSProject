# Prépare un modèle .glb pour Mixamo : allégé, textures incluses, en .fbx.
#   blender -b -P to_fbx.py -- <modele.glb> <sortie.fbx> [triangles]
# Mixamo n'accepte ni le .glb ni les maillages trop lourds (TRELLIS en sort 200 000).
import bpy, sys
argv = sys.argv[sys.argv.index("--") + 1:]
glb, out = argv[0], argv[1]
target = int(argv[2]) if len(argv) > 2 else 40000

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
for o in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
    tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
    if tris > target:
        m = o.modifiers.new("decimate", "DECIMATE"); m.ratio = target / tris
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=m.name)
bpy.ops.export_scene.fbx(filepath=out, path_mode="COPY", embed_textures=True, apply_unit_scale=True)
