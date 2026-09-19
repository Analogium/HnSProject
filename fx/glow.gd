class_name Glow
extends RefCounted

## Les trois textures de lumière des effets : un cœur, un anneau, une traînée.
##
## Elles existent parce que le dessin vectoriel donnait des bords nets — un
## `draw_arc` d'un pixel se lit comme un affichage de portée, pas comme une
## flamme — et parce que le glow du `WorldEnvironment` ne fait déborder que ce
## qui **dépasse 0,9 de luminance** : un effet a besoin d'un cœur presque blanc,
## que 32 pixels de dégradé donnent et qu'un trait d'alpha 0,25 ne donnera
## jamais.
##
## Trois textures et non une par effet : c'est leur *forme* qui diffère, jamais
## leur matière. Générées une fois, gardées pour la session comme les planches
## de la forge.

## Assez grandes pour qu'un effet de 100 px ne montre pas ses pixels, assez
## petites pour être gratuites (2 304 et 4 096 pixels).
const BLOB_SIZE := 48
const RING_SIZE := 64
const STREAK_LENGTH := 64
const STREAK_WIDTH := 16

static var _blob: Texture2D
static var _ring: Texture2D
static var _streak: Texture2D


## Un cœur : opaque au centre, éteint au bord. L'exposant 1,6 tient le centre
## plein plus longtemps qu'un dégradé linéaire — c'est lui qui passe le seuil de
## glow au lieu de le frôler.
static func blob() -> Texture2D:
	if _blob == null:
		_blob = _build(BLOB_SIZE, BLOB_SIZE, func(u: float, v: float) -> float:
			var d := Vector2(u, v).length()
			return pow(clampf(1.0 - d, 0.0, 1.0), 1.6)
		)
	return _blob


## Un anneau mou dont la retombée est **asymétrique** : longue vers l'intérieur,
## courte vers l'extérieur, où elle s'éteint pile sur le rayon de l'effet. Un
## halo qui dépasse promettrait une portée que le coup n'a pas — c'est la
## première chose que la pulsation sacrée refuse.
##
## La crête a un **plateau** et non une pointe. Sans lui, aucun pixel ne tombe
## pile dessus — mesuré 0,87 au mieux sur 64 pixels — et l'anneau passait donc
## sous le seuil de glow de 0,9 : il n'aurait jamais débordé, quelle que soit sa
## couleur. Le piège se reposera à chaque dégradé dont le maximum est un point.
const RING_CREST := 0.88
const RING_PLATEAU := 0.03
## La retombée extérieure s'éteint **un pixel avant le bord de l'image** : sinon
## le dernier pixel garde 0,03 d'alpha, et l'anneau déborde d'un liseré.
const RING_OUT := 1.0 - RING_CREST - RING_PLATEAU - 2.0 / float(RING_SIZE)
const RING_IN := 0.31


static func ring() -> Texture2D:
	if _ring == null:
		_ring = _build(RING_SIZE, RING_SIZE, func(u: float, v: float) -> float:
			var delta := Vector2(u, v).length() - RING_CREST
			var span := RING_OUT if delta > 0.0 else RING_IN
			var t := (absf(delta) - RING_PLATEAU) / span
			return pow(1.0 - clampf(t, 0.0, 1.0), 2.0)
		)
	return _ring


## Une traînée : tête pleine à gauche, queue éteinte à droite. Le carré sur la
## largeur et la puissance 1,5 sur la longueur donnent une comète, pas un bâton.
## Même plateau que l'anneau, et pour la même raison : l'axe de la comète tombe
## entre deux rangées de pixels.
static func streak() -> Texture2D:
	if _streak == null:
		_streak = _build(STREAK_LENGTH, STREAK_WIDTH, func(u: float, v: float) -> float:
			var across := pow(clampf((1.0 - absf(v)) / 0.82, 0.0, 1.0), 2.0)
			return across * pow(clampf(1.0 - (u + 1.0) * 0.5, 0.0, 1.0), 1.5)
		)
	return _streak


## Un cœur centré sur `center`. La couleur passe par `modulate` et non par la
## texture : la même image sert au feu, au froid et au sacré.
static func draw_blob(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	ci.draw_texture_rect(
		blob(), Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color
	)


## `radius` est le rayon **qui mord** : c'est la crête qui s'y pose, et rien n'est
## peint au-delà.
static func draw_ring(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var outer := radius / RING_CREST
	ci.draw_texture_rect(
		ring(), Rect2(center - Vector2(outer, outer), Vector2(outer, outer) * 2.0), false, color
	)


## De `from` vers `to`, `width` de large. La tête est sur `from` : une comète
## regarde là d'où elle vient.
static func draw_streak(ci: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var span := to - from
	var length := span.length()
	if length < 0.01:
		return
	ci.draw_set_transform(from, span.angle(), Vector2.ONE)
	ci.draw_texture_rect(streak(), Rect2(0.0, -width * 0.5, length, width), false, color)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## Le dégradé est écrit dans le canal alpha seul : en mélange additif, le blanc
## multiplié par la couleur de l'effet donne la teinte, et un dégradé posé sur
## le RGB la perdrait au centre.
static func _build(w: int, h: int, falloff: Callable) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var v := (float(y) + 0.5) / float(h) * 2.0 - 1.0
		for x in w:
			var u := (float(x) + 0.5) / float(w) * 2.0 - 1.0
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff.call(u, v)))
	return ImageTexture.create_from_image(img)
