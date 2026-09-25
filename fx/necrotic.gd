class_name Necrotic
extends RefCounted

## La nécrose, **posée** en un seul endroit : sa couleur, le mur de gaz de la
## Déferlante toxique et des créatures de la Porte, le cercle de la Malédiction
## putride. Ses planches — crâne, fumées, faille, créature, œil, spore — sont dans
## `EffectForge`, choisies sur planche au jalon 26.
##
## **La nécrose ronge, elle n'éclaire pas** : son cœur est un jaune maladif, et elle a
## un dedans — l'ombre des orbites, la chair d'une faille —, là où le feu et le sacré
## n'ont qu'une lumière.

## Le jaune maladif du cœur : ni le blanc chaud du feu, ni le blanc du sacré.
const SICK := Color(0.90, 0.96, 0.58)
const CORE := 0.85
## L'ombre des orbites et des pupilles : un violet noir, le bas de la rampe des ombres.
const SHADE := Color(0.30, 0.16, 0.36)
## La chair d'une faille : ce qui s'ouvre sur l'autre monde est vivant.
const FLESH := Color(0.66, 0.36, 0.42)

## Le mur de gaz se refait par crans et non à chaque image : huit formes pour toute
## l'onde, gardées par rayon. Relancée, une Déferlante ne coûte plus rien.
const MIASMA_STEPS := 8
## L'écart entre deux bosses du mur, en pixels, **au plein rayon** : leur nombre ne
## change pas pendant que l'onde s'ouvre, sinon le mur grouillerait.
const MIASMA_BUMP_STEP := 11.0
## Les crans de dissolution du cercle maudit.
const RING_STEPS := 4
## L'écart entre deux points du cercle, en pixels : les capsules font le reste.
const RING_STEP := 8.0

static var _miasmas := {}
static var _rings := {}


## Le cœur de cette teinte — le seul endroit où la nécrose a le droit d'être claire.
static func core(tint: Color) -> Color:
	return tint.lerp(SICK, CORE)


## Le cran de dissolution de `gone`, pour qu'un cache garde la forme.
static func step_of(value: float, steps: int) -> int:
	return clampi(int(value * float(steps)), 0, steps)


## Le mur de gaz d'un souffle de ce rayon, à `k` de sa vie : **d'un seul tenant**,
## bosselé, qui s'écarte en s'épaississant puis se dissout. Choisi sur planche contre
## une couronne de nuages, une nappe tramée, une spirale et une volée de crânes : une
## pièce qu'on répète fait un collier, un mur rastérisé n'a qu'un contour.
static func miasma(tint: Color, radius: float, k: float) -> Array:
	var step := step_of(k, MIASMA_STEPS - 1)
	var key := "%s@%d@%d" % [tint.to_html(false), roundi(radius), step]
	if not _miasmas.has(key):
		var ks := float(step) / float(MIASMA_STEPS - 1)
		var r := radius * (1.0 - pow(1.0 - minf(ks * 1.6, 1.0), 3.0))
		var bumps := maxi(int(TAU * radius / MIASMA_BUMP_STEP), 12)
		var discs: Array[Vector3] = []
		for i in bumps:
			var at := Vector2.from_angle(TAU * float(i) / float(bumps)) * r
			discs.append(Vector3(at.x, at.y, 2.2 + 1.3 * sin(float(i) * 2.7) + ks * 1.5))
		# Une bouffée sur le bord extérieur, une bosse sur deux : sans elles le mur est un
		# tore lisse, un anneau de néon plutôt qu'un gaz.
		var puffs: Array[Vector3] = []
		for i in range(0, bumps, 2):
			var d := discs[i]
			var out := Vector2(d.x, d.y).normalized() * d.z * 0.7
			puffs.append(Vector3(d.x + out.x, d.y + out.y, d.z * 0.9))
		var glints: Array[Vector2] = []
		for i in 5:
			glints.append(Vector2.from_angle(float(i) * 1.3) * r)
		_miasmas[key] = _band(tint, discs, glints, 0.3, clampf((ks - 0.6) * 2.5, 0.0, 1.0), puffs)
	return _miasmas[key]


