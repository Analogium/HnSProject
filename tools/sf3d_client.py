# Stable Fast 3D, en local sur la carte AMD : une image détourée -> un .glb texturé.
# Tourne sous le Python Windows de son venv (voir tools/characters/LISEZMOI.md, « En 3D ») :
#   <venv>/Scripts/python.exe sf3d_client.py <sources sf3d> <image RGBA> <sortie.glb>
import sys, types
import numpy as np, torch, trimesh
from PIL import Image

src_dir, image_path, out = sys.argv[1:4]
sys.path.insert(0, src_dir)
# Le détourage est déjà fait ; rembg exigerait onnxruntime pour rien.
sys.modules["rembg"] = types.ModuleType("rembg")
from sf3d.system import SF3D
from sf3d.utils import resize_foreground

model = SF3D.from_pretrained("stabilityai/stable-fast-3d", config_name="config.yaml",
                             weight_name="model.safetensors")
model.to("cuda").eval()


def on_cpu(f):
    """La cuisson n'est compilée que pour le CPU (pas de CUDA sur une AMD)."""
    def g(*a, **k):
        r = f(*[x.cpu() if torch.is_tensor(x) else x for x in a], **k)
        return r.to("cuda") if torch.is_tensor(r) else r
    return g


for name in ("rasterize", "interpolate", "get_mask"):
    setattr(model.baker, name, on_cpu(getattr(model.baker, name)))
image = resize_foreground(Image.open(image_path).convert("RGBA"), 0.85)
with torch.no_grad(), torch.autocast(device_type="cuda", dtype=torch.bfloat16):
    mesh, _ = model.run_image([image], bake_resolution=1024, remesh="none", vertex_count=-1)
# SF3D tourne le dos à la caméra de face du jeu.
mesh.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [0, 1, 0]))
mesh.export(out, include_normals=True)
