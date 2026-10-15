# Le calage entre une image source détourée (alpha) et le modèle tiré d'elle : même hauteur,
# même centre du haut du corps — le sol resté dans un détourage ne le déplace pas.
# Le jeu regarde le personnage depuis -Y ; l'image de face aussi, celle de dos depuis +Y.
import bpy
import numpy as np


def mesh_points(obj):
    co = np.zeros(len(obj.data.vertices) * 3, np.float32)
    obj.data.vertices.foreach_get("co", co)
    M = np.array(obj.matrix_world)
    return co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]


class Frame:
    def __init__(self, png, co, toward):
        """`co` : les sommets du modèle, repère du monde ; `toward` : -1 de face, +1 de dos."""
        im = bpy.data.images.load(png)
        self.w, self.h = im.size
        self.px = np.array(im.pixels[:], np.float32).reshape(self.h, self.w, 4)[::-1]   # rangée 0 en haut
        self.alpha = self.px[..., 3] > 0.5
        rows = np.where(self.alpha.any(1))[0]
        self.iy0 = rows.min()
        top = self.alpha[self.iy0:self.iy0 + int((rows.max() - self.iy0) * 0.4)]
        self.icx = np.where(top.any(0))[0].mean()
        self.z_top = co[:, 2].max()
        height = self.z_top - co[:, 2].min()
        self.s = (rows.max() - self.iy0) / height          # pixels par unité du modèle
        self.side = -toward                                 # de dos, la droite de l'image est -X
        self.mcx = co[co[:, 2] > self.z_top - 0.4 * height][:, 0].mean()

    def to_image(self, p):
        return np.stack([self.icx + self.side * (p[..., 0] - self.mcx) * self.s,
                         self.iy0 + (self.z_top - p[..., 2]) * self.s], -1)

    def to_model(self, ix, iy):
        """Le point de l'image, en (x, z) du modèle."""
        return self.mcx + self.side * (ix - self.icx) / self.s, self.z_top - (iy - self.iy0) / self.s