## Le cercle d'une malédiction : **épais**, parce qu'un trait d'un pixel se lit comme
## un affichage de portée. Dissous par crans à la fin.
static func ring(tint: Color, radius: float, gone: float) -> Array:
	var step := step_of(gone, RING_STEPS)
	var key := "%s@%d@%d" % [tint.to_html(false), roundi(radius), step]
	if not _rings.has(key):
		var n := maxi(int(TAU * radius / RING_STEP), 8)
		var discs: Array[Vector3] = []
		for i in n:
			var at := Vector2.from_angle(TAU * float(i) / float(n)) * radius
			discs.append(Vector3(at.x, at.y, 1.3))
		_rings[key] = _band(tint, discs, [] as Array[Vector2], 0.5, float(step) / float(RING_STEPS))
	return _rings[key]


## Pose les secteurs d'un anneau autour de `at`.
static func put_band(ci: CanvasItem, pieces: Array, at: Vector2) -> void:
	for piece: EffectForge.Piece in pieces:
		piece.put(ci, at)


## Un anneau autour du centre, par ses disques dans l'ordre — plus des bouffées posées
## dessus —, **en quatre quadrants** coupés le long des
## axes. D'un bloc, `to_image()` balayait tout le vide du milieu — une rangée se
## balaie du premier pixel peint au dernier —, 1,2 ms au rayon 48 ; un quadrant ne
## balaie que l'arc qui le traverse. Chacun est peint **un pixel plus large** que sa
## part puis rogné : le contour de la jointure se calcule sur la silhouette entière, et
## les quadrants se raccordent sans couture.
static func _band(
	tint: Color, discs: Array[Vector3], glints: Array[Vector2], bias: float, gone: float,
	puffs: Array[Vector3] = []
) -> Array:
	var reach := 0.0
	for d in discs + puffs:
		reach = maxf(reach, Vector2(d.x, d.y).length() + d.z + 2.0)
	var c := int(ceilf(reach))
	var side := c * 2 + 1
	var palettes := [ArtPalette.ramp(tint), ArtPalette.ramp(core(tint))]
	var pieces: Array[EffectForge.Piece] = []
	for q in 4:
		var part := Rect2i(
			0 if q % 2 == 0 else c, 0 if q < 2 else c,
			c if q % 2 == 0 else side - c, c if q < 2 else side - c
		)
		var wide := part.grow(1).intersection(Rect2i(0, 0, side, side))
		var canvas := PixelCanvas.new(wide.size.x, wide.size.y)
		var corner := Vector2(wide.position)
		# En capsules d'un disque au suivant, et non en disques : chaque disque prend
		# son propre éclairage, et l'anneau se lisait comme un collier de perles.
		var area := Rect2(corner, Vector2(wide.size))
		for i in discs.size():
			var d := discs[i]
			var e := discs[(i + 1) % discs.size()]
			var from := Vector2(d.x + c, d.y + c)
			var to := Vector2(e.x + c, e.y + c)
			var r := (d.z + e.z) * 0.5
			if area.grow(r + 1.0).has_point(from) or area.grow(r + 1.0).has_point(to):
				canvas.capsule(from - corner, to - corner, r, EffectForge.R_TINT, bias)
		for d in puffs:
			var at := Vector2(d.x + c, d.y + c)
			if area.grow(d.z + 1.0).has_point(at):
				canvas.disc(at - corner, d.z, EffectForge.R_TINT, bias)
		for g in glints:
			var at := Vector2(g.x + c, g.y + c).round()
			canvas.dot_px(int(at.x - corner.x), int(at.y - corner.y), EffectForge.R_CORE, 1.0)
		if canvas.is_empty():
			continue
		var img := canvas.to_image(palettes).get_region(
			Rect2i(part.position - wide.position, part.size)
		)
		EffectForge.dissolve(img, gone)
		pieces.append(EffectForge.Piece.new(
			ImageTexture.create_from_image(img), Vector2(part.position - Vector2i(c, c))
		))
	return pieces


## Une planche posée **par son centre**, calée sur le pixel du jeu.
static func centered(ci: CanvasItem, tex: Texture2D, at: Vector2) -> void:
	var size := Vector2(tex.get_width(), tex.get_height())
	ci.draw_texture_rect(tex, Rect2(EffectForge.snap(ci, at - (size * 0.5).floor()), size), false)
