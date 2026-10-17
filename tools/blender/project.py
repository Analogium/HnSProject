# Repeint la texture d'un modèle avec son image de face, et de dos s'il y en a une.
#   blender -b -P project.py -- <modele.glb> <face.png> <dos.png ou -> <sortie.glb>
# Stable Fast 3D cuit une texture floue (le visage) et devine le dos : celui de la sorcière
# sortait rose pâle au lieu de gris sombre. Chaque texel qui fait face à une image en prend
# la couleur (`align.py` les cale) ; le reste garde celle de Stable Fast 3D, ramenée au ton
# des images. Le remplir du texel vu le plus proche faisait des taches là où la caméra du jeu
# regarde : le dessus du bord du chapeau (jalon 54).
import bpy, os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from align import Frame, mesh_points

argv = sys.argv[sys.argv.index("--") + 1:]
glb, front_png, back_png, out = argv
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
obj = next(o for o in bpy.context.scene.objects if o.type == "MESH")
me = obj.data
me.calc_loop_triangles()
n = len(me.loop_triangles)
vi = np.zeros(n * 3, np.int32); me.loop_triangles.foreach_get("vertices", vi)
li = np.zeros(n * 3, np.int32); me.loop_triangles.foreach_get("loops", li)
co = mesh_points(obj)
uv = np.zeros(len(me.loops) * 2, np.float32); me.uv_layers.active.data.foreach_get("uv", uv)
tri = co[vi.reshape(-1, 3)]                       # (n, 3, 3), repère du monde
tuv = uv.reshape(-1, 2)[li.reshape(-1, 3)]        # (n, 3, 2)
nrm = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
nrm /= np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-12

tex_node = next(nd for nd in obj.active_material.node_tree.nodes
                if nd.type == "TEX_IMAGE" and any(l.to_socket.name == "Base Color" for l in nd.outputs[0].links))
img = tex_node.image
W, H = img.size
tex = np.array(img.pixels[:], np.float32).reshape(H, W, 4)   # rangée 0 en bas, comme v


def raster(P):
    """Les pixels couverts par chaque triangle (P : (n, 3, 2), en pixels) :
    indices de triangle, x, y, et coordonnées barycentriques."""
    out = []
    for t in range(len(P)):
        a, b, c = P[t]
        x0, y0 = np.floor(P[t].min(0)).astype(int)
        x1, y1 = np.ceil(P[t].max(0)).astype(int)
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        px, py = xs.ravel() + 0.5, ys.ravel() + 0.5
        d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(d) < 1e-12:
            continue
        w0 = ((b[1] - c[1]) * (px - c[0]) + (c[0] - b[0]) * (py - c[1])) / d
        w1 = ((c[1] - a[1]) * (px - c[0]) + (a[0] - c[0]) * (py - c[1])) / d
        w2 = 1 - w0 - w1
        k = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if k.any():
            out.append((np.full(k.sum(), t), xs.ravel()[k], ys.ravel()[k], np.stack([w0[k], w1[k], w2[k]], 1)))
    return [np.concatenate(x) for x in zip(*out)]


# Les texels : leur place et leur orientation sur le modèle.
t_id, tx, ty, bw = raster(tuv * [W, H])
ok = (tx >= 0) & (tx < W) & (ty >= 0) & (ty < H)
t_id, tx, ty, bw = t_id[ok], tx[ok], ty[ok], bw[ok]
pos = (tri[t_id] * bw[..., None]).sum(1)
tn = nrm[t_id]
height = co[:, 2].max() - co[:, 2].min()


def project(png, toward):
    """La couleur et le poids d'une image vue depuis `toward` (-1 : de face, le jeu
    regardant le personnage depuis -Y ; +1 : de dos)."""
    fr = Frame(png, co, toward)
    w, h, px, alpha, to_img = fr.w, fr.h, fr.px, fr.alpha, fr.to_image
    # Visibilité : un tampon de profondeur à la résolution de l'image.
    zb = np.full((h, w), np.inf, np.float32)
    zi, zx, zy, zw = raster(to_img(tri))
    depth = (tri[zi][..., 1] * zw).sum(1) * -toward       # le plus petit est le plus proche
    k = (zx >= 0) & (zx < w) & (zy >= 0) & (zy < h)
    np.minimum.at(zb, (zy[k], zx[k]), depth[k])
    q = to_img(pos)
    qx, qy = np.clip(q[:, 0].astype(int), 0, w - 1), np.clip(q[:, 1].astype(int), 0, h - 1)
    seen = (pos[:, 1] * -toward <= zb[qy, qx] + 0.01 * height) & alpha[qy, qx]
    # Seulement ce qui fait vraiment face : vu par la tranche, le bord du chapeau prenait le
    # cramoisi de son dessous, que l'image montre au même endroit.
    facing = np.clip((tn[:, 1] * toward - 0.35) / 0.35, 0, 1)
    return px[qy, qx, :3], np.where(seen, facing, 0.0)


cf_, wf = project(front_png, -1)
f = cf_[wf > 0.5]


def matched(c, w):
    """Une couleur ramenée, canal par canal, au ton de l'image de face sur ce qu'elle couvre."""
    o = c[w > 0.5]
    return np.clip((c - o.mean(0)) / (o.std(0) + 1e-6) * f.std(0) + f.mean(0), 0, 1)


if back_png == "-":
    cb_, wb = cf_, np.zeros_like(wf)
else:
    # Tirée à part, l'image de dos n'a pas la luminosité de celle de face.
    cb_, wb = project(back_png, 1)
    cb_ = matched(cb_, wb)
cover = np.maximum(wf, wb)
proj = (cf_ * wf[:, None] + cb_ * wb[:, None]) / np.maximum(wf + wb, 1e-6)[:, None]
sf3d = matched(tex[ty, tx, :3].copy(), wf)
color = proj * cover[:, None] + sf3d * (1 - cover[:, None])

painted = np.zeros((H, W), bool)
tex[ty, tx, :3] = color
painted[ty, tx] = True
# Les marges entre îlots prennent la couleur voisine, sinon l'ancienne bave aux coutures.
for _ in range(4):
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        src = np.roll(np.roll(painted, dy, 0), dx, 1) & ~painted
        tex[src] = np.roll(np.roll(tex, dy, 0), dx, 1)[src]
        painted |= src
img.pixels[:] = tex.ravel()
img.pack()
print("texels", len(pos), "couverts", round(float((cover > 0.5).mean()), 2))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
