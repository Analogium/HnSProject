class_name Holy
extends RefCounted

## La lumière sacrée, **posée** en un seul endroit : le trait de Frappe sacrée,
## les ondes de Pulsation, la colonne du Pilier et les grains de Lumière sacrée.
##
## Le blanc du sacré vivait dans trois fichiers à trois valeurs — 0,55, 0,60 et
## 0,80 vers le blanc —, exactement le désordre qu'avaient les quatre blancs
## chauds du feu. Il n'y en a plus qu'un, et il est **mesuré** : à 0,70 de blanc,
## le rose monte à 0,91 de luminance et passe le seuil de glow (0,9) ; en dessous
## il reste sous le seuil et la lumière n'éclaire rien.

## Le blanc du sacré : chaud et non bleu — une lumière d'or et de cierge, pas un
## néon. Le même que celui du feu, parce que c'est la même chose : de la lumière.
const GLORY := Color(1.0, 0.96, 0.92)
const HALO := 0.70

## L'épaisseur du halo au pied du trait, et la part de son épaisseur que prend le
## cœur. Un cœur plus large mange la teinte et le trait sort blanc.
const BURST := 7.0
const CORE := 0.38
## De combien le trait est poussé en haut de sa rampe. **Une lumière n'a pas de
## dessous** : éclairé comme un objet, le trait sortait avec un flanc mauve sombre
## et se lisait comme un os. Poussé plus haut encore (0,6), il s'aplatit et perd
## son rose — c'est à 0,35 qu'il garde un peu de volume sans avoir d'ombre.
const LIT := 0.35


## Le cœur d'une lumière de cette teinte — le seul endroit où le sacré a le droit
## d'être presque blanc.
static func halo(tint: Color) -> Color:
	return tint.lerp(GLORY, HALO)


## Un trait de lumière et son éclat de départ, rastérisés d'un coup.
##
## C'est le seul geste du jeu qui parte dans **n'importe quelle direction** : une
## planche ne pivotant pas, un chapelet de marques était la seule autre voie, et
## deux planches cernées qui se recouvrent montrent leurs contours l'une dans
## l'autre. Rastérisé, le trait n'a qu'une silhouette, donc **un seul contour**.
##
## Une fois à la naissance et jamais plus : un trait parti ne change plus de forme.
static func lance(tip: Vector2, radius: float, tint: Color) -> EffectForge.Piece:
	var margin := maxf(radius, BURST) + 2.0
	var corner := Vector2(minf(tip.x, 0.0), minf(tip.y, 0.0)) - Vector2(margin, margin)
	var canvas := PixelCanvas.new(
		int(ceil(absf(tip.x) + margin * 2.0)), int(ceil(absf(tip.y) + margin * 2.0))
	)
	var foot := -corner
	canvas.capsule(foot, foot + tip, radius, EffectForge.R_TINT, LIT)
	canvas.disc(foot, BURST, EffectForge.R_TINT, LIT)
	# Le cœur par-dessus, forcé en haut de sa rampe : c'est lui qui déborde.
	canvas.capsule(foot, foot + tip, radius * CORE, EffectForge.R_CORE, 1.0)
	canvas.disc(foot, BURST * 0.45, EffectForge.R_CORE, 1.0)

	return EffectForge.Piece.new(
		ImageTexture.create_from_image(
			canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(halo(tint))])
		),
		corner
	)


## Un grain de lumière : trois pixels, le cœur au milieu. Le flocon de la glace a
## la forme inverse — ses branches brillent et son centre est de la teinte —,
## parce qu'un cristal accroche la lumière quand un grain **est** la lumière.
static func spark(ci: CanvasItem, at: Vector2, tint: Color, fade: float) -> void:
	if fade <= 0.0:
		return
	var tex := EffectForge.spark(tint)
	var size := Vector2(tex.get_width(), tex.get_height())
	ci.draw_texture_rect(
		tex, Rect2(EffectForge.snap(ci, at - size * 0.5), size), false,
		Color(1.0, 1.0, 1.0, fade)
	)
