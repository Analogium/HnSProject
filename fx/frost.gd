class_name Frost
extends RefCounted

## La glace du jeu, **posée** en un seul endroit : les cristaux de Pics de glace,
## la couronne de la Nova, les éclats du Désastre hivernal et les flocons du
## Tombeau. Les dessins viennent de `EffectForge` ; ce fichier dit comment ils se
## posent — calés sur le pixel du jeu, et sortant de terre plutôt que grandissant.
##
## **Le froid ne se blanchit pas, il s'ombre.** Son cyan porte déjà 0,81 de
## luminance — la matière la plus claire du jeu, contre 0,57 pour le feu et 0,63
## pour la foudre — et il passe le seuil de glow (0,9) à pleine opacité sans qu'on
## y ajoute quoi que ce soit. L'éclaircir lui retirerait sa teinte : la pointe des
## pics d'avant, à 0,55 vers le blanc, était **blanche** et se lisait comme du
## verre.

## Le givre de l'arête. Mélangé à moitié, le cyan garde son bleu (0,68 de rouge)
## et monte à 0,88 de luminance : il déborde sur le sol sans virer au blanc.
const RIME := Color(0.86, 0.97, 1.00)
const RIM := 0.5


## Le givre d'un cristal de cette teinte : le seul trait qui a le droit de briller.
static func rim(tint: Color) -> Color:
	return tint.lerp(RIME, RIM)


## Lève un cristal hors du sol. On **découpe** la planche au ras du sol plutôt que
## de l'étirer : une planche redimensionnée se rééchantillonne et ses blocs de deux
## pixels se brisent. `out` va de 0 — rien — à 1, le cristal entier.
##
## Le pied reste au sol et la pointe monte : c'est l'inverse d'un cristal qui
## grandit sur place, et c'est ce qui dit qu'il **perce**.
##
## **Pas d'opacité à régler : un cristal ne pâlit pas, il redescend.** Posé à
## demi-transparent sur un sol sombre, le cyan sort gris — c'est le même piège que
## l'orange peu opaque du feu, qui sortait brun. Ce qui s'efface, ce sont les
## flocons et le givre au sol, qui sont faits pour ça.
static func raise_spike(
	ci: CanvasItem, foot: Vector2, big: bool, out: float, tint: Color
) -> void:
	if out <= 0.0:
		return
	var tex: Texture2D = EffectForge.spike(tint) if big else EffectForge.small_spike(tint)
	var width := tex.get_width()
	var shown := maxi(int(round(float(tex.get_height()) * minf(out, 1.0))), 1)
	var size := Vector2(float(width), float(shown))
	ci.draw_texture_rect_region(
		tex, Rect2(EffectForge.snap(ci, foot - Vector2(float(width) * 0.5, float(shown))), size),
		Rect2(0.0, 0.0, size.x, size.y)
	)


## Un éclat couché sur son cap, pris parmi les huit orientations : c'est lui qui
## dit qu'un tourbillon tourne. Tous pointés en haut, ce serait une chute de neige.
static func chip(ci: CanvasItem, at: Vector2, heading: float, tint: Color, fade: float) -> void:
	_put(ci, EffectForge.chips(tint)[EffectForge.chip_turn(heading)], at, fade)


## Un flocon emporté : une croix de trois pixels, pas un carré. Un carré est un
## confetti.
static func drift(ci: CanvasItem, at: Vector2, tint: Color, fade: float) -> void:
	_put(ci, EffectForge.flake(tint), at, fade)


static func _put(ci: CanvasItem, tex: Texture2D, at: Vector2, fade: float) -> void:
	if fade <= 0.0:
		return
	var size := Vector2(tex.get_width(), tex.get_height())
	ci.draw_texture_rect(
		tex, Rect2(EffectForge.snap(ci, at - size * 0.5), size), false,
		Color(1.0, 1.0, 1.0, fade)
	)
