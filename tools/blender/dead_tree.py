# Un arbre mort (jalon 54, étape 3) : Poly Haven n'en a pas de debout. Un tronc qui monte en se
# tordant, des branches sur trois niveaux, chacune un tube d'écorce ; la graine décide de la
# forme. La hauteur est celle du jeu, en mètres.
#   blender -b -P dead_tree.py -- <graine> <hauteur> <ecorce_diff> <ecorce_nor> <sortie.glb>
import bpy, bmesh, math, random, sys
from mathutils import Matrix, Vector

seed, height, diffuse, normal, out = sys.argv[sys.argv.index("--") + 1:]
rng = random.Random(int(seed))
HEIGHT = float(height)
# Le tour d'une branche et ses tronçons, en sommets : six et huit pour le tronc et les
# maîtresses branches, quatre et cinq au-delà, invisibles à la distance du jeu.
SIDES = (6, 4)
SEGMENTS = (8, 5)
# Chaque tronçon dévie d'autant, ce qui tord la branche.
BEND = 0.35
# Une branche s'effile de sa base à presque rien : coupée nette, elle faisait une souche haute.
TAPER = 0.85
# Ce qu'une branche garde de sa mère, en longueur et en épaisseur (là où elle part), combien
# elle en porte, et d'où elles partent sur elle.
LENGTH_SHARE = (0.5, 0.75)
RADIUS_SHARE = 0.6
CHILDREN = (3, 5)
SPREAD = (0.3, 0.92)
DEPTH = 4
# L'écorce se répète tous les BARK m le long du bois.
BARK = 1.2


def branch(bm, uv, start, direction, length, radius, depth):
    """Un tube de `start` sur `length`, qui se tord et s'amincit, puis ses enfants."""
    sides, segments = (SIDES[0], SEGMENTS[0]) if depth <= 2 else (SIDES[1], SEGMENTS[1])
    points, d = [start], direction.normalized()
    for _ in range(segments):
        d = (d + Vector([rng.uniform(-BEND, BEND) for _ in range(3)]) * 0.5).normalized()
        # Le bois mort monte encore : une branche ne plonge pas sous elle-même.
        d.z = max(d.z, -0.2)
        points.append(points[-1] + d * length / segments)
    thickness = lambda i: radius * (1.0 - TAPER * i / segments)
    rings, along = [], 0.0
    for i, p in enumerate(points):
        axis = (points[min(i + 1, segments)] - points[max(i - 1, 0)]).normalized()
        side = axis.orthogonal().normalized()
        if i:
            along += (p - points[i - 1]).length
        ring = []
        for k in range(sides + 1):
            angle = 2.0 * math.pi * k / sides
            offset = Matrix.Rotation(angle, 3, axis) @ side * thickness(i)
            ring.append((bm.verts.new(p + offset), (k / sides, along / BARK)))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(sides):
            face = bm.faces.new((a[k][0], a[k + 1][0], b[k + 1][0], b[k][0]))
            for loop, (_, coords) in zip(face.loops, (a[k], a[k + 1], b[k + 1], b[k])):
                loop[uv].uv = coords
    if depth == DEPTH:
        return
    for _ in range(rng.randint(*CHILDREN)):
        i = int(rng.uniform(*SPREAD) * segments)
        tilt = math.radians(rng.uniform(30, 65))
        turn = rng.uniform(0, 2 * math.pi)
        here = (points[i + 1] - points[i]).normalized()
        child = Matrix.Rotation(turn, 3, here) @ Matrix.Rotation(tilt, 3, here.orthogonal().normalized()) @ here
        branch(bm, uv, points[i], child, length * rng.uniform(*LENGTH_SHARE),
               thickness(i) * RADIUS_SHARE, depth + 1)


bpy.ops.wm.read_factory_settings(use_empty=True)
bm = bmesh.new()
uv = bm.loops.layers.uv.new()
trunk = HEIGHT * 0.55
branch(bm, uv, Vector((0, 0, -0.1)), Vector((rng.uniform(-0.15, 0.15), rng.uniform(-0.15, 0.15), 1.0)),
       trunk, HEIGHT * 0.045, 1)
mesh = bpy.data.meshes.new("arbre")
bm.to_mesh(mesh)
tree = bpy.data.objects.new("arbre", mesh)
bpy.context.scene.collection.objects.link(tree)
# Ramené à la hauteur voulue, le pied au sol.
top = max(v.co.z for v in mesh.vertices)
tree.scale = [HEIGHT / top] * 3
bpy.context.view_layer.objects.active = tree
tree.select_set(True)
bpy.ops.object.transform_apply(scale=True)
bpy.ops.object.shade_smooth()

material = bpy.data.materials.new("ecorce")
material.use_nodes = True
nodes, links = material.node_tree.nodes, material.node_tree.links
bsdf = nodes["Principled BSDF"]
color = nodes.new("ShaderNodeTexImage")
color.image = bpy.data.images.load(diffuse)
links.new(color.outputs[0], bsdf.inputs["Base Color"])
relief = nodes.new("ShaderNodeTexImage")
relief.image = bpy.data.images.load(normal)
relief.image.colorspace_settings.name = "Non-Color"
bump = nodes.new("ShaderNodeNormalMap")
links.new(relief.outputs[0], bump.inputs["Color"])
links.new(bump.outputs[0], bsdf.inputs["Normal"])
mesh.materials.append(material)
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True)
print("ARBRE", out, len(mesh.polygons) * 2, "triangles")
