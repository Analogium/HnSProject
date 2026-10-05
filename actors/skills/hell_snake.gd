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
## Avant `SkillStats.CRAWL_SPEED`, qui l'accroît.
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
## Les petits de l'Hydre, à cette échelle : à pleine taille, on ne les distinguait pas de leur
## parent (choisi sur planche, jalon 41).
const HATCHLING_SIZE := 0.6
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
## L'écart de deux plaques de sol brûlant le long de sa trace : sous le rayon d'une
## plaque, le sillon est continu.
const GROUND_STEP := 12.0
## L'écart de deux serpents d'un même lancer, en radians.
const BROOD_SPREAD := 0.9
## L'Ouroboros : le rayon de son anneau autour du point visé. Le rayon où il serre sa proie
## (Constriction), où la Spirale finit, et la vitesse à laquelle elle rabat ce qu'elle mord.
const OUROBOROS_RING := 40.0
const COIL := 9.0
const SPIRAL_PULL := 60.0

var _cast: SkillStats
var _author: StatusEffects
var _contacts: Targets.Contacts
var _tint := Color.WHITE
var _anchor := Vector2.ZERO
var _head := Vector2.ZERO
var _cap := 0.0
var _age := 0.0
var _seed_of := 0.0
var _since_ground := 0.0
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
## Son échelle de dessin et de longueur : 1 pour un serpent, moins pour un petit de l'Hydre.
var _size := 1.0
## Ceux de chaque lanceur — le joueur, le corbeau qui rejoue —, du plus ancien au plus jeune :
## `simultaneous` au plus chacun (jalon 41). Les petits de l'Hydre n'en sont pas.
static var _broods := {}
var _owner_id := 0
## Effacé par un plus jeune : il se dissout sans mordre, sans éclat ni petits.
var _vanishing := false
## Son tour dans le roulement de peinture.
var _slot := 0
## La Gloutonnerie : ses proies depuis sa dernière mue, et la vie qu'elles lui ont donnée.
var _preys := 0
var _life_bonus := 0.0
## La proie qu'il enlace (Constriction), et les états qu'il tient sous l'Étau.
var _coiled: Hurtbox
var _held: StatusEffects
var _since_spit := 0.0


## `owner` : qui le lâche, et dont il compte dans la limite ; null pour un petit.
static func drop(
	parent: Node, point: Vector2, cast: SkillStats, direction: Vector2, author: StatusEffects,
	owner: Node = null, size := 1.0
) -> HellSnake:
	var s := HellSnake.new()
	s._size = size
	if owner != null:
		s._owner_id = owner.get_instance_id()
		var brood: Array = _broods.get_or_add(s._owner_id, [])
		brood.append(s)
		while cast.max_simultaneous() > 0 and brood.size() > cast.max_simultaneous():
			(brood.pop_front() as HellSnake)._vanish()
	# La Gloutonnerie reconnaît ses proies au lancer qui les tue : à chacun le sien, la
	# couvée partage celui du sort.
	s._cast = cast.echoed(1.0) if cast.gluttony > 0.0 else cast
	s._author = author
	s._contacts = Targets.Contacts.new(cast.period)
	s._tint = DamageType.COLORS[cast.nature]
	s._anchor = point
	# L'Ouroboros naît sur son anneau, lancé le long de lui.
	s._head = point
	if cast.ouroboros > 0.0:
		s._head -= direction.normalized().orthogonal() * OUROBOROS_RING
	s._cap = direction.angle()
	# Déjà étendu derrière la tête : né en un point, il se lirait comme une braise.
	for i in range(RINGS, 0, -1):
		s._trace.append(s._head - direction.normalized() * SPACING * size * float(i))
	s._trace.append(s._head)
	if cast.gluttony > 0.0 and author != null:
		author.slew.connect(s._on_slew)
	s._body = s._rings()
	parent.add_child(s)
	Settings.veil(s, Settings.SPELLS)
	return s


