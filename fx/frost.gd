class_name Frost
extends RefCounted

## La glace du jeu en 2D, **posée** en un seul endroit : la couronne de la Nova, les
## éclats du Désastre hivernal et les flocons du Tombeau. Les dessins viennent de
## `EffectForge` ; ce fichier dit comment ils se posent, calés sur le pixel du jeu. Les
## Pics de glace sont en 3D (`IceSpikesFx`).
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


## Un éclat couché sur son cap, pris parmi les huit orientations : c'est lui qui
## dit qu'un tourbillon tourne. Tous pointés en haut, ce serait une chute de neige.
static func chip(ci: CanvasItem, at: Vector2, heading: float, tint: Color, fade: float) -> void:
	EffectForge.put_centered(ci, EffectForge.chips(tint)[EffectForge.chip_turn(heading)], at, fade)


## Un flocon emporté : une croix de trois pixels, pas un carré. Un carré est un
## confetti.
static func drift(ci: CanvasItem, at: Vector2, tint: Color, fade: float) -> void:
	EffectForge.put_centered(ci, EffectForge.flake(tint), at, fade)


## L'Orbe gelée (jalon 44), « sphère de givre » choisie sur planche contre une étoile de
## cristaux, un flocon géant, un cœur et sa ronde, un oursin et un cristal taillé : une boule
## pleine, et la facette de givre qui la traverse dit qu'elle tourne. Fabriquée une fois par
## position de la facette — un demi-tour suffit, elle est symétrique.
const ORB_FRAME := 17
const ORB_TURNS := 8
static var _orbs := {}


static func orb(tint: Color, turn: int) -> Texture2D:
	var key := "%s|%d" % [tint.to_html(false), posmod(turn, ORB_TURNS)]
	if not _orbs.has(key):
		var at := Vector2.ONE * float(ORB_FRAME / 2)
		var facet := Vector2.from_angle(PI * float(posmod(turn, ORB_TURNS)) / float(ORB_TURNS))
		var canvas := PixelCanvas.new(ORB_FRAME, ORB_FRAME)
		canvas.disc(at, 6.5, EffectForge.R_TINT)
		canvas.disc(at + Vector2(-1.5, -1.5), 3.0, EffectForge.R_TINT, 0.25)
		canvas.line(at - facet * 5.0, at + facet * 5.0, EffectForge.R_CORE, 1.0)
		var img := canvas.to_image([ArtPalette.ramp(tint), ArtPalette.ramp(rim(tint))])
		_orbs[key] = ImageTexture.create_from_image(img)
	return _orbs[key]
