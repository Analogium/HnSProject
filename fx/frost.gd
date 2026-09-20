class_name Frost
extends RefCounted

## La glace du jeu, dessinée en un seul endroit : les pics de Pics de glace, les
## bras et les éclats du Désastre hivernal, les pans du Tombeau de glace et les
## esquilles de la Nova de glace. Le pendant de `fx/fire.gd` pour l'autre matière
## qui a une forme propre.
##
## **Le froid ne se blanchit pas, il s'ombre.** Son cyan porte déjà 0,81 de
## luminance — la matière la plus claire du jeu, contre 0,57 pour le feu et 0,63
## pour la foudre — et il passe le seuil de glow (0,9) à pleine opacité sans qu'on
## y ajoute quoi que ce soit. L'éclaircir lui retire sa teinte : la pointe des pics
## d'avant, à 0,55 vers le blanc, était **blanche** et se lisait comme du verre.
##
## Ce qui fait la glace, c'est donc la **facette** : deux flancs de la même teinte
## à deux opacités, et l'arête claire entre les deux. En additif on n'assombrit
## rien — ombrer veut dire retirer de l'alpha, pas de la couleur.

## Le givre de l'arête. Mélangé à moitié, le cyan garde son bleu (0,68 de rouge)
## et monte à 0,88 de luminance : il déborde sur le sol sans virer au blanc.
const RIME := Color(0.86, 0.97, 1.00)
const RIM := 0.5

## Les deux flancs du cristal unité, du pied vers la pointe : `x` monte de 0 à 1,
## `y` s'écarte de l'axe. **Ils diffèrent** — deux flancs identiques donnent un
## sapin, et sept sapins en cercle donnent une couronne de l'avent.
const SIDE_DARK := [Vector2(0.0, 1.00), Vector2(0.30, 0.86), Vector2(0.66, 0.40)]
const SIDE_LIT := [Vector2(0.0, 0.78), Vector2(0.34, 0.92), Vector2(0.74, 0.46)]

## Les deux opacités des flancs, et celle de l'arête. Leur écart est tout le
## relief : à opacités égales, le cristal redevient un triangle plat.
const DARK_FACE := 0.34
const LIT_FACE := 0.62
const RIDGE := 0.95

## Sous cette taille un cristal ne couvre plus un pixel, et sa triangulation
## échoue sur une aire que Godot refuse — même piège que les langues de `Fire`.
const MIN_HEIGHT := 2.0
const MIN_WIDTH := 0.5


## L'arête d'un cristal de cette teinte : le seul trait qui a le droit de briller.
static func rim(tint: Color) -> Color:
	return tint.lerp(RIME, RIM)


## La pointe d'un cristal, là où les deux flancs se rejoignent.
static func tip(foot: Vector2, up: Vector2, height: float, lean: float) -> Vector2:
	return foot + up * height + Vector2(-up.y, up.x) * lean


## Un flanc du cristal, pied et pointe compris : c'est un polygone fermé, pas une
## moitié de silhouette. `lean` penche la pointe, du même côté pour les deux
## flancs — sinon le cristal s'ouvre en ciseaux.
static func shard(
	foot: Vector2, up: Vector2, height: float, half_width: float, lean: float, lit: bool
) -> PackedVector2Array:
	var across := Vector2(-up.y, up.x)
	var flank := 1.0 if lit else -1.0
	var profile: Array = SIDE_LIT if lit else SIDE_DARK
	var out := PackedVector2Array([foot])
	for p: Vector2 in profile:
		out.append(
			foot + up * height * p.x
			+ across * (lean * p.x * p.x + half_width * p.y * flank)
		)
	out.append(tip(foot, up, height, lean))
	return out


## Un cristal complet : le flanc à l'ombre, le flanc éclairé, l'arête.
static func draw_shard(
	ci: CanvasItem, foot: Vector2, up: Vector2, height: float, half_width: float,
	tint: Color, fade: float, lean := 0.0
) -> void:
	if fade <= 0.0 or height < MIN_HEIGHT or half_width < MIN_WIDTH:
		return
	ci.draw_colored_polygon(
		shard(foot, up, height, half_width, lean, false), Color(tint, DARK_FACE * fade)
	)
	ci.draw_colored_polygon(
		shard(foot, up, height, half_width, lean, true), Color(tint, LIT_FACE * fade)
	)
	ci.draw_line(foot, tip(foot, up, height, lean), Color(rim(tint), RIDGE * fade), 1.0)


## Une esquille : une croix d'un pixel, pas un carré. Un carré de deux pixels est
## un confetti ; une croix est un flocon, à la même dépense.
static func draw_flake(ci: CanvasItem, at: Vector2, tint: Color, fade: float, size := 1.0) -> void:
	if fade <= 0.0:
		return
	var color := Color(rim(tint), fade)
	ci.draw_rect(Rect2(at - Vector2(size * 1.5, size * 0.5), Vector2(size * 3.0, size)), color)
	ci.draw_rect(Rect2(at - Vector2(size * 0.5, size * 1.5), Vector2(size, size * 3.0)), color)
