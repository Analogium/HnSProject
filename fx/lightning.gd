class_name Lightning
extends RefCounted

## La foudre du jeu, dessinée en un seul endroit : la chaîne, les éclairs du nuage,
## les bras de la charge statique et la traînée de la ruée. Quatre gestes dessinés
## de quatre façons ne se liraient pas comme la même matière.
##
## Trois passes et rien d'autre : un halo large et **teinté**, un corps, et un
## filament d'un pixel presque blanc. C'est ce filament seul qui dépasse le seuil
## de glow (0,9) — le violet de la foudre plafonne à 0,63 de luminance, donc un
## éclair entièrement teinté ne brille jamais, quelle que soit son opacité. Et
## c'est le halo, large, qui porte la couleur : l'inverse donnerait un éclat
## blanc sans nature.

## Longueur d'un segment du trait brisé. Plus court, le trait devient une corde
## qui grésille ; plus long, une ligne droite qui a raté son virage.
const STEP := 9.0
const JITTER := 4.0

## Cadence du grésillement, en changements de forme par seconde. À 60 — une forme
## par image — l'œil ne voit plus un éclair mais du bruit.
const FLICKER_HZ := 18.0


## La graine qui tient une forme quelques images. Les appelants la combinent avec
## la leur : deux éclairs voisins ne doivent pas battre à l'unisson.
static func hold(age: float) -> int:
	return int(age * FLICKER_HZ)


## Un trait droit cassé en sommets déplacés au hasard.
static func path(
	a: Vector2, b: Vector2, rng: RandomNumberGenerator, jitter_amount := JITTER
) -> PackedVector2Array:
	var n := maxi(ceili(a.distance_to(b) / STEP), 2)
	var across := (b - a).orthogonal().normalized()
	var out := PackedVector2Array([a])
	for k in range(1, n):
		out.append(a.lerp(b, float(k) / float(n)) + across * rng.randf_range(-jitter_amount, jitter_amount))
	out.append(b)
	return out


## Un éclair de `a` vers `b`, fourches comprises. `scale` épaissit tout le trait,
## `forks` compte les branches mortes — c'est ce qui sépare une décharge d'un fil
## électrique, et deux suffisent : au-delà, la silhouette se brouille.
static func draw_bolt(
	ci: CanvasItem, a: Vector2, b: Vector2, rng: RandomNumberGenerator,
	tint: Color, fade: float, scale := 1.0, forks := 2
) -> void:
	if fade <= 0.0:
		return
	var core := tint.lerp(Color.WHITE, 0.92)
	var main := path(a, b, rng, JITTER * scale)
	_passes(ci, main, tint, core, fade, scale)

	var span := a.distance_to(b)
	var along := (b - a).normalized() if span > 0.01 else Vector2.RIGHT
	for i in forks:
		var at := rng.randi_range(1, maxi(main.size() - 2, 1))
		var from_value: Vector2 = main[at]
		# La fourche repart de biais, parfois vers l'arrière : une branche qui
		# suit la trajectoire principale ne se voit pas.
		var away := along.rotated(rng.randf_range(0.5, 1.3) * (1.0 if rng.randf() < 0.5 else -1.0))
		var to := from_value + away * span * rng.randf_range(0.16, 0.34)
		_passes(ci, path(from_value, to, rng, JITTER * 0.7 * scale), tint, core, fade * 0.6, scale * 0.65)


## Un éclat au point d'impact : la fin d'un éclair n'est pas la fin d'un trait.
##
## **Teinté large, blanc minuscule.** Un seul disque blanchi de rayon 6 faisait une
## tache de 26 pixels à l'écran — le facteur 2 du cadrage se paie ici — et les deux
## ennemis frappés disparaissaient dessous.
static func draw_strike(ci: CanvasItem, at: Vector2, tint: Color, fade: float, size := 4.0) -> void:
	Glow.draw_blob(ci, at, size * (0.6 + 0.4 * fade), Color(tint, 0.5 * fade))
	Glow.draw_blob(ci, at, size * 0.34, Color(tint.lerp(Color.WHITE, 0.85), 0.85 * fade))


static func _passes(
	ci: CanvasItem, pts: PackedVector2Array, tint: Color, core: Color, fade: float, scale: float
) -> void:
	# Les deux passes teintées ont une **largeur plancher** : sous trois pixels, le
	# halo disparaît derrière le filament blanc et l'éclair perd sa couleur — un
	# petit projectile de foudre ressortait blanc, donc physique.
	ci.draw_polyline(pts, Color(tint, 0.10 * fade), maxf(7.0 * scale, 4.0))
	ci.draw_polyline(pts, Color(tint, 0.28 * fade), maxf(3.0 * scale, 2.2))
	ci.draw_polyline(pts, Color(core, fade), 1.0)
