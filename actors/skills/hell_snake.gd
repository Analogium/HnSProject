class_name HellSnake
extends Node2D

## Le serpent de Serpent infernal : lâché au sol, il y rôde, et son corps brûle ce
## qu'il touche — une fois par période pour chaque cible.

## Vingt anneaux serrés : c'est la **finesse** qui dit « serpent ». À seize anneaux
## de 3,6 et cinq de rayon, c'était un tuyau épais qui ondulait ; le même corps
## plus fin et plus découpé se lit d'un coup. L'écart est choisi pour que la
## longueur totale ne bouge pas — 54 pixels —, sinon la morsure s'allongerait avec
## le dessin.
const RINGS := 20
const SPACING := 2.85
const SPEED := 62.0
## Au-delà de la moitié, il tourne vers son point de chute ; à la laisse entière, de
## toutes ses forces. Sans rappel, un cap au hasard l'emmène hors de l'écran en
## quatre secondes.
const LEASH := 44.0
const REMINDER := 3.0
## D'un anneau au centre d'une hurtbox ennemie.
const CONTACT := 11.0
## Plus épais qu'à l'époque des cercles tracés : une silhouette cernée perd un
## pixel de matière au contour, et à trois de rayon le serpent sortait ver de
## terre. La morsure, elle, ne bouge pas — c'est `CONTACT` qui la tient.
const HEAD_RADIUS := 4.0
## La queue **finit en pointe**. Arrêtée net à deux pixels, la bête était un tuyau
## coupé — c'est l'une des trois choses qu'un volume éclairé n'invente pas tout
## seul, avec la tête et le dos.
const TAIL_RADIUS := 0.8
const SPAWN := 0.2
const DISSIPATION := 0.4
const EMBER_SHADOW := Color(0.32, 0.05, 0.03)
const EYES := Color(0.15, 0.05, 0.02)
## La crête du dos, plus claire que le corps : c'est elle qui dit de quel côté on
## regarde la bête.
const CREST := Color(1.0, 0.72, 0.30)
## Rangs des rampes passées à `to_image()`, après les tons du corps.
const R_EYE := 5
const R_CREST := 6
## La part du corps que la crête parcourt, de la tête vers la queue.
const CREST_PART := 0.6
const TONGUE := Color(0.9, 0.15, 0.1)

var _cast: SkillStats
var _author: StatusEffects
var _contacts: Targets.Contacts
var _tint := Color.WHITE
var _anchor := Vector2.ZERO
var _head := Vector2.ZERO
var _cap := 0.0
var _age := 0.0
var _seed_of := 0.0
## Les positions passées de la tête, la plus récente à la fin. Le corps s'y pose à
## intervalles de longueur réguliers : il ondule dans les pas de la tête au lieu de
## pivoter d'un bloc.
var _trace: Array[Vector2] = []
## Les anneaux de l'image, tête d'abord, en coordonnées globales.
var _body: Array[Vector2] = []
## Les trois tons du corps, de la tête à la queue. La tête tire vers le blanc
## chaud — **un quart et pas plus** : à 0,6 le corps sortait beige, et un ver beige
## n'est pas un serpent de feu.
var _tones: Array[Color] = []
## Les rampes du corps, une par ton : `PixelCanvas` choisit la couleur au moment
## de l'image, à partir du rang que porte chaque capsule.
var _palettes: Array = []
var _body_tex: ImageTexture
## Le coin de l'image du corps, en repère global et en pixels entiers.
var _corner := Vector2.ZERO
var _rasterised := -1.0


static func drop(
	parent: Node, point: Vector2, cast: SkillStats, direction: Vector2, author: StatusEffects
) -> HellSnake:
	var s := HellSnake.new()
	s._cast = cast
	s._author = author
	s._contacts = Targets.Contacts.new(cast.period)
	s._tint = DamageType.COLORS[cast.dominant_nature()]
	s._anchor = point
	s._head = point
	s._cap = direction.angle()
	# Déjà étendu derrière la tête : né en un point, il se lirait comme une braise.
	for i in range(RINGS, 0, -1):
		s._trace.append(point - direction.normalized() * SPACING * float(i))
	s._trace.append(point)
	s._body = s._rings()
	parent.add_child(s)
	Settings.veil(s, Settings.SPELLS)
	return s