## La Danse du charmeur (jalon 42) : ceux de ce lanceur rôdent désormais autour de ce point.
static func recall(owner: Node, point: Vector2) -> void:
	for snake: HellSnake in _broods.get(owner.get_instance_id(), []):
		snake._anchor = point


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
	if _coiled != null and not is_instance_valid(_coiled):
		_uncoil()
	# Enlacé, il mord deux fois plus vite : l'horloge de ses contacts court double.
	_contacts.advance(delta * (2.0 if _coiled != null else 1.0))
	_ramp(delta)
	_body = _rings()
	if not _vanishing:
		_bite()
		if _cast.spit > 0.0:
			_spit(delta)
	if _age >= lifetime():
		_die()


## Sa vie, et ce que ses proies y ont ajouté.
func lifetime() -> float:
	return _cast.duration + _life_bonus


## Sa dissolution, tout de suite : le fondu de sa fin, puis rien.
func _vanish() -> void:
	_vanishing = true
	_age = maxf(_age, lifetime() - DISSIPATION)


func _enter_tree() -> void:
	crawling += 1
	_slot = _next_slot
	_next_slot += 1


func _exit_tree() -> void:
	crawling -= 1
	_uncoil()
	var brood: Array = _broods.get(_owner_id, [])
	brood.erase(self)
	if brood.is_empty():
		_broods.erase(_owner_id)


## Son tour de peinture à cette image : un serpent sur `ceil(crawling / PAINTED_PER_IMAGE)`.
static func on_turn(slot: int, image: int) -> bool:
	return (image + slot) % maxi(ceili(float(crawling) / float(PAINTED_PER_IMAGE)), 1) == 0


## La peinture suit l'image, pas le pas de physique : quand le jeu rame, Godot enchaîne
## jusqu'à huit pas par image, et rastériser à chacun nourrissait le ralentissement (jalon 41).
## Caché, rien à peindre : le banc des arbres en fait jouer des centaines.
func _process(_delta: float) -> void:
	if _body.is_empty():
		return
	var due := _body_tex == null \
			or (_age - _rasterised >= REDRAW and on_turn(_slot, Engine.get_process_frames()))
	if due and is_visible_in_tree():
		_rasterise()
	queue_redraw()


## Ce que sa mort laisse : les petits de l'Hydre (`HATCHLINGS`). Hors d'un rappel de
## collision, ils naissent tout de suite.
func _die() -> void:
	queue_free()
	if _vanishing:
		return
	var brood := int(_cast.hatchlings)
	if brood <= 0:
		return
	var hatchling := _cast.hatchling()
	for i in brood:
		var toward := Vector2.from_angle(_cap + TAU * float(i) / float(brood))
		drop(get_parent(), _head, hatchling, toward, _author, null, HATCHLING_SIZE)


## Le **chasseur** (`SkillStats.SEEK`) prend pour point de chute l'ennemi le plus proche
## de sa tête : il rôde autour de lui au lieu de rôder où on l'a lâché.
func _hunt() -> void:
	var prey := Targets.nearest(get_world_2d(), _head, _cast.seek_radius)
	if prey != null:
		_anchor = prey.global_position


## Il rôde ; enlacé, il tourne autour de sa proie ; en Ouroboros, autour du point visé —
## sans chasser.
func _ramp(delta: float) -> void:
	var step := SPEED * (1.0 + _cast.crawl_speed * 0.01) * delta
	if _coiled != null:
		_circle(step, _coiled.global_position, COIL)
	elif _cast.ouroboros > 0.0:
		_circle(step, _anchor, _ring())
	else:
		_prowl(delta, step)
	_trace.append(_head)
	if _cast.ground_duration > 0.0 and not _vanishing:
		_since_ground += step
		if _since_ground >= GROUND_STEP:
			_since_ground = 0.0
			DashTrail.patch(get_parent(), _head, _cast.ground(), _author)


