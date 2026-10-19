# Un modèle de décor (jalon 54, étape 3) : un scan de Poly Haven, réduit à `faces` triangles
# pour être posé par centaines, porté à `size` mètres de plus grande dimension, l'origine sous
# son pied, au centre. `piece` : l'objet gardé d'un lot, « - » pour tout.
#   blender -b -P decor.py -- <modele.gltf> <faces> <size> <piece> <sortie.glb>
import bpy, sys

src, faces, size, piece, out = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and piece in ("-", o.name)]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
body = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
body.scale *= float(size) / max(body.dimensions)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
triangles = sum(len(p.vertices) - 2 for p in body.data.polygons)
body.modifiers.new("reduire", "DECIMATE").ratio = min(1.0, int(faces) / triangles)
bpy.ops.object.modifier_apply(modifier="reduire")
pts = [v.co for v in body.data.vertices]
low = min(p.z for p in pts)
middle = [(min(p[i] for p in pts) + max(p[i] for p in pts)) / 2 for i in range(2)]
for v in body.data.vertices:
    v.co.x -= middle[0]
    v.co.y -= middle[1]
    v.co.z -= low
for o in list(bpy.context.scene.objects):
    if o is not body:
        bpy.data.objects.remove(o)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True)
size = [max(v.co[i] for v in body.data.vertices) - min(v.co[i] for v in body.data.vertices) for i in range(3)]
print("DECOR", out, triangles, "->", sum(len(p.vertices) - 2 for p in body.data.polygons), "triangles",
      "taille", [round(x, 2) for x in size], "m")