func _ready() -> void:
	z_index = 1
	# **Un corps de braise, pas de flamme** : à pleine teinte, le corps et les
	# langues avaient la même couleur et la bête devenait une bouillie orange. Les
	# langues brillent parce que le dos est sombre.
	# Cinq tons et non trois : à trois, les changements se voyaient comme deux
	# coutures en travers du dos. La tête garde la teinte pleine, la queue s'éteint
	# — c'est le dos sombre qui fait briller les langues, pas leur propre lumière.
	_tones = [
		_tint, _tint.darkened(0.16), _tint.darkened(0.30),
		_tint.darkened(0.44), _tint.darkened(0.58),
	]
	# Ombre **rouge sombre** et non le violet froid du jeu : une bête de braise est
	# sa propre lumière, et ses creux tiraient au brun-violet — un tronc d'arbre.
	for tone: Color in _tones:
		_palettes.append(ArtPalette.ramp(tone, EMBER_SHADOW))
	_palettes.append(ArtPalette.ramp(EYES, EMBER_SHADOW))
	_palettes.append(ArtPalette.ramp(CREST, EMBER_SHADOW))
	_seed_of = float(get_instance_id() % 1000) * 0.01


func _physics_process(delta: float) -> void:
	_age += delta
	_contacts.advance(delta)
	_ramp(delta)
	_body = _rings()
	_bite()
	if _age - _rasterised >= REDRAW:
		_rasterise()
	queue_redraw()
	if _age >= _cast.duration:
		queue_free()


func _ramp(delta: float) -> void:
	var turn := sin(_age * 2.6 + _seed_of) * 2.2 + sin(_age * 1.1 + _seed_of * 3.0) * 1.4
	var toward_anchor := _anchor - _head
	var beyond := toward_anchor.length() - LEASH * 0.5
	if beyond > 0.0:
		var force := minf(beyond / (LEASH * 0.5), 1.0)
		turn += angle_difference(_cap, toward_anchor.angle()) * REMINDER * force
	_cap += turn * delta
	_head += Vector2.from_angle(_cap) * SPEED * delta
	_trace.append(_head)


## Pose les anneaux le long de la trace, et oublie ce qui est derrière la queue.
func _rings() -> Array[Vector2]:
	var current_value := _trace[_trace.size() - 1]
	var out: Array[Vector2] = [current_value]
	var i := _trace.size() - 2
	var rest := SPACING
	while out.size() < RINGS and i >= 0:
		var next_item := _trace[i]
		var d := current_value.distance_to(next_item)
		if d >= rest:
			current_value = current_value.move_toward(next_item, rest)
			out.append(current_value)
			rest = SPACING
		else:
			rest -= d
			current_value = next_item
			i -= 1
	while out.size() < RINGS:
		out.append(out[out.size() - 1])
	if i > 0:
		_trace = _trace.slice(i)
	return out


func _bite() -> void:
	var middle := _body[int(RINGS * 0.5)]
	var scope := float(RINGS) * SPACING * 0.5 + CONTACT
	for target in Targets.in_circle(get_world_2d(), middle, scope):
		if _touches(target.global_position) and _contacts.accepts(target):
			Targets.strike(target, _cast.roll(Game.rng), _head, _author, _cast)


func _touches(point: Vector2) -> bool:
	for ring in _body:
		if ring.distance_squared_to(point) <= CONTACT * CONTACT:
			return true
	return false


## Le corps est rastérisé **en une seule image** : une capsule d'un anneau au
## suivant, et le contour posé autour de l'union. En file de perles cernées
## chacune, le dos se couvrait de bosses et de moirés — seize dégradés côte à côte
## font du bruit, là où un seul volume éclairé fait une bête.
##
## Mesuré à **0,64 ms par image** (seize anneaux dans 96×96), dont 0,47 pour la
## seule mise en pixels. Refait trente fois par seconde et non soixante : le
## serpent avance d'un pixel par image, sa forme n'en change pas, et la dépense
## retombe à 0,32 ms.
const CANVAS := 96
const REDRAW := 1.0 / 30.0


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((_cast.duration - _age) / DISSIPATION, 0.0, 1.0)
	if _body_tex != null:
		_blit(_body_tex, _corner, fade)

	# Un serpent de feu brûle : une langue un anneau sur trois, jamais sur la queue,
	# où elle serait plus large que la bête. Elles ne mordent pas — la morsure, ce
	# sont les anneaux.
	if _cast.dominant_nature() == DamageType.Kind.FIRE:
		var flames := EffectForge.small_flames(_tint)
		var offset := Vector2(EffectForge.SMALL_WIDTH * 0.5, EffectForge.SMALL_HEIGHT - 2)
		# Un anneau sur quatre : le corps ayant gagné quatre anneaux, un sur trois
		# redonnait le peigne que le premier réglage avait retiré.
		for i in range(0, RINGS - 5, 4):
			var frame := int(_age * EffectForge.FLAME_HZ + float(i) * 1.3) % flames.size()
			_blit(flames[frame], _body[i] - offset, fade)

	# La langue, par intermittence : toujours sortie, elle se lit comme une tige.
	# Dessinée à part du corps, donc à chaque image : elle dure un dixième de
	# seconde, et trente hertz la feraient clignoter.
	if fmod(_age + _seed_of, 0.7) < 0.15:
		var before := Vector2.from_angle(_cap)
		var side := before.orthogonal()
		var root := _body[0] + before * (HEAD_RADIUS + 3.0)
		for step in 3:
			_pixel(root + before * float(step), TONGUE, fade)
		var tip_end := root + before * 3.0
		_pixel(tip_end + (before + side).normalized() * 1.6, TONGUE, fade)
		_pixel(tip_end + (before - side).normalized() * 1.6, TONGUE, fade)