func _prowl(delta: float, step: float) -> void:
	if _cast.seek_radius > 0.0:
		_hunt()
	var turn := sin(_age * 2.6 + _seed_of) * 2.2 + sin(_age * 1.1 + _seed_of * 3.0) * 1.4
	var toward_anchor := _anchor - _head
	var beyond := toward_anchor.length() - LEASH * 0.5
	if beyond > 0.0:
		var force := minf(beyond / (LEASH * 0.5), 1.0)
		turn += angle_difference(_cap, toward_anchor.angle()) * REMINDER * force
	_cap += turn * delta
	_head += Vector2.from_angle(_cap) * step


## Un pas sur ce cercle, dans le sens où il allait.
func _circle(step: float, center: Vector2, ring: float) -> void:
	var from_center := _head - center
	var spin := 1.0 if from_center.cross(Vector2.from_angle(_cap)) >= 0.0 else -1.0
	var phase := from_center.angle() + spin * step / ring
	_head = center + Vector2.from_angle(phase) * ring
	_cap = phase + spin * PI * 0.5


## Le rayon de l'anneau : la Spirale le resserre jusqu'au centre sur la vie du serpent.
func _ring() -> float:
	if _cast.spiral <= 0.0:
		return OUROBOROS_RING
	return lerpf(OUROBOROS_RING, COIL, minf(_age / lifetime(), 1.0))


## Pose les anneaux le long de la trace, et oublie ce qui est derrière la queue.
func _rings() -> Array[Vector2]:
	var current_value := _trace[_trace.size() - 1]
	var out: Array[Vector2] = [current_value]
	var i := _trace.size() - 2
	var rest := SPACING * _size
	while out.size() < RINGS and i >= 0:
		var next_item := _trace[i]
		var d := current_value.distance_to(next_item)
		if d >= rest:
			current_value = current_value.move_toward(next_item, rest)
			out.append(current_value)
			rest = SPACING * _size
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
	var scope := float(RINGS) * SPACING * _size * 0.5 + CONTACT
	for target in Targets.in_circle(get_world_2d(), middle, scope):
		if _touches(target.global_position) and _contacts.accepts(target):
			_bite_one(target)


func _bite_one(target: Hurtbox) -> void:
	# Avant le coup : la pourriture que la morsure pose ne se prolonge pas d'elle-même.
	if _cast.rot_hold > 0.0 and target.states != null:
		target.states.extend(StatusEffects.Kind.ROT, _cast.rot_hold)
	# La Spirale mord depuis le centre, et un recul négatif y rabat la proie.
	if _cast.spiral > 0.0:
		Targets.strike(target, _bite_parts(), _anchor, _author, _cast, -SPIRAL_PULL)
	else:
		Targets.strike(target, _bite_parts(), _head, _author, _cast)
	if _cast.constrict > 0.0 and _coiled == null and is_instance_valid(target):
		_coiled = target
		if _cast.vise > 0.0 and target.states != null:
			_held = target.states
			_held.hold(true)


## Le tirage d'une morsure, grossi par ses proies.
func _bite_parts() -> Array[float]:
	var parts := _cast.roll(Game.rng)
	var appetite := 1.0 + _cast.gluttony * 0.01 * float(_preys)
	for i in parts.size():
		parts[i] *= appetite
	return parts


func _uncoil() -> void:
	_coiled = null
	if _held != null:
		_held.hold(false)
		_held = null


## Le Crachat : toutes les `SPIT_PERIOD`, des étincelles vers la proie la plus proche, s'il
## y en a une à portée ; sinon il guette.
func _spit(delta: float) -> void:
	_since_spit += delta
	if _since_spit < SkillStats.SPIT_PERIOD:
		return
	var prey := Targets.nearest(get_world_2d(), _head, SkillStats.SPIT_REACH)
	if prey == null:
		return
	_since_spit = 0.0
	var spat := _cast.spark(_cast.spit * 0.01)
	var toward := _head.direction_to(prey.global_position)
	var count := 1 + int(_cast.spit_fan)
	for i in count:
		var heading := toward.rotated((float(i) - float(count - 1) * 0.5) * SkillStats.SPIT_SPREAD)
		Fireball.spark(get_parent(), _head, heading, spat, _author)


