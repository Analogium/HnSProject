# Réduit une forme au compte de faces du jeu, la déplie, et y cuit la couleur d'un modèle
# texturé du même personnage, calé par la boîte englobante (jalon 54). Pour TRELLIS.2, les deux
# sont le même fichier : son modèle brut, recuit sur sa version réduite ; recuire, c'est passer
# `model.glb` pour forme.
#   blender -b -P bake_color.py -- <forme.glb> <modele_texture.glb> <sortie.glb>
import bpy, sys
from mathutils import Vector

# Au-delà, le maillage pèse sans se voir à la caméra du jeu ; en deçà, la réduction commence à
# manger les arêtes (essais du jalon 54).
FACES = 40000
TEXTURE = 2048

shape_glb, colored_glb, out = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def load(path):
    """Les maillages d'un .glb, joints en un seul objet, transformations appliquées."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in new:
        if o.name in bpy.data.objects and o is not obj:
            bpy.data.objects.remove(o)
    return obj


def box(o):
    pts = [o.matrix_world @ v.co for v in o.data.vertices]
    return (Vector([min(p[i] for p in pts) for i in range(3)]),
            Vector([max(p[i] for p in pts) for i in range(3)]))


src, dst = load(colored_glb), load(shape_glb)
# La couleur diffuse d'une surface métallique cuit noire : TRELLIS.2 en met partout (0,88 en
# moyenne sur le joueur de flûte, ses habits sortaient noirs). Le jeu n'en lit pas.
for slot in src.material_slots:
    for node in slot.material.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            for link in list(node.inputs["Metallic"].links):
                slot.material.node_tree.links.remove(link)
            node.inputs["Metallic"].default_value = 0.0
(slo, shi), (dlo, dhi) = box(src), box(dst)
k = (shi.z - slo.z) / (dhi.z - dlo.z)
dst.scale = (k, k, k)
dst.location = (slo + shi) / 2 - (dlo + dhi) / 2 * k
dst.location.z = slo.z - dlo.z * k
bpy.ops.object.select_all(action="DESELECT")
dst.select_set(True)
bpy.context.view_layer.objects.active = dst
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
faces = len(dst.data.polygons)
# Déjà réduite (`model.glb`), la forme garde son dépliage : c'est celui que Mixamo a reçu, et
# l'export y reprend la couleur recuite sans regréer (`export_glb`, `color`).
if faces > FACES:
    dst.modifiers.new("reduire", "DECIMATE").ratio = FACES / faces
    bpy.ops.object.modifier_apply(modifier="reduire")
    bpy.ops.object.shade_smooth()
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    # La réduction retourne des faces : le flash du jeu les écartait (corps moucheté), et la
    # cuisson les laissait noires.
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.002)
    bpy.ops.object.mode_set(mode="OBJECT")

image = bpy.data.images.new("couleur", TEXTURE, TEXTURE)
material = bpy.data.materials.new("corps")
material.use_nodes = True
nodes = material.node_tree.nodes
texture = nodes.new("ShaderNodeTexImage")
texture.image = image
material.node_tree.links.new(texture.outputs[0], nodes["Principled BSDF"].inputs["Base Color"])
nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
nodes.active = texture
dst.data.materials.clear()
dst.data.materials.append(material)

# Le rayon part un peu au-dessus de la forme et va chercher la surface du modèle coloré : assez
# loin pour l'atteindre, pas assez pour traverser un membre voisin.
height = shi.z - slo.z
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 1
bake = scene.render.bake
bake.use_selected_to_active, bake.cage_extrusion, bake.max_ray_distance, bake.margin = True, 0.03 * height, 0.08 * height, 8
src.select_set(True)
bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"})
image.pack()
bpy.data.objects.remove(src)
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True)
print("FORME", faces, "->", len(dst.data.polygons), "faces")