## Met le corps en pixels : une capsule par intervalle d'anneaux, le rang de la
## rampe par tiers de longueur. Le cadre est fixe pour que la texture se mette à
## jour au lieu d'être recréée, et `to_image` ne balaie de toute façon que ce qui
## est peint.
func _rasterise() -> void:
	_rasterised = _age
	var middle := (_body[0] + _body[RINGS - 1]) * 0.5
	_corner = (middle - Vector2(CANVAS, CANVAS) * 0.5).round()
	var canvas := PixelCanvas.new(CANVAS, CANVAS)
	var skull := _body[0] - _corner
	var forward := (_body[0] - _body[1]).normalized()
	# **Un crâne et un museau**, pas un disque : deux capsules, donc la tête tourne
	# avec le corps sans demander une planche par direction.
	canvas.capsule(skull, skull - forward * 2.5, HEAD_RADIUS + 1.5, 0)
	canvas.capsule(skull + forward * 5.0, skull + forward * 1.0, 3.2, 0)
	for i in RINGS - 1:
		# Une bande sur deux de deux crans plus sombre : les écailles. C'est le seul
		# motif qui survive à la taille où la bête est vue.
		var tone: int = _tone_of(i)
		if i % 2 == 1:
			tone = mini(tone + 2, _tones.size() - 1)
		canvas.capsule(
			_body[i] - _corner, _body[i + 1] - _corner,
			lerpf(HEAD_RADIUS, TAIL_RADIUS, float(i) / float(RINGS - 1)), tone
		)

	# La crête, posée après le corps : un pixel clair le long de l'échine. Sans
	# elle, un serpent vu de dessus n'a pas de dos — c'est un tuyau. Elle **meurt
	# avant la queue** et s'éteint en chemin : menée jusqu'au bout et à pleine
	# clarté, elle se lit comme un ruban peint sur la bête.
	var ridge := int(float(RINGS) * CREST_PART)
	for i in ridge:
		var steps := int(_body[i].distance_to(_body[i + 1])) + 1
		for step in steps:
			var along := (float(i) + float(step) / float(steps)) / float(ridge)
			var p: Vector2 = _body[i].lerp(_body[i + 1], float(step) / float(steps)) - _corner
			canvas.dot_px(int(round(p.x)), int(round(p.y)), R_CREST, lerpf(1.0, 0.35, along))

	# Deux pixels par œil, dans le sens du museau : à un seul, l'œil disparaît sur
	# une tête de dix pixels et la bête redevient aveugle.
	var side := forward.orthogonal()
	for sign_value: float in [-1.0, 1.0]:
		for step in 2:
			var eye: Vector2 = skull + forward * (1.6 + float(step)) + side * 3.4 * sign_value
			canvas.dot_px(int(round(eye.x)), int(round(eye.y)), R_EYE, 0.5)
	var img := canvas.to_image(_palettes)
	if _body_tex == null:
		_body_tex = ImageTexture.create_from_image(img)
	else:
		_body_tex.update(img)


## Trois tons du corps et non seize : le dégradé fin est dans le volume éclairé,
## et seize rampes ne se distingueraient pas de trois.
func _tone_of(i: int) -> int:
	return mini(i * _tones.size() / RINGS, _tones.size() - 1)


## Pose une planche à ce coin du monde, **calée sur le pixel du jeu** : posée entre
## deux pixels, elle se rééchantillonne et ses blocs se brisent.
func _blit(tex: Texture2D, corner: Vector2, fade: float, tone := 1.0) -> void:
	draw_texture_rect(
		tex, Rect2(corner.round() - global_position, Vector2(tex.get_width(), tex.get_height())),
		false, Color(tone, tone, tone, fade)
	)


func _pixel(at: Vector2, color: Color, fade: float) -> void:
	draw_rect(Rect2(at.round() - global_position, Vector2.ONE), Color(color, fade))