## Une proie de sa morsure : la Gloutonnerie le grossit, `GLUTTONY_MOST` fois au plus.
## Depuis le coup qui tue — l'explosion de la mue se pose d'elle-même en différé.
func _on_slew(cast: SkillStats, _at: Vector2, _victim: StatusEffects) -> void:
	if cast != _cast or _vanishing or _preys >= SkillStats.GLUTTONY_MOST:
		return
	_preys += 1
	_life_bonus += SkillStats.GLUTTONY_LIFE
	_size = 1.0 + SkillStats.GLUTTONY_GROWTH * float(_preys)
	if _preys == SkillStats.GLUTTONY_MOST and _cast.growth_molt > 0.0:
		_molt()


## La Mue de croissance : une gerbe de la force d'une morsure repue, puis le serpent
## repart de zéro — taille, vie, proies. La gerbe a son propre lancer : ses tués ne le
## nourrissent pas, sinon une mue en déclencherait une autre dans la même meute.
func _molt() -> void:
	Explosion.put(
		get_parent(), _head, _bite_parts(), SkillStats.MOLT_RADIUS, null, _tint, _author,
		_cast.echoed(1.0)
	)
	_preys = 0
	_life_bonus = 0.0
	_size = 1.0
	_age = 0.0


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
## Au plus tant de corps repeints par image, chacun à son tour : au-delà, un corps avance
## par petits sauts plutôt que de faire ramer le jeu — 144 serpents coûtaient 22 ms par
## image (jalon 41). Plafonné par seconde de jeu, le coût grossissait avec le ralentissement.
const PAINTED_PER_IMAGE := 8

## Combien rampent en ce moment, et le tour du prochain né.
static var crawling := 0
static var _next_slot := 0


func _draw() -> void:
	var fade := minf(_age / SPAWN, 1.0) * clampf((lifetime() - _age) / DISSIPATION, 0.0, 1.0)
	if _body_tex != null:
		_blit(_body_tex, _corner, fade)

	# Un serpent de feu brûle : une langue un anneau sur trois, jamais sur la queue,
	# où elle serait plus large que la bête. Elles ne mordent pas — la morsure, ce
	# sont les anneaux.
	if _cast.nature == DamageType.Kind.FIRE:
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
		var root := _body[0] + before * (HEAD_RADIUS + 3.0) * _size
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
	var img := _paint()
	if _body_tex == null:
		_body_tex = ImageTexture.create_from_image(img)
	else:
		_body_tex.update(img)


func _paint() -> Image:
	var middle := (_body[0] + _body[RINGS - 1]) * 0.5
	_corner = (middle - Vector2(CANVAS, CANVAS) * 0.5).round()
	var canvas := PixelCanvas.new(CANVAS, CANVAS)
	var skull := _body[0] - _corner
	var forward := (_body[0] - _body[1]).normalized()
	# **Un crâne et un museau**, pas un disque : deux capsules, donc la tête tourne
	# avec le corps sans demander une planche par direction.
	var k := _size
	canvas.capsule(skull, skull - forward * 2.5 * k, (HEAD_RADIUS + 1.5) * k, 0)
	canvas.capsule(skull + forward * 5.0 * k, skull + forward * 1.0 * k, 3.2 * k, 0)
	for i in RINGS - 1:
		# Une bande sur deux de deux crans plus sombre : les écailles. C'est le seul
		# motif qui survive à la taille où la bête est vue.
		var tone: int = _tone_of(i)
		if i % 2 == 1:
			tone = mini(tone + 2, _tones.size() - 1)
		canvas.capsule(
			_body[i] - _corner, _body[i + 1] - _corner,
			lerpf(HEAD_RADIUS, TAIL_RADIUS, float(i) / float(RINGS - 1)) * k, tone
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
			var eye: Vector2 = skull + forward * (1.6 * k + float(step)) + side * 3.4 * k * sign_value
			canvas.dot_px(int(round(eye.x)), int(round(eye.y)), R_EYE, 0.5)
	return canvas.to_image(_palettes)


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
